require ecs
require DagorMath
require AnimV20
require DagorSystem
require DagorMath
require GeomNodeTree
require %appGame.es.animchar.attach_common
require %game.events

[es(tag=server, on_appear, on_disappear, track=slot_attach__attachedTo)]
def skeleton_attach_do_attach_es(evt : Event;
                                 eid : EntityId;
                                 slot_attach__attachedTo : EntityId;
                                 var skeleton_attach__attached : bool&;
                                 var skeleton_attach__attachedTo : EntityId&)
  let oldAttachedTo = skeleton_attach__attachedTo
  skeleton_attach__attachedTo = slot_attach__attachedTo
  if !skeleton_attach__attached && !!slot_attach__attachedTo
    skeleton_attach__attached = true
    sendEvent(eid, [[EventItemAttached attach_to=slot_attach__attachedTo]])
  elif !!slot_attach__attachedTo && oldAttachedTo != slot_attach__attachedTo
    sendEvent(eid, [[EventItemDetached detach_from=oldAttachedTo]])
    sendEvent(eid, [[EventItemAttached attach_to=slot_attach__attachedTo]])
  elif skeleton_attach__attached && !slot_attach__attachedTo
    skeleton_attach__attached = false
    sendEvent(eid, [[EventItemDetached detach_from=oldAttachedTo]])

def remove_skeleton_attach(eid : EntityId;
                           var animchar : AnimcharBaseComponent&)
  let nodesCount = int(animchar.nodeTree.nodeCount)
  for i in range(0, nodesCount)
    geomtree_getNodeTm(*animchar.nodeTree, i) = geomtree_getNodeTm(*animchar.originalNodeTree, i)
  animchar |> animchar_doRecalcAnimAndWtm()
  removeSubTemplate(eid, "base_skeleton_attach")


[es(tag=gameClient, on_appear, track=skeleton_attach__attached, REQUIRE=skeleton_attach__skeletonRemap)]
def skeleton_attach_clear_attach_es(evt : Event;
                                    eid : EntityId;
                                    skeleton_attach__attached : bool;
                                    var animchar__usePrecalculatedData : bool&;
                                    var animchar : AnimcharBaseComponent&)
  if !skeleton_attach__attached
    animchar__usePrecalculatedData = false
    remove_skeleton_attach(eid, animchar)


[es(tag=gameClient, on_disappear, track=skeleton_attach__attached, REQUIRE=skeleton_attach__skeletonRemap)]
def skeleton_attach_destroy_attach_es(evt : Event;
                                      eid : EntityId;
                                      skeleton_attach__attached : bool;
                                      var animchar__usePrecalculatedData : bool&;
                                      var animchar : AnimcharBaseComponent&)
  if skeleton_attach__attached
    animchar__usePrecalculatedData = false
    remove_skeleton_attach(eid, animchar)




def skeleton_attach_remap_impl(attach_animchar : AnimcharBaseComponent;
                               skeleton_attach__attachedTo : EntityId;
                               skeleton_attach__postfixIdx : int;
                               var out_skeleton_remap : UInt16List | UInt16List#;
                               var out_skeleton_recalc_branch : UInt8List | UInt8List#)
  var result = false
  clear(out_skeleton_remap)
  clear(out_skeleton_recalc_branch)
  query(skeleton_attach__attachedTo) <| $ [es] (animchar aka attachedTo_animchar : AnimcharBaseComponent)
    let attachedTonodesCount = int(attachedTo_animchar.nodeTree.nodeCount)

    if attachedTonodesCount == 0
      return

    using() <| $(var nodesWithoutRemap : UInt16List)
      let attachNodesCount = int(attach_animchar.nodeTree.nodeCount)
      for i in range(0, attachNodesCount)
        let origNodeName = *attach_animchar.nodeTree |> geomtree_getNodeName(i)
        var nodeName = origNodeName
        if skeleton_attach__postfixIdx >= 0
          nodeName = "{origNodeName}_{skeleton_attach__postfixIdx}"

        let nodeIdx = *attachedTo_animchar.nodeTree |> geomtree_findNodeIndex(nodeName)
        if nodeIdx >= 0
          assert(nodeIdx <= 255)
          assert(i <= 255)
          push(out_skeleton_remap, uint16(nodeIdx << 8 | i))
        else
          push(nodesWithoutRemap, uint16(i))

      for nodeNo in nodesWithoutRemap
        let parNodeId = geomtree_getParentNodeIdx(*attach_animchar.nodeTree, int(nodeNo))
        for skelNode in out_skeleton_remap
          if get_node_no(skelNode) == parNodeId
            push(out_skeleton_recalc_branch, uint8(nodeNo))
            break
    result = true

  return result

[es(tag=gameClient, on_event=CmdInitSkeletonAttach)]
def skeleton_attach_reinit_es(evt : Event;
                              eid : EntityId;
                              animchar : AnimcharBaseComponent&;
                              skeleton_attach__attachedTo : EntityId;
                              skeleton_attach__postfixIdx : int = -1;
                              var skeleton_attach__skeletonRemap : UInt16List;
                              var skeleton_attach__skeletonRecalcBranch : UInt8List)
  let isSuccess = skeleton_attach_remap_impl(animchar,
                                             skeleton_attach__attachedTo,
                                             skeleton_attach__postfixIdx,
                                             skeleton_attach__skeletonRemap,
                                             skeleton_attach__skeletonRecalcBranch);
  if !isSuccess
    logerr("Could not sekeleton attach {getEntityTemplateName(eid)} to {getEntityTemplateName(skeleton_attach__attachedTo)}")

[es(tag=gameClient, on_appear, REQUIRE=skeleton_attach__skeletonRemap)]
def skeleton_attach_init_es(evt : Event;
                            eid : EntityId;
                            skeleton_attach__attachedTo : EntityId)
  var parentFound = false
  query(skeleton_attach__attachedTo) <| $ [es(REQUIRE=animchar)] ()
    sendEventImmediate(eid, [[CmdInitSkeletonAttach]])
    parentFound = true
  if !parentFound 
    removeSubTemplate(eid, "base_skeleton_attach")

[es(tag=gameClient, after=animchar__updater_es, REQUIRE=attachedToParent, before=after_animchar_update_sync, on_event=UpdateAnimcharEvent, REQUIRE_NOT=skeleton_attach__skeletonRemap)]
def skeleton_attach_remap_es(evt : Event;
                             eid : EntityId;
                             skeleton_attach__attached : bool;
                             skeleton_attach__attachedTo : EntityId)
  if !skeleton_attach__attached
    return
  query(skeleton_attach__attachedTo) <| $ [es] (animchar : AnimcharBaseComponent)
    let attachedTonodesCount = int(animchar.nodeTree.nodeCount)

    if attachedTonodesCount == 0
      return
    addSubTemplate(eid, "base_skeleton_attach")

[es(tag=server, after=animchar__updater_es, before=after_animchar_update_sync, on_event=UpdateAnimcharEvent, REQUIRE=animchar, REQUIRE_NOT=skeletonAttachInited)]
def skeleton_attach_server_init_es(evt : Event;
                                   eid : EntityId;
                                   skeleton_attach__attached : bool;
                                   skeleton_attach__attachedTo : EntityId)
  if !skeleton_attach__attached
    return
  query(skeleton_attach__attachedTo) <| $ [es(REQUIRE=animchar)] ()
    addSubTemplate(eid, "skeleton_attach_inited")

[es(tag=server, on_appear, on_disappear, track=skeleton_attach__attached, REQUIRE=skeletonAttachInited)]
def skeleton_attach_clear_server_es(evt : Event;
                                    eid : EntityId;
                                    skeleton_attach__attached : bool)
  if !skeleton_attach__attached
    removeSubTemplate(eid, "skeleton_attach_inited")
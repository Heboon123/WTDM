from "%scripts/dagui_library.nut" import *
from "%scripts/chat/chatConsts.nut" import voiceChatStats

let { getGlobalModule } = require("%scripts/global_modules.nut")
let g_squad_manager = getGlobalModule("g_squad_manager")
let g_listener_priority = require("%scripts/g_listener_priority.nut")
let { toPixels } = require("%sqDagui/daguiUtil.nut")
let { handyman } = require("%sqStdLibs/helpers/handyman.nut")
let { subscribe_handler } = require("%sqStdLibs/helpers/subscriptions.nut")
let elemModelType = require("%sqDagui/elemUpdater/elemModelType.nut")
let elemViewType = require("%sqDagui/elemUpdater/elemViewType.nut")
let { chatStatesCanUseVoice } = require("%scripts/chat/chatStates.nut")
let { get_option_voicechat } = require("chat")
let { isLoggedIn } = require("%appGlobals/login/loginState.nut")
let { getContact } = require("%scripts/contacts/contacts.nut")
let { myClanInfo } = require("%scripts/clans/clanState.nut")

const MAX_VOICE_ELEMS_IN_GC = 2

elemModelType.addTypes({
  VOICE_CHAT = {

    init = @() subscribe_handler(this, g_listener_priority.DEFAULT_HANDLER)

    onEventVoiceChatStatusUpdated = @(_p) this.notify([])
    onEventSquadStatusChanged = @(_p) this.notify([])
    onEventVoiceChatOptionUpdated = @(_p) this.notify([])
    onEventSquadDataUpdated = @(_p) this.notify([])
    onEventClanInfoUpdate = @(_p) this.notify([])
  }
})


elemViewType.addTypes({
  VOICE_CHAT = {
    model = elemModelType.VOICE_CHAT

    updateView = function(obj, _params) {
      if (!isLoggedIn.get())
        return

      let nestObj = obj.getParent().getParent()
      if (!checkObj(nestObj))
        return

      let myClanInfoV = myClanInfo.get()
      let isWidgetVisible = nestObj.getFinalProp("isClanOnly") != "yes" ||
        (get_option_voicechat()
         && chatStatesCanUseVoice()
         && !g_squad_manager.isInSquad()
         && !!myClanInfoV)
      nestObj.show(isWidgetVisible)

      if (!isWidgetVisible)
        return

      let childRequired = g_squad_manager.isInSquad() ? g_squad_manager.getSMMaxSquadSize()
        : myClanInfoV != null ? myClanInfoV.mlimit
        : 0

      if (obj.childrenCount() < childRequired) {
        if (this.isAnybodyTalk())
          obj.getScene().performDelayed(this, function() {
            if (!obj.isValid())
              return

            this.fillContainer(obj, childRequired)
            this.updateMembersView(obj, nestObj)
          })
      }
      else
        this.updateMembersView(obj, nestObj)
    }

    isAnybodyTalk = function() {
      if (g_squad_manager.isInSquad()) {
        foreach (uid, _member in g_squad_manager.getMembers())
          if (getContact(uid)?.voiceStatus == voiceChatStats.talking)
            return true
        return false
      }
      let myClanInfoV = myClanInfo.get()
      if (myClanInfoV == null)
        return false

      foreach (member in myClanInfoV.members)
        if (getContact(member.uid)?.voiceStatus == voiceChatStats.talking)
          return true

      return false
    }

    updateMembersView = function(obj, nestObj) {
      local memberIndex = 0
      let myClanInfoV = myClanInfo.get()
      if (g_squad_manager.isInSquad()) {
        memberIndex = 1
        let leader = g_squad_manager.getSquadLeaderData()
        foreach (uid, member in g_squad_manager.getMembers())
          this.updateMemberView(obj, member == leader ? 0 : memberIndex++, uid)
      }
      else if (myClanInfoV != null)
        foreach (member in myClanInfoV.members)
          this.updateMemberView(obj, memberIndex++, member.uid)

      while (memberIndex < obj.childrenCount())
        this.updateMemberView(obj, memberIndex++, null)

      let emptyVoiceObj = nestObj.findObject("voice_chat_no_activity")
      if (checkObj(emptyVoiceObj))
        emptyVoiceObj.fade = !this.isAnybodyTalk() ? "in" : "out"
    }

    updateMemberView = function(obj, objIndex, uid) {
      let memberObj = objIndex < obj.childrenCount() ? obj.getChild(objIndex) : null
      if (!checkObj(memberObj))
        return

      let contact = getContact(uid)
      let isTalking = contact?.voiceStatus == voiceChatStats.talking
      memberObj.fade = isTalking ? "in" : "out"
      if (isTalking)
        memberObj.findObject("users_name").setValue(contact?.getName() ?? "")
    }

    fillContainer = function(obj, childRequired) {
      let data = handyman.renderCached("%gui/chat/voiceChatElement.tpl",
        { voiceChatElement = array(childRequired, {}) })
      obj.getScene().replaceContentFromText(obj, data, data.len(), this)

      let heightEnd = obj.getParent().getFinalProp("isSmall") == "yes"
        ? toPixels(get_cur_gui_scene(), "1@gamercardHeight") /
            MAX_VOICE_ELEMS_IN_GC
        : toPixels(get_cur_gui_scene(), "1@voiceChatBaseIconHeight") +
            toPixels(get_cur_gui_scene(), "1@blockInterval")

      for (local i = 0; i < obj.childrenCount(); i++)
        obj.getChild(i)["height-end"] = heightEnd.tointeger().tostring()
    }
  }
})

return {}

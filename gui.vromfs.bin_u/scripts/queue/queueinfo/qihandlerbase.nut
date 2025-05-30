from "%scripts/dagui_library.nut" import *

let { gui_handlers } = require("%sqDagui/framework/gui_handlers.nut")
let QUEUE_TYPE_BIT = require("%scripts/queue/queueTypeBit.nut")
let { handlerType } = require("%sqDagui/framework/handlerType.nut")
let { updateShortQueueInfo } = require("%scripts/queue/queueInfo/qiViewUtils.nut")
let { isQueueActive, findQueue } = require("%scripts/queue/queueState.nut")
let { getQueueEvent } = require("%scripts/queue/queueInfo.nut")

gui_handlers.QiHandlerBase <- class (gui_handlers.BaseGuiHandlerWT) {
  wndType = handlerType.CUSTOM
  sceneBlkName   = "%gui/events/eventQueue.blk"

  queueTypeMask = QUEUE_TYPE_BIT.EVENT
  hasTimerText = true
  timerUpdateObjId = null
  timerTextObjId = null

  queue = null
  event = null
  needAutoDestroy = true 

  isStatsCreated = false

  leaveQueueCb = null

  function initScreen() {
    this.initTimer()
    this.checkCurQueue(true)
  }

  function initTimer() {
    if (!this.hasTimerText || !this.timerUpdateObjId)
      return

    let timerObj = this.scene.findObject(this.timerUpdateObjId)
    timerObj.setUserData(this)
    timerObj.timer_handler_func = "onUpdate"
  }

  function destroy() {
    if (!this.isValid())
      return
    this.scene.show(false)
    this.guiScene.replaceContentFromText(this.scene, "", 0, null)
    this.scene = null
  }

  function checkCurQueue(forceUpdate = false) {
    local q = findQueue({}, this.queueTypeMask)
    if (q && !isQueueActive(q))
      q = null

    if (this.needAutoDestroy && !q)
      return this.destroy()

    let isQueueChanged = q != this.queue
    if (!isQueueChanged && !forceUpdate)
      return isQueueChanged

    this.queue = q
    this.event = this.queue && getQueueEvent(this.queue)
    if (!this.isStatsCreated) {
      this.createStats()
      this.isStatsCreated = true
    }
    this.onQueueChange()
    return isQueueChanged
  }

  function onQueueChange() {
    this.scene.show(this.queue != null)
    if (!this.queue)
      return

    this.updateTimer()
    this.updateStats()
  }

  function onUpdate(_obj, _dt) {
    if (this.queue)
      this.updateTimer()
  }

  function updateTimer() {
    let textObj = this.scene.findObject(this.timerTextObjId)
    let timerObj = this.scene.findObject("wait_time_block")
    let iconObj = this.scene.findObject("queue_wait_icon")
    updateShortQueueInfo(timerObj, textObj, iconObj, loc("yn1/waiting_for_game_query"))
  }

  function leaveQueue(_obj) { if (this.leaveQueueCb) this.leaveQueueCb() }

  function onEventQueueChangeState(_p)     { this.checkCurQueue() }
  function onEventQueueInfoUpdated(_p)     { if (this.queue) this.updateStats() }

  function createStats() {}
  function updateStats() {}
}

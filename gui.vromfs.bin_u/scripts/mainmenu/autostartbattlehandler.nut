from "%scripts/dagui_natives.nut" import set_presence_to_player, is_online_available
from "%scripts/dagui_library.nut" import *
let { gui_handlers } = require("%sqDagui/framework/gui_handlers.nut")
let { show_obj } = require("%sqDagui/daguiUtil.nut")
let QUEUE_TYPE_BIT = require("%scripts/queue/queueTypeBit.nut")
let { setGuiOptionsMode, getGuiOptionsMode } = require("guiOptions")
let lobbyStates = require("%scripts/matchingRooms/lobbyStates.nut")
let { handlerType } = require("%sqDagui/framework/handlerType.nut")
let { handlersManager } = require("%scripts/baseGuiHandlerManagerWT.nut")
let { format } = require("string")
let time = require("%scripts/time.nut")
let { getQueueWaitIconImageMarkup } = require("%scripts/queue/waitIconImage.nut")
let { getCurEsUnitTypesMask } = require("%scripts/queue/curEsUnitTypesMask.nut")
let { get_charserver_time_sec } = require("chard")
let { OPTIONS_MODE_MP_DOMINATION } = require("%scripts/options/optionsExtNames.nut")
let { sessionLobbyStatus } = require("%scripts/matchingRooms/sessionLobbyState.nut")
let { gui_start_mainmenu } = require("%scripts/mainmenu/guiStartMainmenu.nut")
let { checkQueueAndStart, leaveAllQueuesSilent } = require("%scripts/queue/queueManager.nut")
let { EventJoinProcess } = require("%scripts/events/eventJoinProcess.nut")
let { isQueueActive, isQueuesEqual, findQueue, checkQueueType } = require("%scripts/queue/queueState.nut")

let { getCurrentGameMode, getGameModeEvent
} = require("%scripts/gameModes/gameModeManagerState.nut")

let class AutoStartBattleHandler (gui_handlers.BaseGuiHandlerWT) {
  wndType = handlerType.ROOT
  wndGameMode = GM_DOMINATION
  sceneBlkName = "%gui/autoStartBattle.blk"
  queueMask = QUEUE_TYPE_BIT.DOMINATION | QUEUE_TYPE_BIT.NEWBIE

  curGameMode = null
  curQueue = null

  WAIT_BATTLE_DURATION = 20
  goBackTime = -1

  autoStartQueueWnd = null

  function initScreen() {
    set_presence_to_player("menu")
    this.mainOptionsMode = getGuiOptionsMode()
    setGuiOptionsMode(OPTIONS_MODE_MP_DOMINATION)

    this.autoStartQueueWnd = this.scene.findObject("autoStartQueueWnd")

    this.setCurQueue(findQueue({}, this.queueMask))
    this.updateTip()
    this.updateWaitTime()
    this.updateQueueWaitIconImage()
  }

  getCurQueue = @() this.curQueue

  function setCurQueue(value) {
    this.curQueue = value
    if (this.curQueue == null)
      return

    this.updateScene()
  }

  function updateTip() {
    let tipObj = this.scene.findObject("queue_tip")
    if (!tipObj?.isValid())
      return

    tipObj.setValue(getCurEsUnitTypesMask())
  }

  function updateQueueWaitIconImage() {
    let obj = this.scene.findObject("queue_wait_icon_block")
    if (!(obj?.isValid() ?? false))
      return

    let markup = getQueueWaitIconImageMarkup()
    this.guiScene.replaceContentFromText(obj, markup, markup.len(), this)
  }

  function updateWaitTime() {
    local txtWaitTime = ""
    let waitTime = this.getCurQueue()?.getActiveTime() ?? 0
    if (waitTime > 0) {
      let minutes = time.secondsToMinutes(waitTime).tointeger()
      let seconds = waitTime - time.minutesToSeconds(minutes)
      txtWaitTime = format("%d:%02d", minutes, seconds)
    }

    this.scene.findObject("msgText").setValue(txtWaitTime)
  }

  function joinMpQueue() {
    if (this.curQueue != null)
      return

    let gameMode = getCurrentGameMode()
    if (gameMode == null)
      return

    this.guiScene.performDelayed(this, function() {
      if (this.isValid() && this.curQueue == null) {
        let event = getGameModeEvent(gameMode)
        EventJoinProcess(event, null, null, Callback(this.goBack, this))
      }
    })
  }

  function goBack() {
    this.guiScene.performDelayed(this, gui_start_mainmenu)
    leaveAllQueuesSilent()
    base.goBack()
  }

  function onStartAction() {
    if (!is_online_available()) {
      let handler = this
      this.goForwardIfOnline(function() {
          if (handler?.isValid())
            handler.onStartAction.call(handler)
        }, false, true)
      return
    }
    checkQueueAndStart((@() this.joinMpQueue()).bindenv(this), null, "isCanNewflight")
  }

  function onEventQueueChangeState(p) {
    let queue = p?.queue
    if (isQueuesEqual(queue, this.getCurQueue())) {
      this.updateScene()
      return
    }

    if (!checkQueueType(p.queue, this.queueMask))
      return

    this.setCurQueue(isQueueActive(p.queue) ? p.queue : null)
  }

  function onEventQueueInfoUpdated(_params) {
    if (!this.getCurQueue())
      return

    this.updateScene()
  }

  function updateScene() {
    let showQueueTbl = isQueueActive(this.getCurQueue())
    this.setShowQueueTable(showQueueTbl)
  }

  function setShowQueueTable(value) {
    if (value && this.autoStartQueueWnd.isVisible())
      return

    if (value) {
      this.updateTip()
      this.updateQueueWaitIconImage()
    }

    show_obj(this.autoStartQueueWnd, value)
  }

  function startBattle() {
    if (!this.isSceneActive() || this.curQueue)
      return

    this.checkedNewFlight(this.onStartAction.bindenv(this))

    this.goBackTime = get_charserver_time_sec() + this.WAIT_BATTLE_DURATION
    this.scene.findObject("queue_timeout_time").setUserData(this)
  }

  function onEventCurrentGameModeIdChanged(_) {
    if (this.curGameMode == getCurrentGameMode())
      return

    this.curGameMode = getCurrentGameMode()
    this.doWhenActiveOnce("startBattle")
  }

  function onTimer(_, __) {
    if (!this.isValid())
      return

    if (handlersManager.isAnyModalHandlerActive())
      return

    let timeLeft = this.goBackTime - get_charserver_time_sec()
    if (timeLeft < 0)
      return this.goBack()

    if (!isQueueActive(this.curQueue)
        && sessionLobbyStatus.get() == lobbyStates.NOT_IN_ROOM)
      return this.goBack()

    this.updateWaitTime()
  }
}

gui_handlers.AutoStartBattleHandler <- AutoStartBattleHandler
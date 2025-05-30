from "%scripts/dagui_library.nut" import *
from "%scripts/utils_sa.nut" import is_multiplayer

let { getGlobalModule } = require("%scripts/global_modules.nut")
let g_squad_manager = getGlobalModule("g_squad_manager")
let { gui_handlers } = require("%sqDagui/framework/gui_handlers.nut")
let u = require("%sqStdLibs/helpers/u.nut")
let { move_mouse_on_child_by_value, handlersManager, loadHandler
} = require("%scripts/baseGuiHandlerManagerWT.nut")
let fillSessionInfo = require("%scripts/matchingRooms/fillSessionInfo.nut")
let { suggestAndAllowPsnPremiumFeatures } = require("%scripts/user/psnFeatures.nut")
let { isGameModeCoop } = require("%scripts/matchingRooms/matchingGameModesUtils.nut")
let { setGuiOptionsMode } = require("guiOptions")
let lobbyStates = require("%scripts/matchingRooms/lobbyStates.nut")
let { havePremium } = require("%scripts/user/premium.nut")
let { checkAndShowMultiplayerPrivilegeWarning,
  isMultiplayerPrivilegeAvailable } = require("%scripts/user/xboxFeatures.nut")
let { isShowGoldBalanceWarning } = require("%scripts/user/balanceFeatures.nut")
let { OPTIONS_MODE_SEARCH, USEROPT_SEARCH_GAMEMODE, USEROPT_SEARCH_DIFFICULTY
} = require("%scripts/options/optionsExtNames.nut")
let { sessionLobbyStatus, getRoomMembersCnt, getRoomSize, getSessionLobbyGameMode
} = require("%scripts/matchingRooms/sessionLobbyState.nut")
let { create_options_container, get_option } = require("%scripts/options/optionsExt.nut")
let { checkAndCreateGamemodeWnd } = require("%scripts/missions/startMissionsList.nut")
let { matchSearchGm } = require("%scripts/missions/missionsStates.nut")
let { generatePaginator, hidePaginator } = require("%scripts/viewUtils/paginator.nut")
let { getRoomsInfoTbl } = require("%scripts/matchingRooms/sessionLobbyInfo.nut")
let { joinSessionLobbyFoundRoom } = require("%scripts/matchingRooms/sessionLobbyActions.nut")
let { buildMpTable, countWidthForMpTable } = require("%scripts/statistics/mpStatisticsUtil.nut")
let { canPlayGamemodeBySquad } = require("%scripts/missions/missionsUtils.nut")
let { updateVehicleInfoButton } = require("%scripts/vehiclesWindow.nut")
let MRoomsList = require("%scripts/matchingRooms/mRoomsList.nut")

gui_handlers.SessionsList <- class (gui_handlers.GenericOptions) {
  sceneBlkName = "%gui/sessionsList.blk"
  sceneNavBlkName = "%gui/navSessionsList.blk"
  optionsContainer = "mp_coop_options"
  isCoop = true

  sessionsListObj = null
  
  roomsListData = null
  roomsList = null
  curPageRoomsList = null
  curPage = 0
  roomsPerPage = 1

  curDifficulty = -1

  function initScreen() {
    base.initScreen()
    this.sessionsListObj = this.scene.findObject("sessions_table")

    this.roomsList = []
    this.curPageRoomsList = []
    this.roomsListData = MRoomsList.getMRoomsListByRequestParams(null) 

    this.isCoop = isGameModeCoop(matchSearchGm.get())
    this.scene.findObject("sessions_update").setUserData(this)

    let head = this.scene.findObject("sessions_diff_header")
    if (checkObj(head))
      head.setValue(this.isCoop ? loc("multiplayer/difficultyShort") : loc("multiplayer/createModeShort"))

    this.updateRoomsHeader()
    this.initOptions()
    this.initRoomsPerPage()

    this.onSessionsUpdate(null, 0.0)
    this.updateRoomsList()
    this.updateButtons()
  }

  function initRoomsPerPage() {
    let listHeight = this.sessionsListObj.getSize()[1]
    let rowHeight = this.guiScene.calcString("@baseTrHeight", null)
    this.roomsPerPage = max((listHeight / rowHeight).tointeger(), 1)
  }

  function updateButtons() {
    local title = ""
    if (this.isCoop) {
      if (hasFeature("ModeDynamic")) {
        showObjById("btn_dynamic", true)
        let dynBtn = this.guiScene["btn_dynamic"]
        if (checkObj(dynBtn)) {
          dynBtn.inactiveColor = havePremium.value ? "no" : "yes"
          dynBtn.tooltip = havePremium.value ? "" : loc("mainmenu/onlyWithPremium")
        }
      }

      showObjById("btn_coop", true)
      showObjById("btn_builder", hasFeature("ModeBuilder"))
      title = loc("mainmenu/btnMissions")
    }
    else {
      showObjById("btn_skirmish", true)
      title = loc("mainmenu/btnCustomMatch")
    }

    this.setSceneTitle(title)
  }

  function initOptions() {
    setGuiOptionsMode(OPTIONS_MODE_SEARCH)
    local options = null
    if (this.isCoop)
      options = [
        [USEROPT_SEARCH_GAMEMODE, "spinner"],
        [USEROPT_SEARCH_DIFFICULTY, "spinner"],
      ]
    else if (matchSearchGm.get() == GM_SKIRMISH)
      options = [
        [USEROPT_SEARCH_DIFFICULTY, "spinner"],
      ]

    if (!options)
      return

    let container = create_options_container(this.optionsContainer, options, false, 0.5, false)
    let optObj = this.scene.findObject("session-options")
    if (checkObj(optObj))
      this.guiScene.replaceContentFromText(optObj, container.tbl, container.tbl.len(), this)

    this.optionsContainers.append(container.descr)
  }

  function onGamemodeChange(obj) {
    if (!obj)
      return
    let value = obj.getValue()
    let option = get_option(USEROPT_SEARCH_GAMEMODE)
    if (!(value in option.values))
      return

    matchSearchGm.set(option.values[value])
  }

  function onDifficultyChange(obj) {
    if (!checkObj(obj))
      return

    let value = obj.getValue()
    let option = get_option(USEROPT_SEARCH_DIFFICULTY)
    if (!(value in option.values))
      return

    let newDiff = option.idxValues[value]
    if (this.curDifficulty == newDiff)
      return

    this.curDifficulty = newDiff
    this.updateRoomsList()
  }

  function onSkirmish(_obj) { checkAndCreateGamemodeWnd(this, GM_SKIRMISH) }

  function onSessionsUpdate(_obj = null, _dt = 0.0) {
    if (handlersManager.isAnyModalHandlerActive()
        || is_multiplayer()
        || sessionLobbyStatus.get() != lobbyStates.NOT_IN_ROOM)
      return

    this.roomsListData.requestList(this.getCurFilter())
  }

  function onEventSearchedRoomsChanged(_p) {
    this.updateRoomsList()
  }

  function onEventRoomsSearchStarted(_p) {
    this.updateSearchMsg()
  }

  function updateSearchMsg() {
    let infoText = this.guiScene["info-text"]
    if (checkObj(infoText)) {
      let show = (type(this.roomsList) != "array") || (this.roomsList.len() == 0)
      if (show)
        infoText.setValue(this.roomsListData.isNewest() ? loc("wait/sessionNone") : loc("wait/sessionSearch"))
      infoText.show(show)
    }
  }

  function getCurFilter() {
    return { diff = this.curDifficulty }
  }

  function sortRoomsList() {
    
    
    foreach (room in this.roomsList) {
      let size = getRoomSize(room)
      room._players <- getRoomMembersCnt(room)
      room._full <- room._players >= size
    }
    this.roomsList.sort(function(a, b) {
      if (a._full != b._full)
        return a._full ? 1 : -1
      if (a._players != b._players)
        return (a._players > b._players) ? -1 : 1
      return 0
    })
  }

  _columnsList = null
  function getColumnsList() {
    if (this._columnsList)
      return this._columnsList
    if (this.isCoop)
      this._columnsList = ["hasPassword", "mission", "name", "numPlayers", "gm"  ]
    else
      this._columnsList = ["hasPassword", "mission", "name", "numPlayers"  ]
    return this._columnsList
  }

  _roomsMarkUpData = null
  function getRoomsListMarkUpData() {
    if (this._roomsMarkUpData)
      return this._roomsMarkUpData

    this.guiScene.applyPendingChanges(false)
    this._roomsMarkUpData = {
      tr_size = "pw, @baseTrHeight"
      is_header = true
      columns = {
        hasPassword   = { width = "1@baseTrHeight + 1@tablePad" }
        mission       = { halign = "left", relWidth = 50 }
        name          = { width = "@nameWidth" }
        numPlayers    = { relWidth = 10 }
        gm            = { relWidth = 20 }
        
      }
    }

    let columnsOrder = this.getColumnsList()
    let deletedArr = []
    foreach (id, _data in this._roomsMarkUpData.columns)
      if (!isInArray(id, columnsOrder))
        deletedArr.append(id)

    foreach (id in deletedArr)
      this._roomsMarkUpData.columns.$rawdelete(id)

    if (checkObj(this.sessionsListObj))
      countWidthForMpTable(this.sessionsListObj, this._roomsMarkUpData.columns)

    return this._roomsMarkUpData
  }

  function updateRoomsHeader() {
    let headerObj = this.scene.findObject("sessions-header")
    if (!checkObj(headerObj))
      return

    let header = [{
      country = ""
      mission = "#options/mp_mission"
      numPlayers = "#multiplayer/numPlayers"
      gm = "#multiplayer/gamemode"
      difficultyStr = "#multiplayer/difficultyShort"
      name = "#multiplayer/game_host"
    }]
    let headerData = buildMpTable(header, this.getRoomsListMarkUpData(), this.getColumnsList())
    this.guiScene.replaceContentFromText(headerObj, headerData, headerData.len(), this)
  }

  function updateRoomsList() {
    this.roomsListData.requestList(this.getCurFilter())
    this.roomsList = this.roomsListData.getList()
    this.sortRoomsList()
    this.updateSearchMsg()

    this.updateRoomsPage()
  }

  function updateRoomsPage() {
    if (!checkObj(this.sessionsListObj))
      return

    let selectedRoom = this.getCurRoom()
    local selectedRow = -1
    this.curPageRoomsList.clear()

    let maxPage = max((this.roomsList.len() - 1) / this.roomsPerPage, 0)
    this.curPage = clamp(this.curPage, 0, maxPage)

    let start = this.curPage * this.roomsPerPage
    let end = min(start + this.roomsPerPage, this.roomsList.len())
    for (local i = start; i < end; i++) {
      let room = this.roomsList[i]
      this.curPageRoomsList.append(room)
      if (selectedRow < 0 && u.isEqual(room, selectedRoom))
         selectedRow = this.curPageRoomsList.len() - 1
    }
    if (selectedRow < 0 && this.curPageRoomsList.len())
      selectedRow = clamp(this.sessionsListObj.getValue(), 0, this.curPageRoomsList.len() - 1)

    let roomsInfoTbl = getRoomsInfoTbl(this.curPageRoomsList)
    let data = buildMpTable(roomsInfoTbl, this.getRoomsListMarkUpData(), this.getColumnsList(), roomsInfoTbl.len())
    this.sessionsListObj.deleteChildren()
    this.guiScene.appendWithBlk(this.sessionsListObj, data, this)

    this.sessionsListObj.setValue(this.curPageRoomsList.len() > 0 ? selectedRow : -1)
    this.updateCurRoomInfo()
    this.updatePaginator(maxPage)
  }

  function updatePaginator(maxPage) {
    let pagObj = this.scene.findObject("paginator_place")
    if (maxPage > 0)
      generatePaginator(pagObj, this, this.curPage, maxPage, null, true)
    else
      hidePaginator(pagObj)
  }

  function goToPage(obj) {
    this.curPage = obj.to_page.tointeger()
    this.updateRoomsPage()
  }

  function getCurRoom() {
    if (!checkObj(this.sessionsListObj))
      return null

    let curRow = this.sessionsListObj.getValue()
    if (curRow in this.curPageRoomsList)
      return this.curPageRoomsList[curRow]
    return null
  }

  function updateCurRoomInfo() {
    let room = this.getCurRoom()
    fillSessionInfo(this.scene, room?.public)
    updateVehicleInfoButton(this.scene, room)

    let btnObj = this.scene.findObject("btn_select")
    if (checkObj(btnObj))
      btnObj.inactiveColor = room ? "no" : "yes"
  }

  function onSessionSelect() {
    this.updateCurRoomInfo()
  }

  doSelectSessions = @() move_mouse_on_child_by_value(this.sessionsListObj)

  function onGamercard(_obj) {
  }

  function onStart(_obj) {
    if (!suggestAndAllowPsnPremiumFeatures())
      return

    if (!isMultiplayerPrivilegeAvailable.value) {
      checkAndShowMultiplayerPrivilegeWarning()
      return
    }

    if (isShowGoldBalanceWarning())
      return

    let room = this.getCurRoom()
    if (!room)
      return this.msgBox("no_room_selected", loc("ui/nothing_selected"), [["ok"]], "ok")

    if (g_squad_manager.getSquadRoomId() != room.roomId
      && !::g_squad_utils.canJoinFlightMsgBox(
          {
            isLeaderCanJoin = canPlayGamemodeBySquad(getSessionLobbyGameMode(room)),
            showOfflineSquadMembersPopup = true
          }
        )
      )
      return

    this.checkedNewFlight(@() joinSessionLobbyFoundRoom(room))
  }

  function onVehiclesInfo(_obj) {
    loadHandler(gui_handlers.VehiclesWindow, {
      teamDataByTeamName = getTblValue("public", this.getCurRoom())
    })
  }
}
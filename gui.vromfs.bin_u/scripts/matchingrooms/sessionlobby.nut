from "%scripts/dagui_natives.nut" import script_net_assert, in_flight_menu, is_online_available
from "%scripts/dagui_library.nut" import *
from "%scripts/teamsConsts.nut" import Team
from "%scripts/options/optionsConsts.nut" import misCountries
import "%scripts/matchingRooms/lobbyStates.nut" as lobbyStates
from "%scripts/mainConsts.nut" import global_max_players_versus
from "%scripts/utils_sa.nut" import is_mode_with_teams

let { gen_rnd_password, get_array_by_bit_value } = require("%scripts/utils_sa.nut")
let { g_team } = require("%scripts/teams.nut")
let { g_event_display_type } = require("%scripts/events/eventDisplayType.nut")
let { g_url_missions } = require("%scripts/missions/urlMissionsList.nut")
let { g_mislist_type } =  require("%scripts/missions/misListType.nut")
let { g_chat_room_type } = require("%scripts/chat/chatRoomType.nut")
let { getCurrentShopDifficulty } = require("%scripts/gameModes/gameModeManagerState.nut")
let { g_difficulty } = require("%scripts/difficulty.nut")
let { getGlobalModule } = require("%scripts/global_modules.nut")
let g_squad_manager = getGlobalModule("g_squad_manager")
let events = getGlobalModule("events")
let g_listener_priority = require("%scripts/g_listener_priority.nut")
let { set_last_session_debug_info } = require("%scripts/matchingRooms/sessionDebugInfo.nut")
let { SERVER_ERROR_ROOM_PASSWORD_MISMATCH, INVALID_ROOM_ID, INVALID_SQUAD_ID
} = require("matching.errors")
let u = require("%sqStdLibs/helpers/u.nut")
let { convertBlk } = require("%sqstd/datablock.nut")
let ecs = require("%sqstd/ecs.nut")
let { addListenersWithoutEnv, subscribe_handler, broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let { move_mouse_on_obj, loadHandler, isInMenu, handlersManager } = require("%scripts/baseGuiHandlerManagerWT.nut")
let { abs, floor } = require("math")
let { EventOnConnectedToServer } = require("net")
let { MatchingRoomExtraParams = null } = require_optional("dasevents")
let { format } = require("string")
let { get_mp_session_id_str } = require("multiplayer")
let unitTypes = require("%scripts/unit/unitTypesList.nut")
let { getPlayerName } = require("%scripts/user/remapNick.nut")
let { getMissionLocIdsArray, is_user_mission } = require("%scripts/missions/missionsUtilsModule.nut")
let base64 = require("base64")
let { frnd } = require("dagor.random")
let DataBlock = require("DataBlock")
let { showMsgboxIfSoundModsNotAllowed } = require("%scripts/penitentiary/soundMods.nut")
let { getSlotbarOverrideCountriesByMissionName, resetSlotbarOverrided,
  updateOverrideSlotbar } = require("%scripts/slotbar/slotbarOverride.nut")
let { isGameModeCoop } = require("%scripts/matchingRooms/matchingGameModesUtils.nut")
let { shopCountriesList } = require("%scripts/shop/shopCountriesList.nut")
let { getMaxEconomicRank } = require("%appGlobals/ranks_common_shared.nut")
let { getCdBaseDifficulty, get_cd_preset } = require("guiOptions")
let { updateIconPlayersInfo, initListLabelsSquad } = require("%scripts/statistics/squadIcon.nut")
let { getRealName } = require("%scripts/user/nameMapping.nut")
let { switchProfileCountry, profileCountrySq } = require("%scripts/user/playerCountry.nut")
let { debug_dump_stack } = require("dagor.debug")
let { eventbus_send, eventbus_subscribe } = require("eventbus")
let { dynamicMissionPlayed, isDynamicWon } = require("dynamicMission")
let { get_meta_mission_info_by_name, leave_mp_session, quit_to_debriefing,
  interrupt_multiplayer, get_mission_difficulty_int
} = require("guiMission")
let { set_game_mode, get_game_mode, get_game_type, get_cur_game_mode_name } = require("mission")
let { addRecentContacts, getContactsGroupUidList } = require("%scripts/contacts/contactsManager.nut")
let { notifyQueueLeave } = require("%scripts/matching/serviceNotifications/match.nut")
let { matchingApiFunc, matchingRpcSubscribe, checkMatchingError } = require("%scripts/matching/api.nut")
let { serializeDyncampaign, invitePlayerToRoom, roomSetReadyState, roomSetPassword,
  roomStartSession, kickMember, setRoomAttributes, setMemberAttributes, requestLeaveRoom,
  requestJoinRoom, requestDestroyRoom, requestCreateRoom, isMyUserId
} = require("%scripts/matching/serviceNotifications/mrooms.nut")
let { getUrlOrFileMissionMetaInfo, getCombineLocNameMission } = require("%scripts/missions/missionsUtils.nut")
let { getModeById } = require("%scripts/matching/matchingGameModes.nut")
let { sendBqEvent } = require("%scripts/bqQueue/bqQueue.nut")
let { web_rpc } = require("%scripts/webRPC.nut")
let { saveLocalByAccount } = require("%scripts/clientState/localProfileDeprecated.nut")
let { isInFlight } = require("gameplayBinding")
let time = require("%scripts/time.nut")
let { clearMpChatLog } = require("%scripts/chat/mpChatModel.nut")
let { isInJoiningGame, isInSessionRoom, isWaitForQueueRoom, sessionLobbyStatus, isInSessionLobbyEventRoom,
  isMeSessionLobbyRoomOwner, isRoomInSession
} = require("%scripts/matchingRooms/sessionLobbyState.nut")
let { userIdInt64, userName } = require("%scripts/user/profileStates.nut")
let { getProfileInfo } = require("%scripts/user/userInfoStats.nut")
let { getEventDisplayType, getEventEconomicName, getEventRankCalcMode, isEventWithLobby } = require("%scripts/events/eventInfo.nut")
let { getCurSlotbarUnit, getCrewsListByCountry } = require("%scripts/slotbar/slotbarState.nut")
let { getMissionsComplete, getStats } = require("%scripts/myStats.nut")
let { guiStartMpLobby } = require("%scripts/missions/startMissionsList.nut")
let { addPopup } = require("%scripts/popups/popups.nut")
let { getCrewUnit } = require("%scripts/crew/crew.nut")
let { gui_handlers } = require("%sqDagui/framework/gui_handlers.nut")
let { handlerType } = require("%sqDagui/framework/handlerType.nut")
let { showMsgboxIfEacInactive } = require("%scripts/penitentiary/antiCheat.nut")
let { isMeBanned } = require("%scripts/penitentiary/penalties.nut")
let { isInBattleState } = require("%scripts/clientState/clientStates.nut")
let { checkShowMultiplayerAasWarningMsg } = require("%scripts/user/antiAddictSystem.nut")
let openEditBoxDialog = require("%scripts/wndLib/editBoxHandler.nut")
let { isLoggedIn } = require("%scripts/login/loginStates.nut")

/*
SessionLobby API

  all:
    createRoom(missionSettings)
    isInSessionRoom
    joinRoom
    leaveRoom
    setReady(bool)
    syncAllInfo

  room owner:
    destroyRoom
    updateRoomAttributes(missionSettings)
    invitePlayer(uid)
    kickPlayer(uid)
    startSession

  squad leader:
    startCoopBySquad(missionSettings)

*/


const NET_SERVER_LOST = 0x82220002  //for hostCb
const NET_SERVER_QUIT_FROM_GAME = 0x82220003

const CUSTOM_GAMEMODE_KEY = "_customGameMode"

const MAX_BR_DIFF_AVAILABLE_AND_REQ_UNITS = 0.6

local last_round = true

let allowed_mission_settings = { //only this settings are allowed in room
                              //default params used only to check type atm
  name = null
  missionURL = null
  players = 12
  hidden = false  //can be found by search rooms

  creator = ""
  hasPassword = false
  cluster = ""
  allowJIP = true
  coop = true
  friendOnly = false
  country_allies = ["country_ussr"]
  country_axis = ["country_germany"]

  mission = {
    name = "stalingrad_GSn"
    loc_name = ""
    postfix = ""
    _gameMode = 12
    _gameType = 0
    difficulty = "arcade"
    custDifficulty = "0"
    environment = "Day"
    weather = "cloudy"

    maxRespawns = -1
    timeLimit = 0
    killLimit = 0

    raceLaps = 1
    raceWinners = 1
    raceForceCannotShoot = false

    isBotsAllowed = true
    useTankBots = false
    ranks = {}
    useShipBots = false
    keepDead = true
    isLimitedAmmo = false
    isLimitedFuel = false
    optionalTakeOff = false
    dedicatedReplay = false
    useKillStreaks = false
    disableAirfields = false
    spawnAiTankOnTankMaps = true
    allowEmptyTeams = false

    isHelicoptersAllowed = false
    isAirplanesAllowed = false
    isTanksAllowed = false
    isShipsAllowed = false

    takeoffMode = 0
    currentMissionIdx = -1
    allowedTagsPreset = ""

    locName = ""
    locDesc = ""
  }
}

let memberDefaults = freeze({
  team = Team.Any
  country = "country_0"
  squad = INVALID_SQUAD_ID
  spectator = false
  ready = false
  is_in_session = false
  clanTag = ""
  title = ""
  pilotId = 0
  selAirs = ""
  state = PLAYER_IN_LOBBY_NOT_READY
})

let SessionLobbyState =  persist("SessionLobbyState", @() {
  roomId = INVALID_ROOM_ID
  settings = {}
  uploadedMissionId = ""
  isRoomByQueue = false
  roomUpdated = false
  password = ""
  members = []
  memberHostId = -1

  //my room attributes
  spectator = false
  isReady = false
  isInLobbySession = false //in some lobby session are used instead of ready
  team = Team.Any
  countryData = null
  myState = PLAYER_IN_LOBBY_NOT_READY
  isSpectatorSelectLocked = false
  crsSetTeamTo = Team.none
  curEdiff = -1
  _syncedMyInfo = null
  needJoinSessionAfterMyInfoApply = false
  isLeavingLobbySession = false

  playersInfo = {}

  isReadyInSetStateRoom = null // if null then not response is expected from roomSetReadyState
})

local needCheckReconnect = false
local playersInfoByNames = {}
//local delayedJoinRoomFunc = null //wasn`t used

local SessionLobby

gui_handlers.JoiningGameWaitBox <- class (gui_handlers.BaseGuiHandlerWT) {
  wndType = handlerType.MODAL
  sceneBlkName = "%gui/msgBox.blk"
  timeToShowCancel = 30
  timer = -1

  function initScreen() {
    this.scene.findObject("msgWaitAnimation").show(true)
    this.scene.findObject("msg_box_timer").setUserData(this)
    this.updateInfo()
  }

  function onEventLobbyStatusChange(_params) {
    this.updateInfo()
  }

  function onEventEventsDataUpdated(_params) {
    this.updateInfo()
  }

  function updateInfo() {
    if (!isInJoiningGame.get())
      return this.goBack()

    this.resetTimer() //statusChanged
    this.checkGameMode()

    let misData = SessionLobby.getMissionParams()
    local msg = loc("wait/sessionJoin")
    if (sessionLobbyStatus.get() == lobbyStates.UPLOAD_CONTENT)
      msg = loc("wait/sessionUpload")
    if (misData)
      msg = "".concat(msg, "\n\n", colorize("activeTextColor", this.getCurrentMissionGameMode()),
        "\n", colorize("userlogColoredText", this.getCurrentMissionName()))

    this.scene.findObject("msgText").setValue(msg)
  }

  function getCurrentMissionGameMode() {
    local gameModeName = get_cur_game_mode_name()
    if (gameModeName == "domination") {
      let event = SessionLobby.getRoomEvent()
      if (event == null)
        return ""

      if (getEventDisplayType(event) != g_event_display_type.RANDOM_BATTLE)
        gameModeName = "event"
    }
    return loc($"multiplayer/{gameModeName}Mode")
  }

  function getCurrentMissionName() {
    if (get_game_mode() == GM_DOMINATION) {
      let event = SessionLobby.getRoomEvent()
      if (event)
        return events.getEventNameText(event)
    }
    else {
      let misName = SessionLobby.getMissionNameLoc()
      if (misName != "")
        return misName
    }
    return ""
  }

  function checkGameMode() {
    let gm = SessionLobby.getGameMode()
    let curGm = get_game_mode()
    if (gm < 0 || curGm == gm)
      return

    set_game_mode(gm)
    if (this.mainGameMode < 0)
      this.mainGameMode = curGm  //to restore gameMode after close window
  }

  function showCancelButton(show) {
    let btnId = "btn_cancel"
    local obj = this.scene.findObject(btnId)
    if (obj) {
      obj.show(show)
      obj.enable(show)
      if (show)
        move_mouse_on_obj(obj)
      return
    }
    if (!show)
      return

    let data = format(
      "Button_text{id:t='%s'; btnName:t='AB'; text:t='#msgbox/btn_cancel'; on_click:t='onCancel'}",
      btnId)
    let holderObj = this.scene.findObject("buttons_holder")
    if (!holderObj)
      return

    this.guiScene.appendWithBlk(holderObj, data, this)
    obj = this.scene.findObject(btnId)
    move_mouse_on_obj(obj)
  }

  function resetTimer() {
    this.timer = this.timeToShowCancel
    this.showCancelButton(false)
  }

  function onUpdate(_obj, dt) {
    if (this.timer < 0)
      return
    this.timer -= dt
    if (this.timer < 0)
      this.showCancelButton(true)
  }

  function onCancel() {
    this.guiScene.performDelayed(this, function() {
      if (this.timer >= 0)
        return
      ::destroy_session_scripted("on cancel join game")
      SessionLobby.leaveRoom()
    })
  }
}

let joiningGameWaitBox = @() loadHandler(gui_handlers.JoiningGameWaitBox)

let isReconnectChecking = mkWatched(persist, "isReconnectChecking", false)

function reconnect(roomId, gameModeName) {
  let event = events.getEvent(gameModeName)
  if (!showMsgboxIfEacInactive(event) || !showMsgboxIfSoundModsNotAllowed(event))
    return

  if (event != null) {
    checkShowMultiplayerAasWarningMsg(@() SessionLobby.joinRoom(roomId))
    return
  }

  SessionLobby.joinRoom(roomId)
}

function onCheckReconnect(response) {
  isReconnectChecking(false)

  let roomId = response?.roomId
  let gameModeName = response?.game_mode_name
  if (!roomId || !gameModeName)
    return

  scene_msg_box("backToBattle_dialog", null, loc("msgbox/return_to_battle_session"), [
    ["yes", @() reconnect(roomId, gameModeName)],
    ["no"]], "yes")
}

function checkReconnect() {
  if (isReconnectChecking.value || !isLoggedIn.get() || isInBattleState.value || isMeBanned())
    return

  isReconnectChecking(true)
  matchingApiFunc("match.check_reconnect", onCheckReconnect)
}

addListenersWithoutEnv({
  MatchingConnect = @(_) checkReconnect()
})


SessionLobby = {
  getTeam = @() SessionLobbyState.team
  getRoomId = @() SessionLobbyState.roomId
  getSettings = @() SessionLobbyState.settings
  getIsSpectator =  @() SessionLobbyState.spectator
  getIsReady =  @() SessionLobbyState.isReady
  getPassword = @() SessionLobbyState.password
  getIsInLobbySession = @() SessionLobbyState.isInLobbySession
  getMembers = @() SessionLobbyState.members
  getMyState = @() SessionLobbyState.myState
  getIsSpectatorSelectLocked = @() SessionLobbyState.isSpectatorSelectLocked
  getPersistStates = @() SessionLobbyState.keys()

  checkReconnect

  roomTimers = [
    {
      publicKey = "timeToCloseByDisbalance"
      color = "@warningTextColor"
      function getLocText(public, locParams) {
        local res = loc("multiplayer/closeByDisbalance", locParams)
        if ("disbalanceType" in public)
          res = "".concat(res, "\n", loc("multiplayer/reason"), loc("ui/colon"),
            loc($"roomCloseReason/{public.disbalanceType}"))
        return res
      }
    }
    {
      publicKey = "matchStartTime"
      color = "@inQueueTextColor"
      function getLocText(_public, locParams) {
        return loc("multiplayer/battleStartsIn", locParams)
      }
    }
  ]

  function getDifficulty(room = null) {
    let diffValue = this.getMissionData(room)?.difficulty
    let difficulty = (diffValue == "custom")
      ? g_difficulty.getDifficultyByDiffCode(getCdBaseDifficulty())
      : g_difficulty.getDifficultyByName(diffValue)
    return difficulty
  }

  function getLockedCountryData() {
    if (SessionLobbyState.crsSetTeamTo == Team.none)
      return null

    let availableCountries = this.getTeamData(SessionLobbyState.crsSetTeamTo)?.countries ?? []
    if (availableCountries.len() == 0)
      return null

    return {
      availableCountries = availableCountries
      reasonText = loc("multiplayer/cantChangeCountryInLobby", {
        availableCountries = "".concat(loc("available_countries"), loc("ui/colon"),
          loc("ui/comma").join(availableCountries.map(@(c) loc(c))))
      })
    }
  }

  function getMissionNameLocIdsArray(room = null) {
    let misData = this.getMissionData(room)
    if ("name" in misData)
      return getMissionLocIdsArray(getUrlOrFileMissionMetaInfo(misData.name))
    return []
  }

  function setCustomPlayersInfo(customPlayersInfo) {
    SessionLobbyState.playersInfo = customPlayersInfo
    updateIconPlayersInfo()
  }

  function setIngamePresence(roomPublic, roomId) {
    local team = 0
    let myPinfo = this.getMemberPlayerInfo(userIdInt64.value)
    if (myPinfo != null)
      team = myPinfo.team

    let inGamePresence = {
      gameModeId = getTblValue("game_mode_id", roomPublic)
      gameQueueId = getTblValue("game_queue_id", roomPublic)
      mission    = getTblValue("mission", roomPublic)
      roomId     = roomId
      team       = team
    }
    ::g_user_presence.setPresence({ in_game_ex = inGamePresence })
  }

  function setWaitForQueueRoom(set) {
    if (sessionLobbyStatus.get() == lobbyStates.NOT_IN_ROOM || sessionLobbyStatus.get() == lobbyStates.WAIT_FOR_QUEUE_ROOM)
      this.switchStatus(set ? lobbyStates.WAIT_FOR_QUEUE_ROOM : lobbyStates.NOT_IN_ROOM)
  }

  function leaveWaitForQueueRoom() {
    if (!isWaitForQueueRoom.get())
      return

    this.setWaitForQueueRoom(false)
    addPopup(null, loc("NET_CANNOT_ENTER_SESSION"))
  }

  function findParam(key, tbl1, tbl2) {
    if (key in tbl1)
      return tbl1[key]
    if (key in tbl2)
      return tbl2[key]
    return null
  }

  function validateMissionCountry(country, fullCountriesList) {
    if (isInArray(country, fullCountriesList))
      return null
    if (isInArray($"country_{country}", fullCountriesList))
      return $"country_{country}"
    return null
  }

  function prepareSettings(missionSettings) {
    let _settings = {}
    let mission = missionSettings.mission

    foreach (key, v in allowed_mission_settings) {
      if (key == "mission")
        continue
      local value = this.findParam(key, missionSettings, mission)
      if (type(v) == "array" && type(value) != "array")
        value = [value]
      _settings[key] <- value //value == null will clear param on server
    }

    _settings.mission <- {}
    foreach (key, _v in allowed_mission_settings.mission) {
      local value = this.findParam(key, mission, missionSettings)
      if (key == "postfix")
        value = getTblValue(key, missionSettings)
      if (value == null)
        continue

      _settings.mission[key] <- u.isDataBlock(value) ? convertBlk(value) : value
    }

    _settings.mission.keepOwnUnits <- mission?.editSlotbar?.keepOwnUnits ?? true
    _settings.creator <- userName.value
    _settings.mission.originalMissionName <- getTblValue("name", _settings.mission, "")
    if ("postfix" in _settings.mission && _settings.mission.postfix) {
      let ending = "_tm"
      local nameNoTm = _settings.mission.name
      if (nameNoTm.len() > ending.len() && nameNoTm.slice(nameNoTm.len() - ending.len()) == ending)
        nameNoTm = nameNoTm.slice(0, nameNoTm.len() - ending.len())
      _settings.mission.loc_name = nameNoTm + _settings.mission.postfix
      _settings.mission.name += _settings.mission.postfix
    }
    if (is_user_mission(mission))
      _settings.userMissionName <- loc($"missions/{mission.name}")
    if (!("_gameMode" in _settings.mission))
      _settings.mission._gameMode <- get_game_mode()
    if (!("_gameType" in _settings.mission))
      _settings.mission._gameType <- get_game_type()
    if (getTblValue("coop", _settings) == null)
      _settings.coop <- isGameModeCoop(_settings.mission._gameMode)
    if (("difficulty" in _settings.mission) && _settings.mission.difficulty == "custom")
      _settings.mission.custDifficulty <- get_cd_preset(DIFFICULTY_CUSTOM)

    //validate Countries
    let countriesType = getTblValue("countriesType", missionSettings, misCountries.ALL)
    local fullCountriesList = getSlotbarOverrideCountriesByMissionName(_settings.mission.originalMissionName)
    if (!fullCountriesList.len())
      fullCountriesList = clone shopCountriesList
    foreach (name in ["country_allies", "country_axis"]) {
      local countries = null
      if (countriesType == misCountries.BY_MISSION) {
        countries = getTblValue(name, _settings, [])
        for (local i = countries.len() - 1; i >= 0; i--) {
          countries[i] = this.validateMissionCountry(countries[i], fullCountriesList)
          if (!countries[i])
            countries.remove(i)
        }
      }
      else if (countriesType == misCountries.SYMMETRIC || countriesType == misCountries.CUSTOM) {
        let bitMaskKey = (countriesType == misCountries.SYMMETRIC) ? "country_allies" : name
        countries = get_array_by_bit_value(getTblValue($"{bitMaskKey}_bitmask", missionSettings, 0), shopCountriesList)
      }
      _settings[name] <- (countries && countries.len()) ? countries : fullCountriesList
    }

    let userAllowedUnitTypesMask = missionSettings?.userAllowedUnitTypesMask ?? 0
    if (userAllowedUnitTypesMask)
      foreach (unitType in unitTypes.types)
        if (unitType.isAvailableByMissionSettings(_settings.mission) && !(userAllowedUnitTypesMask & unitType.bit) && unitType.isPresentOnMatching)
          _settings.mission[unitType.missionSettingsAvailabilityFlag] = false

    local mrankMin = missionSettings?.mrankMin ?? 0
    local mrankMax = missionSettings?.mrankMax ?? getMaxEconomicRank()
    if (mrankMin > mrankMax) {
      let temp = mrankMin
      mrankMin = mrankMax
      mrankMax = temp
    }
    if (mrankMin > 0 || mrankMax < getMaxEconomicRank())
      _settings.mranks <- { min = mrankMin, max = mrankMax }

    _settings.chatPassword <- isInSessionRoom.get() ? this.getChatRoomPassword() : gen_rnd_password(16)
    if (!u.isEmpty(SessionLobbyState.settings?.externalSessionId))
      _settings.externalSessionId <- SessionLobbyState.settings.externalSessionId
    if (!u.isEmpty(SessionLobbyState.settings?.psnMatchId))
      _settings.psnMatchId <- SessionLobbyState.settings.psnMatchId

    this.fillTeamsInfo(_settings, mission)

    this.checkDynamicSettings(true, _settings)
    this.setSettings(_settings)
  }

  function setExternalId(extId) {
    if (SessionLobbyState.settings?.externalSessionId == extId)
      return

    SessionLobbyState.settings["externalSessionId"] <- extId
    setRoomAttributes({ roomId = SessionLobbyState.roomId, public = SessionLobbyState.settings }, @(p) SessionLobby.afterRoomUpdate(p))
  }

  function getExternalId() {
    return SessionLobbyState.settings?.externalSessionId
  }

  function setPsnMatchId(mId) {
    this.syncMyInfo({ psnMatchId = mId })
  }


  function setSettings(v_settings, notify = false, checkEqual = true) {
    if (type(v_settings) == "array") {
      log("v_settings param, public info, is array, instead of table")
      debug_dump_stack()
      return
    }

    if (checkEqual && u.isEqual(SessionLobbyState.settings, v_settings))
      return

    //v_settings can be publick date of room, and it does not need to be updated settings somewhere else
    SessionLobbyState.settings = clone v_settings
    //not mission room settings
    SessionLobbyState.settings.connect_on_join <- !this.haveLobby()

    this.UpdateCrsSettings()
    this.UpdatePlayersInfo()
    updateOverrideSlotbar(this.getMissionName(true))

    SessionLobbyState.curEdiff = this.calcEdiff(SessionLobbyState.settings)

    SessionLobbyState.roomUpdated = notify || !isMeSessionLobbyRoomOwner.get() || !isInSessionRoom.get() || isInSessionLobbyEventRoom.get()
    if (!SessionLobbyState.roomUpdated)
      setRoomAttributes({ roomId = SessionLobbyState.roomId, public = SessionLobbyState.settings }, function(p) { SessionLobby.afterRoomUpdate(p) })

    if (isInSessionRoom.get())
      this.validateTeamAndReady()

    let newGm = this.getGameMode()
    if (newGm >= 0)
      set_game_mode(newGm)

    broadcastEvent("LobbySettingsChange")
  }

  function UpdatePlayersInfo() {
    // old format. players_info in lobby is array of objects for each player
    if ("players_info" in SessionLobbyState.settings) {
      SessionLobbyState.playersInfo.clear()
      playersInfoByNames.clear()
      foreach (pinfo in SessionLobbyState.settings.players_info) {
        SessionLobbyState.playersInfo[pinfo.id] <- pinfo
        playersInfoByNames[pinfo.name] <- pinfo
      }
      return
    }

    // new format. player infos are separate values in rooms public table
    foreach (k, pinfo in SessionLobbyState.settings) {
      if (k.indexof("pinfo_") != 0)
        continue
      let uid = k.slice(6).tointeger()
      if (pinfo == null || pinfo.len() == 0) {
        SessionLobbyState.playersInfo?.$rawdelete(uid)
      }
      else {
        SessionLobbyState.playersInfo[uid] <- pinfo
        playersInfoByNames[pinfo.name] <- pinfo
      }
    }
    updateIconPlayersInfo()
  }

  function UpdateCrsSettings() {
    SessionLobbyState.isSpectatorSelectLocked = false
    let userInUidsList = function(list_name) {
      let ids = getTblValue(list_name, this.getSessionInfo())
      if (u.isArray(ids))
        return isInArray(userIdInt64.value, ids)
      return false
    }

    if (userInUidsList("referees") || userInUidsList("spectators")) {
      SessionLobbyState.isSpectatorSelectLocked = true
      this.setSpectator(SessionLobbyState.isSpectatorSelectLocked)
    }

    SessionLobbyState.crsSetTeamTo = Team.none
    foreach (team in events.getSidesList()) {
      let players = this.getSessionInfo()?[events.getTeamName(team)].players
      if (!u.isArray(players))
        continue

      foreach (uid in players)
        if (isMyUserId(uid)) {
          SessionLobbyState.crsSetTeamTo = team
          break
        }

      if (SessionLobbyState.crsSetTeamTo != Team.none)
        break
    }
  }

  function fillTeamsInfo(v_settings, _misBlk) {
    //!!fill simmetric teams data
    let teamData = {}
    teamData.allowedCrafts <- []

    foreach (unitType in unitTypes.types)
      if (unitType.isAvailableByMissionSettings(v_settings.mission) && unitType.isPresentOnMatching) {
        let rule = { ["class"] = unitType.getMissionAllowedCraftsClassName() }
        if (v_settings?.mranks)
          rule.mranks <- v_settings.mranks
        teamData.allowedCrafts.append(rule)
      }

    //!!fill assymetric teamdata
    let teamDataA = teamData
    local teamDataB = clone teamData

    //in future better to comletely remove old countries selection, and use only countries in teamData
    teamDataA.countries <- v_settings.country_allies
    teamDataB.countries <- v_settings.country_axis

    this.addTeamsInfoToSettings(v_settings, teamDataA, teamDataB)
  }

  function addTeamsInfoToSettings(v_settings, teamDataA, teamDataB) {
    v_settings[events.getTeamName(Team.A)] <- teamDataA
    v_settings[events.getTeamName(Team.B)] <- teamDataB
  }

  function checkDynamicSettings(silent = false, v_settings = null) {
    if (!isMeSessionLobbyRoomOwner.get() && isInSessionRoom.get())
      return

    if (!v_settings) {
      if (!SessionLobbyState.settings || !SessionLobbyState.settings.len())
        return //owner have joined back to the room, and not receive settings yet
      v_settings = SessionLobbyState.settings
    }
    else
      silent = true //no need to update when custom settings checked

    local changed = false
    let wasHidden = getTblValue("hidden", v_settings, false)
    v_settings.hidden <- getTblValue("coop", v_settings, false)
      || (isRoomInSession.get() && !getTblValue("allowJIP", v_settings, true))
    changed = changed || (wasHidden != v_settings.hidden) // warning disable: -const-in-bool-expr

    let wasPassword = getTblValue("hasPassword", v_settings, false)
    v_settings.hasPassword <- SessionLobbyState.password != ""
    changed = changed || (wasPassword != v_settings.hasPassword)

    if (changed && !silent)
      this.setSettings(SessionLobbyState.settings, false, false)
  }

  function onSettingsChanged(p) {
    if (SessionLobbyState.roomId != p.roomId)
      return
    let set = getTblValue("public", p)
    if (!set)
      return

    if ("last_round" in set) {
      last_round = set.last_round
      log($"last round {last_round}")
    }

    let newSet = clone SessionLobbyState.settings
    foreach (k, v in set)
      if (v == null) {
        newSet?.$rawdelete(k)
      }
      else
        newSet[k] <- v

    this.setSettings(newSet, true)

    this.setRoomInSession(this.isSessionStartedInRoom())
  }

  function setRoomInSession(newIsInSession) {
    if (newIsInSession == isRoomInSession.get())
      return

    isRoomInSession.set(newIsInSession)
    if (!isInSessionRoom.get())
      return

    broadcastEvent("LobbyRoomInSession")
    if (isMeSessionLobbyRoomOwner.get())
      this.checkDynamicSettings()
  }

  function isCoop() {
    return ("coop" in SessionLobbyState.settings) ? SessionLobbyState.settings.coop : false
  }

  function haveLobby() {
    let gm = this.getGameMode()
    if (gm == GM_SKIRMISH)
      return true
    if (gm == GM_DOMINATION)
      return isEventWithLobby(this.getRoomEvent())
    return false
  }

  function getSessionInfo() {
    return SessionLobbyState.settings
  }

  function getMissionName(isOriginalName = false, room = null) {
    let misData = this.getMissionData(room)
    let missionName = misData?.name ?? ""
    return isOriginalName ? (misData?.originalMissionName ?? missionName) : missionName
  }

  function getMissionNameLoc(room = null) {
    let misData = this.getMissionData(room)
    if ("name" in misData) {
      let missionMetaInfo = getUrlOrFileMissionMetaInfo(misData.name)
      return getCombineLocNameMission(missionMetaInfo ? missionMetaInfo : misData)
    }
    return ""
  }

  function getPublicData(room = null) {
    return room ? (("public" in room) ? room.public : room) : SessionLobbyState.settings
  }

  function getMissionData(room = null) {
    return getTblValue("mission", this.getPublicData(room))
  }

  function getGameMode(room = null) {
    return getTblValue("_gameMode", this.getMissionData(room), GM_DOMINATION)
  }

  function getGameType(room = null) {
    let res = getTblValue("_gameType", this.getMissionData(room), 0)
    return u.isInteger(res) ? res : 0
  }

  function getMGameModeId(room = null) { //gameModeId by matchingGameModes
    return getTblValue("game_mode_id", this.getPublicData(room))
  }

  function getClusterName(room = null) {
    local cluster = getTblValue("cluster", room)
    if (cluster == null)
      cluster = getTblValue("cluster", this.getPublicData(room))
    return cluster || ""
  }

  function getMaxRespawns(room = null) {
    return getTblValue("maxRespawns", this.getMissionData(room), 0)
  }

  function getTimeLimit(room = null) {
    local timeLimit = getTblValue("timeLimit", this.getMissionData(room), 0)
    if (timeLimit)
      return timeLimit

    let missionName = this.getMissionName(true, room)
    if (!missionName)
      return timeLimit

    let misData = get_meta_mission_info_by_name(missionName)
    timeLimit = getTblValue("timeLimit", misData, 0)
    return timeLimit
  }

  //need only for  event roomsList, because other rooms has full rules list in public
  //return null when no such rules
  function getRoomSpecialRules(_room = null) {
    return null //now all data come in room teamData even in list. But maybe this mehanism will be used in future.
  }

  function getTeamData(teamCode, room = null) {
    return events.getTeamData(this.getPublicData(room), teamCode)
  }

  function getRequiredCrafts(teamCode = Team.A, room = null) {
    let teamData = this.getTeamData(teamCode, room)
    return events.getRequiredCrafts(teamData)
  }

  function getRoomSessionStartTime(room = null) {
    return getTblValue("matchStartTime", this.getPublicData(room), 0)
  }

  function getUnitTypesMask(room = null) {
    return events.getEventUnitTypesMask(this.getMGameMode(room) || this.getPublicData(room))
  }

  function getRequiredUnitTypesMask(room = null) {
    return events.getEventRequiredUnitTypesMask(this.getMGameMode(room) || this.getPublicData(room))
  }

  function getNotAvailableUnitByBRText(unit, room = null) {
    if (!unit)
      return null

    let mGameMode = this.getMGameMode(room)
    if (!mGameMode)
      return null

    let curBR = unit.getBattleRating(isInFlight()
      ? get_mission_difficulty_int()
      : getCurrentShopDifficulty().diffCode)
    let maxBR = (this.getBattleRatingParamByPlayerInfo(this.getMemberPlayerInfo(userIdInt64.value),
      ES_UNIT_TYPE_SHIP)?.units?[0]?.rating ?? 0) + MAX_BR_DIFF_AVAILABLE_AND_REQ_UNITS
    return (events.isUnitTypeRequired(mGameMode, ES_UNIT_TYPE_SHIP)
      && unit.esUnitType == ES_UNIT_TYPE_AIRCRAFT
      && ((curBR - maxBR) * 10).tointeger() >= 0)
        ? loc("not_available_aircraft/byBR", {
            gameModeName = events.getEventNameText(mGameMode),
            lockedUnitType = colorize("userlogColoredText",
              loc($"mainmenu/type_{unit.unitType.lowerName}")),
            battleRatingDiff = colorize("userlogColoredText", format("%.1f", MAX_BR_DIFF_AVAILABLE_AND_REQ_UNITS)),
            reqUnitType = colorize("userlogColoredText", loc("mainmenu/type_ship_and_boat"))
          })
        : null
  }

  function calcEdiff(room = null) {
    return this.getDifficulty(room).getEdiffByUnitMask(this.getUnitTypesMask(room))
  }

  function getCurRoomEdiff() {
    return SessionLobbyState.curEdiff
  }

  function getMissionParam(name, defValue = "") {
    if (("mission" in SessionLobbyState.settings) && (name in SessionLobbyState.settings.mission))
      return SessionLobbyState.settings.mission[name]
    return defValue
  }

  function getPublicParam(name, defValue = "") {
    if (name in SessionLobbyState.settings)
      return SessionLobbyState.settings[name]
    return defValue
  }

  function getMissionParams() {
    if (!isInSessionRoom.get())
      return null
    return ("mission" in SessionLobbyState.settings) ? SessionLobbyState.settings.mission : null
  }


  function getOperationId() {
    if (!isInSessionRoom.get())
      return -1
    return (this.getMissionParams()?.customRules?.operationId ?? -1).tointeger()
  }

  function getWwBattleId() {
    if (!isInSessionRoom.get())
      return ""
    return (this.getMissionParams()?.customRules?.battleId ?? "")
  }

  function getTeamsCountries(room = null) {
    let res = []
    local hasCountries = false
    foreach (t in [Team.A, Team.B]) {
      let teamData = this.getTeamData(t, room)
      let countries = events.getCountries(teamData)
      res.append(countries)
      hasCountries = hasCountries || countries.len()
    }

    if (hasCountries)
      return res
    //!!FIX ME: is we need a code below? But better to do something with it only with a s.zvyagin
    let mGameMode = this.getMGameMode(room)
    if (mGameMode)
      return events.getCountriesByTeams(mGameMode)

    let pData = this.getPublicData(room)
    foreach (idx, name in ["country_allies", "country_axis"])
      if (name in pData)
        res[idx] = pData[name]
    return res
  }

  function switchStatus(v_status) {
    if (sessionLobbyStatus.get() == v_status)
      return

    let wasInRoom = isInSessionRoom.get()
    let wasStatus = sessionLobbyStatus.get()
    let wasSessionInLobby = isInSessionLobbyEventRoom.get()
    sessionLobbyStatus.set(v_status)  //for easy notify other handlers about change status
    if (isInJoiningGame.get())
      joiningGameWaitBox()
    if (sessionLobbyStatus.get() == lobbyStates.IN_LOBBY) {
      //delay to allow current view handlers to catch room state change event before destroy
      let guiScene = get_main_gui_scene()
      if (guiScene)
        guiScene.performDelayed(this, guiStartMpLobby)
    }

    if (sessionLobbyStatus.get() == lobbyStates.IN_DEBRIEFING && this.hasSessionInLobby())
      this.leaveEventSessionWithRetry()

    if (sessionLobbyStatus.get() == lobbyStates.NOT_IN_ROOM || sessionLobbyStatus.get() == lobbyStates.IN_DEBRIEFING)
      this.setReady(false, true)
    if (sessionLobbyStatus.get() == lobbyStates.NOT_IN_ROOM) {
      this.resetParams()
      if (wasStatus == lobbyStates.JOINING_SESSION)
        ::destroy_session_scripted("on leave room while joining session")
    }
    if (sessionLobbyStatus.get() == lobbyStates.JOINING_SESSION)
      addRecentContacts(g_squad_manager.getSquadMembersDataForContact())

    this.updateMyState()

    broadcastEvent("LobbyStatusChange")
    eventbus_send("setIsMultiplayerState", { isMultiplayer = isInSessionRoom.get() })
    if (wasInRoom != isInSessionRoom.get())
      broadcastEvent("LobbyIsInRoomChanged", { wasSessionInLobby })
  }

  function resetParams() {
    SessionLobbyState.settings.clear()
    this.changePassword("") //reset password after leave room
    this.updateMemberHostParams(null)
    SessionLobbyState.team = Team.Any
    SessionLobbyState.isRoomByQueue = false
    isInSessionLobbyEventRoom.set(false)
    SessionLobbyState.myState = PLAYER_IN_LOBBY_NOT_READY
    SessionLobbyState.roomUpdated = false
    SessionLobbyState.spectator = false
    SessionLobbyState._syncedMyInfo = null
    SessionLobbyState.needJoinSessionAfterMyInfoApply = false
    SessionLobbyState.isLeavingLobbySession = false
    SessionLobbyState.playersInfo.clear()
    playersInfoByNames.clear()
    resetSlotbarOverrided()
    ::g_user_presence.setPresence({ in_game_ex = null })
  }

  function resetPlayersInfo() {
    SessionLobbyState.playersInfo.clear()
    playersInfoByNames.clear()
  }

  function switchStatusChecked(oldStatusList, newStatus) {
    if (isInArray(sessionLobbyStatus.get(), oldStatusList))
      this.switchStatus(newStatus)
  }

  function changePassword(v_password) {
    if (type(v_password) != "string" || SessionLobbyState.password == v_password)
      return

    if (isMeSessionLobbyRoomOwner.get() && sessionLobbyStatus.get() != lobbyStates.NOT_IN_ROOM && sessionLobbyStatus.get() != lobbyStates.CREATING_ROOM) {
      let prevPass = SessionLobbyState.password
      roomSetPassword({ roomId = SessionLobbyState.roomId, password = v_password },
        function(p) {
          if (!checkMatchingError(p)) {
            SessionLobbyState.password = prevPass
            SessionLobby.checkDynamicSettings()
          }
        })
    }
    SessionLobbyState.password = v_password
  }

  function getMisListType(v_settings = null) {
    if (this.isUserMission(v_settings))
      return g_mislist_type.UGM
    if (this.isUrlMission(v_settings))
      return g_mislist_type.URL
    return g_mislist_type.BASE
  }

  function isUserMission(v_settings = null) {
    return getTblValue("userMissionName", v_settings || SessionLobbyState.settings) != null
  }

  function isUrlMission(room = null) {
    return this.getMissionUrl(room) != ""
  }

  function getMissionUrl(room = null) {
    return this.getPublicData(room)?.missionURL ?? ""
  }

  function isMissionReady() {
    return !this.isUserMission() ||
           (sessionLobbyStatus.get() != lobbyStates.UPLOAD_CONTENT && SessionLobbyState.uploadedMissionId == this.getMissionName())
  }

  function uploadUserMission(afterDoneFunc = null) {
    if (!isInSessionRoom.get() || !this.isUserMission() || sessionLobbyStatus.get() == lobbyStates.UPLOAD_CONTENT)
      return
    if (SessionLobbyState.uploadedMissionId == this.getMissionName()) {
      afterDoneFunc?()
      return
    }

    let missionId = this.getMissionName()
    let missionInfo = DataBlock()
    missionInfo.setFrom(getUrlOrFileMissionMetaInfo(missionId))
    let missionBlk = DataBlock()
    if (missionInfo)
      missionBlk.load(missionInfo.mis_file)
    //dlog("GP: upload mission!")
    //debugTableData(missionBlk)

    let blkData = base64.encodeBlk(missionBlk)
    //dlog($"GP: data = {blkData}")
    //debugTableData(blkData)
    if (!blkData || !("result" in blkData) || !blkData.result.len()) {
      showInfoMsgBox(loc("msg/cant_load_user_mission"))
      return
    }

    this.switchStatus(lobbyStates.UPLOAD_CONTENT)
    setRoomAttributes({ roomId = SessionLobbyState.roomId, private = { userMission = blkData.result } },
                          function(p) {
                            if (!checkMatchingError(p)) {
                              SessionLobby.returnStatusToRoom()
                              return
                            }
                            SessionLobbyState.uploadedMissionId = missionId
                            SessionLobby.returnStatusToRoom()
                            if (afterDoneFunc)
                              afterDoneFunc()
                          })
  }

  function mergeTblChanges(tblBase, tblNew) {
    if (tblNew == null)
      return tblBase

    foreach (key, value in tblNew)
      if (value != null)
        tblBase[key] <- value
      else if (key in tblBase)
        tblBase.$rawdelete(key)
    return tblBase
  }

  function updateMemberHostParams(member = null) { //null = host leave
    SessionLobbyState.memberHostId = member ? member.memberId : -1
  }


  function updateReadyAndSyncMyInfo(ready) {
    SessionLobbyState.isReady = ready
    this.syncMyInfo({ state = this.updateMyState(true) })
    broadcastEvent("LobbyReadyChanged")
  }

  function onMemberInfoUpdate(params) {
    if (params.roomId != SessionLobbyState.roomId)
      return
    if (this.isMemberHost(params))
      return this.updateMemberHostParams(params)

    local member = null
    foreach (m in SessionLobbyState.members)
      if (m.memberId == params.memberId) {
        member = m
        break
      }
    if (!member)
      return

    foreach (tblName in ["public", "private"])
      if (tblName in params)
        if (tblName in member)
          this.mergeTblChanges(member[tblName], params[tblName])
        else
          member[tblName] <- params[tblName]

    if (isMyUserId(member.userId)) {
      isMeSessionLobbyRoomOwner.set(this.isMemberOperator(member))
      SessionLobbyState.isInLobbySession = this.isMemberInSession(member)
      this.initMyParamsByMemberInfo(member)
      let ready = getTblValue("ready", getTblValue("public", member, {}), null)
      if (!this.hasSessionInLobby() && ready != null && ready != SessionLobbyState.isReady)
        this.updateReadyAndSyncMyInfo(ready)
      else if (SessionLobbyState.needJoinSessionAfterMyInfoApply)
        this.tryJoinSession(true)
      SessionLobbyState.needJoinSessionAfterMyInfoApply = false
    }
    broadcastEvent("LobbyMemberInfoChanged")
  }

  function initMyParamsByMemberInfo(me = null) {
    if (!me)
      me = u.search(SessionLobbyState.members, function(m) { return isMyUserId(m.userId) })
    if (!me)
      return

    let myTeam = this.getMemberPublicParam(me, "team")
    if (myTeam != Team.Any && myTeam != SessionLobbyState.team)
      SessionLobbyState.team = myTeam

    if (myTeam == Team.Any)
      this.validateTeamAndReady()
  }

  function syncMyInfo(newInfo, reqUpdateMatchingSlots = false) {
    if (isInArray(sessionLobbyStatus.get(), [lobbyStates.NOT_IN_ROOM, lobbyStates.WAIT_FOR_QUEUE_ROOM, lobbyStates.CREATING_ROOM, lobbyStates.JOINING_ROOM])
        || !this.haveLobby()
        || SessionLobbyState.isLeavingLobbySession)
      return

    local syncData = newInfo
    if (!SessionLobbyState._syncedMyInfo)
      SessionLobbyState._syncedMyInfo = newInfo
    else {
      syncData = {}
      foreach (key, value in newInfo) {
        if (key in SessionLobbyState._syncedMyInfo) {
          if (SessionLobbyState._syncedMyInfo[key] == value)
            continue
          if (type(value) == "array" || type(value) == "table")
            if (u.isEqual(SessionLobbyState._syncedMyInfo[key], value))
              continue
        }
        syncData[key] <- value
        SessionLobbyState._syncedMyInfo[key] <- value
      }
    }

    // DIRTY HACK: Server ignores spectator=true flag if it is sent before pressing Ready button,
    // when Referee joins into already started Skirmish mission.
    if (getTblValue("state", newInfo) == lobbyStates.IN_ROOM)
      syncData.spectator <- getTblValue("spectator", SessionLobbyState._syncedMyInfo, false)

    let info = {
      roomId = SessionLobbyState.roomId
      public = syncData
    }

    // Sends info to server
    setMemberAttributes(info,  function(_p) {
      if (reqUpdateMatchingSlots)
        this.checkUpdateMatchingSlots()
    }.bindenv(this))
    broadcastEvent("LobbyMyInfoChanged", syncData)
  }

  function syncAllInfo() {
    let myInfo = getProfileInfo()
    let myStats = getStats()
    let squadId = g_squad_manager.getSquadData().id

    this.syncMyInfo({
      team = SessionLobbyState.team
      squad = this.getGameMode() == GM_SKIRMISH && squadId != "" ? squadId.tointeger() : INVALID_SQUAD_ID
      country = SessionLobbyState.countryData ? SessionLobbyState.countryData.country : null
      selAirs = SessionLobbyState.countryData ? SessionLobbyState.countryData.selAirs : null
      slots = SessionLobbyState.countryData ? SessionLobbyState.countryData.slots : null
      spectator = SessionLobbyState.spectator
      clanTag = myInfo.clanTag
      title = myStats ? myStats.title : ""
      pilotId = myInfo.pilotId
      state = this.updateMyState(true)
    })
  }

  function getMemberState(member) {
    return this.getMemberPublicParam(member, "state")
  }

  function getMemberPublicParam(member, param) {
    return (("public" in member) && (param in member.public)) ? member.public[param] : memberDefaults[param]
  }

  function isMemberInSession(member) {
    return this.getMemberPublicParam(member, "is_in_session")
  }

  function isMemberReady(member) {
    return this.getMemberPublicParam(member, "ready")
  }

  function getMemberInfo(member) {
    if (!member)
      return null

    let pub = ("public" in member) ? member.public : {}
    let res = {
      memberId = member.memberId
      userId = member.userId.tostring() //member info same format as get_mplayers_list
      name = member.name
      isLocal = isMyUserId(member.userId)
      spectator = getTblValue("spectator", member, false)
      isBot = false
    }
    foreach (key, value in memberDefaults)
      res[key] <- (key in pub) ? pub[key] : value

    if (this.hasSessionInLobby()) {
      if (res.state == PLAYER_IN_LOBBY_NOT_READY || res.state == PLAYER_IN_LOBBY_READY)
        res.state = this.isMemberInSession(member) ? PLAYER_IN_LOBBY_READY : PLAYER_IN_LOBBY_NOT_READY
    }
    else if (!this.isUserCanChangeReady() && res.state == PLAYER_IN_LOBBY_NOT_READY)
      res.state = PLAYER_IN_LOBBY_READY //player cant change ready self, and will go to battle event when no ready.
    return res
  }

  function getMemberByName(name, room = null) {
    if (name == "")
      return null
    foreach (_key, member in this.getRoomMembers(room))
      if (member.name == name)
        return member
    return null
  }

  function getMembersInfoList(room = null) {
    let res = []
    foreach (member in this.getRoomMembers(room))
      res.append(this.getMemberInfo(member))
    return res
  }

  function updateMyState(silent = false) {
    local newState = PLAYER_IN_LOBBY_NOT_READY
    if (sessionLobbyStatus.get() == lobbyStates.IN_LOBBY || sessionLobbyStatus.get() == lobbyStates.START_SESSION)
      newState = SessionLobbyState.isReady ? PLAYER_IN_LOBBY_READY : PLAYER_IN_LOBBY_NOT_READY
    else if (sessionLobbyStatus.get() == lobbyStates.IN_LOBBY_HIDDEN)
      newState = PLAYER_IN_LOBBY_READY
    else if (sessionLobbyStatus.get() == lobbyStates.IN_SESSION)
      newState = PLAYER_IN_FLIGHT
    else if (sessionLobbyStatus.get() == lobbyStates.IN_DEBRIEFING)
      newState = PLAYER_IN_STATISTICS_BEFORE_LOBBY

    let changed = SessionLobbyState.myState != newState
    SessionLobbyState.myState = newState
    if (!silent && changed)
      this.syncMyInfo({ state = this.updateMyState(true) })
    return SessionLobbyState.myState
  }

  function setReady(ready, silent = false, forceRequest = false) { //return is my info changed
    if (!forceRequest && SessionLobbyState.isReady == ready)
      return false
    if (ready && !this.canSetReady(silent)) {
      if (SessionLobbyState.isReady)
        ready = false
      else
        return false
    }

    if (!isInSessionRoom.get()) {
      SessionLobbyState.isReady = false
      return ready
    }

    SessionLobbyState.isReadyInSetStateRoom = ready
    roomSetReadyState(
      { state = ready, roomId = SessionLobbyState.roomId },
       function(p) {
        SessionLobbyState.isReadyInSetStateRoom = null
        if (!isInSessionRoom.get()) {
          SessionLobbyState.isReady = false
          return
        }

        let wasReady = SessionLobbyState.isReady
        local needUpdateState = !silent
        SessionLobbyState.isReady = ready

        //if we receive error on set ready, result is ready == false always.
        if (!checkMatchingError(p, !silent)) {
          SessionLobbyState.isReady = false
          needUpdateState = true
        }

        if (SessionLobbyState.isReady == wasReady)
          return

        if (needUpdateState)
          this.syncMyInfo({ state = this.updateMyState(true) })
        broadcastEvent("LobbyReadyChanged")
      }.bindenv(this))
    return true
  }

  //matching update slots from char when ready flag set to true
  function checkUpdateMatchingSlots() {
    if (this.hasSessionInLobby()) {
      if (SessionLobbyState.isInLobbySession)
        this.joinEventSession(false, { update_profile = true })
    }
    else if (SessionLobbyState.isReady && (SessionLobbyState.isReadyInSetStateRoom == null || SessionLobbyState.isReadyInSetStateRoom))
      this.setReady(SessionLobbyState.isReady, true, true)
  }

  function getAvailableTeam() {
    if (SessionLobbyState.spectator)
      return (SessionLobbyState.crsSetTeamTo == Team.none) ? Team.Any : SessionLobbyState.crsSetTeamTo

    let myCountry = profileCountrySq.value
    let aTeams = [SessionLobbyState.crsSetTeamTo != Team.B, //Team.A or Team.none
                    SessionLobbyState.crsSetTeamTo != Team.A
                   ]

    let teamsCountries = this.getTeamsCountries()
    foreach (idx, _value in aTeams)
      if (!isInArray(myCountry, getTblValue(idx, teamsCountries, teamsCountries[0])))
        aTeams[idx] = false

    local canPlayTeam = 0
    if (aTeams[0])
      canPlayTeam = aTeams[1] ? Team.Any : Team.A
    else
      canPlayTeam = aTeams[1] ? Team.B : Team.none
    return canPlayTeam
  }

  function checkMyTeam() { //returns changed data
    let data = {}

    if (!this.haveLobby())
      return data

    local setTeamTo = SessionLobbyState.team
    if (this.getAvailableTeam() == Team.none) {
      if (this.setReady(false, true))
        data.state <- this.updateMyState(true)
      setTeamTo = SessionLobbyState.crsSetTeamTo
    }

    if (setTeamTo != Team.none && this.setTeam(setTeamTo, true)) {
      data.team <- SessionLobbyState.team
      let myCountry = profileCountrySq.value
      let availableCountries = this.getTeamData(SessionLobbyState.team)?.countries ?? []
      if (availableCountries.len() > 0 && !isInArray(myCountry, availableCountries))
        switchProfileCountry(availableCountries[0])
    }
    return data
  }

  function canChangeTeam() {
    if (!this.haveLobby() || isInSessionLobbyEventRoom.get())
      return false
    let canPlayTeam = this.getAvailableTeam()
    return canPlayTeam == Team.Any
  }


  function switchTeam(skipTeamAny = false) {
    if (!this.canChangeTeam())
      return false

    local newTeam = SessionLobbyState.team + 1
    if (newTeam >= Team.none)
      newTeam = skipTeamAny ? 1 : 0
    return this.setTeam(newTeam)
  }

  function setTeam(newTeam, silent = false) { //return is team changed
    local _team = newTeam
    let canPlayTeam = this.getAvailableTeam()

    if (canPlayTeam == Team.A || canPlayTeam == Team.B)
      _team = canPlayTeam

    if (SessionLobbyState.team == _team)
      return false

    SessionLobbyState.team = _team

    if (!silent)
      this.syncMyInfo({ team = SessionLobbyState.team }, true)

    return true
  }

  function canBeSpectator() {
    if (!hasFeature("Spectator"))
      return false
    if (this.getGameMode() != GM_SKIRMISH) //spectator only for skirmish mode
      return false
    return true
  }

  function switchSpectator() {
    if (!this.canBeSpectator() && !SessionLobbyState.spectator)
      return false

    local newSpectator = !SessionLobbyState.spectator
    return this.setSpectator(newSpectator)
  }

  function setSpectator(newSpectator) { //return is spectator changed
    if (!this.canBeSpectator())
      newSpectator = false
    if (SessionLobbyState.spectator == newSpectator)
      return false

    SessionLobbyState.spectator = newSpectator
    this.syncMyInfo({ spectator = SessionLobbyState.spectator }, true)
    return true
  }

  function setCountryData(data) { //return is data changed
    local changed = !SessionLobbyState.countryData || !u.isEqual(SessionLobbyState.countryData, data)
    SessionLobbyState.countryData = data
    let teamDataChanges = this.checkMyTeam()
    changed = changed || teamDataChanges.len() > 0
    if (!changed)
      return false

    foreach (i, v in teamDataChanges)
      data[i] <- v
    this.syncMyInfo(data, true)
    return true
  }

  function validateTeamAndReady() {
    let teamDataChanges = this.checkMyTeam()
    if (!teamDataChanges.len()) {
      if (SessionLobbyState.isReady && !this.canSetReady(true))
        this.setReady(false)
      return
    }
    this.syncMyInfo(teamDataChanges, true)
  }

  function canSetReady(silent) {
    if (SessionLobbyState.spectator)
      return true

    let availTeam = this.getAvailableTeam()
    if (availTeam == Team.none) {
      if (!silent)
        showInfoMsgBox(loc("events/no_selected_country"))
      return false
    }

    let curCountry = SessionLobbyState.countryData?.country
    let checkUnitsResult = this.checkUnitsInSlotbar(curCountry, availTeam)
    let res = checkUnitsResult.isAvailable
    if (!res && !silent)
      showInfoMsgBox(checkUnitsResult.reasonText)

    return res
  }

  function isUserCanChangeReady() {
    return !this.hasSessionInLobby()
  }

  function canChangeSettings() {
    return !isInSessionLobbyEventRoom.get() && isMeSessionLobbyRoomOwner.get()
  }

  function canStartSession() {
    return !isInSessionLobbyEventRoom.get() && isMeSessionLobbyRoomOwner.get()
  }

  function canChangeCrewUnits() {
    return !isInSessionLobbyEventRoom.get() || !isRoomInSession.get()
  }

  function canChangeCountry() {
    return !isInSessionRoom.get() || !isInSessionLobbyEventRoom.get()
  }

  function canInviteIntoSession() {
    return isInSessionRoom.get() && this.getGameMode() == GM_SKIRMISH
  }

  function isInvalidCrewsAllowed() {
    return !isInSessionRoom.get() || !isInSessionLobbyEventRoom.get()
  }

  function isMpSquadChatAllowed() {
    return this.getGameMode() != GM_SKIRMISH
  }

  function startCoopBySquad(missionSettings) {
    if (sessionLobbyStatus.get() != lobbyStates.NOT_IN_ROOM)
      return false

    this.prepareSettings(missionSettings)

    requestCreateRoom({ size = 4, public = SessionLobbyState.settings }, function(p) { SessionLobby.afterRoomCreation(p) })
    this.switchStatus(lobbyStates.CREATING_ROOM)
    return true
  }

  function createRoom(missionSettings) {
    if (sessionLobbyStatus.get() != lobbyStates.NOT_IN_ROOM)
      return false

    this.prepareSettings(missionSettings)

    let initParams = {
      size = this.getMaxMembersCount()
      public = SessionLobbyState.settings
    }
    if (SessionLobbyState.password && SessionLobbyState.password != "")
      initParams.password <- SessionLobbyState.password
    let blacklist = getContactsGroupUidList(EPL_BLOCKLIST)
    if (blacklist.len())
      initParams.blacklist <- blacklist

    requestCreateRoom(initParams, function(p) { SessionLobby.afterRoomCreation(p) })
    this.switchStatus(lobbyStates.CREATING_ROOM)
    return true
  }

  function createEventRoom(mGameMode, lobbyParams) {
    if (sessionLobbyStatus.get() != lobbyStates.NOT_IN_ROOM)
      return false

    let params = {
      public = {
        game_mode_id = mGameMode.gameModeId
      }
      custom_matching_lobby = lobbyParams
    }

    isInSessionLobbyEventRoom.set(true)
    requestCreateRoom(params, function(p) { SessionLobby.afterRoomCreation(p) })
    this.switchStatus(lobbyStates.CREATING_ROOM)
    return true
  }

  function continueCoopWithSquad(missionSettings) {
    this.switchStatus(lobbyStates.IN_ROOM);
    this.prepareSettings(missionSettings);
  }

  function afterRoomCreation(params) {
    if (!checkMatchingError(params))
      return this.switchStatus(lobbyStates.NOT_IN_ROOM)

    isMeSessionLobbyRoomOwner.set(true)
    SessionLobbyState.isRoomByQueue = false
    this.afterRoomJoining(params)
  }

  function destroyRoom() {
    if (!isMeSessionLobbyRoomOwner.get())
      return

    requestDestroyRoom({ roomId = SessionLobbyState.roomId }, function(_p) {})
    this.afterLeaveRoom({})
  }

  function leaveRoom() {
    if (sessionLobbyStatus.get() == lobbyStates.NOT_IN_ROOM || sessionLobbyStatus.get() == lobbyStates.WAIT_FOR_QUEUE_ROOM) {
      this.setWaitForQueueRoom(false)
      return
    }

    requestLeaveRoom({}, function(_p) {
        SessionLobby.afterLeaveRoom({})
     })
  }

  function checkLeaveRoomInDebriefing() {
    if (get_game_mode() == GM_DYNAMIC && !isDynamicWon())
      return;

    if (!last_round)
      return;

    if (isInSessionRoom.get() && !this.haveLobby())
      this.leaveRoom()
  }

  //return true if success
  function goForwardAfterDebriefing() {
    if (!this.haveLobby() || !isInSessionRoom.get())
      return false

    SessionLobbyState.isRoomByQueue = false //from now it not room by queue because we are back to lobby from session
    if (sessionLobbyStatus.get() == lobbyStates.IN_LOBBY)
      guiStartMpLobby()
    else
      this.returnStatusToRoom()
    return true
  }

  function afterLeaveRoom(_p) {
    SessionLobbyState.roomId = INVALID_ROOM_ID
    this.switchStatus(lobbyStates.NOT_IN_ROOM)

    if (needCheckReconnect) {
      needCheckReconnect = false

      let guiScene = get_main_gui_scene()
      if (guiScene)
        guiScene.performDelayed({}, checkReconnect) //notify room leave will be received soon
    }
  }

  function sendJoinRoomRequest(join_params, _cb = function(...) {}) {
    if (isInSessionRoom.get())
      this.leaveRoom() //leave old room before join the new one

    leave_mp_session()

    if (!isMeSessionLobbyRoomOwner.get()) {
      this.setSettings({})
      SessionLobbyState.members = []
    }

    set_last_session_debug_info(
      ("roomId" in join_params) ? ($"room:{join_params.roomId}") :
      ("battleId" in join_params) ? ($"battle:{join_params.battleId}") :
      ""
    )

    this.switchStatus(lobbyStates.JOINING_ROOM)
    requestJoinRoom(join_params, this.afterRoomJoining.bindenv(this))
  }

  function joinBattle(battleId) {
    ::queues.leaveAllQueuesSilent()
    notifyQueueLeave({})
    isMeSessionLobbyRoomOwner.set(false)
    SessionLobbyState.isRoomByQueue = false
    this.sendJoinRoomRequest({ battleId = battleId })
  }

  function joinRoom(v_roomId, senderId = "", v_password = null,
                                  cb = function(...) {}) { //by default not a queue, but no id too
    if (SessionLobbyState.roomId == v_roomId && isInSessionRoom.get())
      return

    if (!isLoggedIn.get() || isInSessionRoom.get()) {
      //delayedJoinRoomFunc =  function() { this.joinRoom(v_roomId, senderId, v_password, cb) }

      if (isInSessionRoom.get())
        this.leaveRoom()
      return
    }

    isMeSessionLobbyRoomOwner.set(isMyUserId(senderId))
    SessionLobbyState.isRoomByQueue = senderId == null

    if (SessionLobbyState.isRoomByQueue)
      notifyQueueLeave({})
    else
      ::queues.leaveAllQueuesSilent()

    if (v_password && v_password.len())
      this.changePassword(v_password)

    let joinParams = { roomId = v_roomId }
    if (SessionLobbyState.password != "")
      joinParams.password <- SessionLobbyState.password

    this.sendJoinRoomRequest(joinParams, cb)
  }

  function joinFoundRoom(room) { //by default not a queue, but no id too
    if (("hasPassword" in room) && room.hasPassword && this.getRoomCreatorUid(room) != userName.value)
      this.joinRoomWithPassword(room.roomId)
    else
      this.joinRoom(room.roomId)
  }

  function joinRoomWithPassword(joinRoomId, prevPass = "", wasEntered = false) {
    if (joinRoomId == "") {
      assert(false, "SessionLobby Error: try to join room with password with empty room id")
      return
    }

    openEditBoxDialog({
      value = prevPass
      title = loc("mainmenu/password")
      label = wasEntered ? loc("matching/SERVER_ERROR_ROOM_PASSWORD_MISMATCH") : ""
      isPassword = true
      allowEmpty = false
      okFunc = @(pass) SessionLobby.joinRoom(joinRoomId, "", pass)
    })
  }

  function afterRoomJoining(params) {
    if (params.error == SERVER_ERROR_ROOM_PASSWORD_MISMATCH) {
      let joinRoomId = params.roomId //not_in_room status will clear room Id
      let oldPass = params.password
      this.switchStatus(lobbyStates.NOT_IN_ROOM)
      this.joinRoomWithPassword(joinRoomId, oldPass, oldPass != "")
      return
    }

    if (!checkMatchingError(params))
      return this.switchStatus(lobbyStates.NOT_IN_ROOM)

    SessionLobbyState.roomId = params.roomId
    SessionLobbyState.roomUpdated = true
    SessionLobbyState.members = getTblValue("members", params, [])
    this.initMyParamsByMemberInfo()
    clearMpChatLog()
    ::g_squad_utils.updateMyCountryData()

    let public = getTblValue("public", params, SessionLobbyState.settings)
    if (!isMeSessionLobbyRoomOwner.get() || u.isEmpty(SessionLobbyState.settings)) {
      this.setSettings(public)

      let mGameMode = this.getMGameMode()
      if (mGameMode) {
        this.setIngamePresence(public, SessionLobbyState.roomId)
        isInSessionLobbyEventRoom.set(isEventWithLobby(mGameMode))
      }
      log($"Joined room: isInSessionLobbyEventRoom {isInSessionLobbyEventRoom.get()}")

      if (SessionLobbyState.isRoomByQueue && !this.isSessionStartedInRoom())
        SessionLobbyState.isRoomByQueue = false
      if (isInSessionLobbyEventRoom.get() && !SessionLobbyState.isRoomByQueue && this.haveLobby())
        SessionLobbyState.needJoinSessionAfterMyInfoApply = true
    }

    for (local i = SessionLobbyState.members.len() - 1; i >= 0; i--)
      if (this.isMemberHost(SessionLobbyState.members[i])) {
        this.updateMemberHostParams(SessionLobbyState.members[i])
        SessionLobbyState.members.remove(i)
      }
      else if (isMyUserId(SessionLobbyState.members[i].userId))
        isMeSessionLobbyRoomOwner.set(this.isMemberOperator(SessionLobbyState.members[i]))

    this.returnStatusToRoom()
    this.syncAllInfo()

    this.checkSquadAutoInvite()

    let event = this.getRoomEvent()
    if (event) {
      if (events.isEventVisibleInEventsWindow(event))
        saveLocalByAccount("lastPlayedEvent", {
          eventName = event.name
          economicName = getEventEconomicName(event)
        })

      broadcastEvent("AfterJoinEventRoom", event)
    }

    if (isMeSessionLobbyRoomOwner.get() && get_game_mode() == GM_DYNAMIC && !dynamicMissionPlayed()) {
      serializeDyncampaign(
        function(p) {
          if (checkMatchingError(p))
            SessionLobby.checkAutoStart()
          else
            SessionLobby.destroyRoom();
        });
    }
    else
      this.checkAutoStart()
    initListLabelsSquad()

    last_round = getTblValue("last_round", public, true)
    this.setRoomInSession(this.isSessionStartedInRoom())
    broadcastEvent("RoomJoined", params)
  }

  function returnStatusToRoom() {
    local newStatus = lobbyStates.IN_ROOM
    if (this.haveLobby())
      newStatus = SessionLobbyState.isRoomByQueue ? lobbyStates.IN_LOBBY_HIDDEN : lobbyStates.IN_LOBBY
    this.switchStatus(newStatus)
  }

  function isMemberOperator(member) {
    return ("public" in member) && ("operator" in member.public) && member.public.operator
  }

  function invitePlayer(uid) {
    if (SessionLobbyState.roomId == INVALID_ROOM_ID) { // we are not in room. nothere to invite
      let is_in_room = isInSessionRoom.get()                   // warning disable: -declared-never-used
      let room_id = SessionLobbyState.roomId                          // warning disable: -declared-never-used
      script_net_assert("trying to invite into room without roomId")
      return
    }

    let params = { roomId = SessionLobbyState.roomId, userId = uid, password = SessionLobbyState.password }
    invitePlayerToRoom(params, @(p) checkMatchingError(p, false))
  }

  function kickPlayer(member) {
    if (!("memberId" in member) || !isMeSessionLobbyRoomOwner.get() || !isInSessionRoom.get())
      return

    foreach (_idx, m in SessionLobbyState.members)
      if (m.memberId == member.memberId)
        kickMember({ roomId = SessionLobbyState.roomId, memberId = member.memberId }, function(p) { checkMatchingError(p) })
  }

  function updateRoomAttributes(missionSettings) {
    if (!isMeSessionLobbyRoomOwner.get())
      return

    this.prepareSettings(missionSettings)
  }

  function afterRoomUpdate(params) {
    if (!checkMatchingError(params, false))
      return this.destroyRoom()

    SessionLobbyState.roomUpdated = true
    this.checkAutoStart()
  }

  function isMemberHost(m) {
    return (m.memberId == SessionLobbyState.memberHostId || (("public" in m) && ("host" in m.public) && m.public.host))
  }

  function isMemberSpectator(m) {
    return (("public" in m) && ("spectator" in m.public) && m.public.spectator)
  }

  function getMembersCount(room = null) {
    local res = 0
    foreach (m in this.getRoomMembers(room))
      if (!this.isMemberHost(m))
        res++
    return res
  }

  //we doesn't know full members info outside room atm, but still return the same data format.
  function getMembersCountByTeams(room = null, needReadyOnly = false) {
    let res = {
      total = 0,
      participants = 0,
      spectators = 0,
      [Team.Any] = 0,
      [Team.A] = 0,
      [Team.B] = 0
    }

    let roomMembers = this.getRoomMembers(room)
    if (room && !roomMembers.len()) {
      let teamsCount = room?.session.teams
      foreach (team in g_team.getTeams()) {
        let count = teamsCount?[team.id].players ?? 0
        res[team.code] = count
        res.total += count
      }
      return res
    }

    if (!isInSessionRoom.get() && !room)
      return res

    foreach (m in roomMembers) {
      if (this.isMemberHost(m))
        continue

      if (needReadyOnly)
        if (!this.hasSessionInLobby() && !this.isMemberReady(m))
          continue
        else if (this.hasSessionInLobby() && !this.isMemberInSession(m))
          continue

      res.total++
      if (this.isMemberSpectator(m))
        res.spectators++
      else
        res.participants++
      if (("public" in m) && ("team" in m.public) && (m.public.team.tointeger() in res))
        res[m.public.team.tointeger()]++
    }
    return res
  }

  function getChatRoomId() {
    return g_chat_room_type.MP_LOBBY.getRoomId(SessionLobbyState.roomId)
  }

  function isLobbyRoom(roomId) {
    return g_chat_room_type.MP_LOBBY.checkRoomId(roomId)
  }

  function getChatRoomPassword() {
    return this.getPublicParam("chatPassword", "")
  }

  function isSessionStartedInRoom(room = null) {
    return getTblValue("hasSession", this.getPublicData(room), false)
  }

  function getMaxMembersCount(room = null) {
    if (room)
      return this.getRoomSize(room)
    return getTblValue("players", SessionLobbyState.settings, 0)
  }

  function checkAutoStart() {
    if (isMeSessionLobbyRoomOwner.get() && !SessionLobbyState.isRoomByQueue && !this.haveLobby() && SessionLobbyState.roomUpdated
      && g_squad_manager.getOnlineMembersCount() <= this.getMembersCount())
      this.startSession()
  }

  function startSession() {
    if (sessionLobbyStatus.get() != lobbyStates.IN_ROOM
        && sessionLobbyStatus.get() != lobbyStates.IN_LOBBY
        && sessionLobbyStatus.get() != lobbyStates.IN_LOBBY_HIDDEN)
      return
    if (!this.isMissionReady()) {
      this.uploadUserMission(function() { SessionLobby.startSession() })
      return
    }
    log("start session")

    roomStartSession({ roomId = SessionLobbyState.roomId, cluster = this.getPublicParam("cluster", "EU") },
        function(p) {
          if (!isInSessionRoom.get())
            return
          if (!checkMatchingError(p)) {
            if (!SessionLobby.haveLobby())
              SessionLobby.destroyRoom()
            else if (isInMenu())
              SessionLobby.returnStatusToRoom()
            return
          }
          SessionLobby.switchStatus(lobbyStates.JOINING_SESSION)
        })
    this.switchStatus(lobbyStates.START_SESSION)
  }

  function hostCb(res) {
    if ((type(res) == "table") && ("errCode" in res)) {
      local errorCode;
      if (res.errCode == 0) {
        if (get_game_mode() == GM_DOMINATION)
          errorCode = NET_SERVER_LOST
        else
          errorCode = NET_SERVER_QUIT_FROM_GAME
      }
      else
        errorCode = res.errCode

      needCheckReconnect = true

      if (isInSessionRoom.get())
        if (this.haveLobby())
          this.returnStatusToRoom()
        else
          this.leaveRoom()

      ::error_message_box("yn1/connect_error", errorCode,
        [["ok", @() ::destroy_session_scripted("on error message from host") ]],
        "ok",
        { saved = true })
    }
    //else
    //  switchStatus(lobbyStates.JOINING_SESSION)
  }

  function onMemberJoin(params) {
    if (this.isMemberHost(params))
      return this.updateMemberHostParams(params)

    foreach (m in SessionLobbyState.members)
      if (m.memberId == params.memberId) {
        this.onMemberInfoUpdate(params)
        return
      }
    SessionLobbyState.members.append(params)
    broadcastEvent("LobbyMembersChanged")
    this.checkAutoStart()
  }

  function onMemberLeave(params, kicked = false) {
    if (this.isMemberHost(params))
      return this.updateMemberHostParams(null)

    foreach (idx, m in SessionLobbyState.members)
      if (params.memberId == m.memberId) {
        SessionLobbyState.members.remove(idx)
        if (isMyUserId(m.userId)) {
          this.afterLeaveRoom({})
          if (kicked) {
            if (!isInMenu()) {
              quit_to_debriefing()
              interrupt_multiplayer(true)
              in_flight_menu(false)
            }
            scene_msg_box("you_kicked_out_of_battle", null, loc("matching/msg_kicked"),
                            [["ok", function () {}]], "ok",
                            { saved = true })
          }
        }
        broadcastEvent("LobbyMembersChanged")
        break
      }
  }

  //only with full room info
  function getRoomMembers(room = null) {
    if (!room)
      return SessionLobbyState.members
    return getTblValue("members", room, [])
  }

  function getRoomMembersCnt(room) {
    return getTblValue("membersCnt", room, 0)
  }

  function getRoomSize(room) {
    return getTblValue("players", getTblValue("public", room), getTblValue("size", room, 0))
  }

  function getRoomCreatorUid(room) {
    return getTblValue("creator", getTblValue("public", room))
  }

  function getRoomsInfoTbl(roomsList) {
    let res = []
    foreach (room in roomsList) {
      let public = room?.public
      let misData = public?.mission ?? {}
      let item = {
        hasPassword = public?.hasPassword ?? false
        numPlayers = this.getRoomMembersCnt(room)
        numPlayersTotal = this.getRoomSize(room)
      }
      if ("roomName" in public)
        item.mission <- public.roomName
      else if (this.isUrlMission(public)) {
        let url = this.getMissionUrl(public)
        let urlMission =  g_url_missions.findMissionByUrl(url)
        let missionName = urlMission ? urlMission.name : url
        item.mission <- missionName
      }
      else
        item.mission <- this.getMissionNameLoc(public)
      if ("creator" in public)
        item.name <- getPlayerName(public?.creator ?? "")
      if ("difficulty" in misData)
        item.difficultyStr <- loc($"options/{misData.difficulty}")
      res.append(item)
    }
    return res
  }

  function isRoomHavePassword(_room) {
    return false
  }

  function getMembersReadyStatus() {
    let res = {
      readyToStart = true
      ableToStart = false //can be not full ready, but able to start.
      haveNotReady = false
      statusText = loc("multiplayer/readyToGo")
    }

    let teamsCount = {
      [Team.Any] = 0,
      [Team.A] = 0,
      [Team.B] = 0
    }

    foreach (_idx, member in SessionLobbyState.members) {
      let ready = this.isMemberReady(member)
      let spectator = this.getMemberPublicParam(member, "spectator")
      let team = this.getMemberPublicParam(member, "team").tointeger()
      res.haveNotReady = res.haveNotReady || (!ready && !spectator)
      res.ableToStart = res.ableToStart || !spectator
      if (ready && !spectator) {
        if (team in teamsCount)
          teamsCount[team]++
        else
          teamsCount[Team.Any]++
      }
    }

    res.readyToStart = !res.haveNotReady
    if (res.haveNotReady)
      res.statusText = loc("multiplayer/not_all_ready")

    let gt = this.getGameType()
    let checkTeams = is_mode_with_teams(gt)
    if (!checkTeams)
      return res

    let haveBots = this.getMissionParam("isBotsAllowed", false)
    let maxInTeam = (0.5 * this.getMaxMembersCount() + 0.5).tointeger()

    if ((!haveBots && (abs(teamsCount[Team.A] - teamsCount[Team.B]) - teamsCount[Team.Any] > 1))
        || teamsCount[Team.A] > maxInTeam || teamsCount[Team.B] > maxInTeam) {
      res.readyToStart = false
      res.statusText = loc("multiplayer/nonBalancedGame")
    }

    let areAllowedEmptyTeams = this.getMissionParam("allowEmptyTeams", false)
    if (!res.ableToStart || (!haveBots && !areAllowedEmptyTeams)) {
      let minInTeam = 1
      let teamAEnough = (teamsCount[Team.A] + teamsCount[Team.Any]) >= minInTeam
      let teamBEnough = (teamsCount[Team.B] + teamsCount[Team.Any]) >= minInTeam
      let teamsTotalEnough = teamsCount[Team.A] + teamsCount[Team.B] + teamsCount[Team.Any] >= minInTeam * 2
      if (!teamAEnough || !teamBEnough || !teamsTotalEnough) {
        res.readyToStart = false
        res.ableToStart = false
        res.statusText = loc(res.haveNotReady ? "multiplayer/notEnoughReadyPlayers" : "multiplayer/notEnoughPlayers")
      }
    }

    return res
  }

  function canInvitePlayer(uid) {
    return isInSessionRoom.get() && !isMyUserId(uid) && this.haveLobby() && !this.isPlayerInMyRoom(uid)
  }

  function isPlayerInMyRoom(uid) {
    let roomMembers = this.getRoomMembers()
    foreach (member in roomMembers)
      if (member.userId == uid.tointeger())
        return true

    return false
  }

  function needAutoInviteSquad() {
    return isInSessionRoom.get() && (isMeSessionLobbyRoomOwner.get() || (this.haveLobby() && !SessionLobbyState.isRoomByQueue))
  }

  function checkSquadAutoInvite() {
    if (!g_squad_manager.isSquadLeader() || !this.needAutoInviteSquad())
      return

    let sMembers = g_squad_manager.getMembers()
    foreach (uid, member in sMembers)
      if (member.online
          && member.isReady
          && !member.isMe()
          && !u.search(SessionLobbyState.members, @(m) m.userId == uid)) {
        this.invitePlayer(uid)
      }
  }

  onEventSquadStatusChanged = @(_p) this.checkSquadAutoInvite()

  function getValueSettings(value) {
    if (value != "" && (value in SessionLobbyState.settings))
      return SessionLobbyState.settings[value]
    return null
  }

  function getMemberPlayerInfo(uid) {
    return SessionLobbyState.playersInfo?[uid.tointeger()]
  }

  function getPlayersInfo() {
    return SessionLobbyState.playersInfo
  }

  function isMemberInMySquadByName(name) {
    if (!isInSessionRoom.get())
      return false

    let myInfo = this.getMemberPlayerInfo(userIdInt64.value)
    if (myInfo != null && (myInfo.squad == INVALID_SQUAD_ID || myInfo.name == name))
      return false

    let memberInfo = playersInfoByNames?[name] ?? playersInfoByNames?[getRealName(name)]

    if (memberInfo == null || myInfo == null)
      return false

    return memberInfo.team == myInfo.team && memberInfo.squad == myInfo.squad
  }

  function isMemberInMySquadById(userId) {
    if (userId == null || userId == userIdInt64.value)
      return false
    if (!isInSessionRoom.get())
      return false

    let myInfo = this.getMemberPlayerInfo(userIdInt64.value)
    if (myInfo == null || myInfo.squad == INVALID_SQUAD_ID)
      return false

    let memberInfo = this.getMemberPlayerInfo(userId)

    if (memberInfo == null)
      return false

    return memberInfo.team == myInfo.team && memberInfo.squad == myInfo.squad
  }

  function isEqualSquadId(squadId1, squadId2) {
    return squadId1 != INVALID_SQUAD_ID && squadId1 == squadId2
  }

  function getBattleRatingParamByPlayerInfo(member, esUnitTypeFilter = null) {
    let craftsInfo = member?.crafts_info
    if (craftsInfo == null)
      return null
    let difficulty = isInFlight() ? get_mission_difficulty_int() : getCurrentShopDifficulty().diffCode
    let units = []
    foreach (unitInfo in craftsInfo) {
      let unitName = unitInfo.name
      let unit = getAircraftByName(unitName)
      if (esUnitTypeFilter != null && esUnitTypeFilter != unit.esUnitType)
        continue

      units.append({
        rating = unit?.getBattleRating(difficulty) ?? 0
        name = loc($"{unitName}_shop")
        rankUnused = unitInfo?.rankUnused ?? false
      })
    }
    units.sort(@(a, b) a.rankUnused <=> b.rankUnused || b.rating <=> a.rating)
    let squad = member?.squad ?? INVALID_SQUAD_ID
    return { rank = member.mrank, squad = squad, units = units }
  }

  /**
   * Returns true if unit available for spawn is player's own unit with own crew.
   * Returns false for non player's (random, etc.) units available for spawn.
   */
  function isUsedPlayersOwnUnit(member, unitId) {
    return u.search(member?.crafts_info ?? [], @(ci) ci.name == unitId) != null
  }

  /**
   * Returns null if all countries available.
   */
  function getCountriesByTeamIndex(teamIndex) {
    let event = this.getRoomEvent()
    if (!event)
      return null
    return events.getCountries(events.getTeamData(event, teamIndex))
  }

  function getMyCurUnit() {
    return getCurSlotbarUnit()
  }

  function getTeamToCheckUnits() {
    return SessionLobbyState.team == Team.B ? Team.B : Team.A
  }

  function getTeamDataToCheckUnits() {
    return this.getTeamData(this.getTeamToCheckUnits())
  }

  /**
   * Returns table with two keys: checkAllowed, checkForbidden.
   * Takes in account current selected team.
   */
  function isUnitAllowed(unit) {
    let roomSpecialRules = this.getRoomSpecialRules()
    if (roomSpecialRules && !events.isUnitMatchesRule(unit, roomSpecialRules, true, this.getCurRoomEdiff()))
      return false

    let teamData = this.getTeamDataToCheckUnits()
    return !teamData || events.isUnitAllowedByTeamData(teamData, unit.name, this.getCurRoomEdiff())
  }

  function hasUnitRequirements() {
    return events.hasUnitRequirements(this.getTeamDataToCheckUnits())
  }

  function isUnitRequired(unit) {
    let teamData = this.getTeamDataToCheckUnits()
    if (!teamData)
      return false

    return events.isUnitMatchesRule(unit.name,
      events.getRequiredCrafts(teamData), true, this.getCurRoomEdiff())
  }

  /**
   * Returns table with two keys: checkAllowed, checkForbidden.
   * Takes in account current selected team.
   * @param countryName Applied to units in all countries if not specified.
   * @param team Optional parameter to override current selected team.
   */
  function checkUnitsInSlotbar(countryName, teamToCheck = null) {
    let res = {
      isAvailable = true
      reasonText = ""
    }

    if (teamToCheck == null)
      teamToCheck = SessionLobbyState.team
    local teamsToCheck
    if (teamToCheck == Team.Any)
      teamsToCheck = [Team.A, Team.B]
    else if (teamToCheck == Team.none)
      teamsToCheck = []
    else
      teamsToCheck = [teamToCheck]

    local hasTeamData = false
    local hasUnitsInSlotbar = false
    local hasAnyAvailable = false
    local isCurUnitAvailable = false
    let hasRespawns = this.getMaxRespawns() != 1
    let ediff = this.getCurRoomEdiff()
    let curUnit = this.getMyCurUnit()
    let crews = getCrewsListByCountry(countryName)

    foreach (team in teamsToCheck) {
      let teamName = events.getTeamName(team)
      let teamData = getTblValue(teamName, this.getSessionInfo(), null)
      if (teamData == null)
        continue

      hasTeamData = true
      foreach (crew in crews) {
        let unit = getCrewUnit(crew)
        hasUnitsInSlotbar = hasUnitsInSlotbar || unit != null
        if (!unit || !events.isUnitAllowedByTeamData(teamData, unit.name, ediff))
          continue

        hasAnyAvailable = true
        if (unit == curUnit)
          isCurUnitAvailable = true
      }
    }

    if (hasTeamData) { //allow all when no team data
      if (!hasUnitsInSlotbar)
        res.reasonText = loc("events/empty_slotbar")
      else if (!hasRespawns && !isCurUnitAvailable)
        res.reasonText = loc("events/selected_craft_is_not_allowed")
      else if (!hasAnyAvailable)
        res.reasonText = loc("events/no_allowed_crafts")
      res.isAvailable = res.reasonText == ""
    }

    return res
  }

  /**
   * Returns random team but prefers one with valid units.
   */
  function getRandomTeam() {
    let curCountry = SessionLobbyState.countryData ? SessionLobbyState.countryData.country : null
    let teams = []
    let allTeams = events.getSidesList()
    foreach (team in allTeams) {
      let checkTeamResult = this.checkUnitsInSlotbar(curCountry, team)
      if (checkTeamResult.isAvailable)
        teams.append(team)
    }
    if (teams.len() == 0)
      teams.extend(allTeams)
    if (teams.len() == 1)
      return teams[0]
    let randomIndex = floor(teams.len() * frnd())
    return teams[randomIndex]
  }

  function getRankCalcMode() {
    let event = this.getRoomEvent()
    return getEventRankCalcMode(event)
  }

  function getMGameMode(room = null, isCustomGameModeAllowed = true) {
    let mGameModeId = this.getMGameModeId(room)
    if (mGameModeId == null)
      return null

    if (isCustomGameModeAllowed && (CUSTOM_GAMEMODE_KEY in room))
      return room._customGameMode

    let mGameMode = getModeById(mGameModeId)
    if (isCustomGameModeAllowed && room && mGameMode && events.isCustomGameMode(mGameMode)) {
      let customGameMode = clone mGameMode
      foreach (team in g_team.getTeams())
        customGameMode[team.name] <- this.getTeamData(team.code, room)
      customGameMode.isSymmetric <- false
      room[CUSTOM_GAMEMODE_KEY] <- customGameMode
      return customGameMode
    }
    return mGameMode
  }

  function getRoomEvent(room = null) {
    return events.getEvent(this.getPublicData(room)?.game_mode_name)
  }

  function getMaxDisbalance() {
    return getTblValue("maxLobbyDisbalance", this.getMGameMode(), global_max_players_versus)
  }

  function onEventMatchingDisconnect(_p) {
    this.leaveRoom()
  }

  function onEventMatchingConnect(_p) {
    this.leaveRoom()
  }

  function onEventLoadingStateChange(_p) {
    if (handlersManager.isInLoading)
      return

    if (isInFlight())
      this.switchStatusChecked(
        [lobbyStates.IN_ROOM, lobbyStates.IN_LOBBY, lobbyStates.IN_LOBBY_HIDDEN,
         lobbyStates.JOINING_SESSION],
        lobbyStates.IN_SESSION
      )
    else
      this.switchStatusChecked(
        [lobbyStates.IN_SESSION, lobbyStates.JOINING_SESSION],
        lobbyStates.IN_DEBRIEFING
      )
  }

  function getRoomActiveTimers() {
    let res = []
    if (!isInSessionRoom.get())
      return res

    let curTime = ::get_matching_server_time()
    foreach (timerId, cfg in this.roomTimers) {
      let tgtTime = this.getPublicParam(cfg.publicKey, -1)
      if (tgtTime == -1 || !is_numeric(tgtTime) || tgtTime < curTime)
        continue

      let timeLeft = tgtTime - curTime
      res.append({
        id = timerId
        timeLeft = timeLeft
        text = colorize(cfg.color, cfg.getLocText(SessionLobbyState.settings, { time = time.secondsToString(timeLeft, true, true) }))
      })
    }
    return res
  }

  function hasSessionInLobby() {
    return isInSessionLobbyEventRoom.get()
  }

  function canJoinSession() {
    if (this.hasSessionInLobby())
      return !SessionLobbyState.isLeavingLobbySession
    return isRoomInSession.get()
  }

  function tryJoinSession(needLeaveRoomOnError = false) {
     if (!this.canJoinSession())
       return false

     if (this.hasSessionInLobby()) {
       this.joinEventSession(needLeaveRoomOnError)
       return true
     }
     if (isRoomInSession.get()) {
       this.setReady(true)
       return true
     }
     return false
  }

  function joinEventSession(needLeaveRoomOnError = false, params = null) {
    matchingApiFunc("mrooms.join_session",
      function(params_) {
        if (!checkMatchingError(params_) && needLeaveRoomOnError)
          this.leaveRoom()
      }.bindenv(this),
      params
    )
  }

  function leaveEventSessionWithRetry() {
    SessionLobbyState.isLeavingLobbySession = true
    matchingApiFunc("mrooms.leave_session",
      function(params) {
        // there is a some lag between actual disconnect from host and disconnect detection
        // just try to leave until host says that player is not in session anymore
        if (getTblValue("error_id", params) == "MATCH.PLAYER_IN_SESSION")
          ::g_delayed_actions.add(this.leaveEventSessionWithRetry.bindenv(this), 1000)
        else {
          SessionLobbyState.isLeavingLobbySession = false
          broadcastEvent("LobbyStatusChange")
        }
      }.bindenv(this))
  }

  function onEventUnitRepaired(_p) {
    this.checkUpdateMatchingSlots()
  }

  function onEventSlotbarUnitChanged(_p) {
    this.checkUpdateMatchingSlots()
  }

}

::SessionLobby <- SessionLobby

eventbus_subscribe("notify_session_start", function notify_session_start(...) {
  let sessionId = get_mp_session_id_str()
  if (sessionId != "")
    set_last_session_debug_info($"sid:{sessionId}")

  log("notify_session_start")
  sendBqEvent("CLIENT_BATTLE_2", "joining_session", {
    gm = get_game_mode()
    sessionId = sessionId
    missionsComplete = getMissionsComplete()
  })
  SessionLobby.switchStatus(lobbyStates.JOINING_SESSION)
})

function rpcJoinBattle(params) {
  if (!is_online_available())
    return "client not ready"
  let battleId = params.battleId
  if (type(battleId) != "string")
    return "bad battleId type"
  if (g_squad_manager.getSquadSize() > 1)
    return "player is in squad"
  if (isInSessionRoom.get())
    return "already in room"
  if (isInFlight())
    return "already in session"
  if (!showMsgboxIfEacInactive({ enableEAC = true }))
    return "EAC is not active"
  if (!showMsgboxIfSoundModsNotAllowed({ allowSoundMods = false }))
    return "sound mods not allowed"

  checkShowMultiplayerAasWarningMsg(function() {
    log($"join to battle with id {battleId}")
    SessionLobby.joinBattle(battleId)
  })
  return "ok"
}

web_rpc.register_handler("join_battle", rpcJoinBattle)
subscribe_handler(SessionLobby, g_listener_priority.DEFAULT_HANDLER)

matchingRpcSubscribe("match.notify_wait_for_session_join",
  @(_) SessionLobby.setWaitForQueueRoom(true))
matchingRpcSubscribe("match.notify_join_session_aborted",
  @(_) SessionLobby.leaveWaitForQueueRoom())

ecs.register_es("on_connected_to_server_es", {
  [EventOnConnectedToServer] = function() {
    if (MatchingRoomExtraParams == null)
      return
    let routeEvaluationChance = SessionLobby.getRoomEvent()?.routeEvaluationChance ?? 0.0
    let ddosSimulationChance = SessionLobby.getRoomEvent()?.ddosSimulationChance ?? 0.0
    let ddosSimulationAddRtt = SessionLobby.getRoomEvent()?.ddosSimulationAddRtt ?? 0
    ecs.g_entity_mgr.broadcastEvent(MatchingRoomExtraParams({
        routeEvaluationChance = routeEvaluationChance,
        ddosSimulationChance = ddosSimulationChance,
        ddosSimulationAddRtt = ddosSimulationAddRtt,
    }));
  },
})

eventbus_subscribe("on_sign_out", function(...) {
 if (!isInSessionRoom.get())
   return
 SessionLobby.leaveRoom()
})

eventbus_subscribe("on_connection_failed", function on_connection_failed(evt) {
  let text = evt.reason
  if (!isInSessionRoom.get())
    return
  ::destroy_session_scripted("on_connection_failed")
  SessionLobby.leaveRoom()
  showInfoMsgBox(text, "on_connection_failed")
})

return SessionLobby

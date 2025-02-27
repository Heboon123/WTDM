from "%scripts/dagui_library.nut" import *
from "%scripts/controls/controlsConsts.nut" import AIR_MOUSE_USAGE

let globalEnv = require("globalEnv")
let { subscribe_handler } = require("%sqStdLibs/helpers/subscriptions.nut")
let { OPTIONS_MODE_GAMEPLAY, USEROPT_HELPERS_MODE, USEROPT_MOUSE_USAGE,
  USEROPT_MOUSE_USAGE_NO_AIM, USEROPT_INSTRUCTOR_ENABLED, USEROPT_AUTOTRIM
} = require("%scripts/options/optionsExtNames.nut")
let { isLoggedIn } = require("%scripts/login/loginStates.nut")

let g_aircraft_helpers = {
  /* PRIVATE */
  // Shorter options names
  controlHelpersOptions = {
    helpersMode       = USEROPT_HELPERS_MODE
    mouseUsage        = USEROPT_MOUSE_USAGE
    mouseUsageNoAim   = USEROPT_MOUSE_USAGE_NO_AIM
    instructorEnabled = USEROPT_INSTRUCTOR_ENABLED
    autotrim          = USEROPT_AUTOTRIM
  }

  // Private flags
  isInitialized = false
  isHelpersChangePerformed = false


  /* PUBLIC */
  // Set option and call change handler if changed
  function setOptionValue(optionId, newValue) {
    let oldValue = ::get_gui_option_in_mode(optionId, OPTIONS_MODE_GAMEPLAY)
    if (oldValue == newValue)
      return
    ::set_gui_option_in_mode(optionId, newValue, OPTIONS_MODE_GAMEPLAY)
    this.onHelpersChanged(optionId)
  }


  // Init options if not and get option
  function getOptionValue(optionId) {
    if (!this.isInitialized)
      this.onHelpersChanged()
    return ::get_gui_option_in_mode(optionId, OPTIONS_MODE_GAMEPLAY)
  }


  // Helper options change handler
  function onHelpersChanged(forcedByOption = null, forceUpdateFromPreset = false) {
    // Do not continue if not logged in or if recursion call happend
    if (!isLoggedIn.get() || this.isHelpersChangePerformed)
      return
    this.isHelpersChangePerformed = true

    // Get current options values
    let options = {}
    if (!forceUpdateFromPreset)
      foreach (name, optionId in this.controlHelpersOptions)
        options[name] <- ::get_gui_option_in_mode(
          optionId, OPTIONS_MODE_GAMEPLAY)
    else
      foreach (name, _optionId in this.controlHelpersOptions)
        options[name] <- null
    let prevOptions = clone options

    // Synchronize mouseUsage and mouseUsageNoAim
    if (options.mouseUsage != AIR_MOUSE_USAGE.AIM) {
      if (forcedByOption == USEROPT_MOUSE_USAGE_NO_AIM)
        options.mouseUsage = options.mouseUsageNoAim
      else
        options.mouseUsageNoAim = options.mouseUsage
    }

    // Determine target helpers mode
    if (forcedByOption == USEROPT_MOUSE_USAGE) {
      if (options.mouseUsage == AIR_MOUSE_USAGE.AIM)
        options.helpersMode = globalEnv.EM_MOUSE_AIM
      else
        options.helpersMode = max(options.helpersMode, globalEnv.EM_INSTRUCTOR)
      }
    else if (USEROPT_INSTRUCTOR_ENABLED == forcedByOption) {
      if (options.instructorEnabled)
        options.helpersMode = min(options.helpersMode, globalEnv.EM_INSTRUCTOR)
      else
        options.helpersMode = max(options.helpersMode, globalEnv.EM_REALISTIC)
    }
    else if (USEROPT_AUTOTRIM == forcedByOption) {
      if (options.autotrim)
        options.helpersMode = min(options.helpersMode, globalEnv.EM_REALISTIC)
      else
        options.helpersMode = globalEnv.EM_FULL_REAL
    }

    else if (options.helpersMode == null) {
      // For new profiles or profiles without helpersMode
      if (options.mouseUsage == AIR_MOUSE_USAGE.AIM)
        options.helpersMode = globalEnv.EM_MOUSE_AIM
      else if (options.autotrim == false)
        options.helpersMode = globalEnv.EM_FULL_REAL
      else if (options.instructorEnabled == false)
        options.helpersMode = globalEnv.EM_REALISTIC
      else
        options.helpersMode = is_platform_android ?
          globalEnv.EM_INSTRUCTOR : globalEnv.EM_MOUSE_AIM
    }


    // Enable helpers before set according to helpers mode
    options.instructorEnabled = true
    options.autotrim = true

    // Set helpers options according to helpers mode
    let helpersMode = options.helpersMode
    if ( helpersMode == globalEnv.EM_FULL_REAL) {
      options.instructorEnabled = false
      options.autotrim = false
      if (options.mouseUsage == AIR_MOUSE_USAGE.AIM)
        options.mouseUsage = options.mouseUsageNoAim
    }
    else if (helpersMode == globalEnv.EM_REALISTIC) {
      options.instructorEnabled = false
      if (options.mouseUsage == AIR_MOUSE_USAGE.AIM)
        options.mouseUsage = options.mouseUsageNoAim
    }
    else if (helpersMode == globalEnv.EM_INSTRUCTOR) {
      if (options.mouseUsage == AIR_MOUSE_USAGE.AIM)
        options.mouseUsage = options.mouseUsageNoAim
    }
    else if ( helpersMode == globalEnv.EM_MOUSE_AIM) {
      options.mouseUsage = AIR_MOUSE_USAGE.AIM
    }

    // Load current mouse usage from preset if it undefined
    if (options.mouseUsageNoAim == null) {
      options.mouseUsageNoAim = this.getPresetMouseUsage()
      if (options.mouseUsage == null)
        options.mouseUsage = options.mouseUsageNoAim
    }

    // Set changed gui options
    foreach (name, optionId in this.controlHelpersOptions)
      if (options[name] != prevOptions[name])
        ::set_gui_option_in_mode(optionId,
          options[name], OPTIONS_MODE_GAMEPLAY)

    this.updatePresetMouseUsage()
    this.isHelpersChangePerformed = false
    this.isInitialized = true
  }


  // Get mouse usage from axes params
  function getPresetMouseUsage() {
    // Load current mouse usage from used preset
    let curPreset = ::g_controls_manager.getCurPreset()

    if (getTblValue("mouseJoystick", curPreset.params))
      return AIR_MOUSE_USAGE.JOYSTICK
    else if (getTblValue("mouseAxisId", curPreset.getAxis("elevator")) == 1)
      return AIR_MOUSE_USAGE.RELATIVE
    else if (getTblValue("mouseAxisId", curPreset.getAxis("camy")) == 1)
      return AIR_MOUSE_USAGE.VIEW
    else
      return AIR_MOUSE_USAGE.NOT_USED
  }


  // Update mouse usage in axes params according to helpers options
  function updatePresetMouseUsage() {
    let curPreset = ::g_controls_manager.getCurPreset()
    let mouseUsageNoAim = ::get_gui_option_in_mode(
      USEROPT_MOUSE_USAGE_NO_AIM, OPTIONS_MODE_GAMEPLAY)

    // Do not update mouse usage if it not chagned
    if (this.getPresetMouseUsage() == mouseUsageNoAim)
      return

    // Update mouseJoystick param
    curPreset.params.mouseJoystick <-
      mouseUsageNoAim == AIR_MOUSE_USAGE.JOYSTICK

    // Clear mouse axes
    foreach (_axisName, axis in curPreset.axes)
      if ("mouseAxisId" in axis &&
        (axis.mouseAxisId == 0 || axis.mouseAxisId == 1))
        axis.mouseAxisId <- -1

    // Set new mouse axes
    if (mouseUsageNoAim == AIR_MOUSE_USAGE.JOYSTICK ||
      mouseUsageNoAim == AIR_MOUSE_USAGE.RELATIVE) {
      curPreset.getAxis("ailerons").mouseAxisId <- 0
      curPreset.getAxis("elevator").mouseAxisId <- 1
    }
    else if (mouseUsageNoAim == AIR_MOUSE_USAGE.VIEW) {
      curPreset.getAxis("camx").mouseAxisId <- 0
      curPreset.getAxis("camy").mouseAxisId <- 1
    }

    // Commit changes if committing not performed now
    ::g_controls_manager.commitControls()
  }

  // Event handlers
  function onEventLoginComplete(_params) {
    this.onHelpersChanged()
  }

  function onEventSignOut(_params) {
    this.isInitialized = false
  }

  function onEventBeforeControlsCommit(_params) {
    this.onHelpersChanged()
  }

  function onEventControlsReloaded(_params) {
    this.onHelpersChanged(null, true)
  }
}

subscribe_handler(g_aircraft_helpers)

return {
  g_aircraft_helpers
}
from "%rGui/globals/ui_library.nut" import *

let extWatched = require("globals/extWatched.nut")

let gamepadCursorControl = extWatched("gamepadCursorControl", false)
let haveXinputDevice = extWatched("haveXinputDevice", false) 
let showConsoleButtons = extWatched("showConsoleButtons", false)
let cursorVisible = extWatched("cursorVisible", true)

let enabledGamepadCursorControlInScene = keepref(Computed(
  @() gamepadCursorControl.value && haveXinputDevice.value && cursorVisible.value))

let enabledKBCursorControlInScene = keepref(Computed(@() cursorVisible.value))

function updateSceneGamepadCursorControl(value) {
  log($"ctrlsState: updateSceneGamepadCursorControl: {value} ({gamepadCursorControl.value}, {haveXinputDevice.value}, {cursorVisible.value})")
  gui_scene.setConfigProps({ gamepadCursorControl = value })
}
updateSceneGamepadCursorControl(enabledGamepadCursorControlInScene.value)

function updateSceneKBCursorControl(value) {
  gui_scene.setConfigProps({ kbCursorControl = value })
}
updateSceneKBCursorControl(true)

enabledGamepadCursorControlInScene.subscribe(updateSceneGamepadCursorControl)
enabledKBCursorControlInScene.subscribe(updateSceneKBCursorControl)

return {
  showConsoleButtons
  cursorVisible
}

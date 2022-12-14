from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let config = ::get_cur_gui_scene()?.getSceneConfig()
if (config)
{
  config.gamepadCursorSpeed = 2.0
  config.gamepadCursorNonLin = 2.5
  config.gamepadCursorDeadZone = 0.15

  config.gamepadCursorHoverMaxTime = 0.5
  config.gamepadCursorHoverMinMul = 0.5
  config.gamepadCursorHoverMaxMul = 0.8
}

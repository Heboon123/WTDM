from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

let { is_stereo_mode } = require_native("vr")

let needUseHangarDof = @() is_stereo_mode()

return {
  needUseHangarDof
}
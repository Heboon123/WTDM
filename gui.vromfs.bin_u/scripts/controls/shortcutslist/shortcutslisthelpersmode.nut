from "%scripts/dagui_library.nut" import *
//checked for explicitness
#no-root-fallback
#explicit-this

return [{
  id = "helpers_mode"
  type = CONTROL_TYPE.LISTBOX
  optionType = ::USEROPT_HELPERS_MODE
  onChangeValue = "onOptionsFilter"
  isFilterObj = true
}]
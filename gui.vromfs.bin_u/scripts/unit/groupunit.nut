from "%scripts/dagui_library.nut" import *

let { getTooltipType } = require("%scripts/utils/genericTooltipTypes.nut")
let { buildUnitSlot } = require("%scripts/slotbar/slotbarView.nut")
let { image_for_air } = require("%scripts/unit/unitInfo.nut")

function getGroupUnitMarkUp(name, unit, group, overrideParams = {}) {
  let params = {
    status = "owned"
    inactive = true
    isLocalState = false
    needMultiLineName = true
    tooltipParams = { showLocalState = false }
    tooltipId = getTooltipType("UNIT_GROUP").getTooltipId(group)
  }.__update(overrideParams)

  if (group != null)
    unit = {
      name = name
      nameLoc = overrideParams?.nameLoc ?? ""
      image = image_for_air(unit)
      isFakeUnit = true
    }

  return buildUnitSlot(name, unit, params)
}


return {
  getGroupUnitMarkUp
}
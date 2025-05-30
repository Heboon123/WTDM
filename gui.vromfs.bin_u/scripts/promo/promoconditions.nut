from "%scripts/dagui_library.nut" import *
from "%scripts/clans/clanState.nut" import is_in_clan

let { split_by_chars } = require("string")
let visibleConditionsList = {
  isInClan = @() is_in_clan()
  isNotInClan = @() !is_in_clan()
}

function isVisibleByConditions(blk) {
  let visibleConditions = blk?.visibleConditions
  if (visibleConditions == null)
    return true

  foreach (name in split_by_chars(visibleConditions, "; "))
    if (!(visibleConditionsList?[name]?() ?? true))
      return false

  return true
}

return {
  isVisibleByConditions
}
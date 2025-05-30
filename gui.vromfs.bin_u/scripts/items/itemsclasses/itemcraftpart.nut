from "%scripts/dagui_library.nut" import *
from "%scripts/items/itemsConsts.nut" import itemType

let ItemExternal = require("%scripts/items/itemsClasses/itemExternal.nut")
let { registerItemClass } = require("%scripts/items/itemsTypeClasses.nut")

let CraftPart = class (ItemExternal) {
  static iType = itemType.CRAFT_PART
  static name = "CraftPart"
  static defaultLocId = "craft_part"
  static typeIcon = "#ui/gameuiskin#item_type_craftpart.svg"

  canConsume            = @() false
  shouldShowAmount      = @(count) count >= 0
  getOpenedBigIcon      = @() ""

  getLocIdsListImpl = @() base.getLocIdsListImpl().__update({
    openingRewardTitle = "mainmenu/itemCreated/title"
  })
}

registerItemClass(CraftPart)

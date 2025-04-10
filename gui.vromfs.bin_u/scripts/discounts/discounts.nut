from "%scripts/dagui_natives.nut" import ps4_get_region, has_entitlement, periodic_task_register, get_entitlements_price_blk, get_entitlement_gold_discount, periodic_task_unregister
from "%scripts/dagui_library.nut" import *

let { g_top_menu_right_side_sections } = require("%scripts/mainmenu/topMenuSectionsConfigs.nut")
let g_listener_priority = require("%scripts/g_listener_priority.nut")
let { format } = require("string")
let { subscribe_handler, broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let { getTimestampFromStringUtc } = require("%scripts/time.nut")
let { targetPlatform, isPlatformPC, isPlatformPS4 } = require("%scripts/clientState/platform.nut")

let { canUseIngameShop, haveDiscount, getShopItemsTable, needEntStoreDiscountIcon
} = require("%scripts/onlineShop/entitlementsShopData.nut")

let { getEntitlementId } = require("%scripts/onlineShop/onlineBundles.nut")
let { getEntitlementConfig } = require("%scripts/onlineShop/entitlements.nut")
let { discountUnitsBundles } = require("%scripts/onlineShop/discountBundles.nut")

let buttonsList = require("%scripts/mainmenu/topMenuButtons.nut").buttonsListWatch
let topMenuOnlineShopId = Computed(@() buttonsList.value?.ONLINE_SHOP.id ?? "")
let { eachBlock } = require("%sqstd/datablock.nut")
let { shopCountriesList } = require("%scripts/shop/shopCountriesList.nut")
let { GUI } = require("%scripts/utils/configs.nut")
let { promoteUnits } = require("%scripts/unit/remainingTimeUnit.nut")
let getAllUnits = require("%scripts/unit/allUnits.nut")
let { get_charserver_time_sec } = require("chard")
let { get_price_blk } = require("blkGetters")
let { isUnitGift } = require("%scripts/unit/unitShopInfo.nut")
let { isCountryAvailable } = require("%scripts/firstChoice/firstChoice.nut")
let { getDiscountByPath } = require("%scripts/discounts/discountUtils.nut")

let platformMapForDiscountFromGuiBlk = {
  pc = isPlatformPC
  ps4_scee = isPlatformPS4 && ps4_get_region() == SCE_REGION_SCEE
  ps4_scea = isPlatformPS4 && ps4_get_region() == SCE_REGION_SCEA
  ps4_scej = isPlatformPS4 && ps4_get_region() == SCE_REGION_SCEJ
}
local updateGiftUnitsDiscountTask = -1

let discountsList = persist("discountsList", @() {})

let g_discount = {

  getDiscountIconId = @(name) $"{name}_discount"
  canBeVisibleOnUnit = @(unit) unit && unit.isVisibleInShop() && !unit.isBought()
  discountsList
  consoleEntitlementUnits = {} 

  function updateOnlineShopDiscounts() {
    this.consoleEntitlementUnits.clear()

    if (!needEntStoreDiscountIcon)
      return

    let isDiscountAvailable = haveDiscount()
    discountsList[topMenuOnlineShopId.value] = isDiscountAvailable

    if (isDiscountAvailable)
      foreach (_label, item in getShopItemsTable()) {
        if (item.haveDiscount()) {
          let entId = getEntitlementId(item.id)
          let config = getEntitlementConfig(entId)
          let unitsList = config?.aircraftGift ?? []
          foreach (unitName in unitsList)
            this.consoleEntitlementUnits[unitName] <- item.getDiscountPercent()
        }
      }

    this.updateDiscountData()
  }

  onEventXboxShopDataUpdated = @(_p) this.updateOnlineShopDiscounts()
  onEventPs4ShopDataUpdated = @(_p) this.updateOnlineShopDiscounts()
  onEventEpicShopDataUpdated = @(_p) this.updateOnlineShopDiscounts()
  onEventEpicShopItemUpdated = @(_p) this.updateOnlineShopDiscounts()

  function updateGiftUnitsDiscountFromGuiBlk(giftUnits) { 
    if (updateGiftUnitsDiscountTask >= 0) {
      periodic_task_unregister(updateGiftUnitsDiscountTask)
      updateGiftUnitsDiscountTask = -1
    }

    let discountsBlk = GUI.get()?.entitlement_units_discount
    if (discountsBlk == null)
      return

    local minUpdateDiscountsTimeSec = null
    for (local i = 0; i < discountsBlk.blockCount(); i++) {
      let discountConfigBlk = discountsBlk.getBlock(i)
      let platforms = (discountConfigBlk?.platform ?? "pc").split(";")
      local isSuitableForCurrentPlatform = false
      foreach (platform in platforms) {
        if (targetPlatform != platform && !(platformMapForDiscountFromGuiBlk?[platform] ?? false))
          continue

        isSuitableForCurrentPlatform = true
        break
      }

      if (!isSuitableForCurrentPlatform)
        continue

      let startTime = getTimestampFromStringUtc(discountConfigBlk.beginDate)
      let endTime = getTimestampFromStringUtc(discountConfigBlk.endDate)
      let currentTime = get_charserver_time_sec()
      if (currentTime >= endTime)
        continue

      if (currentTime < startTime) {
        let updateTimeSec = startTime - currentTime
        minUpdateDiscountsTimeSec = min(minUpdateDiscountsTimeSec ?? updateTimeSec, updateTimeSec)
        continue
      }

      let updateTimeSec = endTime - currentTime
      minUpdateDiscountsTimeSec = min(minUpdateDiscountsTimeSec ?? updateTimeSec, updateTimeSec)
      foreach (unitName, discount in discountConfigBlk)
        if (unitName in giftUnits)
          discountsList.entitlementUnits[unitName] <- discount
    }

    if (minUpdateDiscountsTimeSec != null)
      updateGiftUnitsDiscountTask = periodic_task_register(this,
        @(_dt) this.updateDiscountData(), minUpdateDiscountsTimeSec)
  }

  function clearDiscountsList() {
    foreach (button in buttonsList.value)
      if (button.needDiscountIcon)
        discountsList[button.id] <- false
    discountsList.changeExp <- false
    discountsList.topmenu_research <- false

    discountsList.entitlements <- {}

    discountsList.entitlementUnits <- {}
    discountsList.airList <- {}
  }

}

g_discount.clearDiscountsList()


g_discount.getUnitDiscount <- function getUnitDiscount(unit) {
  if (!this.canBeVisibleOnUnit(unit))
    return 0
  return max(this.getUnitDiscountByName(unit.name),
               this.getEntitlementUnitDiscount(unit.name))
}

g_discount.getGroupDiscount <- function getGroupDiscount(list) {
  local res = 0
  foreach (unit in list)
    res = max(res, this.getUnitDiscount(unit))
  return res
}

g_discount.pushDiscountsUpdateEvent <- function pushDiscountsUpdateEvent() {
  ::update_gamercards()
  broadcastEvent("DiscountsDataUpdated")
}

g_discount.onEventUnitBought <- function onEventUnitBought(p) {
  let unitName = getTblValue("unitName", p)
  if (!unitName)
    return

  if (this.getUnitDiscountByName(unitName) == 0 && this.getEntitlementUnitDiscount(unitName) == 0)
    return

  this.updateDiscountData()
  
  get_gui_scene().performDelayed(this, this.pushDiscountsUpdateEvent)
}

g_discount.updateDiscountData <- function updateDiscountData(isSilentUpdate = false) {
  this.clearDiscountsList()

  let pBlk = get_price_blk()

  let chPath = ["exp_to_gold_rate"]
  chPath.append(shopCountriesList)
  discountsList.changeExp = getDiscountByPath(chPath, pBlk) > 0

  let giftUnits = {}

  foreach (air in getAllUnits())
    if (isCountryAvailable(air.shopCountry)
        && !air.isBought()
        && air.isVisibleInShop()) {
      if (isUnitGift(air)) {
        if (isPlatformPC)
          giftUnits[air.name] <- 0
        continue
      }

      let path = ["aircrafts", air.name]
      let discount = getDiscountByPath(path, pBlk)
      if (discount > 0)
        discountsList.airList[air.name] <- discount
    }

  eachBlock(get_entitlements_price_blk(), @(b, n) this.checkEntitlement(n, b, giftUnits), this)

  this.updateGiftUnitsDiscountFromGuiBlk(giftUnits)  

  if (canUseIngameShop() && needEntStoreDiscountIcon)
    discountsList[topMenuOnlineShopId.value] = haveDiscount()

  discountsList.entitlementUnits.__update(
    this.consoleEntitlementUnits, discountUnitsBundles.get())

  local isShopDiscountVisible = false
  foreach (airName, discount in discountsList.airList)
    if (discount > 0 && this.canBeVisibleOnUnit(getAircraftByName(airName))) {
      isShopDiscountVisible = true
      break
    }
  if (!isShopDiscountVisible)
    foreach (airName, discount in discountsList.entitlementUnits)
      if (discount > 0 && this.canBeVisibleOnUnit(getAircraftByName(airName))) {
        isShopDiscountVisible = true
        break
      }
  discountsList.topmenu_research = isShopDiscountVisible

  if (!isSilentUpdate)
    this.pushDiscountsUpdateEvent()
}

g_discount.checkEntitlement <- function checkEntitlement(entName, entlBlock, giftUnits) {
  let discountItemList = ["premium", "warpoints", "eagles", "campaign", "bonuses"]
  local chapter = entlBlock?.chapter
  if (!isInArray(chapter, discountItemList))
    return

  local discount = get_entitlement_gold_discount(entName)
  let singleDiscount = entlBlock?.singleDiscount && !has_entitlement(entName)
                            ? entlBlock.singleDiscount
                            : 0

  discount = max(discount, singleDiscount)
  if (discount == 0)
    return

  discountsList.entitlements[entName] <- discount

  if (chapter == "campaign" || chapter == "bonuses") {
    if (canUseIngameShop())
      chapter = topMenuOnlineShopId.value
  }

  local chapterVal = true
  if (chapter == topMenuOnlineShopId.value)
    chapterVal = canUseIngameShop() || isPlatformPC
  discountsList[chapter] <- chapterVal

  if (entlBlock?.aircraftGift)
    foreach (unitName in entlBlock % "aircraftGift")
      if (unitName in giftUnits)
        discountsList.entitlementUnits[unitName] <- discount
}

g_discount.generateDiscountInfo <- function generateDiscountInfo(discountsTable, headerLocId = "") {
  local maxDiscount = 0
  let headerText = "".concat(loc(headerLocId == "" ? "discount/notification" : headerLocId), "\n")
  local discountText = ""
  foreach (locId, discount in discountsTable) {
    if (discount <= 0)
      continue

    discountText = "".concat(discountText, loc("discount/list_string", { itemName = loc(locId), discount = discount }), "\n")
    maxDiscount = max(maxDiscount, discount)
  }

  if (discountsTable.len() > 20)
    discountText = format(loc("discount/buy/tooltip"), maxDiscount.tostring())

  if (discountText == "")
    return {}

  discountText = "".concat(headerText, discountText)

  return { maxDiscount = maxDiscount, discountTooltip = discountText }
}

g_discount.updateDiscountNotifications <- function updateDiscountNotifications(scene = null) {
  foreach (name in ["topmenu_research", "changeExp"]) {
    let id = this.getDiscountIconId(name)
    let obj = checkObj(scene) ? scene.findObject(id) : get_cur_gui_scene()[id]
    if (!(obj?.isValid() ?? false))
      continue

    let discount = this.getDiscount(name)
    let hasDiscount = name == "topmenu_research"
      ? discount && !(promoteUnits.value.findvalue(@(d) d.isActive) != null)
      : discount
    obj.show(hasDiscount)
  }

  let section = g_top_menu_right_side_sections.getSectionByName("shop")
  let sectionId = section.getTopMenuButtonDivId()
  let shopObj = checkObj(scene) ? scene.findObject(sectionId) : get_cur_gui_scene()[sectionId]
  if (!checkObj(shopObj))
    return

  let stObj = shopObj.findObject(section.getTopMenuDiscountId())
  if (!checkObj(stObj))
    return

  local haveAnyDiscount = false
  foreach (column in section.buttons) {
    foreach (button in column) {
      if (!button.needDiscountIcon)
        continue

      let id = this.getDiscountIconId(button.id)
      let dObj = shopObj.findObject(id)
      if (!checkObj(dObj))
        continue

      let discountStatus = this.getDiscount(button.id)
      haveAnyDiscount = haveAnyDiscount || discountStatus
      dObj.show(discountStatus)
    }
  }

  stObj.show(haveAnyDiscount)
}

g_discount.getDiscount <- function getDiscount(id, defVal = false) {
  return discountsList?[id] ?? defVal
}

g_discount.getEntitlementDiscount <- function getEntitlementDiscount(id) {
  return discountsList.entitlements?[id] || 0
}

g_discount.getEntitlementUnitDiscount <- function getEntitlementUnitDiscount(unitName) {
  return discountsList.entitlementUnits?[unitName] || 0
}

g_discount.getUnitDiscountByName <- function getUnitDiscountByName(unitName) {
  return discountsList.airList?[unitName] || 0
}

g_discount.haveAnyUnitDiscount <- function haveAnyUnitDiscount() {
  return discountsList.entitlementUnits.len() > 0 || discountsList.airList.len() > 0
}

g_discount.getUnitDiscountList <- function getUnitDiscountList(countryId = null) {
  if (!this.haveAnyUnitDiscount())
    return {}

  let newDiscountsList = {}
  foreach (unit in getAllUnits())
    if (!countryId || unit.shopCountry == countryId) {
      let discount = this.getUnitDiscount(unit)
      if (discount > 0)
        newDiscountsList[$"{unit.name}_shop"] <- discount
    }

  return newDiscountsList
}

function getUnitsDiscounts(countryId = "", armyId = "") {
  if (!g_discount.haveAnyUnitDiscount())
    return []

  let newDiscountsList = []
  foreach (unit in getAllUnits())
    if ((countryId == "" || unit.shopCountry == countryId) && (armyId == "" || unit.unitType.armyId == armyId)) {
      let discount = g_discount.getUnitDiscount(unit)
      if (discount > 0)
        newDiscountsList.append({ unit, discount })
    }

  return newDiscountsList
}

discountUnitsBundles.subscribe(@(_) g_discount.updateDiscountData())

subscribe_handler(g_discount, g_listener_priority.CONFIG_VALIDATION)

::g_discount <- g_discount
return {
  g_discount
  getUnitsDiscounts
}
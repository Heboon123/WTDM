from "%scripts/dagui_natives.nut" import wp_get_cost_gold2, wp_get_cost2, get_spare_aircrafts_count, wp_get_modification_cost, wp_get_weapon_max_count, wp_get_modification_open_cost_gold, shop_is_weapon_purchased, shop_get_spawn_score, wp_get_spare_cost_gold, wp_get_spare_cost, wp_get_modification_max_count, wp_get_modification_cost_gold
from "%scripts/dagui_library.nut" import *
from "%scripts/weaponry/weaponryConsts.nut" import weaponsItem

let { Cost } = require("%scripts/money.nut")
let u = require("%sqStdLibs/helpers/u.nut")
let enums = require("%sqStdLibs/helpers/enums.nut")
let { getWeaponNameText } = require("%scripts/weaponry/weaponryDescription.nut") 
let { getModificationName } = require("%scripts/weaponry/bulletsInfo.nut")
let { getByCurBundle, MAX_SPARE_AMOUNT } = require("%scripts/weaponry/itemInfo.nut")
let { canBuyMod } = require("%scripts/weaponry/modificationInfo.nut")
let { getLastWeapon } = require("%scripts/weaponry/weaponryInfo.nut")
let { shopIsModificationPurchased } = require("chardResearch")
let { getCurMissionRules } = require("%scripts/misCustomRules/missionCustomState.nut")
let { isUnitUsable } = require("%scripts/unit/unitStatus.nut")

::g_weaponry_types <- {
  types = []
  cache = {
    byType = {}
  }

  template = {
    type = weaponsItem.unknown
    isSpendable = false
    isPremium = false

    getLocName = function(_unit, _item, _limitedName = false) { return "" }
    getHeader = @(_unit) ""

    canBuy = function(_unit, _item) { return false }
    getAmount = function(_unit, _item) { return 0 }
    getMaxAmount = function(_unit, _item) { return 0 }

    getUnlockCost = function(_unit, _item) { return Cost() }
    getCost = function(_unit, _item) { return Cost() }
    getScoreCostText = function(_unit, _item) { return "" }

    purchase = function() {}
    canPurchase = function() { return false }
  }
}

::g_weaponry_types._getUnlockCost <- function _getUnlockCost(unit, item) {
  if (item.name == "")
    return Cost()
  return Cost(0, wp_get_modification_open_cost_gold(unit.name, item.name))
}

::g_weaponry_types._getCost <- function _getCost(unit, item) {
  if (item.name == "")
    return Cost()
  return Cost(
    wp_get_modification_cost(unit.name, item.name),
    wp_get_modification_cost_gold(unit.name, item.name)
  )
}

::g_weaponry_types._getAmount <- function _getAmount(unit, item) {
  if (("isDefaultForGroup" in item) && item.isDefaultForGroup >= 0)
    return 1
  return shopIsModificationPurchased(unit.name, item.name)
}

enums.addTypesByGlobalName("g_weaponry_types", {
  UNKNOWN = {}


  WEAPON = {
    type = weaponsItem.weapon
    getLocName = @ (unit, item, _limitedName = false) getWeaponNameText(unit, false, item.name, ",  ")
    getHeader = @(unit) (unit.isAir() || unit.isHelicopter()) ? loc("options/secondary_weapons")
       : loc("options/additional_weapons")
    getCost = function(unit, item) {
      return Cost(
        wp_get_cost2(unit.name, item.name),
        wp_get_cost_gold2(unit.name, item.name)
      )
    }
    getAmount = function(unit, item) { return shop_is_weapon_purchased(unit.name, item.name) }
    getMaxAmount = function(unit, item) { return wp_get_weapon_max_count(unit.name, item.name) }
    canBuy = function(unit, item) { return isUnitUsable(unit) && this.getAmount(unit, item) < this.getMaxAmount(unit, item) }

    getScoreCostText = function(unit, item) {
      let fullCost = shop_get_spawn_score(unit.name, item.name, [])
      if (!fullCost)
        return ""

      let emptyCost = shop_get_spawn_score(unit.name, "", [])
      local weapCost = fullCost - emptyCost
      if (!weapCost)
        return ""

      if (getCurMissionRules().getCurSpawnScore() < fullCost)
        weapCost = colorize("badTextColor", weapCost)
      return loc("shop/spawnScore", { cost = weapCost })
    }
  }


  BULLETS = {
    type = weaponsItem.bullets
    getLocName = @(unit, item, limitedName = false) getModificationName(unit, item.name, limitedName)
    getCost = ::g_weaponry_types._getCost
    getAmount = ::g_weaponry_types._getAmount
    getMaxAmount = function(unit, item) { return wp_get_modification_max_count(unit.name, item.name) }
    canBuy = function(unit, item) { return isUnitUsable(unit) && canBuyMod(unit, item) }
  }


  MODIFICATION = {
    type = weaponsItem.modification
    getLocName = @(unit, item, limitedName = false) getModificationName(unit, item.name, limitedName)
    getUnlockCost = ::g_weaponry_types._getUnlockCost
    getCost = ::g_weaponry_types._getCost
    getAmount = @(unit, item) this.getUnlockCost(unit, item).isZero()
        && this.getCost(unit, item).isZero()
        && (item?.reqExp ?? 0) == 0
        && item?.reqModification == null
      ? 1
      : ::g_weaponry_types._getAmount(unit, item)
    getMaxAmount = function(unit, item) { return wp_get_modification_max_count(unit.name, item.name) }
    canBuy = function(unit, item) { return isUnitUsable(unit) && canBuyMod(unit, item) }

    getScoreCostText = function(unit, item) {
      let fullCost = shop_get_spawn_score(unit.name, getLastWeapon(unit.name), [ item.name ])
      if (!fullCost)
        return ""

      let emptyCost = shop_get_spawn_score(unit.name, getLastWeapon(unit.name), [])
      local bulletCost = fullCost - emptyCost
      if (!bulletCost)
        return ""

      if (getCurMissionRules().getCurSpawnScore() < fullCost)
        bulletCost = colorize("badTextColor", bulletCost)
      return loc("shop/spawnScore", { cost = bulletCost })
    }
  }


  EXPENDABLES = {
    type = weaponsItem.expendables
    getLocName = @(unit, item, limitedName = false) getModificationName(unit, item.name, limitedName)
    getUnlockCost = ::g_weaponry_types._getUnlockCost
    getCost = ::g_weaponry_types._getCost
    getAmount = ::g_weaponry_types._getAmount
    getMaxAmount = function(unit, item) { return wp_get_modification_max_count(unit.name, item.name) }
    canBuy = function(unit, item) { return isUnitUsable(unit) && canBuyMod(unit, item) }
  }


  SPARE = {
    type = weaponsItem.spare
    getLocName = function(_unit, item, ...) { return loc($"spare/{item.name}") }
    getCost = function(unit, ...) { return Cost(
      wp_get_spare_cost(unit.name),
      wp_get_spare_cost_gold(unit.name)
    ) }
    getAmount = function(unit, ...) { return get_spare_aircrafts_count(unit.name) }
    getMaxAmount = function(...) { return MAX_SPARE_AMOUNT }
    canBuy = function(unit, item) { return isUnitUsable(unit) && this.getAmount(unit, item) < this.getMaxAmount(unit, item) }
  }




  PRIMARYWEAPON = {
    type = weaponsItem.primaryWeapon
    getLocName = function(unit, item, _limitedName = false) { return getWeaponNameText(unit, true, item.name, " ") }
    getCost = ::g_weaponry_types._getCost
    getAmount = function(unit, item) { return u.isEmpty(item.name) ? 1 : shopIsModificationPurchased(unit.name, item.name) }
    getMaxAmount = function(unit, item) { return wp_get_modification_max_count(unit.name, item.name) }
    canBuy = function(unit, item) { return isUnitUsable(unit) && canBuyMod(unit, item) }
  }


  BUNDLE = {
    type = weaponsItem.bundle
    getLocName = function(unit, item, limitedName = false) {
      return getByCurBundle(unit, item,  function(unit_, curItem) {
        return ::g_weaponry_types.getUpgradeTypeByItem(curItem).getLocName(unit_, curItem, limitedName)
      })
    }
    getUnlockCost = function(unit, item) {
      return getByCurBundle(unit, item, function(unit_, curItem) {
        return ::g_weaponry_types.getUpgradeTypeByItem(curItem).getUnlockCost(unit_, curItem)
      })
    }
    getCost = function(unit, item) {
      return getByCurBundle(unit, item, function(unit_, curItem) {
        return ::g_weaponry_types.getUpgradeTypeByItem(curItem).getCost(unit_, curItem)
      })
    }
  }


  NEXTUNIT = {
    type = weaponsItem.nextUnit
    getLocName = function(_unit, item, ...) { return loc($"elite/{item.name}") }
  }
}, null, "typeName")








::g_weaponry_types.getUpgradeTypeByItem <- function getUpgradeTypeByItem(item) {
  if (!("type" in item))
    return ::g_weaponry_types.UNKNOWN

  return enums.getCachedType("type", item.type, ::g_weaponry_types.cache.byType, ::g_weaponry_types, ::g_weaponry_types.UNKNOWN)
}

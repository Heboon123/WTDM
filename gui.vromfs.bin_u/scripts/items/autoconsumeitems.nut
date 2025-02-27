from "%scripts/dagui_library.nut" import *
from "%scripts/dagui_natives.nut" import char_send_custom_action
from "%scripts/items/itemsConsts.nut" import itemType
let { addListenersWithoutEnv } = require("%sqStdLibs/helpers/subscriptions.nut")
let DataBlock = require("DataBlock")
let { addTask } = require("%scripts/tasker.nut")
let { getUserstatItemRewardData } = require("%scripts/userstat/userstatItemsRewards.nut")
let inventoryClient = require("%scripts/inventory/inventoryClient.nut")

local shouldCheckAutoConsume = false

let failedAutoConsumeItems = {}
local isAutoConsumeInProgress = false

let multiConsumeList = []
let singleConsumeList = []

function decreaseItemsAmountIfNeed(itemsList) {
  foreach (item in itemsList) {
    let newItem = ::ItemsManager.getInventoryItemById(item.id)
    if (!newItem || item.amount != newItem.amount)
      continue

    local isSameItems = false
    foreach (uid, amount in item.amountByUids) {
      if (amount != newItem.amountByUids?[uid]) {
        isSameItems = false
        break
      }
      isSameItems = true
    }
    if (!isSameItems)
      continue

    newItem.uids.each(@(uid) inventoryClient.removeItem(uid))
    newItem.amountByUids.clear()
    item.uids.clear()
  }
}

function onFinishMultiItemsConsume() {
  //items list refreshed, but ext inventory only requested.
  //so update item amount to avoid repeated request before real update
  decreaseItemsAmountIfNeed(multiConsumeList)
  multiConsumeList.clear()
  isAutoConsumeInProgress = false
}

function fillItemsListsForAutoConsume() {
  let itemList = ::ItemsManager.getInventoryList(itemType.ALL, @(i) i.shouldAutoConsume)

  foreach (item in itemList) {
    if (!item.uids?[0])
      continue
    if (!item.canMultipleConsume || !item?.canConsume() || getUserstatItemRewardData(item.id) != null) {
      singleConsumeList.append(item)
      continue
    }
    multiConsumeList.append(item)
  }
}

function clearItemsListsForAutoConsume() {
  multiConsumeList.clear()
  singleConsumeList.clear()
}

function getItemsBlkForMultiAutoConsume(list) {
  let res = DataBlock()
  let itemsBlk = res.addBlock("items")
  foreach (item in list) {
    if (!item.amountByUids)
      continue

    foreach (uid, amount in item.amountByUids) {
      let itemBlk = itemsBlk.addNewBlock("item")
      itemBlk.setInt("itemId", uid.tointeger())
      itemBlk.setInt("quantity", amount)
    }
  }
  return res
}

function consumeMultipleItems() {
  if (isAutoConsumeInProgress || multiConsumeList.len() == 0)
    return

  isAutoConsumeInProgress = true

  let itemsBlk = getItemsBlkForMultiAutoConsume(multiConsumeList)
  let blkParams = DataBlock()
  blkParams.addBool("textBlk", true)

  let taskId = char_send_custom_action(
    "cln_multi_consume_inventory_item",
    EATT_SIMPLE_OK,
    blkParams,
    itemsBlk.formatAsString(),
    -1
  )
  addTask(taskId, {}, onFinishMultiItemsConsume)
}

local consumeSingleItems = @() null
consumeSingleItems = function() {
  if (isAutoConsumeInProgress || singleConsumeList.len() == 0)
    return

  let onConsumeFinish = function(p = {}) {
    if (!(p?.success ?? true) && p?.itemId != null)
      failedAutoConsumeItems[p.itemId] <- true
    isAutoConsumeInProgress = false
    consumeSingleItems()
  }

  foreach (item in singleConsumeList)
    if (!(item.id in failedAutoConsumeItems) && item.consume(onConsumeFinish, {})) {
      isAutoConsumeInProgress = true
      break
    }
}

function autoConsumeItems() {
  if (isAutoConsumeInProgress)
    return

  clearItemsListsForAutoConsume()
  fillItemsListsForAutoConsume()

  consumeMultipleItems()
  consumeSingleItems()
}

function checkAutoConsume() {
  if (!shouldCheckAutoConsume)
    return
  shouldCheckAutoConsume = false
  autoConsumeItems()
}

addListenersWithoutEnv({
  SignOut = @(_p) failedAutoConsumeItems.clear()
})

return {
  setShouldCheckAutoConsume = @(value) shouldCheckAutoConsume = value
  checkAutoConsume
  autoConsumeItems
}
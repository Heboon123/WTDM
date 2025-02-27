from "%scripts/dagui_library.nut" import *

let g_listener_priority = require("%scripts/g_listener_priority.nut")
let { broadcastEvent, addListenersWithoutEnv } = require("%sqStdLibs/helpers/subscriptions.nut")
let { regionalUnlocks } = require("%scripts/unlocks/regionalUnlocks.nut")
let { script_net_assert_once } = require("%sqStdLibs/helpers/net_errors.nut")
let { get_unlocks_blk, get_personal_unlocks_blk } = require("blkGetters")
let { isLoggedIn } = require("%scripts/login/loginStates.nut")

let cacheById = persist("unlocksCacheById", @() {})
let cacheArray = persist("unlocksCacheArray", @() [])
// <unlockTypeName> = [<unlockBlk>]
let cacheByType = persist("unlocksCacheByType", @() {})
let isCacheValid = persist("unlocksIsCacheValid", @() { value = false })

function addUnlockToCache(unlock) {
  if (unlock?.id == null) {
    let unlockConfigString = toString(unlock, 2) // warning disable: -declared-never-used
    script_net_assert_once("missing id in unlock", "Unlocks: Missing id in unlock. Cannot cache unlock.")
    return
  }
  cacheById[unlock.id] <- unlock
  cacheArray.append(unlock)

  let typeName = unlock.type
  if (typeName not in cacheByType)
    cacheByType[typeName] <- []
  cacheByType[typeName].append(unlock)
}

function convertBlkToCache(blk) {
  foreach (unlock in (blk % "unlockable"))
    addUnlockToCache(unlock)
}

function cache() {
  if (isCacheValid.value)
    return

  isCacheValid.value = true
  cacheById.clear()
  cacheArray.clear()
  cacheByType.clear()
  convertBlkToCache(get_unlocks_blk())
  if (!isLoggedIn.get())
    return

  convertBlkToCache(get_personal_unlocks_blk())
  foreach (unlock in regionalUnlocks.value)
    addUnlockToCache(unlock)
}

function invalidateCache() {
  isCacheValid.value = false
  broadcastEvent("UnlocksCacheInvalidate")
}

function getAllUnlocks() {
  cache()
  return cacheById
}

function getAllUnlocksWithBlkOrder() {
  cache()
  return cacheArray
}

let getUnlockById = @(unlockId) getAllUnlocks()?[unlockId]

function getUnlocksByTypeInBlkOrder(typeName) {
  cache()
  return cacheByType?[typeName] ?? []
}

regionalUnlocks.subscribe(function(_) {
  cache()

  // Clean up non-existent regional unlocks
  for (local i = cacheArray.len() - 1; i >= 0; --i) {
    let unlock = cacheArray[i]
    if (!(unlock?.isRegional ?? false))
      break // Regional unlocks are added in the end, so we can stop here
    if (unlock.id in regionalUnlocks.value)
      continue // Skip, as changes in blk are not expected for regional unlocks

    cacheArray.remove(i)
    cacheById.$rawdelete(unlock.id)

    let inOrder = cacheByType[unlock.type]
    for (local j = inOrder.len() - 1; j >= 0; --j)
      if (inOrder[j] == unlock) {
        inOrder.remove(j)
        break
      }
  }

  foreach (unlock in regionalUnlocks.value)
    if (unlock.id not in cacheById)
      addUnlockToCache(unlock)

  broadcastEvent("RegionalUnlocksChanged")
})

addListenersWithoutEnv({
  SignOut = @(_) invalidateCache()
  LoginComplete = @(_) invalidateCache()
  ProfileUpdated = @(_) invalidateCache()
}, g_listener_priority.CONFIG_VALIDATION)

return {
  getAllUnlocks
  getAllUnlocksWithBlkOrder
  getUnlockById
  getUnlocksByTypeInBlkOrder
}
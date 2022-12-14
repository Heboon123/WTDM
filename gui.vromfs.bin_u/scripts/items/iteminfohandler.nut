from "%scripts/dagui_library.nut" import *

//checked for explicitness
#no-root-fallback
#explicit-this

let { fillItemDescr } = require("%scripts/items/itemVisual.nut")
let { handlerType } = require("%sqDagui/framework/handlerType.nut")

local class ItemInfoHandler extends ::gui_handlers.BaseGuiHandlerWT {
  wndType = handlerType.CUSTOM
  sceneBlkName = "%gui/items/itemDesc.blk"

  currentItemId = null
  currentCategoryId = null

  function updateHandlerData(item, shopDesc = false, preferMarkup = false, params = null)
  {
    this.scene.scrollToView(true)
    fillItemDescr(item, this.scene, this, shopDesc, preferMarkup, params)

    if (item == null)
    {
      this.currentItemId = null
      this.currentCategoryId = null
      return
    }

    if (item.id == this.currentItemId && this.currentCategoryId != null)
    {
      this.openCategory(this.currentCategoryId)
      return
    }
    this.currentItemId = item.id
    this.currentCategoryId = null
  }

  function setHandlerVisible(value)
  {
    this.scene.show(value)
    this.scene.enable(value)
  }

  function openCategory(categoryId)
  {
    let containerObj = this.scene.findObject("item_info_collapsable_prizes")
    if (!checkObj(containerObj))
      return
    let total = containerObj.childrenCount()
    local visible = false
    this.guiScene.setUpdatesEnabled(false, false)
    for(local i = 0; i < total; i++)
    {
      let childObj = containerObj.getChild(i)
      if (childObj.isCategory == "no")
      {
        childObj.enable(visible)
        childObj.show(visible)
        continue
      }
      if (childObj.categoryId == categoryId)
      {
        childObj.collapsed = childObj.collapsed == "no" ? "yes" : "no"
        visible = childObj.collapsed == "no"
        continue
      }
      childObj.collapsed = "yes"
      visible = false
    }
    this.guiScene.setUpdatesEnabled(true, true)
  }

  function onPrizeCategoryClick(obj)
  {
    this.currentCategoryId = obj.categoryId
    this.openCategory(this.currentCategoryId)
    if (::show_console_buttons)
      ::move_mouse_on_obj(obj)
  }

}

::gui_handlers.ItemInfoHandler <- ItemInfoHandler

return function(scene) {
  if (!checkObj(scene))
    return null
  return ::handlersManager.loadHandler(ItemInfoHandler, { scene = scene })
}
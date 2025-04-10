from "%scripts/dagui_natives.nut" import browser_reload_page, browser_go, browser_get_current_url, browser_go_back
from "%scripts/dagui_library.nut" import *

let { BaseGuiHandler } = require("%sqDagui/framework/baseGuiHandler.nut")
let { gui_handlers } = require("%sqDagui/framework/gui_handlers.nut")
let u = require("%sqStdLibs/helpers/u.nut")
let { handlerType } = require("%sqDagui/framework/handlerType.nut")
let { broadcastEvent } = require("%sqStdLibs/helpers/subscriptions.nut")
let { format } = require("string")
let statsd = require("statsd")
let { getPollIdByFullUrl, generatePollUrl } = require("%scripts/web/webpoll.nut")
let { openUrl } = require("%scripts/onlineShop/url.nut")
let { getStringWidthPx } = require("%scripts/viewUtils/daguiFonts.nut")
let { startsWith, stripTags } = require("%sqstd/string.nut")
let { addTask } = require("%scripts/tasker.nut")

::embedded_browser_event <- function embedded_browser_event(event_type, url, error_desc, error_code,
  is_main_frame) {
  broadcastEvent(
    "EmbeddedBrowser",
    { eventType = event_type, url = url, errorDesc = error_desc,
    errorCode = error_code, isMainFrame = is_main_frame, title = "" }
  );
}

::notify_browser_window <- function notify_browser_window(params) {
  broadcastEvent("EmbeddedBrowser", params)
}

gui_handlers.BrowserModalHandler <- class (BaseGuiHandler) {
  wndType = handlerType.MODAL
  sceneBlkName = "%gui/browser.blk"
  sceneNavBlkName = null
  url = ""
  externalUrl = ""
  lastLoadedUrl = ""
  baseUrl = ""
  needVoiceChat = false
  urlTags = []
  isLoadingPage = true

  function initScreen() {
    let browserObj = this.scene.findObject("browser_area")
    browserObj.url = this.url
    this.lastLoadedUrl = this.baseUrl
    browser_go(this.url)
  }

  function browserCloseAndUpdateEntitlements() {
    addTask(::update_entitlements_limited(),
                       {
                         showProgressBox = true
                         progressBoxText = loc("charServer/checking")
                       },
                       @() ::update_gamercards())
    this.goBack()
  }

  function browserGoBack() {
    browser_go_back()
  }

  function onBrowserBtnReload() {
    browser_reload_page()
  }

  function browserForceExternal() {
    local taggedUrl = this.isLoadingPage
      ? this.lastLoadedUrl
      : browser_get_current_url()
    if (!u.isEmpty(this.urlTags) && taggedUrl != "") {
      let tagsStr = " ".join(this.urlTags)
      if (!startsWith(taggedUrl, tagsStr))
        taggedUrl = " ".concat(tagsStr, taggedUrl)
    }

    let newUrl = u.isEmpty(this.externalUrl) ? taggedUrl : this.externalUrl
    openUrl(u.isEmpty(newUrl) ? this.baseUrl : newUrl, true, false, "internal_browser")
  }

  function setTitle(title) {
    if (u.isEmpty(title))
      return

    let titleObj = this.scene.findObject("wnd_title")
    if (checkObj(titleObj))
      titleObj.setValue(title)
  }

  function onEventEmbeddedBrowser(params) {
    let evType = params.eventType
    if (evType == BROWSER_EVENT_DOCUMENT_READY) {
      this.lastLoadedUrl = browser_get_current_url()
      this.toggleWaitAnimation(false)
    }
    else if (evType == BROWSER_EVENT_FAIL_LOADING_FRAME) {
      if (params.isMainFrame) {
        this.toggleWaitAnimation(false)
        let message = "".concat(loc("browser/error_load_url"), loc("ui/dot"),
          "\n", loc("browser/error_code"), loc("ui/colon"), params.errorCode, loc("ui/comma"), params.errorDesc)
        let urlCommentMarkup = this.getUrlCommentMarkupForMsgbox(params.url)
        this.msgBox("error_load_url", message, [["ok", @() null ]], "ok", { data_below_text = urlCommentMarkup })
      }
    }
    else if (evType == BROWSER_EVENT_NEED_RESEND_FRAME) {
      this.toggleWaitAnimation(false)

      this.msgBox("error", loc("browser/error_should_resend_data"),
          [["#mainmenu/btnBack", this.browserGoBack],
           ["#mainmenu/btnRefresh",  function() { browser_go(params.url) }]],
           "#mainmenu/btnBack")
    }
    else if (evType == BROWSER_EVENT_CANT_DOWNLOAD) {
      this.toggleWaitAnimation(false)
      showInfoMsgBox(loc("browser/error_cant_download"))
    }
    else if (evType == BROWSER_EVENT_BEGIN_LOADING_FRAME) {
      if (params.isMainFrame) {
        this.toggleWaitAnimation(true)
        this.setTitle(params.title)
      }
    }
    else if (evType == BROWSER_EVENT_FINISH_LOADING_FRAME) {
      this.lastLoadedUrl = browser_get_current_url()
      if (params.isMainFrame) {
        this.toggleWaitAnimation(false)
        this.setTitle(params.title)
      }
    }
    else if (evType == BROWSER_EVENT_BROWSER_CRASHED) {
      log("[BRWS] embedded browser crashed, forcing external")
      statsd.send_counter("sq.browser.crash", 1, { reason = params.errorDesc })
      this.browserForceExternal()
      this.goBack()
    }
    else {
      log("[BRWS] onEventEmbeddedBrowser: unknown event type", params.eventType)
    }
  }

  function onEventWebPollAuthResult(_param) {
    
    let currentUrl = u.isEmpty(browser_get_current_url()) ? this.url : browser_get_current_url()
    if (u.isEmpty(currentUrl))
      return
    
    
    let pollId = getPollIdByFullUrl(currentUrl)
    if (! pollId)
      return
    this.externalUrl = generatePollUrl(pollId, false)
  }

  function toggleWaitAnimation(show) {
    this.isLoadingPage = show

    let waitSpinner = this.scene.findObject("browserWaitAnimation");
    if (checkObj(waitSpinner))
      waitSpinner.show(show);
  }

  function onDestroy() {
    broadcastEvent("DestroyEmbeddedBrowser")
  }

  function wordWrapText(str, width) {
    if (type(str) != "string" || str == "" || width <= 0)
      return str
    let wrapped = []
    let lines = str.split("\n")
    foreach (line in lines) {
      let unicodeLine = utf8(line)
      let strLen = unicodeLine.charCount()
      for (local pos = 0; pos < strLen; pos += width)
        wrapped.append(unicodeLine.slice(pos, pos + width))
    }
    return "\n".join(wrapped)
  }

  function getUrlCommentMarkupForMsgbox(urlStr) {
    if (urlStr == "")
      return ""

    
    let fontSizePropName = "smallFont"
    let fontSizeCssId = "fontSmall"
    let maxWidthPx = to_pixels("0.8@rw")
    let textWidthPx = getStringWidthPx(urlStr, fontSizeCssId, this.guiScene)
    if (textWidthPx != 0 && textWidthPx > maxWidthPx) {
      let splitByChars = (1.0 * maxWidthPx / textWidthPx * utf8(urlStr).charCount()).tointeger()
      urlStr = this.wordWrapText(urlStr, splitByChars)
    }
    return format("textareaNoTab { %s:t='yes'; overlayTextColor:t='faded'; text:t='%s'; }",
      fontSizePropName, stripTags(urlStr))
  }
}

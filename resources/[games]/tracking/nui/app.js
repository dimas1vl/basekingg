const isDevMode = typeof window.invokeNative === "undefined"
const devImageUrl = "https://picsum.photos/1920/1080?grayscale"
const displayController = window.createDisplayController()
const footerLeftButton = document.getElementById("footer-arrow-button")
const footerRightButton = document.getElementById("footer-action-button")
const DEFAULT_NUI_TIMEOUT = 15000

const getResourceName = function() {
  if (typeof window.GetParentResourceName === "function") {
    return window.GetParentResourceName()
  }

  return "multi_tracking"
}

const fetchNui = async function(eventName, data) {
  if (isDevMode) {
    console.log("[multi_tracking] fetchNui", eventName, data || {})
    return { ok: true }
  }

  const controller = new AbortController()
  const timeoutId = setTimeout(function() {
    controller.abort()
  }, DEFAULT_NUI_TIMEOUT)

  try {
    const response = await fetch(`https://${getResourceName()}/${eventName}`, {
      method: "post",
      headers: {
        "Content-Type": "application/json; charset=UTF-8"
      },
      body: JSON.stringify(data || {}),
      signal: controller.signal
    })

    return await response.json()
  } finally {
    clearTimeout(timeoutId)
  }
}

const handleFooterDirectionClick = function(direction) {
  fetchNui("footerControllerDirection", {
    direction: direction
  }).catch(function() {})
}

const handleMessage = function(event) {
  const payload = event.data || {}
  const action = payload.action
  const data = payload.data || {}

  if (action === "setImage") {
    displayController.setImage(data.url)
    displayController.setDescription(data.description || "")
    return
  }
  if (action === "setDescription" || action === "updateDescription") {
    displayController.setDescription(data.description || data.text || "")
    return
  }
  if (action === "hideImage") {
    displayController.hideImage()
    return
  }
  if (action === "setOpacity") {
    document.body.style.opacity = data.value ?? 1
    return
  }
  if (action === "footerController") {
    if (typeof data.visible === "boolean") {
      displayController.setVisibleFooter(data.visible)
    }

    if (Object.prototype.hasOwnProperty.call(data, "spawn")) {
      displayController.setFooter(data.spawn || "")
    }

    return
  }
}

window.addEventListener("message", handleMessage)
window.addEventListener("resize", displayController.resizeNoise)

if (footerLeftButton) {
  footerLeftButton.addEventListener("click", function() {
    handleFooterDirectionClick("left")
  })
}

if (footerRightButton) {
  footerRightButton.addEventListener("click", function() {
    handleFooterDirectionClick("right")
  })
}

if (isDevMode) {
  displayController.setImage(devImageUrl)
  displayController.setDescription("Tracking feed online")
  displayController.setVisibleFooter(true)
  displayController.setFooter("Praia")
}

window.createDisplayController = function() {
  const frameElement = document.getElementById("frame")
  const noiseCanvas = document.getElementById("noise")
  const rootElement = document.getElementById("root")
  const descriptionTextElement = document.getElementById("description-text")
  const footerElement = document.getElementById("footer-controller")
  const footerSpawnTextElement = document.getElementById("footer-spawn-text")

  if (!frameElement || !noiseCanvas || !rootElement || !descriptionTextElement || !footerElement || !footerSpawnTextElement) {
    throw new Error("nui elements not found")
  }

  const noiseContext = noiseCanvas.getContext("2d", { alpha: true })

  if (!noiseContext) {
    throw new Error("nui context not available")
  }

  let noiseImageData = noiseContext.createImageData(noiseCanvas.width, noiseCanvas.height)
  let isVisible = false
  let isFooterVisible = false

  const setRootVisibility = function(nextIsVisible) {
    if (nextIsVisible) {
      rootElement.classList.add("visible")
      return
    }

    rootElement.classList.remove("visible")
  }

  const resizeNoise = function() {
    const targetWidth = Math.max(window.innerWidth, 1920)
    const targetHeight = Math.max(window.innerHeight, 1080)

    if (noiseCanvas.width === targetWidth && noiseCanvas.height === targetHeight) {
      return
    }

    noiseCanvas.width = targetWidth
    noiseCanvas.height = targetHeight
    noiseImageData = noiseContext.createImageData(noiseCanvas.width, noiseCanvas.height)

    if (isVisible) {
      renderStaticNoise()
    }
  }

  const renderStaticNoise = function() {
    if (!isVisible) {
      return
    }

    const pixels = noiseImageData.data

    for (let index = 0; index < pixels.length; index += 4) {
      const value = Math.random() * 255
      const spike = Math.random() > 0.9 ? 255 : value
      pixels[index] = value
      pixels[index + 1] = value
      pixels[index + 2] = spike
      pixels[index + 3] = 80 + Math.random() * 150
    }

    noiseContext.putImageData(noiseImageData, 0, 0)
  }

  const setImage = function(imageUrl) {
    if (!imageUrl || typeof imageUrl !== "string") {
      return
    }

    frameElement.src = imageUrl
    frameElement.classList.add("visible")
    rootElement.classList.add("has-image")
    isVisible = true
    setRootVisibility(true)
    renderStaticNoise()
  }

  const setDescription = function(textValue) {
    if (typeof textValue !== "string") {
      descriptionTextElement.textContent = ""
      rootElement.classList.remove("has-description")
      return
    }

    const sanitizedText = textValue.trim()
    descriptionTextElement.textContent = sanitizedText

    if (!sanitizedText) {
      rootElement.classList.remove("has-description")
      return
    }

    rootElement.classList.add("has-description")
  }

  const hideImage = function() {
    frameElement.classList.remove("visible")
    frameElement.src = ""
    rootElement.classList.remove("has-image")
    isVisible = false
    if (!isFooterVisible) {
      setRootVisibility(false)
    }
    setDescription("")
  }

  const setVisibleFooter = function(nextIsVisible) {
    isFooterVisible = nextIsVisible === true
    if (nextIsVisible) {
      footerElement.classList.add("visible")
      setRootVisibility(true)
      return
    }
    footerElement.classList.remove("visible")
    if (!isVisible) {
      setRootVisibility(false)
    }
  }

  const setFooter = function(spawnValue) {
    if (typeof spawnValue !== "string") {
      footerSpawnTextElement.textContent = ""
      return
    }

    footerSpawnTextElement.textContent = spawnValue.trim()
  }

  resizeNoise()
  hideImage()

  return {
    resizeNoise: resizeNoise,
    setImage: setImage,
    hideImage: hideImage,
    setDescription: setDescription,
    setVisibleFooter: setVisibleFooter,
    setFooter: setFooter
  }
}

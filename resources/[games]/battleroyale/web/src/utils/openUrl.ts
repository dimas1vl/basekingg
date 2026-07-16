import { isEnvBrowser } from "./misc";

export default function openUrl(url: string) {
  if (isEnvBrowser()) {
    window.open(url, '_blank')
    return
  }

  (window as any).invokeNative('openUrl', url)
}
const CDN_URL = import.meta.env.VITE_CDN_URL ?? ''

export const cdn = (file: string) => (CDN_URL ? new URL(file, CDN_URL).href : file)

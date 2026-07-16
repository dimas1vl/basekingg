import fallbackWeaponUrl from '@/assets/hud/weapon_carbine.png?url'

// Mapeia o id "limpo" do ícone (ex.: "bullpup-rifle-icon", vindo da config
// do servidor em ShopWeapon.icon) -> URL do asset bundlado pelo Vite.
// As imagens ficam em src/assets/weapons/<id>.png.
const modules = import.meta.glob('@/assets/weapons/*.png', {
  eager: true,
  query: '?url',
  import: 'default',
}) as Record<string, string>

const ICONS: Record<string, string> = {}
for (const path in modules) {
  const name = path.split('/').pop()?.replace(/\.png$/, '')
  if (name) ICONS[name] = modules[path]
}

/** Resolve a URL da imagem de uma arma da loja a partir do id do ícone. */
export function weaponIconSrc(icon?: string): string {
  if (!icon) return fallbackWeaponUrl
  return ICONS[icon] ?? fallbackWeaponUrl
}

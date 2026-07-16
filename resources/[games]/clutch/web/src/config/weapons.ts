// Weapon hash -> image mapping.
//
// As imagens foram baixadas do wiki rage.mp (https://wiki.rage.mp/wiki/Weapons)
// e ficam em src/assets/weapons/. Cada hash WEAPON_* aponta para o icon
// correspondente. Armas sem mapeamento caem no placeholder automaticamente.

import fallbackWeaponUrl from '@/assets/hud/weapon_carbine.png?url'

// Melee
import knifeUrl                  from '@/assets/weapons/knife-icon.png?url'
import knucklesUrl               from '@/assets/weapons/knuckles-icon.png?url'
import nightstickUrl             from '@/assets/weapons/nightstick-icon.png?url'
import hammerUrl                 from '@/assets/weapons/hammer-icon.png?url'
import baseballBatUrl            from '@/assets/weapons/baseball-bat-icon.png?url'
import golfClubUrl               from '@/assets/weapons/golf-club-icon.png?url'
import crowbarUrl                from '@/assets/weapons/crowbar-icon.png?url'
import bottleUrl                 from '@/assets/weapons/broken-bottle-icon.png?url'
import dagUrl                    from '@/assets/weapons/antique-cavalry-dagger-icon.png?url'
import hatchetUrl                from '@/assets/weapons/hatchet-icon.png?url'
import machete                   from '@/assets/weapons/switch-blade-icon.png?url'
import battleAxeUrl              from '@/assets/weapons/battle-axe-icon.png?url'
import poolCueUrl                from '@/assets/weapons/pool-cue-icon.png?url'
import stoneHatchetUrl           from '@/assets/weapons/stone-hatchet-icon.png?url'
import pipeWrenchUrl             from '@/assets/weapons/pipe-wrench-icon.png?url'
import candyCaneUrl              from '@/assets/weapons/candy-cane-icon.png?url'
import fistUrl                   from '@/assets/weapons/fist-icon.png?url'
import flashlightUrl             from '@/assets/weapons/flashlight-icon.png?url'

// Pistols
import pistolUrl                 from '@/assets/weapons/pistol-icon.png?url'
import pistolMk2Url              from '@/assets/weapons/pistol-mk2-icon.png?url'
import combatPistolUrl           from '@/assets/weapons/combat-pistol-icon.png?url'
import apPistolUrl               from '@/assets/weapons/appistol-icon.png?url'
import pistol50Url               from '@/assets/weapons/pistol.50-icon.png?url'
import snsPistolUrl              from '@/assets/weapons/sns-pistol-icon.png?url'
import snsPistolMk2Url           from '@/assets/weapons/sns-pistol-mk2-icon.png?url'
import heavyPistolUrl            from '@/assets/weapons/heavy-pistol-icon.png?url'
import vintagePistolUrl          from '@/assets/weapons/vintage-pistol-icon.png?url'
import marksmanPistolUrl         from '@/assets/weapons/marksman-pistol-icon.png?url'
import machinePistolUrl          from '@/assets/weapons/machine-pistol-icon.png?url'
import flareGunUrl               from '@/assets/weapons/flaregun-icon.png?url'
import revolverUrl               from '@/assets/weapons/heavy-revolver-icon.png?url'
import revolverMk2Url            from '@/assets/weapons/heavy-revolver-mk2-icon.png?url'
import doubleActionUrl           from '@/assets/weapons/double-action-revolver-icon.png?url'
import navyRevolverUrl           from '@/assets/weapons/navy-revolver-icon.png?url'
import ceramicPistolUrl          from '@/assets/weapons/ceramic-pistol-icon.png?url'
import pericoPistolUrl           from '@/assets/weapons/perico-pistol-icon.png?url'
import stunGunUrl                from '@/assets/weapons/stungun-icon.png?url'
import theShockerUrl             from '@/assets/weapons/the-shocker-icon.png?url'
import wm29PistolUrl             from '@/assets/weapons/wm-29-pistol-icon.png?url'

// SMGs / PDWs
import microSmgUrl               from '@/assets/weapons/micro-smg-icon.png?url'
import smgUrl                    from '@/assets/weapons/smg-icon.png?url'
import smgMk2Url                 from '@/assets/weapons/smg-mk2-icon.png?url'
import assaultSmgUrl             from '@/assets/weapons/assault-smg-icon.png?url'
import combatPdwUrl              from '@/assets/weapons/combat-pdw-icon.png?url'
import miniSmgUrl                from '@/assets/weapons/mini-smg-icon.png?url'
import tacticalSmgUrl            from '@/assets/weapons/tactical-smg-icon.png?url'

// Rifles
import advancedRifleUrl          from '@/assets/weapons/advanced-rifle-icon.png?url'
import carbineMk2Url             from '@/assets/weapons/carbine-rifle-mk2-icon.png?url'
import specialCarbineUrl         from '@/assets/weapons/special-carbine-icon.png?url'
import specialCarbineMk2Url      from '@/assets/weapons/special-carbine-mk2-icon.png?url'
import bullpupRifleUrl           from '@/assets/weapons/bullpup-rifle-icon.png?url'
import bullpupRifleMk2Url        from '@/assets/weapons/bullpup-rifle-mk2-icon.png?url'
import compactRifleUrl           from '@/assets/weapons/compact-rifle-icon.png?url'
import musketUrl                 from '@/assets/weapons/musket-icon.png?url'

// Shotguns
import pumpShotgunUrl            from '@/assets/weapons/pump-shotgun-icon.png?url'
import sawedOffShotgunUrl        from '@/assets/weapons/sawed-off-shotgun-icon.png?url'
import assaultShotgunUrl         from '@/assets/weapons/assault-shotgun-icon.png?url'
import bullpupShotgunUrl         from '@/assets/weapons/bullpup-shotgun-icon.png?url'
import heavyShotgunUrl           from '@/assets/weapons/heavy-shotgun-icon.png?url'
import doubleBarrelShotgunUrl    from '@/assets/weapons/double-barrel-shotgun-icon.png?url'
import sweeperShotgunUrl         from '@/assets/weapons/sweeper-shotgun-icon.png?url'

// Heavy
import unholyHellbringerUrl      from '@/assets/weapons/unholy-hellbringer-icon.png?url'
import upNAtomizerUrl            from '@/assets/weapons/up-n-atomizer-icon.png?url'
import grenadeLauncherUrl        from '@/assets/weapons/grenade-compact-launcher-icon.png?url'
import empLauncherUrl            from '@/assets/weapons/emp-launcher-icon.png?url'

// Throwables / Gadgets
import grenadeUrl                from '@/assets/weapons/grenade-icon.png?url'
import stickyBombUrl             from '@/assets/weapons/sticky-bomb-icon.png?url'
import molotovUrl                from '@/assets/weapons/molotov-icon.png?url'
import flareUrl                  from '@/assets/weapons/flare-icon.png?url'
import snowballUrl               from '@/assets/weapons/snowball-icon.png?url'
import ballUrl                   from '@/assets/weapons/ball-icon.png?url'
import pipeBombUrl               from '@/assets/weapons/pipe-bomb-icon.png?url'
import tearGasUrl                from '@/assets/weapons/tear-gas-icon.png?url'
import bzGasUrl                  from '@/assets/weapons/bz-gas-icon.png?url'
import proximityMineUrl          from '@/assets/weapons/proximity-mines-icon.png?url'
import petrolCanUrl              from '@/assets/weapons/petrolcan-icon.png?url'
import parachuteUrl              from '@/assets/weapons/parachute-icon.png?url'
import acidPackageUrl            from '@/assets/weapons/acid-package-icon.png?url'

export const WEAPON_IMAGES: Record<string, string> = {
  // Melee
  WEAPON_UNARMED:                fistUrl,
  WEAPON_KNIFE:                  knifeUrl,
  WEAPON_KNUCKLE:                knucklesUrl,
  WEAPON_NIGHTSTICK:             nightstickUrl,
  WEAPON_HAMMER:                 hammerUrl,
  WEAPON_BAT:                    baseballBatUrl,
  WEAPON_GOLFCLUB:               golfClubUrl,
  WEAPON_CROWBAR:                crowbarUrl,
  WEAPON_BOTTLE:                 bottleUrl,
  WEAPON_DAGGER:                 dagUrl,
  WEAPON_HATCHET:                hatchetUrl,
  WEAPON_SWITCHBLADE:            machete,
  WEAPON_MACHETE:                machete,
  WEAPON_BATTLEAXE:              battleAxeUrl,
  WEAPON_POOLCUE:                poolCueUrl,
  WEAPON_STONE_HATCHET:          stoneHatchetUrl,
  WEAPON_WRENCH:                 pipeWrenchUrl,
  WEAPON_CANDYCANE:              candyCaneUrl,
  WEAPON_FLASHLIGHT:             flashlightUrl,

  // Pistols
  WEAPON_PISTOL:                 pistolUrl,
  WEAPON_PISTOL_MK2:             pistolMk2Url,
  WEAPON_COMBATPISTOL:           combatPistolUrl,
  WEAPON_APPISTOL:               apPistolUrl,
  WEAPON_PISTOL50:               pistol50Url,
  WEAPON_SNSPISTOL:              snsPistolUrl,
  WEAPON_SNSPISTOL_MK2:          snsPistolMk2Url,
  WEAPON_HEAVYPISTOL:            heavyPistolUrl,
  WEAPON_VINTAGEPISTOL:          vintagePistolUrl,
  WEAPON_MARKSMANPISTOL:         marksmanPistolUrl,
  WEAPON_MACHINEPISTOL:          machinePistolUrl,
  WEAPON_FLAREGUN:               flareGunUrl,
  WEAPON_REVOLVER:               revolverUrl,
  WEAPON_REVOLVER_MK2:           revolverMk2Url,
  WEAPON_DOUBLEACTION:           doubleActionUrl,
  WEAPON_NAVYREVOLVER:           navyRevolverUrl,
  WEAPON_CERAMICPISTOL:          ceramicPistolUrl,
  WEAPON_PERICOPISTOL:           pericoPistolUrl,
  WEAPON_STUNGUN:                stunGunUrl,
  WEAPON_STUNGUN_MP:             theShockerUrl,
  WEAPON_WM_29_PISTOL:           wm29PistolUrl,

  // SMGs
  WEAPON_MICROSMG:               microSmgUrl,
  WEAPON_SMG:                    smgUrl,
  WEAPON_SMG_MK2:                smgMk2Url,
  WEAPON_ASSAULTSMG:             assaultSmgUrl,
  WEAPON_COMBATPDW:              combatPdwUrl,
  WEAPON_MINISMG:                miniSmgUrl,
  WEAPON_TACTICALSMG:            tacticalSmgUrl,

  // Rifles — usa o MK2 quando o icon base não existe no wiki
  WEAPON_ASSAULTRIFLE:           compactRifleUrl,
  WEAPON_ASSAULTRIFLE_MK2:       compactRifleUrl,
  WEAPON_CARBINERIFLE:           carbineMk2Url,
  WEAPON_CARBINERIFLE_MK2:       carbineMk2Url,
  WEAPON_ADVANCEDRIFLE:          advancedRifleUrl,
  WEAPON_SPECIALCARBINE:         specialCarbineUrl,
  WEAPON_SPECIALCARBINE_MK2:     specialCarbineMk2Url,
  WEAPON_BULLPUPRIFLE:           bullpupRifleUrl,
  WEAPON_BULLPUPRIFLE_MK2:       bullpupRifleMk2Url,
  WEAPON_COMPACTRIFLE:           compactRifleUrl,
  WEAPON_MILITARYRIFLE:          carbineMk2Url,
  WEAPON_HEAVYRIFLE:             carbineMk2Url,
  WEAPON_TACTICALRIFLE:          carbineMk2Url,
  WEAPON_MUSKET:                 musketUrl,

  // Snipers (não há icons base no wiki — usam o musket como fallback temático)
  WEAPON_SNIPERRIFLE:            musketUrl,
  WEAPON_HEAVYSNIPER:            musketUrl,
  WEAPON_HEAVYSNIPER_MK2:        musketUrl,
  WEAPON_MARKSMANRIFLE:          musketUrl,
  WEAPON_MARKSMANRIFLE_MK2:      musketUrl,

  // Shotguns
  WEAPON_PUMPSHOTGUN:            pumpShotgunUrl,
  WEAPON_PUMPSHOTGUN_MK2:        pumpShotgunUrl,
  WEAPON_SAWNOFFSHOTGUN:         sawedOffShotgunUrl,
  WEAPON_ASSAULTSHOTGUN:         assaultShotgunUrl,
  WEAPON_BULLPUPSHOTGUN:         bullpupShotgunUrl,
  WEAPON_HEAVYSHOTGUN:           heavyShotgunUrl,
  WEAPON_DBSHOTGUN:              doubleBarrelShotgunUrl,
  WEAPON_AUTOSHOTGUN:            sweeperShotgunUrl,
  WEAPON_COMBATSHOTGUN:          pumpShotgunUrl,

  // Heavy
  WEAPON_HOMINGLAUNCHER:         grenadeLauncherUrl,
  WEAPON_GRENADELAUNCHER:        grenadeLauncherUrl,
  WEAPON_GRENADELAUNCHER_SMOKE:  grenadeLauncherUrl,
  WEAPON_COMPACTLAUNCHER:        grenadeLauncherUrl,
  WEAPON_RPG:                    grenadeLauncherUrl,
  WEAPON_FIREWORK:               grenadeLauncherUrl,
  WEAPON_HELLBRINGER:            unholyHellbringerUrl,
  WEAPON_UNHOLYHELLBRINGER:      unholyHellbringerUrl,
  WEAPON_RAYPISTOL:              upNAtomizerUrl,
  WEAPON_UP_N_ATOMIZER:          upNAtomizerUrl,
  WEAPON_EMPLAUNCHER:            empLauncherUrl,

  // Throwables / Gadgets
  WEAPON_GRENADE:                grenadeUrl,
  WEAPON_STICKYBOMB:             stickyBombUrl,
  WEAPON_MOLOTOV:                molotovUrl,
  WEAPON_FLARE:                  flareUrl,
  WEAPON_SNOWBALL:               snowballUrl,
  WEAPON_BALL:                   ballUrl,
  WEAPON_PIPEBOMB:               pipeBombUrl,
  WEAPON_SMOKEGRENADE:           tearGasUrl,
  WEAPON_BZGAS:                  bzGasUrl,
  WEAPON_PROXMINE:               proximityMineUrl,
  WEAPON_PETROLCAN:              petrolCanUrl,
  GADGET_PARACHUTE:              parachuteUrl,
  WEAPON_ACIDPACKAGE:            acidPackageUrl,
}

/**
 * Resolve a URL da imagem para uma arma. Cai no placeholder quando o hash
 * não estiver mapeado — assim a HUD nunca quebra mesmo com armas exóticas.
 */
export function getWeaponImage(hash?: string): string {
  if (!hash) return fallbackWeaponUrl
  return WEAPON_IMAGES[hash] ?? fallbackWeaponUrl
}

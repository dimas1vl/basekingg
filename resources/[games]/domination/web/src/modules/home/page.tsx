import { useHud } from './useHud'
import StatsBar from './components/StatsBar'
import CompassBar from './components/CompassBar'
import Notify from './components/Notify'
import KillFeed from './components/KillFeed'
import ReloadIndicator from './components/ReloadIndicator'
import WeaponHotbar from './components/WeaponHotbar'
import LevelBar from './components/LevelBar'
import WeaponInfo from './components/WeaponInfo'
import BottomBar from './components/BottomBar'
import DamageMarkers from './components/DamageMarkers'
import KillMarker from './components/KillMarker'
import { useSettings } from '@/store/settings'

// HUD da Dominação — layout do Figma "HUD IN GAME - dominas".
// Cada elemento é um componente próprio em ./components; o estado/listeners
// ficam em ./useHud. Aqui só montamos o layout nas posições do design.
export default function Home() {
  const { hud, killFeed, heading, level, xpInto, xpPer, notify, reloading, progress } = useHud()
  const hset = useSettings((s) => s.settings.hud)

  return (
    <div className="absolute inset-0 overflow-hidden">
      {/* Marcadores de dano/kill */}
      <DamageMarkers />
      <KillMarker />

      {/* Topo esquerdo — stats + moldura do minimapa */}
      {!hset.hideStats && (
        <StatsBar kills={hud.kills} deaths={hud.deaths} killStreak={hud.killStreak} players={hud.players} />
      )}

      {/* Topo central — bússola + notificação */}
      {!hset.hideCompass && <CompassBar heading={heading} />}
      {notify.visible && <Notify title={notify.title} description={notify.description} />}

      {/* Topo direito — kill feed */}
      {!hset.hideKillfeed && <KillFeed entries={killFeed} />}

      {/* Centro inferior — recarga + hotbar + nível/XP */}
      <ReloadIndicator visible={reloading} />
      <WeaponHotbar health={hud.health} slots={hud.slots} activeSlot={hud.activeSlot} />
      {!hset.hideLevel && <LevelBar level={level} xpInto={xpInto} xpPer={xpPer} />}

      {/* Inferior direito — munição/arma + velocidade */}
      {!hset.hideWeapon && (
        <WeaponInfo
          ammo={hud.ammo}
          maxAmmo={hud.maxAmmo}
          activeSlot={hud.activeSlot}
          speed={hud.speed}
          weapon={hud.activeWeapon}
          showSpeed={hud.inVehicle}
        />
      )}

      {/* Rodapé — barra de progresso da rodada */}
      <BottomBar progress={progress} />
    </div>
  )
}

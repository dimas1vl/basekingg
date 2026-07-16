import { useState } from 'react'
import { useLobby } from '@/providers/LobbyProvider'
import { fetchData } from '@/utils/fetchData'
import { DEFAULT_SETTINGS, type ProfileSettingKey, type ProfileTab } from './data'
import { ProfileHeader } from './components/profile-header'
import { InfoTab } from './components/info-tab'
import { InventoryTab } from './components/inventory-tab'
import { SettingsTab } from './components/settings-tab'

export default function ProfilePage() {
  const { player } = useLobby()
  const [tab, setTab] = useState<ProfileTab>('info')
  const [settings, setSettings] = useState(DEFAULT_SETTINGS)

  const handleSetting = (key: ProfileSettingKey, value: boolean) => {
    setSettings((prev) => prev.map((s) => (s.key === key ? { ...s, value } : s)))
    fetchData('setProfileSetting', { key, value })
  }

  return (
    <div className="relative flex flex-col w-full h-full overflow-hidden">
      {/* Fundo escuro com brilho radial suave (design PERFIIL) */}
      <div className="absolute inset-0 -z-10 bg-[#101012]" />
      <div
        className="absolute inset-0 -z-10"
        style={{
          background:
            'radial-gradient(115rem 65rem at 50% 40%, rgba(29,28,34,0.9) 0%, rgba(29,28,34,0) 70%)',
        }}
      />

      <ProfileHeader player={player} tab={tab} onTab={setTab} />

      <div className="flex-1 min-h-0">
        {tab === 'info' && <InfoTab player={player} />}
        {tab === 'inventory' && <InventoryTab />}
        {tab === 'settings' && <SettingsTab settings={settings} onChange={handleSetting} />}
      </div>
    </div>
  )
}

export type RankingTab = 'player' | 'clan' | 'algo1' | 'algo2'

export type RankRow = {
  rank: number
  name: string
  values: string[]
}

export type RankingTabDef = {
  id: RankingTab
  label: string
  enabled: boolean
}

export const RANKING_TABS: RankingTabDef[] = [
  { id: 'player', label: 'JOGADOR', enabled: true },
  { id: 'clan', label: 'CLAN', enabled: true },
  { id: 'algo1', label: 'ALGO', enabled: false },
  { id: 'algo2', label: 'ALGO', enabled: false },
]

export const PLAYER_COLUMNS = ['NOME', 'ELO', 'VITÓRIAS', 'KILLS', 'K/D%']
export const CLAN_COLUMNS = ['CLAN', 'VITORIAS', 'PARTIDAS', 'PONTOS']

export const MOCK_PLAYER_RANKING: RankRow[] = [
  { rank: 1, name: 'RACCO COSTA', values: ['DIAMANTE III', '151', '543', '76%'] },
  { rank: 2, name: 'RACCO COSTA', values: ['DIAMANTE III', '151', '543', '76%'] },
  { rank: 3, name: 'RACCO COSTA', values: ['DIAMANTE III', '152', '540', '75%'] },
  { rank: 4, name: 'RACCO COSTA', values: ['DIAMANTE III', '153', '538', '74%'] },
  { rank: 5, name: 'RACCO COSTA', values: ['DIAMANTE III', '154', '535', '73%'] },
  { rank: 6, name: 'RACCO COSTA', values: ['DIAMANTE III', '155', '532', '72%'] },
  { rank: 7, name: 'RACCO COSTA', values: ['DIAMANTE III', '156', '530', '71%'] },
  { rank: 8, name: 'RACCO COSTA', values: ['DIAMANTE III', '157', '525', '70%'] },
  { rank: 9, name: 'RACCO COSTA', values: ['DIAMANTE III', '158', '520', '69%'] },
  { rank: 10, name: 'RACCO COSTA', values: ['DIAMANTE III', '159', '515', '68%'] },
  { rank: 11, name: 'RACCO COSTA', values: ['DIAMANTE III', '160', '510', '67%'] },
  { rank: 12, name: 'RACCO COSTA', values: ['DIAMANTE III', '161', '505', '66%'] },
  { rank: 13, name: 'RACCO COSTA', values: ['DIAMANTE III', '162', '500', '65%'] },
  { rank: 14, name: 'RACCO COSTA', values: ['DIAMANTE III', '163', '495', '64%'] },
  { rank: 15, name: 'RACCO COSTA', values: ['DIAMANTE III', '164', '490', '63%'] },
  { rank: 16, name: 'RACCO COSTA', values: ['DIAMANTE III', '165', '485', '62%'] },
]

export const MOCK_CLAN_RANKING: RankRow[] = [
  { rank: 1, name: 'KillZone', values: ['DIAMANTE III', '151', '543'] },
  { rank: 2, name: 'LOUD', values: ['DIAMANTE III', '151', '543'] },
  { rank: 3, name: 'Thunderstrike', values: ['RAPID IV', '165', '560'] },
  { rank: 4, name: 'ShadowPulse', values: ['RAPID IV', '162', '550'] },
  { rank: 5, name: 'Frostbite', values: ['FUSION II', '170', '580'] },
  { rank: 6, name: 'Blaze', values: ['FUSION II', '167', '570'] },
  { rank: 7, name: 'Quicksilver', values: ['VECTOR X', '175', '600'] },
  { rank: 8, name: 'Tempest', values: ['VECTOR X', '172', '590'] },
  { rank: 9, name: 'Ironclad', values: ['TITAN V', '180', '620'] },
  { rank: 10, name: 'Abyss', values: ['TITAN V', '177', '610'] },
  { rank: 11, name: 'Vortex', values: ['PHANTOM II', '185', '640'] },
  { rank: 12, name: 'Zenith', values: ['PHANTOM II', '182', '630'] },
  { rank: 13, name: 'Raptor', values: ['WILDFIRE I', '190', '660'] },
  { rank: 14, name: 'Spectre', values: ['WILDFIRE I', '188', '650'] },
  { rank: 15, name: 'Catalyst', values: ['BLAZE III', '195', '680'] },
  { rank: 16, name: 'Equinox', values: ['BLAZE III', '192', '670'] },
]

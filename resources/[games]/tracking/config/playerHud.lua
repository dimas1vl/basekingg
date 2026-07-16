-- Config do HUD do jogador no tracking.

TrackingPlayerHud = {
    weapons = {
        { slot = 1, weapon = 'WEAPON_CARBINERIFLE', ammo = 9999, label = 'FUZIL' },
        { slot = 2, weapon = 'WEAPON_SMG',          ammo = 9999, label = 'SMG' },
        { slot = 3, weapon = 'WEAPON_PISTOL',       ammo = 9999, label = 'PISTOLA' },
        { slot = 4, weapon = 'WEAPON_PUMPSHOTGUN',  ammo = 9999, label = 'ESPINGARDA' },
        { slot = 5, weapon = 'WEAPON_KNIFE',        ammo = 1,    label = 'FACA',
          speedMultiplier = 1.20 },
    },

    startHealth = 200,
    startArmor  = 100,
    hudUpdateMs = 500,
}

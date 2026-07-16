# Imagens das armas

Solte aqui os PNGs/SVGs das armas usando o **hash em lowercase** como nome:

```
weapon_pistol.png
weapon_smg.png
weapon_carbinerifle.png
weapon_assaultrifle.png
weapon_sniperrifle.png
weapon_pumpshotgun.png
weapon_knife.png
weapon_grenade.png
```

Depois de adicionar:

1. Abra `src/config/weapons.ts`
2. Descomente o `import ... from '@/assets/weapons/<nome>.png?url'` correspondente
3. Descomente a entrada em `WEAPON_IMAGES` (chave = string do hash do GTA, ex: `WEAPON_PISTOL`)
4. `npm run build` no diretório `web/`
5. `restart deathmatch`

Os hashes oficiais ficam em https://wiki.rage.mp/index.php?title=Weapons ou no GTA V wiki — basta usar o nome `WEAPON_*` na chave do `WEAPON_IMAGES`.

Enquanto uma arma não tiver imagem mapeada, ela cai no placeholder (`assets/hud/weapon_carbine.png`) automaticamente — a HUD não quebra.

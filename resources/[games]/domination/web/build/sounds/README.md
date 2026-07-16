# Sons do menu de configurações (ÁUDIO)

Coloque os arquivos de som AQUI (`web/public/sounds/`). Ao rodar `yarn build`, o Vite
copia esta pasta para `web/build/sounds/` automaticamente (NÃO coloque os arquivos
direto em `web/build`, pois o build apaga essa pasta).

## Estrutura esperada

```
sounds/
  saque/   <- som ao sacar/trocar a arma
  hit/     <- som quando VOCÊ acerta um inimigo (hitmarker)
  kill/    <- som quando você mata
  ping/    <- som quando VOCÊ leva dano (aviso)
```

Cada categoria pode ter vários efeitos. O nome do arquivo (sem extensão) é o "efeito"
que aparece no dropdown do menu. As opções padrão do menu são:

```
default.ogg
op1.ogg
op2.ogg
op3.ogg
op4.ogg
```

Exemplo: `sounds/kill/op2.ogg` aparece como efeito "op2" na categoria SOM DA KILL.

Formatos aceitos pelo NUI (Chromium): `.ogg`, `.mp3`, `.wav`. Recomendado `.ogg`.

Para adicionar/renomear as opções do dropdown, edite `SFX_OPTIONS` em
`web/src/store/settings.ts` e crie os arquivos com os mesmos nomes.

Enquanto não houver arquivo para um efeito/volume, o som simplesmente não toca
(sem erro). O volume de cada categoria é ajustável no menu (0–100%).

import { imgVector11, imgVector12, imgUnion3 } from '../assets'

// Moldura decorativa do minimapa (Figma Frame 200), canto superior esquerdo.
// O minimapa em si é renderizado pelo jogo; aqui só desenhamos a borda/cantos.
export default function MinimapFrame() {
  return (
    <div className="absolute h-[174px] left-[40px] top-[79px] w-[276px]">
      <div className="absolute h-[174px] left-0 top-0 w-[276px]">
        <img alt="" className="absolute block inset-0 max-w-none size-full" height="174" src={imgVector11} width="276" />
      </div>
      <div className="absolute h-[180px] left-[-3px] top-[-3px] w-[282px]">
        <div className="absolute inset-[-0.56%_-0.35%_-0.69%_-0.35%]">
          <img alt="" className="block max-w-none size-full" src={imgVector12} />
        </div>
      </div>
      <div className="absolute h-[13px] left-[158px] top-[-7px] w-[35px]">
        <div className="absolute inset-[-7.69%_-2.86%]">
          <img alt="" className="block max-w-none size-full" src={imgUnion3} />
        </div>
      </div>
      <div className="absolute h-[13px] left-[25px] top-[167px] w-[35px]">
        <div className="absolute inset-[-7.69%_-2.86%]">
          <img alt="" className="block max-w-none size-full" src={imgUnion3} />
        </div>
      </div>
    </div>
  )
}

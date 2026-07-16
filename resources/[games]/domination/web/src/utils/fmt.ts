/** Inteiro com separador de milhar por ponto (ex.: 1234567 -> "1.234.567"). */
export function fmtInt(n: number | string | undefined | null): string {
  const v = Math.floor(Number(n) || 0)
  return v.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
}

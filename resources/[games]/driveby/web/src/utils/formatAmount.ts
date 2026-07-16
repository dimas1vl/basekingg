export function formatAmount(value: number, options: {
  decimals?: number;
  showZeroDecimals?: boolean;
  currency?: string;
  compact?: boolean;
} = {}): string {
  const {
    decimals = 1,
    showZeroDecimals = false,
    currency = '',
    compact = true
  } = options;

  if (value === 0) return `${currency}0`;

  const abs = Math.abs(value);
  const sign = value < 0 ? '-' : '';

  const thresholds = [
    { value: 1000000000, abbr: 'b' },
    { value: 1000000, abbr: 'm' },
    { value: 1000, abbr: 'k' }
  ];

  if (compact) {
    for (const { value: threshold, abbr } of thresholds) {
      if (abs >= threshold) {
        const formatted = (abs / threshold).toFixed(decimals);
        return sign + currency + (showZeroDecimals ? formatted : formatted.replace(/\.0$/, '')) + abbr;
      }
    }
  }

  const formatted = abs.toFixed(decimals);
  return sign + currency + (showZeroDecimals ? formatted : formatted.replace(/\.0$/, ''));
}
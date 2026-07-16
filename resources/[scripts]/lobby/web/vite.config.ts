import react from '@vitejs/plugin-react'
import * as path from 'path'
import { defineConfig } from 'vite'
import tsconfigPaths from 'vite-tsconfig-paths'

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  base: './',
  build: {
    outDir: 'build',
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
      modules: path.resolve(__dirname, './src/modules'),
      '@inventario': path.resolve(__dirname, '../../lobby_inventory/web/src'),
      // Force bare imports (react, lucide-react, etc.) coming from the
      // @inventario alias to resolve against the lobby's node_modules so the
      // inventario resource does not need its own duplicated dependencies.
      react: path.resolve(__dirname, './node_modules/react'),
      'react-dom': path.resolve(__dirname, './node_modules/react-dom'),
      'lucide-react': path.resolve(__dirname, './node_modules/lucide-react'),
    },
  },
})

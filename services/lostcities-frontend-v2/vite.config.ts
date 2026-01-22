import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueJsx from '@vitejs/plugin-vue-jsx'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueJsx(),
    vueDevTools(),
  ],
  define: {
    global: {},
  },
  server: {
    proxy: {
      '^/api/accounts': {
        target: `http://localhost:8080`,
        changeOrigin: true,

      },
      '^/api/matches': {
        target: `http://localhost:8081`,
        changeOrigin: true,

      },
      '^/api/gamestate': {
        target: `http://localhost:8082`,
        changeOrigin: true,

      },
      '^/api/player-events': {
        target: `http://localhost:8083`,
        changeOrigin: true,
        ws: true
      }
    }
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    },
  },
})

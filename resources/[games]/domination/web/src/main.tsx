import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter } from 'react-router-dom'
import App from './app'
import { VisibilityProvider } from './providers/Visibility'
import { startDevMocks } from './dev/devMocks'
import './styles/global.css'
import './styles/domination.css'

// Pré-visualização no browser (yarn dev). No jogo isto é no-op.
startDevMocks()

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      refetchOnReconnect: false,
      refetchOnMount: false,
    },
  },
})

ReactDOM.createRoot(document.getElementById('root')!).render(
  <QueryClientProvider client={queryClient}>
    <BrowserRouter>
      <VisibilityProvider>
        <App />
      </VisibilityProvider>
    </BrowserRouter>
  </QueryClientProvider>,
)

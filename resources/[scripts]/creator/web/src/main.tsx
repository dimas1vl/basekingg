import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter } from 'react-router-dom'
import App from './app'
import { VisibilityProvider } from './providers/Visibility'
import { debugData } from './utils/debugData'
import './styles/global.css'

debugData([{ event: 'show', data: true }])

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      refetchOnReconnect: false,
      refetchOnMount: false,
    },
  },
})

console.log('oi')

ReactDOM.createRoot(document.getElementById('root')!).render(
  <QueryClientProvider client={queryClient}>
    <BrowserRouter>
      <VisibilityProvider>
        <App />
      </VisibilityProvider>
    </BrowserRouter>
  </QueryClientProvider>,
)

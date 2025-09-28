import axios from 'axios'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:3001',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
})

api.interceptors.request.use(
  (config) => {
    // Add userId to all requests
    const userId = localStorage.getItem('userId') || 'default-user'
    if (config.method === 'post' || config.method === 'get') {
      if (config.method === 'post') {
        config.data = { ...config.data, userId }
      } else {
        config.params = { ...config.params, userId }
      }
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error.response?.data || error.message)
    return Promise.reject(error)
  }
)

export default api

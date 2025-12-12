import api from './index'

export const authApi = {
  register: (data) => api.post('/auth/register', data),
  login: (data) => api.post('/auth/login', data),
  oauth: (provider, data) => api.post(`/auth/oauth/${provider}`, data)
}


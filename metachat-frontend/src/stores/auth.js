import { defineStore } from 'pinia'
import { authApi } from '@/api/auth'
import { usersApi } from '@/api/users'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    user: null,
    token: localStorage.getItem('token') || null,
    isAuthenticated: false
  }),

  getters: {
    userId: (state) => state.user?.id,
    userName: (state) => state.user?.username || state.user?.first_name || 'Пользователь'
  },

  actions: {
    async login(credentials) {
      try {
        const response = await authApi.login(credentials)
        const { token, id, ...userData } = response.data
        
        this.token = token
        this.user = { id, ...userData }
        this.isAuthenticated = true
        
        localStorage.setItem('token', token)
        localStorage.setItem('user', JSON.stringify(this.user))
        
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка входа' 
        }
      }
    },

    async register(userData) {
      try {
        const response = await authApi.register(userData)
        const { token, id, ...user } = response.data
        
        this.token = token
        this.user = { id, ...user }
        this.isAuthenticated = true
        
        localStorage.setItem('token', token)
        localStorage.setItem('user', JSON.stringify(this.user))
        
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка регистрации' 
        }
      }
    },

    async checkAuth() {
      try {
        const storedUser = localStorage.getItem('user')
        if (storedUser) {
          this.user = JSON.parse(storedUser)
          this.isAuthenticated = true
          
          const userId = this.user.id
          if (userId) {
            const response = await usersApi.getUser(userId)
            this.user = response.data
            localStorage.setItem('user', JSON.stringify(this.user))
          }
        }
      } catch (error) {
        this.logout()
      }
    },

    logout() {
      this.user = null
      this.token = null
      this.isAuthenticated = false
      localStorage.removeItem('token')
      localStorage.removeItem('user')
    }
  }
})


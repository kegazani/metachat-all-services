import { defineStore } from 'pinia'
import { matchesApi } from '@/api/matches'

export const useMatchesStore = defineStore('matches', {
  state: () => ({
    matchRequests: [],
    loading: false
  }),

  actions: {
    async fetchUserMatchRequests(userId, status = '') {
      this.loading = true
      try {
        const response = await matchesApi.getUserMatchRequests(userId, { status })
        this.matchRequests = response.data.requests || response.data || []
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка загрузки запросов' 
        }
      } finally {
        this.loading = false
      }
    },

    async createMatchRequest(data) {
      this.loading = true
      try {
        const response = await matchesApi.createMatchRequest(data)
        this.matchRequests.push(response.data)
        return { success: true, data: response.data }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка создания запроса' 
        }
      } finally {
        this.loading = false
      }
    },

    async acceptMatchRequest(requestId, userId) {
      this.loading = true
      try {
        const response = await matchesApi.acceptMatchRequest(requestId, userId)
        const index = this.matchRequests.findIndex(r => r.id === requestId)
        if (index !== -1) {
          this.matchRequests[index] = response.data
        }
        return { success: true, data: response.data }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка принятия запроса' 
        }
      } finally {
        this.loading = false
      }
    },

    async rejectMatchRequest(requestId, userId) {
      this.loading = true
      try {
        const response = await matchesApi.rejectMatchRequest(requestId, userId)
        const index = this.matchRequests.findIndex(r => r.id === requestId)
        if (index !== -1) {
          this.matchRequests[index] = response.data
        }
        return { success: true, data: response.data }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка отклонения запроса' 
        }
      } finally {
        this.loading = false
      }
    },

    async cancelMatchRequest(requestId, userId) {
      this.loading = true
      try {
        await matchesApi.cancelMatchRequest(requestId, userId)
        this.matchRequests = this.matchRequests.filter(r => r.id !== requestId)
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка отмены запроса' 
        }
      } finally {
        this.loading = false
      }
    }
  }
})


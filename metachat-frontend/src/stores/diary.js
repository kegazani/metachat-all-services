import { defineStore } from 'pinia'
import { diaryApi } from '@/api/diary'
import { useAuthStore } from './auth'

export const useDiaryStore = defineStore('diary', {
  state: () => ({
    entries: [],
    currentEntry: null,
    sessions: [],
    currentSession: null,
    analytics: null,
    loading: false
  }),

  actions: {
    async fetchEntries(userId, params = {}) {
      this.loading = true
      try {
        const response = await diaryApi.getUserEntries(userId, {
          page: params.page || 1,
          limit: params.limit || 20
        })
        this.entries = response.data.entries || response.data || []
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка загрузки записей' 
        }
      } finally {
        this.loading = false
      }
    },

    async fetchEntry(id) {
      this.loading = true
      try {
        const response = await diaryApi.getEntry(id)
        this.currentEntry = response.data
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка загрузки записи' 
        }
      } finally {
        this.loading = false
      }
    },

    async createEntry(data) {
      this.loading = true
      try {
        const authStore = useAuthStore()
        const response = await diaryApi.createEntry({
          ...data,
          user_id: authStore.userId
        })
        this.entries.unshift(response.data)
        return { success: true, data: response.data }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка создания записи' 
        }
      } finally {
        this.loading = false
      }
    },

    async updateEntry(id, data) {
      this.loading = true
      try {
        const response = await diaryApi.updateEntry(id, data)
        const index = this.entries.findIndex(e => e.id === id)
        if (index !== -1) {
          this.entries[index] = response.data
        }
        if (this.currentEntry?.id === id) {
          this.currentEntry = response.data
        }
        return { success: true, data: response.data }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка обновления записи' 
        }
      } finally {
        this.loading = false
      }
    },

    async deleteEntry(id) {
      this.loading = true
      try {
        await diaryApi.deleteEntry(id)
        this.entries = this.entries.filter(e => e.id !== id)
        if (this.currentEntry?.id === id) {
          this.currentEntry = null
        }
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка удаления записи' 
        }
      } finally {
        this.loading = false
      }
    },

    async fetchAnalytics() {
      try {
        const response = await diaryApi.getAnalytics()
        this.analytics = response.data
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка загрузки аналитики' 
        }
      }
    }
  }
})


import { defineStore } from 'pinia'
import { chatApi } from '@/api/chat'
import { useAuthStore } from './auth'

export const useChatStore = defineStore('chat', {
  state: () => ({
    chats: [],
    currentChat: null,
    messages: {},
    loading: false
  }),

  actions: {
    async fetchUserChats(userId) {
      this.loading = true
      try {
        const response = await chatApi.getUserChats(userId)
        this.chats = response.data || []
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка загрузки чатов' 
        }
      } finally {
        this.loading = false
      }
    },

    async fetchChat(chatId) {
      this.loading = true
      try {
        const response = await chatApi.getChat(chatId)
        this.currentChat = response.data
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка загрузки чата' 
        }
      } finally {
        this.loading = false
      }
    },

    async fetchMessages(chatId, params = {}) {
      try {
        const response = await chatApi.getMessages(chatId, {
          limit: params.limit || 50,
          before_message_id: params.before_message_id
        })
        if (!this.messages[chatId]) {
          this.messages[chatId] = []
        }
        this.messages[chatId] = response.data.messages || response.data || []
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка загрузки сообщений' 
        }
      }
    },

    async sendMessage(chatId, content) {
      try {
        const authStore = useAuthStore()
        const response = await chatApi.sendMessage(chatId, {
          sender_id: authStore.userId,
          content
        })
        if (!this.messages[chatId]) {
          this.messages[chatId] = []
        }
        this.messages[chatId].push(response.data)
        return { success: true, data: response.data }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка отправки сообщения' 
        }
      }
    },

    async createChat(userId1, userId2) {
      try {
        const response = await chatApi.createChat({ user_id1: userId1, user_id2: userId2 })
        this.chats.push(response.data)
        return { success: true, data: response.data }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка создания чата' 
        }
      }
    },

    async markAsRead(chatId, userId) {
      try {
        await chatApi.markAsRead(chatId, userId)
        return { success: true }
      } catch (error) {
        return { 
          success: false, 
          error: error.response?.data?.message || 'Ошибка отметки прочитанным' 
        }
      }
    }
  }
})


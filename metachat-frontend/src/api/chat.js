import api from './index'

export const chatApi = {
  createChat: (data) => api.post('/chats', data),
  getChat: (chatId) => api.get(`/chats/${chatId}`),
  getUserChats: (userId) => api.get(`/chats/user/${userId}`),
  sendMessage: (chatId, data) => api.post(`/chats/${chatId}/messages`, data),
  getMessages: (chatId, params) => api.get(`/chats/${chatId}/messages`, { params }),
  markAsRead: (chatId, userId) => api.put(`/chats/${chatId}/messages/read`, null, { params: { user_id: userId } })
}


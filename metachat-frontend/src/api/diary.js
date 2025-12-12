import api from './index'

export const diaryApi = {
  createEntry: (data) => api.post('/diary/entries', data),
  getEntry: (id) => api.get(`/diary/entries/${id}`),
  updateEntry: (id, data) => api.put(`/diary/entries/${id}`, data),
  deleteEntry: (id) => api.delete(`/diary/entries/${id}`),
  getUserEntries: (userId, params) => api.get(`/diary/entries/user/${userId}`, { params }),
  startSession: (data) => api.post('/diary/sessions', data),
  getSession: (id) => api.get(`/diary/sessions/${id}`),
  endSession: (id) => api.put(`/diary/sessions/${id}/end`),
  getUserSessions: (userId, params) => api.get(`/diary/sessions/user/${userId}`, { params }),
  getAnalytics: () => api.get('/diary/analytics')
}


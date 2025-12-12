import api from './index'

export const matchesApi = {
  createMatchRequest: (data) => api.post('/match-requests', data),
  getUserMatchRequests: (userId, params) => api.get(`/match-requests/user/${userId}`, { params }),
  getMatchRequest: (requestId) => api.get(`/match-requests/${requestId}`),
  acceptMatchRequest: (requestId, userId) => api.put(`/match-requests/${requestId}/accept`, null, { params: { user_id: userId } }),
  rejectMatchRequest: (requestId, userId) => api.put(`/match-requests/${requestId}/reject`, null, { params: { user_id: userId } }),
  cancelMatchRequest: (requestId, userId) => api.delete(`/match-requests/${requestId}`, { params: { user_id: userId } })
}


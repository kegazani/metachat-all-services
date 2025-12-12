import api from './index'

export const usersApi = {
  getUser: (id) => api.get(`/users/${id}`),
  updateProfile: (id, data) => api.put(`/users/${id}`, data),
  getProfileProgress: (id) => api.get(`/users/${id}/profile-progress`),
  getStatistics: (id) => api.get(`/users/${id}/statistics`),
  assignArchetype: (id, data) => api.post(`/users/${id}/archetype`, data),
  updateArchetype: (id, data) => api.put(`/users/${id}/archetype`, data),
  updateModalities: (id, data) => api.put(`/users/${id}/modalities`, data),
  getCommonTopics: (id1, id2) => api.get(`/users/${id1}/common-topics/${id2}`)
}


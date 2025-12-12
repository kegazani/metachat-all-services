<template>
  <div class="matches-page">
    <el-card>
      <template #header>
        <div class="header-actions">
          <h3>Запросы на общение</h3>
          <el-radio-group v-model="statusFilter" @change="handleFilterChange">
            <el-radio-button label="">Все</el-radio-button>
            <el-radio-button label="pending">Ожидают</el-radio-button>
            <el-radio-button label="accepted">Приняты</el-radio-button>
            <el-radio-button label="rejected">Отклонены</el-radio-button>
          </el-radio-group>
        </div>
      </template>

      <el-loading v-loading="matchesStore.loading" />

      <div v-if="matchesStore.matchRequests.length === 0 && !matchesStore.loading" class="empty-state">
        <el-empty description="Нет запросов на общение" />
      </div>

      <div v-else class="matches-list">
        <el-card
          v-for="request in matchesStore.matchRequests"
          :key="request.id"
          class="match-card"
          :class="{
            'match-pending': request.status === 'pending',
            'match-accepted': request.status === 'accepted',
            'match-rejected': request.status === 'rejected'
          }"
        >
          <div class="match-content">
            <div class="match-info">
              <div class="match-user">
                <el-avatar :size="50">
                  {{ getOtherUserName(request).charAt(0) }}
                </el-avatar>
                <div class="user-details">
                  <h4>{{ getOtherUserName(request) }}</h4>
                  <el-tag :type="getStatusType(request.status)" size="small">
                    {{ getStatusText(request.status) }}
                  </el-tag>
                </div>
              </div>
              <div v-if="request.similarity" class="similarity">
                <span class="similarity-label">Совпадение:</span>
                <el-progress
                  :percentage="request.similarity * 100"
                  :status="request.similarity > 0.7 ? 'success' : request.similarity > 0.5 ? 'warning' : ''"
                />
              </div>
              <div v-if="request.common_topics?.length" class="common-topics">
                <span class="topics-label">Общие темы:</span>
                <el-tag
                  v-for="topic in request.common_topics.slice(0, 5)"
                  :key="topic"
                  size="small"
                  style="margin-right: 4px"
                >
                  {{ topic }}
                </el-tag>
              </div>
            </div>
            <div class="match-actions">
              <template v-if="request.status === 'pending' && isIncomingRequest(request)">
                <el-button type="success" @click="handleAccept(request.id)">
                  Принять
                </el-button>
                <el-button type="danger" @click="handleReject(request.id)">
                  Отклонить
                </el-button>
              </template>
              <template v-else-if="request.status === 'pending' && !isIncomingRequest(request)">
                <el-button type="danger" @click="handleCancel(request.id)">
                  Отменить
                </el-button>
              </template>
              <template v-else-if="request.status === 'accepted'">
                <el-button type="primary" @click="openChat(request)">
                  Открыть чат
                </el-button>
              </template>
            </div>
          </div>
        </el-card>
      </div>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useMatchesStore } from '@/stores/matches'
import { useChatStore } from '@/stores/chat'
import { ElMessage } from 'element-plus'

const router = useRouter()
const authStore = useAuthStore()
const matchesStore = useMatchesStore()
const chatStore = useChatStore()

const statusFilter = ref('')

const getOtherUserName = (request) => {
  if (request.from_user_id === authStore.userId) {
    return request.to_user?.username || request.to_user?.first_name || 'Пользователь'
  }
  return request.from_user?.username || request.from_user?.first_name || 'Пользователь'
}

const isIncomingRequest = (request) => {
  return request.to_user_id === authStore.userId
}

const getStatusType = (status) => {
  const types = {
    pending: 'warning',
    accepted: 'success',
    rejected: 'danger'
  }
  return types[status] || ''
}

const getStatusText = (status) => {
  const texts = {
    pending: 'Ожидает',
    accepted: 'Принят',
    rejected: 'Отклонен'
  }
  return texts[status] || status
}

const handleFilterChange = async () => {
  await matchesStore.fetchUserMatchRequests(authStore.userId, statusFilter.value)
}

const handleAccept = async (requestId) => {
  const result = await matchesStore.acceptMatchRequest(requestId, authStore.userId)
  if (result.success) {
    ElMessage.success('Запрос принят')
    const request = matchesStore.matchRequests.find(r => r.id === requestId)
    if (request) {
      await openChat(request)
    }
  } else {
    ElMessage.error(result.error || 'Ошибка принятия запроса')
  }
}

const handleReject = async (requestId) => {
  const result = await matchesStore.rejectMatchRequest(requestId, authStore.userId)
  if (result.success) {
    ElMessage.success('Запрос отклонен')
  } else {
    ElMessage.error(result.error || 'Ошибка отклонения запроса')
  }
}

const handleCancel = async (requestId) => {
  const result = await matchesStore.cancelMatchRequest(requestId, authStore.userId)
  if (result.success) {
    ElMessage.success('Запрос отменен')
  } else {
    ElMessage.error(result.error || 'Ошибка отмены запроса')
  }
}

const openChat = async (request) => {
  const otherUserId = request.from_user_id === authStore.userId
    ? request.to_user_id
    : request.from_user_id

  let chat = chatStore.chats.find(c =>
    (c.user_id1 === authStore.userId && c.user_id2 === otherUserId) ||
    (c.user_id2 === authStore.userId && c.user_id1 === otherUserId)
  )

  if (!chat) {
    const result = await chatStore.createChat(authStore.userId, otherUserId)
    if (result.success) {
      chat = result.data
    }
  }

  if (chat) {
    router.push(`/chat/${chat.id}`)
  }
}

onMounted(async () => {
  await matchesStore.fetchUserMatchRequests(authStore.userId, statusFilter.value)
})
</script>

<style scoped>
.matches-page {
  max-width: 1200px;
  margin: 0 auto;
}

.header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-actions h3 {
  margin: 0;
}

.empty-state {
  padding: 60px 0;
  text-align: center;
}

.matches-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.match-card {
  transition: all 0.2s;
}

.match-card:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
}

.match-content {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 20px;
}

.match-info {
  flex: 1;
}

.match-user {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
}

.user-details h4 {
  margin: 0 0 4px 0;
  color: #303133;
}

.similarity {
  margin: 12px 0;
}

.similarity-label {
  display: block;
  font-size: 12px;
  color: #909399;
  margin-bottom: 4px;
}

.common-topics {
  margin-top: 12px;
}

.topics-label {
  display: block;
  font-size: 12px;
  color: #909399;
  margin-bottom: 8px;
}

.match-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
</style>


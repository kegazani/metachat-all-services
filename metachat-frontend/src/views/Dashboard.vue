<template>
  <div class="dashboard">
    <el-row :gutter="20">
      <el-col :span="24">
        <el-card>
          <template #header>
            <h3>Добро пожаловать, {{ userName }}!</h3>
          </template>
          <p>Это ваша главная страница MetaChat. Здесь вы можете управлять дневником, находить собеседников и общаться.</p>
        </el-card>
      </el-col>
    </el-row>
    
    <el-row :gutter="20" style="margin-top: 20px">
      <el-col :span="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon :size="40" color="#409EFF"><Document /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ diaryCount }}</div>
              <div class="stat-label">Записей в дневнике</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon :size="40" color="#67C23A"><UserFilled /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ matchesCount }}</div>
              <div class="stat-label">Активных матчей</div>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card class="stat-card">
          <div class="stat-content">
            <el-icon :size="40" color="#E6A23C"><ChatLineRound /></el-icon>
            <div class="stat-info">
              <div class="stat-value">{{ chatsCount }}</div>
              <div class="stat-label">Активных чатов</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top: 20px">
      <el-col :span="12">
        <el-card>
          <template #header>
            <h4>Последние записи</h4>
          </template>
          <div v-if="recentEntries.length === 0" class="empty-state">
            <p>Пока нет записей</p>
            <el-button type="primary" @click="$router.push('/diary')">
              Создать запись
            </el-button>
          </div>
          <div v-else>
            <div
              v-for="entry in recentEntries"
              :key="entry.id"
              class="entry-item"
              @click="$router.push(`/diary/${entry.id}`)"
            >
              <h5>{{ entry.title || 'Без названия' }}</h5>
              <p class="entry-preview">{{ entry.content?.substring(0, 100) }}...</p>
              <span class="entry-date">{{ formatDate(entry.created_at) }}</span>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <template #header>
            <h4>Быстрые действия</h4>
          </template>
          <div class="quick-actions">
            <el-button type="primary" size="large" @click="$router.push('/diary')">
              <el-icon><Edit /></el-icon>
              Новая запись
            </el-button>
            <el-button type="success" size="large" @click="$router.push('/matches')">
              <el-icon><Search /></el-icon>
              Найти собеседника
            </el-button>
            <el-button type="info" size="large" @click="$router.push('/analytics')">
              <el-icon><DataAnalysis /></el-icon>
              Аналитика
            </el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useDiaryStore } from '@/stores/diary'
import { useChatStore } from '@/stores/chat'
import { useMatchesStore } from '@/stores/matches'
import {
  Document,
  UserFilled,
  ChatLineRound,
  Edit,
  Search,
  DataAnalysis
} from '@element-plus/icons-vue'

const authStore = useAuthStore()
const diaryStore = useDiaryStore()
const chatStore = useChatStore()
const matchesStore = useMatchesStore()

const userName = computed(() => authStore.userName)
const diaryCount = ref(0)
const matchesCount = ref(0)
const chatsCount = ref(0)
const recentEntries = ref([])

const formatDate = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleDateString('ru-RU', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

onMounted(async () => {
  const userId = authStore.userId
  if (userId) {
    await Promise.all([
      diaryStore.fetchEntries(userId).then(() => {
        diaryCount.value = diaryStore.entries.length
        recentEntries.value = diaryStore.entries.slice(0, 5)
      }),
      chatStore.fetchUserChats(userId).then(() => {
        chatsCount.value = chatStore.chats.length
      }),
      matchesStore.fetchUserMatchRequests(userId, 'accepted').then(() => {
        matchesCount.value = matchesStore.matchRequests.length
      })
    ])
  }
})
</script>

<style scoped>
.dashboard {
  max-width: 1200px;
  margin: 0 auto;
}

.stat-card {
  cursor: pointer;
  transition: transform 0.2s;
}

.stat-card:hover {
  transform: translateY(-4px);
}

.stat-content {
  display: flex;
  align-items: center;
  gap: 20px;
}

.stat-info {
  flex: 1;
}

.stat-value {
  font-size: 32px;
  font-weight: 600;
  color: #303133;
}

.stat-label {
  font-size: 14px;
  color: #909399;
  margin-top: 4px;
}

.empty-state {
  text-align: center;
  padding: 40px 0;
}

.entry-item {
  padding: 16px;
  border-bottom: 1px solid #ebeef5;
  cursor: pointer;
  transition: background-color 0.2s;
}

.entry-item:hover {
  background-color: #f5f7fa;
}

.entry-item:last-child {
  border-bottom: none;
}

.entry-item h5 {
  margin: 0 0 8px 0;
  color: #303133;
  font-size: 16px;
}

.entry-preview {
  color: #606266;
  font-size: 14px;
  margin: 8px 0;
  line-height: 1.5;
}

.entry-date {
  font-size: 12px;
  color: #909399;
}

.quick-actions {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.quick-actions .el-button {
  justify-content: flex-start;
}
</style>


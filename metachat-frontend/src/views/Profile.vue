<template>
  <div class="profile-page">
    <el-row :gutter="20">
      <el-col :span="8">
        <el-card>
          <div class="profile-header">
            <el-avatar :size="120" :src="user?.avatar">
              {{ userName.charAt(0) }}
            </el-avatar>
            <h2>{{ userName }}</h2>
            <p v-if="user?.email" class="user-email">{{ user.email }}</p>
          </div>
        </el-card>

        <el-card style="margin-top: 20px">
          <template #header>
            <h4>Статистика</h4>
          </template>
          <div v-if="statistics" class="statistics">
            <div class="stat-item">
              <span class="stat-label">Записей в дневнике</span>
              <span class="stat-value">{{ statistics.diary_entries_count || 0 }}</span>
            </div>
            <div class="stat-item">
              <span class="stat-label">Активных матчей</span>
              <span class="stat-value">{{ statistics.active_matches || 0 }}</span>
            </div>
            <div class="stat-item">
              <span class="stat-label">Сообщений отправлено</span>
              <span class="stat-value">{{ statistics.messages_sent || 0 }}</span>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :span="16">
        <el-card>
          <template #header>
            <h3>Редактировать профиль</h3>
          </template>
          <el-form ref="formRef" :model="form" label-width="140px">
            <el-form-item label="Имя">
              <el-input v-model="form.first_name" />
            </el-form-item>
            <el-form-item label="Фамилия">
              <el-input v-model="form.last_name" />
            </el-form-item>
            <el-form-item label="Дата рождения">
              <el-date-picker
                v-model="form.date_of_birth"
                type="date"
                format="YYYY-MM-DD"
                value-format="YYYY-MM-DD"
                style="width: 100%"
              />
            </el-form-item>
            <el-form-item label="Биография">
              <el-input
                v-model="form.bio"
                type="textarea"
                :rows="4"
                placeholder="Расскажите о себе..."
              />
            </el-form-item>
            <el-form-item label="Аватар URL">
              <el-input v-model="form.avatar" placeholder="URL изображения" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="saving" @click="handleSave">
                Сохранить изменения
              </el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <el-card v-if="profileProgress" style="margin-top: 20px">
          <template #header>
            <h4>Прогресс профиля</h4>
          </template>
          <div class="progress-info">
            <el-progress
              :percentage="profileProgress.completion_percentage || 0"
              :status="profileProgress.completion_percentage === 100 ? 'success' : ''"
            />
            <p class="progress-text">
              {{ profileProgress.completion_percentage || 0 }}% профиля заполнено
            </p>
            <div v-if="profileProgress.personality_calculated" class="personality-status">
              <el-tag type="success">Личность рассчитана</el-tag>
            </div>
            <div v-else class="personality-status">
              <el-tag type="warning">Личность еще не рассчитана</el-tag>
              <p class="hint">Нужно больше записей в дневнике для расчета личности</p>
            </div>
          </div>
        </el-card>

        <el-card v-if="user?.big_five" style="margin-top: 20px">
          <template #header>
            <h4>Личность (Big Five)</h4>
          </template>
          <div class="big-five">
            <div class="trait" v-for="(value, trait) in user.big_five" :key="trait">
              <div class="trait-header">
                <span class="trait-name">{{ getTraitName(trait) }}</span>
                <span class="trait-value">{{ (value * 100).toFixed(0) }}%</span>
              </div>
              <el-progress :percentage="value * 100" />
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { usersApi } from '@/api/users'
import { ElMessage } from 'element-plus'

const authStore = useAuthStore()
const formRef = ref(null)
const saving = ref(false)

const user = computed(() => authStore.user)
const userName = computed(() => authStore.userName)
const statistics = ref(null)
const profileProgress = ref(null)

const form = reactive({
  first_name: '',
  last_name: '',
  date_of_birth: '',
  bio: '',
  avatar: ''
})

const getTraitName = (trait) => {
  const names = {
    openness: 'Открытость',
    conscientiousness: 'Добросовестность',
    extraversion: 'Экстраверсия',
    agreeableness: 'Доброжелательность',
    neuroticism: 'Нейротизм'
  }
  return names[trait] || trait
}

const handleSave = async () => {
  saving.value = true
  try {
    await usersApi.updateProfile(authStore.userId, form)
    await authStore.checkAuth()
    ElMessage.success('Профиль обновлен')
  } catch (error) {
    ElMessage.error(error.response?.data?.message || 'Ошибка обновления профиля')
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  const userId = authStore.userId
  if (userId) {
    if (user.value) {
      form.first_name = user.value.first_name || ''
      form.last_name = user.value.last_name || ''
      form.date_of_birth = user.value.date_of_birth || ''
      form.bio = user.value.bio || ''
      form.avatar = user.value.avatar || ''
    }

    try {
      const [statsRes, progressRes] = await Promise.all([
        usersApi.getStatistics(userId),
        usersApi.getProfileProgress(userId)
      ])
      statistics.value = statsRes.data
      profileProgress.value = progressRes.data
    } catch (error) {
      console.error('Ошибка загрузки данных профиля:', error)
    }
  }
})
</script>

<style scoped>
.profile-page {
  max-width: 1200px;
  margin: 0 auto;
}

.profile-header {
  text-align: center;
  padding: 20px 0;
}

.profile-header h2 {
  margin: 16px 0 8px 0;
  color: #303133;
}

.user-email {
  color: #909399;
  font-size: 14px;
}

.statistics {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 0;
  border-bottom: 1px solid #ebeef5;
}

.stat-item:last-child {
  border-bottom: none;
}

.stat-label {
  color: #606266;
  font-size: 14px;
}

.stat-value {
  font-size: 20px;
  font-weight: 600;
  color: #303133;
}

.progress-info {
  padding: 20px 0;
}

.progress-text {
  margin: 12px 0;
  color: #606266;
  font-size: 14px;
}

.personality-status {
  margin-top: 16px;
}

.hint {
  margin-top: 8px;
  font-size: 12px;
  color: #909399;
}

.big-five {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.trait {
  padding: 12px 0;
}

.trait-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}

.trait-name {
  font-weight: 500;
  color: #303133;
}

.trait-value {
  color: #606266;
  font-size: 14px;
}
</style>


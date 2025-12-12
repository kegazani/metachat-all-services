<template>
  <div class="analytics-page">
    <el-card>
      <template #header>
        <h3>Аналитика дневника</h3>
      </template>

      <el-loading v-loading="loading" />

      <div v-if="analytics" class="analytics-content">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-card>
              <template #header>
                <h4>Эмоциональный профиль</h4>
              </template>
              <div v-if="analytics.emotion_distribution" class="emotion-chart">
                <div
                  v-for="(value, emotion) in analytics.emotion_distribution"
                  :key="emotion"
                  class="emotion-item"
                >
                  <div class="emotion-header">
                    <span class="emotion-name">{{ getEmotionName(emotion) }}</span>
                    <span class="emotion-value">{{ (value * 100).toFixed(1) }}%</span>
                  </div>
                  <el-progress :percentage="value * 100" />
                </div>
              </div>
            </el-card>
          </el-col>

          <el-col :span="12">
            <el-card>
              <template #header>
                <h4>Популярные темы</h4>
              </template>
              <div v-if="analytics.top_topics?.length" class="topics-list">
                <el-tag
                  v-for="(topic, index) in analytics.top_topics"
                  :key="topic.topic || index"
                  size="large"
                  style="margin: 4px"
                >
                  {{ topic.topic }} ({{ topic.frequency }})
                </el-tag>
              </div>
              <el-empty v-else description="Недостаточно данных" />
            </el-card>
          </el-col>
        </el-row>

        <el-row :gutter="20" style="margin-top: 20px">
          <el-col :span="24">
            <el-card>
              <template #header>
                <h4>Статистика записей</h4>
              </template>
              <div class="stats-grid">
                <div class="stat-box">
                  <div class="stat-value">{{ analytics.total_entries || 0 }}</div>
                  <div class="stat-label">Всего записей</div>
                </div>
                <div class="stat-box">
                  <div class="stat-value">{{ analytics.avg_tokens_per_entry?.toFixed(0) || 0 }}</div>
                  <div class="stat-label">Среднее токенов на запись</div>
                </div>
                <div class="stat-box">
                  <div class="stat-value">{{ analytics.total_tokens || 0 }}</div>
                  <div class="stat-label">Всего токенов</div>
                </div>
                <div class="stat-box">
                  <div class="stat-value">{{ analytics.entries_this_month || 0 }}</div>
                  <div class="stat-label">Записей в этом месяце</div>
                </div>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </div>

      <el-empty v-else description="Недостаточно данных для аналитики" />
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useDiaryStore } from '@/stores/diary'

const diaryStore = useDiaryStore()
const loading = ref(false)
const analytics = ref(null)

const getEmotionName = (emotion) => {
  const names = {
    joy: 'Радость',
    trust: 'Доверие',
    fear: 'Страх',
    surprise: 'Удивление',
    sadness: 'Грусть',
    disgust: 'Отвращение',
    anger: 'Гнев',
    anticipation: 'Предвкушение'
  }
  return names[emotion] || emotion
}

onMounted(async () => {
  loading.value = true
  const result = await diaryStore.fetchAnalytics()
  loading.value = false
  
  if (result.success) {
    analytics.value = diaryStore.analytics
  }
})
</script>

<style scoped>
.analytics-page {
  max-width: 1200px;
  margin: 0 auto;
}

.analytics-content {
  padding: 20px 0;
}

.emotion-chart {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.emotion-item {
  padding: 8px 0;
}

.emotion-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 8px;
}

.emotion-name {
  font-weight: 500;
  color: #303133;
  text-transform: capitalize;
}

.emotion-value {
  font-size: 14px;
  color: #606266;
}

.topics-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
  padding: 20px 0;
}

.stat-box {
  text-align: center;
  padding: 20px;
  background: #f5f7fa;
  border-radius: 8px;
}

.stat-value {
  font-size: 32px;
  font-weight: 600;
  color: #409EFF;
  margin-bottom: 8px;
}

.stat-label {
  font-size: 14px;
  color: #909399;
}
</style>


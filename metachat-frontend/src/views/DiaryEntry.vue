<template>
  <div class="diary-entry-page">
    <el-loading v-loading="diaryStore.loading" />
    
    <el-card v-if="diaryStore.currentEntry">
      <template #header>
        <div class="entry-header">
          <h2>{{ diaryStore.currentEntry.title || 'Без названия' }}</h2>
          <div class="header-actions">
            <el-button @click="showEditDialog = true">
              <el-icon><Edit /></el-icon>
              Редактировать
            </el-button>
            <el-button type="danger" @click="handleDelete">
              <el-icon><Delete /></el-icon>
              Удалить
            </el-button>
          </div>
        </div>
      </template>

      <div class="entry-meta">
        <span class="entry-date">{{ formatDate(diaryStore.currentEntry.created_at) }}</span>
        <div v-if="diaryStore.currentEntry.tags?.length" class="entry-tags">
          <el-tag v-for="tag in diaryStore.currentEntry.tags" :key="tag" style="margin-right: 8px">
            {{ tag }}
          </el-tag>
        </div>
      </div>

      <div class="entry-content">
        <p v-html="formatContent(diaryStore.currentEntry.content)"></p>
      </div>

      <div v-if="diaryStore.currentEntry.mood_analysis" class="mood-analysis">
        <el-divider>Анализ настроения</el-divider>
        <div class="mood-info">
          <el-tag type="success" size="large">
            {{ diaryStore.currentEntry.mood_analysis.dominant_emotion }}
          </el-tag>
          <div class="mood-details">
            <p><strong>Валентность:</strong> {{ diaryStore.currentEntry.mood_analysis.valence?.toFixed(2) }}</p>
            <p><strong>Возбуждение:</strong> {{ diaryStore.currentEntry.mood_analysis.arousal?.toFixed(2) }}</p>
          </div>
        </div>
      </div>
    </el-card>

    <el-dialog
      v-model="showEditDialog"
      title="Редактировать запись"
      width="600px"
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="Название" prop="title">
          <el-input v-model="form.title" />
        </el-form-item>
        <el-form-item label="Содержание" prop="content">
          <el-input v-model="form.content" type="textarea" :rows="10" />
        </el-form-item>
        <el-form-item label="Теги">
          <el-select
            v-model="form.tags"
            multiple
            filterable
            allow-create
            style="width: 100%"
          >
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showEditDialog = false">Отмена</el-button>
        <el-button type="primary" :loading="saving" @click="handleUpdate">
          Сохранить
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useDiaryStore } from '@/stores/diary'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Edit, Delete } from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const diaryStore = useDiaryStore()

const showEditDialog = ref(false)
const saving = ref(false)
const formRef = ref(null)

const form = reactive({
  title: '',
  content: '',
  tags: []
})

const rules = {
  title: [
    { required: true, message: 'Введите название', trigger: 'blur' }
  ],
  content: [
    { required: true, message: 'Введите содержание', trigger: 'blur' }
  ]
}

const formatDate = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleDateString('ru-RU', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatContent = (content) => {
  if (!content) return ''
  return content.replace(/\n/g, '<br>')
}

const handleUpdate = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      saving.value = true
      const result = await diaryStore.updateEntry(route.params.id, {
        ...form,
        token_count: form.content.split(/\s+/).length
      })
      saving.value = false
      
      if (result.success) {
        ElMessage.success('Запись обновлена')
        showEditDialog.value = false
      } else {
        ElMessage.error(result.error || 'Ошибка обновления записи')
      }
    }
  })
}

const handleDelete = async () => {
  try {
    await ElMessageBox.confirm(
      'Вы уверены, что хотите удалить эту запись?',
      'Подтверждение',
      {
        confirmButtonText: 'Удалить',
        cancelButtonText: 'Отмена',
        type: 'warning'
      }
    )
    
    const result = await diaryStore.deleteEntry(route.params.id)
    if (result.success) {
      ElMessage.success('Запись удалена')
      router.push('/diary')
    } else {
      ElMessage.error(result.error || 'Ошибка удаления записи')
    }
  } catch {
  }
}

onMounted(async () => {
  await diaryStore.fetchEntry(route.params.id)
  if (diaryStore.currentEntry) {
    form.title = diaryStore.currentEntry.title || ''
    form.content = diaryStore.currentEntry.content || ''
    form.tags = diaryStore.currentEntry.tags || []
  }
})
</script>

<style scoped>
.diary-entry-page {
  max-width: 900px;
  margin: 0 auto;
}

.entry-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.entry-header h2 {
  margin: 0;
  flex: 1;
}

.header-actions {
  display: flex;
  gap: 8px;
}

.entry-meta {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
  padding-bottom: 16px;
  border-bottom: 1px solid #ebeef5;
}

.entry-date {
  color: #909399;
  font-size: 14px;
}

.entry-tags {
  display: flex;
  flex-wrap: wrap;
}

.entry-content {
  line-height: 1.8;
  color: #303133;
  font-size: 16px;
  margin-bottom: 24px;
}

.mood-analysis {
  margin-top: 32px;
  padding-top: 24px;
}

.mood-info {
  display: flex;
  align-items: center;
  gap: 24px;
}

.mood-details {
  flex: 1;
}

.mood-details p {
  margin: 8px 0;
  color: #606266;
}
</style>


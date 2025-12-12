<template>
  <div class="diary-page">
    <el-card>
      <template #header>
        <div class="header-actions">
          <h3>Мой дневник</h3>
          <el-button type="primary" @click="showCreateDialog = true">
            <el-icon><Plus /></el-icon>
            Новая запись
          </el-button>
        </div>
      </template>

      <el-loading v-loading="diaryStore.loading" />

      <div v-if="diaryStore.entries.length === 0 && !diaryStore.loading" class="empty-state">
        <el-empty description="Пока нет записей">
          <el-button type="primary" @click="showCreateDialog = true">
            Создать первую запись
          </el-button>
        </el-empty>
      </div>

      <div v-else class="entries-list">
        <div
          v-for="entry in diaryStore.entries"
          :key="entry.id"
          class="entry-card"
          @click="openEntry(entry.id)"
        >
          <div class="entry-header">
            <h4>{{ entry.title || 'Без названия' }}</h4>
            <div class="entry-actions">
              <el-button
                type="danger"
                size="small"
                text
                @click.stop="handleDelete(entry.id)"
              >
                <el-icon><Delete /></el-icon>
              </el-button>
            </div>
          </div>
          <p class="entry-content">{{ entry.content?.substring(0, 200) }}{{ entry.content?.length > 200 ? '...' : '' }}</p>
          <div class="entry-footer">
            <span class="entry-date">{{ formatDate(entry.created_at) }}</span>
            <el-tag v-if="entry.tags?.length" size="small" v-for="tag in entry.tags.slice(0, 3)" :key="tag" style="margin-left: 8px">
              {{ tag }}
            </el-tag>
          </div>
        </div>
      </div>
    </el-card>

    <el-dialog
      v-model="showCreateDialog"
      title="Новая запись"
      width="600px"
      @close="resetForm"
    >
      <el-form ref="formRef" :model="form" :rules="rules" label-width="100px">
        <el-form-item label="Название" prop="title">
          <el-input v-model="form.title" placeholder="Введите название записи" />
        </el-form-item>
        <el-form-item label="Содержание" prop="content">
          <el-input
            v-model="form.content"
            type="textarea"
            :rows="10"
            placeholder="Расскажите о своих мыслях и переживаниях..."
          />
        </el-form-item>
        <el-form-item label="Теги">
          <el-select
            v-model="form.tags"
            multiple
            filterable
            allow-create
            placeholder="Добавьте теги"
            style="width: 100%"
          >
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showCreateDialog = false">Отмена</el-button>
        <el-button type="primary" :loading="saving" @click="handleCreate">
          Сохранить
        </el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useDiaryStore } from '@/stores/diary'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Delete } from '@element-plus/icons-vue'

const router = useRouter()
const authStore = useAuthStore()
const diaryStore = useDiaryStore()

const showCreateDialog = ref(false)
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
    { required: true, message: 'Введите содержание', trigger: 'blur' },
    { min: 10, message: 'Содержание должно быть не менее 10 символов', trigger: 'blur' }
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

const openEntry = (id) => {
  router.push(`/diary/${id}`)
}

const resetForm = () => {
  form.title = ''
  form.content = ''
  form.tags = []
  if (formRef.value) {
    formRef.value.resetFields()
  }
}

const handleCreate = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      saving.value = true
      const result = await diaryStore.createEntry({
        ...form,
        token_count: form.content.split(/\s+/).length
      })
      saving.value = false
      
      if (result.success) {
        ElMessage.success('Запись создана')
        showCreateDialog.value = false
        resetForm()
      } else {
        ElMessage.error(result.error || 'Ошибка создания записи')
      }
    }
  })
}

const handleDelete = async (id) => {
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
    
    const result = await diaryStore.deleteEntry(id)
    if (result.success) {
      ElMessage.success('Запись удалена')
    } else {
      ElMessage.error(result.error || 'Ошибка удаления записи')
    }
  } catch {
  }
}

onMounted(async () => {
  const userId = authStore.userId
  if (userId) {
    await diaryStore.fetchEntries(userId)
  }
})
</script>

<style scoped>
.diary-page {
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

.entries-list {
  display: grid;
  gap: 16px;
}

.entry-card {
  padding: 20px;
  border: 1px solid #ebeef5;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s;
  background: #fff;
}

.entry-card:hover {
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

.entry-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
}

.entry-header h4 {
  margin: 0;
  color: #303133;
  font-size: 18px;
  flex: 1;
}

.entry-content {
  color: #606266;
  line-height: 1.6;
  margin: 12px 0;
}

.entry-footer {
  display: flex;
  align-items: center;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid #ebeef5;
}

.entry-date {
  font-size: 12px;
  color: #909399;
}
</style>


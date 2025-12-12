<template>
  <div class="auth-container">
    <el-card class="auth-card">
      <template #header>
        <div class="card-header">
          <h2>Регистрация в MetaChat</h2>
        </div>
      </template>
      <el-form
        ref="formRef"
        :model="form"
        :rules="rules"
        label-width="140px"
        @submit.prevent="handleRegister"
      >
        <el-form-item label="Имя пользователя" prop="username">
          <el-input
            v-model="form.username"
            placeholder="Введите имя пользователя"
            size="large"
          />
        </el-form-item>
        <el-form-item label="Email" prop="email">
          <el-input
            v-model="form.email"
            type="email"
            placeholder="Введите email"
            size="large"
          />
        </el-form-item>
        <el-form-item label="Пароль" prop="password">
          <el-input
            v-model="form.password"
            type="password"
            placeholder="Введите пароль"
            size="large"
            show-password
          />
        </el-form-item>
        <el-form-item label="Имя" prop="first_name">
          <el-input
            v-model="form.first_name"
            placeholder="Введите имя"
            size="large"
          />
        </el-form-item>
        <el-form-item label="Фамилия" prop="last_name">
          <el-input
            v-model="form.last_name"
            placeholder="Введите фамилию"
            size="large"
          />
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            :loading="loading"
            @click="handleRegister"
            style="width: 100%"
          >
            Зарегистрироваться
          </el-button>
        </el-form-item>
        <el-form-item>
          <div class="auth-footer">
            <span>Уже есть аккаунт?</span>
            <el-link type="primary" @click="$router.push('/login')">
              Войти
            </el-link>
          </div>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElMessage } from 'element-plus'

const router = useRouter()
const authStore = useAuthStore()

const formRef = ref(null)
const loading = ref(false)

const form = reactive({
  username: '',
  email: '',
  password: '',
  first_name: '',
  last_name: ''
})

const rules = {
  username: [
    { required: true, message: 'Введите имя пользователя', trigger: 'blur' },
    { min: 3, message: 'Имя пользователя должно быть не менее 3 символов', trigger: 'blur' }
  ],
  email: [
    { required: true, message: 'Введите email', trigger: 'blur' },
    { type: 'email', message: 'Введите корректный email', trigger: 'blur' }
  ],
  password: [
    { required: true, message: 'Введите пароль', trigger: 'blur' },
    { min: 6, message: 'Пароль должен быть не менее 6 символов', trigger: 'blur' }
  ],
  first_name: [
    { required: true, message: 'Введите имя', trigger: 'blur' }
  ],
  last_name: [
    { required: true, message: 'Введите фамилию', trigger: 'blur' }
  ]
}

const handleRegister = async () => {
  if (!formRef.value) return
  
  await formRef.value.validate(async (valid) => {
    if (valid) {
      loading.value = true
      const result = await authStore.register(form)
      loading.value = false
      
      if (result.success) {
        ElMessage.success('Регистрация успешна')
        router.push('/')
      } else {
        ElMessage.error(result.error || 'Ошибка регистрации')
      }
    }
  })
}
</script>

<style scoped>
.auth-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.auth-card {
  width: 100%;
  max-width: 500px;
}

.card-header {
  text-align: center;
}

.card-header h2 {
  margin: 0;
  color: #303133;
}

.auth-footer {
  width: 100%;
  display: flex;
  justify-content: center;
  gap: 8px;
  font-size: 14px;
}
</style>


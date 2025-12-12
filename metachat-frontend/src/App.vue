<template>
  <el-config-provider :locale="locale">
    <router-view v-if="isAuthenticated || isAuthPage" />
    <div v-else class="loading-container">
      <el-loading :loading="true" text="Загрузка..." />
    </div>
  </el-config-provider>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { ElConfigProvider, ElLoading } from 'element-plus'
import ru from 'element-plus/dist/locale/ru.mjs'

const route = useRoute()
const authStore = useAuthStore()

const locale = ru

const isAuthPage = computed(() => {
  return route.path === '/login' || route.path === '/register'
})

const isAuthenticated = computed(() => {
  return authStore.isAuthenticated
})

onMounted(async () => {
  const token = localStorage.getItem('token')
  if (token) {
    await authStore.checkAuth()
  }
})
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  background: #f5f7fa;
}

#app {
  min-height: 100vh;
}

.loading-container {
  width: 100vw;
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>


<template>
  <el-container class="main-layout">
    <el-aside width="250px" class="sidebar">
      <div class="logo">
        <h2>MetaChat</h2>
      </div>
      <el-menu
        :default-active="activeMenu"
        router
        class="sidebar-menu"
        background-color="#304156"
        text-color="#bfcbd9"
        active-text-color="#409EFF"
      >
        <el-menu-item index="/">
          <el-icon><House /></el-icon>
          <span>Главная</span>
        </el-menu-item>
        <el-menu-item index="/diary">
          <el-icon><Document /></el-icon>
          <span>Дневник</span>
        </el-menu-item>
        <el-menu-item index="/matches">
          <el-icon><UserFilled /></el-icon>
          <span>Матчи</span>
        </el-menu-item>
        <el-menu-item index="/chat">
          <el-icon><ChatLineRound /></el-icon>
          <span>Чаты</span>
        </el-menu-item>
        <el-menu-item index="/analytics">
          <el-icon><DataAnalysis /></el-icon>
          <span>Аналитика</span>
        </el-menu-item>
        <el-menu-item index="/profile">
          <el-icon><User /></el-icon>
          <span>Профиль</span>
        </el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header class="header">
        <div class="header-content">
          <div class="header-title">
            <h3>{{ pageTitle }}</h3>
          </div>
          <div class="header-actions">
            <el-dropdown @command="handleCommand">
              <span class="user-dropdown">
                <el-avatar :size="32" :src="userAvatar">{{ userName.charAt(0) }}</el-avatar>
                <span class="user-name">{{ userName }}</span>
                <el-icon><ArrowDown /></el-icon>
              </span>
              <template #dropdown>
                <el-dropdown-menu>
                  <el-dropdown-item command="profile">Профиль</el-dropdown-item>
                  <el-dropdown-item command="logout" divided>Выйти</el-dropdown-item>
                </el-dropdown-menu>
              </template>
            </el-dropdown>
          </div>
        </div>
      </el-header>
      <el-main class="main-content">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import {
  House,
  Document,
  UserFilled,
  ChatLineRound,
  DataAnalysis,
  User,
  ArrowDown
} from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const activeMenu = computed(() => route.path)
const userName = computed(() => authStore.userName)
const userAvatar = computed(() => authStore.user?.avatar)

const pageTitle = computed(() => {
  const titles = {
    '/': 'Главная',
    '/diary': 'Дневник',
    '/matches': 'Матчи',
    '/chat': 'Чаты',
    '/analytics': 'Аналитика',
    '/profile': 'Профиль'
  }
  return titles[route.path] || 'MetaChat'
})

const handleCommand = (command) => {
  if (command === 'profile') {
    router.push('/profile')
  } else if (command === 'logout') {
    authStore.logout()
    router.push('/login')
  }
}
</script>

<style scoped>
.main-layout {
  height: 100vh;
}

.sidebar {
  background-color: #304156;
  overflow-y: auto;
}

.logo {
  padding: 20px;
  text-align: center;
  border-bottom: 1px solid #434a55;
}

.logo h2 {
  color: #fff;
  font-size: 24px;
  font-weight: 600;
}

.sidebar-menu {
  border-right: none;
}

.header {
  background: #fff;
  border-bottom: 1px solid #e4e7ed;
  padding: 0;
  height: 60px;
  display: flex;
  align-items: center;
}

.header-content {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
}

.header-title h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 500;
  color: #303133;
}

.user-dropdown {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  padding: 4px 12px;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.user-dropdown:hover {
  background-color: #f5f7fa;
}

.user-name {
  font-size: 14px;
  color: #606266;
}

.main-content {
  background: #f5f7fa;
  padding: 20px;
  overflow-y: auto;
}
</style>


<template>
  <div class="chat-page">
    <el-row :gutter="20">
      <el-col :span="6">
        <el-card class="chats-list-card">
          <template #header>
            <h4>Чаты</h4>
          </template>
          <el-loading v-loading="chatStore.loading" />
          <div v-if="chatStore.chats.length === 0" class="empty-chats">
            <p>Нет активных чатов</p>
          </div>
          <div v-else class="chats-list">
            <div
              v-for="chat in chatStore.chats"
              :key="chat.id"
              class="chat-item"
              :class="{ active: currentChatId === chat.id }"
              @click="openChat(chat.id)"
            >
              <el-avatar :size="40">
                {{ getChatUserName(chat).charAt(0) }}
              </el-avatar>
              <div class="chat-info">
                <div class="chat-name">{{ getChatUserName(chat) }}</div>
                <div class="chat-preview">{{ getLastMessage(chat) }}</div>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :span="18">
        <el-card v-if="currentChatId" class="chat-window">
          <template #header>
            <div class="chat-header">
              <h4>{{ getCurrentChatUserName() }}</h4>
            </div>
          </template>

          <div ref="messagesContainer" class="messages-container">
            <div
              v-for="message in messages"
              :key="message.id"
              class="message"
              :class="{ 'message-own': message.sender_id === authStore.userId }"
            >
              <div class="message-content">
                <p>{{ message.content }}</p>
                <span class="message-time">{{ formatTime(message.created_at) }}</span>
              </div>
            </div>
          </div>

          <div class="message-input">
            <el-input
              v-model="newMessage"
              type="textarea"
              :rows="3"
              placeholder="Введите сообщение..."
              @keydown.ctrl.enter="sendMessage"
            />
            <el-button
              type="primary"
              :loading="sending"
              @click="sendMessage"
              style="margin-top: 8px"
            >
              Отправить
            </el-button>
          </div>
        </el-card>

        <el-card v-else class="chat-placeholder">
          <el-empty description="Выберите чат для начала общения" />
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useChatStore } from '@/stores/chat'
import { chatApi } from '@/api/chat'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const chatStore = useChatStore()

const currentChatId = ref(route.params.chatId || null)
const newMessage = ref('')
const sending = ref(false)
const messagesContainer = ref(null)

const messages = computed(() => {
  if (!currentChatId.value) return []
  return chatStore.messages[currentChatId.value] || []
})

const getChatUserName = (chat) => {
  if (chat.user_id1 === authStore.userId) {
    return chat.user2?.username || chat.user2?.first_name || 'Пользователь'
  }
  return chat.user1?.username || chat.user1?.first_name || 'Пользователь'
}

const getCurrentChatUserName = () => {
  if (!currentChatId.value) return ''
  const chat = chatStore.chats.find(c => c.id === currentChatId.value)
  return chat ? getChatUserName(chat) : ''
}

const getLastMessage = (chat) => {
  const chatMessages = chatStore.messages[chat.id]
  if (chatMessages && chatMessages.length > 0) {
    return chatMessages[chatMessages.length - 1].content.substring(0, 50)
  }
  return 'Нет сообщений'
}

const formatTime = (dateString) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleTimeString('ru-RU', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const openChat = async (chatId) => {
  currentChatId.value = chatId
  router.push(`/chat/${chatId}`)
  await chatStore.fetchChat(chatId)
  await chatStore.fetchMessages(chatId)
  await scrollToBottom()
}

const sendMessage = async () => {
  if (!newMessage.value.trim() || !currentChatId.value) return

  sending.value = true
  const result = await chatStore.sendMessage(currentChatId.value, newMessage.value)
  sending.value = false

  if (result.success) {
    newMessage.value = ''
    await scrollToBottom()
    await chatStore.markAsRead(currentChatId.value, authStore.userId)
  }
}

const scrollToBottom = async () => {
  await nextTick()
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight
  }
}

watch(() => route.params.chatId, (newChatId) => {
  if (newChatId) {
    openChat(newChatId)
  } else {
    currentChatId.value = null
  }
})

onMounted(async () => {
  await chatStore.fetchUserChats(authStore.userId)
  if (currentChatId.value) {
    await openChat(currentChatId.value)
  }
})
</script>

<style scoped>
.chat-page {
  max-width: 1400px;
  margin: 0 auto;
  height: calc(100vh - 140px);
}

.chats-list-card {
  height: 100%;
}

.chats-list-card :deep(.el-card__body) {
  padding: 0;
  height: calc(100% - 57px);
  overflow-y: auto;
}

.empty-chats {
  padding: 40px 20px;
  text-align: center;
  color: #909399;
}

.chats-list {
  display: flex;
  flex-direction: column;
}

.chat-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  cursor: pointer;
  border-bottom: 1px solid #ebeef5;
  transition: background-color 0.2s;
}

.chat-item:hover {
  background-color: #f5f7fa;
}

.chat-item.active {
  background-color: #ecf5ff;
}

.chat-info {
  flex: 1;
  min-width: 0;
}

.chat-name {
  font-weight: 500;
  color: #303133;
  margin-bottom: 4px;
}

.chat-preview {
  font-size: 12px;
  color: #909399;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.chat-window {
  height: 100%;
  display: flex;
  flex-direction: column;
}

.chat-window :deep(.el-card__body) {
  display: flex;
  flex-direction: column;
  height: calc(100% - 57px);
  padding: 0;
}

.chat-header {
  padding: 16px 20px;
  border-bottom: 1px solid #ebeef5;
}

.chat-header h4 {
  margin: 0;
}

.messages-container {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.message {
  display: flex;
  max-width: 70%;
}

.message-own {
  align-self: flex-end;
}

.message-content {
  background: #f0f2f5;
  padding: 12px 16px;
  border-radius: 12px;
}

.message-own .message-content {
  background: #409EFF;
  color: #fff;
}

.message-content p {
  margin: 0 0 4px 0;
  word-wrap: break-word;
}

.message-time {
  font-size: 11px;
  opacity: 0.7;
}

.message-input {
  padding: 16px 20px;
  border-top: 1px solid #ebeef5;
}

.chat-placeholder {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>


<script setup lang="ts">
import { ref, onMounted } from 'vue'
import apiClient from '@/api/client'

const backendStatus = ref<string>('Checking connection...')
const error = ref<string | null>(null)

const checkBackendConnection = async () => {
  try {
    const response = await apiClient.get('/health_check')
    backendStatus.value = response.data.message
    error.value = null
  } catch (e) {
    backendStatus.value = 'Connection failed'
    error.value = 'Could not connect to the backend server'
  }
}

onMounted(() => {
  checkBackendConnection()
})
</script>

<template>
  <div class="min-h-screen bg-gray-100 py-6 flex flex-col justify-center sm:py-12">
    <div class="relative py-3 sm:max-w-xl sm:mx-auto">
      <div
        class="absolute inset-0 bg-gradient-to-r from-cyan-400 to-light-blue-500 shadow-lg transform -skew-y-6 sm:skew-y-0 sm:-rotate-6 sm:rounded-3xl">
      </div>
      <div class="relative px-4 py-10 bg-white shadow-lg sm:rounded-3xl sm:p-20">
        <div class="max-w-md mx-auto">
          <div class="divide-y divide-gray-200">
            <div class="py-8 text-base leading-6 space-y-4 text-gray-700 sm:text-lg sm:leading-7">
              <h1 class="text-2xl font-bold mb-4">Backend Connection Status</h1>
              <p class="mb-2" :class="{ 'text-green-600': !error, 'text-red-600': error }">
                {{ backendStatus }}
              </p>
              <p v-if="error" class="text-red-500 text-sm">
                {{ error }}
              </p>
              <button @click="checkBackendConnection"
                class="mt-4 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                Check Connection
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>


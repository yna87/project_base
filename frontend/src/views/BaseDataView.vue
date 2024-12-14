<script setup lang="ts">
import { computed } from 'vue'
import { useRouter, useRoute, type RouteRecordRaw } from 'vue-router'

const router = useRouter()
const route = useRoute()

const displayRoutes = computed(() => {
  return router.getRoutes().filter((route): route is RouteRecordRaw => {
    return (
      !route.path.includes(':') &&
      !route.path.includes('*') &&
      route.path.startsWith('/database') &&
      route.path !== '/database'
    )
  })
})

const isActiveRoute = (path: string) => route.path === path

const formatRouteName = (route: RouteRecordRaw) => {
  const name = route.path.replace('/database/', '')
  return name.charAt(0).toUpperCase() + name.slice(1)
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
    <!-- サイドバー -->
    <aside class="fixed left-0 z-40 w-64 h-screen transition-transform" aria-label="Sidebar">
      <!-- ロゴエリア -->
      <div
        class="h-16 flex items-center justify-start px-6 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <span class="text-xl font-semibold text-gray-800 dark:text-white">Database</span>
      </div>

      <!-- ナビゲーション -->
      <div
        class="h-[calc(100%-4rem)] overflow-y-auto bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700">
        <nav class="p-4 space-y-2">
          <router-link v-for="route in displayRoutes" :key="route.path" :to="route.path" :class="[
            'flex items-center px-4 py-3 rounded-lg transition-all duration-200 text-sm font-medium',
            isActiveRoute(route.path)
              ? 'bg-blue-500 text-white shadow-md hover:bg-blue-600'
              : 'text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-700'
          ]">
            <span class="ml-3">{{ route.name || formatRouteName(route) }}</span>
          </router-link>
        </nav>
      </div>
    </aside>

    <!-- メインコンテンツ -->
    <main class="pl-64 min-h-screen">
      <!-- ヘッダー -->
      <header class="h-16 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div class="h-full px-6 flex items-center justify-between">
          <h1 class="text-lg font-medium text-gray-800 dark:text-white">
            {{ route.name || formatRouteName(route) }}
          </h1>
        </div>
      </header>

      <!-- コンテンツエリア -->
      <div class="p-6">
        <router-view />
      </div>
    </main>
  </div>
</template>


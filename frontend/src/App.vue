<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- ナビゲーションバー -->
    <nav class="bg-white shadow sticky top-0">
      <div class="max-w-7xl mx-auto px-4">
        <div class="flex space-x-4 h-14">
          <RouterLink to="/" class="flex items-center px-3 text-gray-600 hover:text-gray-900">
            Home
          </RouterLink>
          <RouterLink to="/system" class="flex items-center px-3 text-gray-600 hover:text-gray-900">
            System
          </RouterLink>
          <RouterLink to="/database" class="flex items-center px-3 text-gray-600 hover:text-gray-900">
            Database
          </RouterLink>
        </div>
      </div>
    </nav>

    <!-- メインコンテンツ -->
    <main class="max-w-7xl mx-auto px-4 py-4">
      <RouterView />
    </main>
  </div>
</template>


import { createRouter, createWebHistory } from 'vue-router'
import { databaseRoutes } from './routes'
import HomeView from '@/views/HomeView.vue'
import SystemView from '@/views/SystemView.vue'

const routes = [
  {
    path: '/',
    name: 'home',
    component: HomeView,
  },
  {
    path: '/system',
    name: 'system',
    component: SystemView,
  },
  databaseRoutes,
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router


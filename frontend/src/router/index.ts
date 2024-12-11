import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router';
import ProjectListView from '../pages/ProjectListView.vue';
import CalendarView from '../pages/CalendarView.vue';
import TaskListView from '../pages/TaskListView.vue';

const routes: Array<RouteRecordRaw> = [
  {
    path: '/',
    redirect: '/projects'
  },
  {
    path: '/projects',
    name: 'projects',
    component: ProjectListView
  },
  {
    path: '/calendar',
    name: 'calendar',
    component: CalendarView
  },
  {
    path: '/tasks',
    name: 'tasks',
    component: TaskListView
  }
];

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
});

export default router;

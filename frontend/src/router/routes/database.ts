import { RouteRecordRaw } from 'vue-router'
import BaseDataView from '@/views/BaseDataView.vue'

export const databaseRoutes: RouteRecordRaw = {
    path: '/database',
    component: BaseDataView,
    children: [
    ]
}


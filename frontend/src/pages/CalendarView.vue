<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useApi } from '../composables/useApi'
import type { Project, Phase } from '../types'

const api = useApi()

// State
const currentDate = ref(new Date())
const projects = ref<Project[]>([])

// Computed
const currentYear = computed(() => currentDate.value.getFullYear())
const currentMonth = computed(() => currentDate.value.getMonth())

const daysInMonth = computed(() => {
  return new Date(currentYear.value, currentMonth.value + 1, 0).getDate()
})

const firstDayOfMonth = computed(() => {
  return new Date(currentYear.value, currentMonth.value, 1).getDay()
})

const calendarDays = computed(() => {
  const days = []
  const totalDays = daysInMonth.value
  const firstDay = firstDayOfMonth.value

  // Add empty cells for days before the first of the month
  for (let i = 0; i < firstDay; i++) {
    days.push(null)
  }

  // Add actual days
  for (let i = 1; i <= totalDays; i++) {
    days.push(i)
  }

  return days
})

const monthName = computed(() => {
  return new Date(currentYear.value, currentMonth.value).toLocaleString('ja-JP', { month: 'long' })
})

// Methods
const loadProjects = async () => {
  const result = await api.getProjects()
  if (result) {
    projects.value = result
  }
}

const getPhaseEvents = (day: number) => {
  if (!day) return []

  const currentDateStr = `${currentYear.value}-${String(currentMonth.value + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
  const events: { project: Project; phaseType: string; phase: Phase }[] = []

  projects.value.forEach(project => {
    Object.entries(project.phases).forEach(([phaseType, phase]) => {
      if (isDateInRange(currentDateStr, phase.startDate, phase.endDate)) {
        events.push({
          project,
          phaseType,
          phase
        })
      }
    })
  })

  return events
}

const isDateInRange = (date: string, start: string, end: string) => {
  return date >= start && date <= end
}

const getStatusColor = (status: string) => {
  switch (status) {
    case 'notStarted':
      return 'bg-gray-200'
    case 'inProgress':
      return 'bg-blue-200'
    case 'completed':
      return 'bg-green-200'
    default:
      return 'bg-gray-100'
  }
}

const getPhaseLabel = (phaseType: string) => {
  const labels = {
    planning: '基本設計',
    design: '詳細設計',
    development: '開発',
    testing: 'テスト'
  }
  return labels[phaseType as keyof typeof labels]
}

const changeMonth = (offset: number) => {
  const newDate = new Date(currentDate.value)
  newDate.setMonth(newDate.getMonth() + offset)
  currentDate.value = newDate
}

const togglePhaseStatus = async (project: Project, phaseType: string) => {
  const statusOrder = ['notStarted', 'inProgress', 'completed']
  const currentStatus = project.phases[phaseType as keyof typeof project.phases].status
  const currentIndex = statusOrder.indexOf(currentStatus)
  const nextStatus = statusOrder[(currentIndex + 1) % statusOrder.length]

  const updatedProject = await api.updateProject(project.id, {
    ...project,
    phases: {
      ...project.phases,
      [phaseType]: {
        ...project.phases[phaseType as keyof typeof project.phases],
        status: nextStatus
      }
    }
  })

  if (updatedProject) {
    await loadProjects()
  }
}

// Lifecycle
onMounted(loadProjects)
</script>

<template>
  <div class="p-6">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold">プロジェクトカレンダー</h1>
      <div class="flex items-center space-x-4">
        <button 
          @click="changeMonth(-1)"
          class="px-4 py-2 bg-gray-100 rounded hover:bg-gray-200"
        >
          前月
        </button>
        <span class="text-xl">{{ currentYear }}年 {{ monthName }}</span>
        <button 
          @click="changeMonth(1)"
          class="px-4 py-2 bg-gray-100 rounded hover:bg-gray-200"
        >
          翌月
        </button>
      </div>
    </div>

    <div class="grid grid-cols-7 gap-1">
      <div 
        v-for="day in ['日', '月', '火', '水', '木', '金', '土']" 
        :key="day"
        class="p-2 text-center font-bold bg-gray-100"
      >
        {{ day }}
      </div>

      <div 
        v-for="(day, index) in calendarDays" 
        :key="index"
        class="min-h-[120px] p-2 border"
      >
        <div v-if="day" class="mb-2">{{ day }}</div>
        <div v-if="day" class="space-y-1">
          <div 
            v-for="event in getPhaseEvents(day)"
            :key="`${event.project.id}-${event.phaseType}`"
            :class="[
              'p-1 text-xs rounded cursor-pointer',
              getStatusColor(event.phase.status)
            ]"
            @click="togglePhaseStatus(event.project, event.phaseType)"
          >
            <div class="font-bold">{{ event.project.name }}</div>
            <div>{{ getPhaseLabel(event.phaseType) }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useApi } from '../composables/useApi';

// Types
interface Project {
  id: number;
  name: string;
  startDate: string;
  endDate: string;
  phases: {
    planning: Phase;
    design: Phase;
    development: Phase;
    testing: Phase;
  };
}

interface Phase {
  startDate: string;
  endDate: string;
  status: 'notStarted' | 'inProgress' | 'completed';
}

interface Task {
  id: number;
  title: string;
  projectId: number;
  phaseType: 'planning' | 'design' | 'development' | 'testing';
  status: 'incomplete' | 'complete';
}

// State
const api = useApi();
const tasks = ref<Task[]>([]);
const projects = ref<Project[]>([]);
const selectedProjectId = ref<number | null>(null);
const selectedPhaseType = ref<string | null>(null);
const selectedStatus = ref<string | null>(null);
const showNewTaskModal = ref(false);

// New task form
const newTask = ref({
  title: '',
  projectId: null as number | null,
  phaseType: null as string | null,
});

// Constants
const phaseTypes = [
  { value: 'planning', label: '基本設計' },
  { value: 'design', label: '詳細設計' },
  { value: 'development', label: '開発' },
  { value: 'testing', label: 'テスト' },
];

const statusTypes = [
  { value: 'incomplete', label: '未完了' },
  { value: 'complete', label: '完了' },
];

// Computed
const filteredTasks = computed(() => {
  return tasks.value.filter(task => {
    const projectMatch = !selectedProjectId.value || task.projectId === selectedProjectId.value;
    const phaseMatch = !selectedPhaseType.value || task.phaseType === selectedPhaseType.value;
    const statusMatch = !selectedStatus.value || task.status === selectedStatus.value;
    return projectMatch && phaseMatch && statusMatch;
  });
});

// Methods
const loadData = async () => {
  const projectsData = await api.getProjects();
  projects.value = projectsData || [];
  
  const allTasks: Task[] = [];
  for (const project of projects.value) {
    const projectTasks = await api.getTasks(project.id);
    if (projectTasks) {
      allTasks.push(...projectTasks);
    }
  }
  tasks.value = allTasks;
};

const handleCreateTask = async () => {
  if (!newTask.value.title || !newTask.value.projectId || !newTask.value.phaseType) {
    return;
  }

  await api.createTask({
    title: newTask.value.title,
    projectId: newTask.value.projectId,
    phaseType: newTask.value.phaseType as 'planning' | 'design' | 'development' | 'testing',
    status: 'incomplete'
  });

  // Reset form and reload data
  newTask.value = {
    title: '',
    projectId: null,
    phaseType: null,
  };
  showNewTaskModal.value = false;
  await loadData();
};

const toggleTaskStatus = async (task: Task) => {
  const newStatus = task.status === 'complete' ? 'incomplete' : 'complete';
  await api.updateTask(task.id, { status: newStatus });
  await loadData();
};

const getProjectName = (projectId: number) => {
  const project = projects.value.find(p => p.id === projectId);
  return project?.name || '';
};

const getPhaseLabel = (phaseType: string) => {
  return phaseTypes.find(phase => phase.value === phaseType)?.label || phaseType;
};

// Lifecycle
onMounted(loadData);
</script>

<template>
  <div class="p-6">
    <div class="mb-6">
      <h1 class="text-2xl font-bold mb-4">タスク一覧</h1>
      
      <!-- Filters -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <select
          v-model="selectedProjectId"
          class="rounded-lg border-gray-300 shadow-sm"
        >
          <option :value="null">すべてのプロジェクト</option>
          <option
            v-for="project in projects"
            :key="project.id"
            :value="project.id"
          >
            {{ project.name }}
          </option>
        </select>

        <select
          v-model="selectedPhaseType"
          class="rounded-lg border-gray-300 shadow-sm"
        >
          <option :value="null">すべてのフェーズ</option>
          <option
            v-for="phase in phaseTypes"
            :key="phase.value"
            :value="phase.value"
          >
            {{ phase.label }}
          </option>
        </select>

        <select
          v-model="selectedStatus"
          class="rounded-lg border-gray-300 shadow-sm"
        >
          <option :value="null">すべてのステータス</option>
          <option
            v-for="status in statusTypes"
            :key="status.value"
            :value="status.value"
          >
            {{ status.label }}
          </option>
        </select>

        <button
          @click="showNewTaskModal = true"
          class="bg-blue-500 text-white px-4 py-2 rounded-lg hover:bg-blue-600 transition-colors"
        >
          新規タスク作成
        </button>
      </div>

      <!-- Tasks Table -->
      <div class="overflow-x-auto">
        <table class="min-w-full border-collapse border border-gray-200">
          <thead>
            <tr class="bg-gray-50">
              <th class="border border-gray-200 px-4 py-2 text-left">タスク名</th>
              <th class="border border-gray-200 px-4 py-2 text-left">プロジェクト</th>
              <th class="border border-gray-200 px-4 py-2 text-left">フェーズ</th>
              <th class="border border-gray-200 px-4 py-2 text-left">ステータス</th>
              <th class="border border-gray-200 px-4 py-2 text-left">アクション</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="task in filteredTasks" :key="task.id" class="hover:bg-gray-50">
              <td class="border border-gray-200 px-4 py-2">{{ task.title }}</td>
              <td class="border border-gray-200 px-4 py-2">{{ getProjectName(task.projectId) }}</td>
              <td class="border border-gray-200 px-4 py-2">{{ getPhaseLabel(task.phaseType) }}</td>
              <td class="border border-gray-200 px-4 py-2">
                <span
                  :class="{
                    'px-2 py-1 rounded-full text-sm': true,
                    'bg-green-100 text-green-800': task.status === 'complete',
                    'bg-yellow-100 text-yellow-800': task.status === 'incomplete'
                  }"
                >
                  {{ task.status === 'complete' ? '完了' : '未完了' }}
                </span>
              </td>
              <td class="border border-gray-200 px-4 py-2">
                <button
                  @click="toggleTaskStatus(task)"
                  class="text-sm text-blue-500 hover:text-blue-700"
                >
                  {{ task.status === 'complete' ? '未完了に戻す' : '完了にする' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- New Task Modal -->
    <div
      v-if="showNewTaskModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center"
    >
      <div class="bg-white p-6 rounded-lg w-full max-w-md">
        <h2 class="text-xl font-bold mb-4">新規タスク作成</h2>
        
        <div class="space-y-4">
          <div>
            <label class="block mb-1">タスク名</label>
            <input
              v-model="newTask.title"
              type="text"
              class="w-full rounded-lg border-gray-300 shadow-sm"
            />
          </div>

          <div>
            <label class="block mb-1">プロジェクト</label>
            <select
              v-model="newTask.projectId"
              class="w-full rounded-lg border-gray-300 shadow-sm"
            >
              <option :value="null">選択してください</option>
              <option
                v-for="project in projects"
                :key="project.id"
                :value="project.id"
              >
                {{ project.name }}
              </option>
            </select>
          </div>

          <div>
            <label class="block mb-1">フェーズ</label>
            <select
              v-model="newTask.phaseType"
              class="w-full rounded-lg border-gray-300 shadow-sm"
            >
              <option :value="null">選択してください</option>
              <option
                v-for="phase in phaseTypes"
                :key="phase.value"
                :value="phase.value"
              >
                {{ phase.label }}
              </option>
            </select>
          </div>

          <div class="flex justify-end space-x-2 mt-6">
            <button
              @click="showNewTaskModal = false"
              class="px-4 py-2 text-gray-600 hover:text-gray-800"
            >
              キャンセル
            </button>
            <button
              @click="handleCreateTask"
              class="bg-blue-500 text-white px-4 py-2 rounded-lg hover:bg-blue-600 transition-colors"
            >
              作成
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
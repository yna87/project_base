<script setup lang="ts">
import { computed, ref } from 'vue'

interface TableHeader {
  key: string
  label: string
  sortable?: boolean
}

const props = defineProps<{
  data: Record<string, any>[],
  headers?: TableHeader[],
  delete?: (id: any) => Promise<void>,
}>();

// ヘッダー情報の自動生成
const generatedHeaders = computed<TableHeader[]>(() => {
  if (props.headers) return [...props.headers, { key: 'actions', label: 'アクション', sortable: false }]
  if (props.data.length === 0) return []

  // オブジェクトの最初の要素からキーを取得
  const firstItem = props.data[0]
  return [
    ...Object.keys(firstItem).map(key => ({
      key,
      label: formatLabel(key),
      sortable: true
    })),
    { key: 'actions', label: 'アクション', sortable: false }  // アクション列を追加
  ]
})

// キャメルケースやスネークケースを人が読みやすい形式に変換
const formatLabel = (key: string): string => {
  return key
    .replace(/[_-]/g, ' ')
    .replace(/([A-Z])/g, str => ' ' + str)
    .replace(/^./, str => str.toUpperCase())
    .trim()
}

// ソート関連の状態管理
const sortColumn = ref<string>('')
const sortDirection = ref<'asc' | 'desc'>('asc')

// ソート関数
const sortBy = (key: string) => {
  if (key === 'actions') return  // アクション列はソート不可
  if (sortColumn.value === key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortColumn.value = key
    sortDirection.value = 'asc'
  }
}

// ソート済みデータの計算
const sortedData = computed(() => {
  if (!sortColumn.value) return props.data

  return [...props.data].sort((a, b) => {
    const aValue = a[sortColumn.value]
    const bValue = b[sortColumn.value]

    if (typeof aValue === 'string' && typeof bValue === 'string') {
      return sortDirection.value === 'asc'
        ? aValue.localeCompare(bValue)
        : bValue.localeCompare(aValue)
    }

    return sortDirection.value === 'asc'
      ? aValue > bValue ? 1 : -1
      : aValue < bValue ? 1 : -1
  })
})

// 削除ハンドラー
const handleDelete = (item: Record<string, any>) => {
  if (props.delete && item.id) {
    props.delete(item.id)
  }
}
</script>

<template>
  <div class="w-full overflow-x-auto">
    <table v-if="data.length > 0" class="w-full min-w-full divide-y divide-gray-200">
      <thead class="bg-gray-50">
        <tr>
          <th
            v-for="header in generatedHeaders"
            :key="header.key"
            @click="header.sortable && sortBy(header.key)"
            class="px-6 py-3 text-left text-sm font-semibold text-gray-600"
            :class="[
              header.sortable && 'cursor-pointer hover:bg-gray-100 transition-colors',
              sortColumn === header.key && 'bg-gray-100'
            ]"
          >
            <div class="flex items-center space-x-1">
              <span>{{ header.label }}</span>
              <span v-if="header.sortable" class="text-gray-400">
                <span v-if="sortColumn === header.key" class="ml-1">
                  {{ sortDirection === 'asc' ? '↑' : '↓' }}
                </span>
                <span v-else class="ml-1 opacity-0 group-hover:opacity-50">↑</span>
              </span>
            </div>
          </th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200">
        <tr
          v-for="(item, index) in sortedData"
          :key="index"
          class="hover:bg-gray-50 transition-colors"
        >
          <td
            v-for="header in generatedHeaders"
            :key="header.key"
            class="px-6 py-4 text-sm text-gray-600 whitespace-nowrap"
          >
            <template v-if="header.key === 'actions'">
              <button
                v-if="delete"
                @click="handleDelete(item)"
                class="text-red-600 hover:text-red-800 font-medium"
              >
                削除
              </button>
            </template>
            <template v-else>
              {{ item[header.key] }}
            </template>
          </td>
        </tr>
      </tbody>
    </table>
    <div
      v-else
      class="w-full p-8 text-center text-gray-500 bg-gray-50 rounded-lg"
    >
      データがありません
    </div>
  </div>
</template>


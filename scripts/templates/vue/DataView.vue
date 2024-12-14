<script setup lang="ts">
import { useApi } from '@/composables/use_api';
import { {{ table.name | pascalcase }} } from '@/models/{{ table.name | lower }}';
import { onMounted, ref } from 'vue';
import DataTable from '@/components/DataTable.vue';
import DataForm from '@/components/DataForm.vue';

const api = useApi();
const {{ table.plural_name | lower }} = ref<{{ table.name | pascalcase }}[] | null>(null);
const showForm = ref(false);

const onGet{{ table.plural_name | pascalcase }} = async () => {
  {{ table.plural_name | lower }}.value = await api.get{{ table.plural_name | pascalcase }}();
};

const onCreate{{ table.name | pascalcase }} = async ({{ table.name | lower }}: {{ table.name | pascalcase }}) => {
  await api.create{{ table.name | pascalcase }}({{ table.name | lower }});
  showForm.value = false;
  {{ table.plural_name | lower }}.value = await api.get{{ table.plural_name | pascalcase }}();
}

const onDelete{{ table.name | pascalcase }} = async (id: number) => {
  await api.delete{{ table.name | pascalcase }}(id);
  {{ table.plural_name | lower }}.value = await api.get{{ table.plural_name | pascalcase }}();
}

onMounted(async () => {
  await onGet{{ table.plural_name | pascalcase }}();
});
</script>

<template>
  <div class="space-y-6">
    <div class="flex justify-between items-center">
      <h1 class="text-2xl font-bold text-gray-900">{{ table.plural_name | pascalcase }}</h1>
      <button
        @click="showForm = !showForm"
        class="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
      >
        {% raw %}
        {{ showForm ? '新規作成をキャンセル' : '新規作成' }}
        {% endraw %}
      </button>
    </div>

    <DataForm
      v-if="showForm"
      :data="new {{ table.name | pascalcase }}()"
      :submit="onCreate{{ table.name | pascalcase }}"
    />

    <DataTable
      v-if="{{ table.plural_name | lower }}"
      :data="{{ table.plural_name | lower }}"
      :delete="onDelete{{ table.name | pascalcase }}"
    />
  </div>
</template>


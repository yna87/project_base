<script setup lang="ts">
import { useApi } from '@/composables/use_api';
import { {{ table.name | pascalcase }} } from '@/models/{{ table.name | lower }}';
import { onMounted, ref } from 'vue';

import DataTable from '@/components/DataTable.vue';

const api = useApi();
const {{ table.plural_name | lower }} = ref<{{ table.name | pascalcase }}[] | null>(null);

onMounted(async () => {
    {{ table.plural_name | lower }}.value = await api.get{{ table.plural_name | pascalcase }}();
})
</script>

<template>
  <DataTable v-if="{{ table.plural_name | lower }}" :data="{{ table.plural_name | lower }}" auto-headers />
</template>


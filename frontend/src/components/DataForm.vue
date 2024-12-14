<script setup lang="ts">
import { computed, ref } from 'vue';

interface FormField {
  key: string;
  type: string;
  value: any;
}

const props = defineProps<{
  data: Record<string, any>,
  submit: (d: typeof props.data) => Promise<void>,
}>();

const formData = ref({ ...props.data });
const isSubmitting = ref(false);
const error = ref('');

const getInputType = (value: any): string => {
  switch (typeof value) {
    case 'number':
      return 'number';
    case 'boolean':
      return 'checkbox';
    case 'string':
      return 'text';
    default:
      return 'text';
  }
};

const fields = computed((): FormField[] => {
  return Object.entries(props.data).map(([key, value]) => ({
    key,
    type: getInputType(value),
    value
  }));
});

const onSubmit = async () => {
  console.log(formData.value);
  try {
    isSubmitting.value = true;
    error.value = '';
    await props.submit(formData.value);
  } catch (e) {
    error.value = e instanceof Error ? e.message : '送信中にエラーが発生しました';
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <form @submit.prevent="onSubmit" class="space-y-4">
    <div v-for="field in fields" :key="field.key" class="form-field">
      <label :for="field.key" class="block text-sm font-medium text-gray-700">
        {{ field.key }}
      </label>
      
      <input
        v-if="field.type !== 'checkbox'"
        :id="field.key"
        :type="field.type"
        v-model="formData[field.key]"
        class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
      />
      
      <input
        v-else
        :id="field.key"
        type="checkbox"
        v-model="formData[field.key]"
        class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
      />
    </div>

    <div v-if="error" class="text-red-600 text-sm mt-2">
      {{ error }}
    </div>

    <button
      type="submit"
      :disabled="isSubmitting"
      class="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
    >
      {{ isSubmitting ? '送信中...' : '保存' }}
    </button>
  </form>
</template>


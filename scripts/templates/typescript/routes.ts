import { RouteRecordRaw } from 'vue-router'
import BaseDataView from '@/views/BaseDataView.vue'
{% for table in tables %}
import {{ table.plural_name }}DataView from '@/views/{{ table.plural_name }}DataView.vue'
{% endfor %}

export const databaseRoutes: RouteRecordRaw = {
    path: '/database',
    component: BaseDataView,
    children: [
        {% for table in tables %}
        {
            path: '{{ table.plural_name | lower }}',
            name: '{{ table.plural_name | lower }}',
            component: {{ table.plural_name }}DataView
        },
        {% endfor %}
    ]
}


import { RouteRecordRaw } from 'vue-router'
import BaseDataView from '@/views/BaseDataView.vue'
{% for table in tables %}
import Manage{{ table.plural_name }}View from '@/views/Manage{{ table.plural_name }}View.vue'
{% endfor %}

export const databaseRoutes: RouteRecordRaw = {
    path: '/database',
    component: BaseDataView,
    children: [
        {% for table in tables %}
        {
            path: '{{ table.plural_name | lower }}',
            name: '{{ table.plural_name | lower }}',
            component: Manage{{ table.plural_name }}View
        },
        {% endfor %}
    ]
}


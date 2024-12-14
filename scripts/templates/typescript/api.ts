import apiClient from './client';
{% for table in tables %}
import { {{ table.name }} } from '../models/{{ table.name | lower }}';
{% endfor %}

export class Api {
    {% for table in tables %}
    // {{ table.name }} API methods
    async get{{ table.name }}(id: number): Promise<{{ table.name }}> {
        const response = await apiClient.get<{{ table.name }}>(`/{{ table.plural_name | lower }}/${id}`);
        return new {{ table.name }}(response.data);
    }

    async get{{ table.plural_name }}(): Promise<{{ table.name }}[]> {
        const response = await apiClient.get<{{ table.name }}[]>('/{{ table.plural_name | lower }}');
        return response.items.map(item => new {{ table.name }}(item));
    }

    async update{{ table.name }}(id: number, {{ table.name | lower }}: Partial<{{ table.name }}>): Promise<{{ table.name }}> {
        const response = await apiClient.put<{{ table.name }}>(`/{{ table.plural_name | lower }}/${id}`, {{ table.name | lower }});
        return new {{ table.name }}(response.data);
    }

    async create{{ table.name }}({{ table.name | lower }}: Omit<{{ table.name }}, 'id'>): Promise<{{ table.name }}> {
        const response = await apiClient.post<{{ table.name }}>('/{{ table.plural_name | lower }}', {{ table.name | lower }});
        return new {{ table.name }}(response.data);
    }

    async delete{{ table.name }}(id: number): Promise<void> {
        await apiClient.delete(`/{{ table.plural_name | lower }}/${id}`);
    }
    {% endfor %}
}

export default Api;


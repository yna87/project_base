import apiClient from './client';
import { User } from '../models/user';

export class Api {
    // User API methods
    async getUser(id: number): Promise<User> {
        const response = await apiClient.get<User>(`/users/${id}`);
        return new User(response.data);
    }

    async getUsers(): Promise<User[]> {
        const response = await apiClient.get<User[]>('/users');
        return response.data.map(item => new User(item));
    }

    async updateUser(id: number, user: Partial<User>): Promise<User> {
        const response = await apiClient.put<User>(`/users/${id}`, user);
        return new User(response.data);
    }

    async createUser(user: Omit<User, 'id'>): Promise<User> {
        const response = await apiClient.post<User>('/users', user);
        return new User(response.data);
    }

    async deleteUser(id: number): Promise<void> {
        await apiClient.delete(`/users/${id}`);
    }
}

export default Api;
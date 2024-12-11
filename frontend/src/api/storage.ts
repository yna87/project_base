import { Project, Task } from '../types';

const STORAGE_KEYS = {
  PROJECTS: 'projects',
  TASKS: 'tasks',
};

export class StorageService {
  private getItem<T>(key: string): T[] {
    const data = localStorage.getItem(key);
    return data ? JSON.parse(data) : [];
  }

  private setItem<T>(key: string, value: T[]): void {
    localStorage.setItem(key, JSON.stringify(value));
  }

  getProjects(): Project[] {
    return this.getItem<Project>(STORAGE_KEYS.PROJECTS);
  }

  setProjects(projects: Project[]): void {
    this.setItem(STORAGE_KEYS.PROJECTS, projects);
  }

  getTasks(): Task[] {
    return this.getItem<Task>(STORAGE_KEYS.TASKS);
  }

  setTasks(tasks: Task[]): void {
    this.setItem(STORAGE_KEYS.TASKS, tasks);
  }
}

export const storageService = new StorageService();

import { Project, Task, PhaseType } from '../types';
import { storageService } from './storage';

export class Api {
  // Projects
  async getProjects(): Promise<Project[]> {
    return storageService.getProjects();
  }

  async getProject(id: number): Promise<Project | undefined> {
    const projects = await this.getProjects();
    return projects.find(p => p.id === id);
  }

  async createProject(project: Omit<Project, 'id'>): Promise<Project> {
    const projects = await this.getProjects();
    const newProject: Project = {
      ...project,
      id: projects.length ? Math.max(...projects.map(p => p.id)) + 1 : 1
    };
    storageService.setProjects([...projects, newProject]);
    return newProject;
  }

  async updateProject(id: number, project: Partial<Project>): Promise<Project | undefined> {
    const projects = await this.getProjects();
    const index = projects.findIndex(p => p.id === id);
    if (index === -1) return undefined;

    const updatedProject = { ...projects[index], ...project };
    projects[index] = updatedProject;
    storageService.setProjects(projects);
    return updatedProject;
  }

  async deleteProject(id: number): Promise<boolean> {
    const projects = await this.getProjects();
    const filteredProjects = projects.filter(p => p.id !== id);
    if (filteredProjects.length === projects.length) return false;
    
    storageService.setProjects(filteredProjects);
    // Clean up related tasks
    const tasks = await this.getTasks();
    const filteredTasks = tasks.filter(t => t.projectId !== id);
    storageService.setTasks(filteredTasks);
    return true;
  }

  // Tasks
  async getTasks(projectId?: number): Promise<Task[]> {
    const tasks = storageService.getTasks();
    return projectId ? tasks.filter(t => t.projectId === projectId) : tasks;
  }

  async getProjectPhaseTasks(projectId: number, phaseType: PhaseType): Promise<Task[]> {
    const tasks = await this.getTasks(projectId);
    return tasks.filter(t => t.phaseType === phaseType);
  }

  async createTask(task: Omit<Task, 'id'>): Promise<Task> {
    const tasks = await this.getTasks();
    const newTask: Task = {
      ...task,
      id: tasks.length ? Math.max(...tasks.map(t => t.id)) + 1 : 1
    };
    storageService.setTasks([...tasks, newTask]);
    return newTask;
  }

  async updateTask(id: number, task: Partial<Task>): Promise<Task | undefined> {
    const tasks = await this.getTasks();
    const index = tasks.findIndex(t => t.id === id);
    if (index === -1) return undefined;

    const updatedTask = { ...tasks[index], ...task };
    tasks[index] = updatedTask;
    storageService.setTasks(tasks);
    return updatedTask;
  }

  async deleteTask(id: number): Promise<boolean> {
    const tasks = await this.getTasks();
    const filteredTasks = tasks.filter(t => t.id !== id);
    if (filteredTasks.length === tasks.length) return false;
    
    storageService.setTasks(filteredTasks);
    return true;
  }
}

export const api = new Api();

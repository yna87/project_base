import axios, { AxiosInstance, CreateAxiosDefaults } from 'axios';
import { ApiResponse } from './types';

import { snakeCase, camelCase } from 'lodash';

// オブジェクトのキーをsnake_caseに変換する関数
const toSnakeCase = (obj) => {
  if (Array.isArray(obj)) {
    return obj.map(toSnakeCase);
  } else if (obj !== null && typeof obj === 'object') {
    return Object.keys(obj).reduce((acc, key) => {
      acc[snakeCase(key)] = toSnakeCase(obj[key]);
      return acc;
    }, {});
  }
  return obj;
};

// オブジェクトのキーをcamelCaseに変換する関数
const toCamelCase = (obj) => {
  if (Array.isArray(obj)) {
    return obj.map(toCamelCase);
  } else if (obj !== null && typeof obj === 'object') {
    return Object.keys(obj).reduce((acc, key) => {
      acc[camelCase(key)] = toCamelCase(obj[key]);
      return acc;
    }, {});
  }
  return obj;
};

class ApiClient {
  constructor (config?: CreateAxiosDefaults) {
    this.axiosInstance = axios.create(config);

    // リクエストインターセプター
    this.axiosInstance.interceptors.request.use((config) => {
      if (config.data) {
        config.data = toSnakeCase(config.data);
      }
      if (config.params) {
        config.params = toSnakeCase(config.params);
      }
      return config;
    });

    // レスポンスインターセプター
    this.axiosInstance.interceptors.response.use((response) => {
      if (response.data) {
        response.data = toCamelCase(response.data);
      }
      return response;
    });
  }
  
  private axiosInstance: AxiosInstance;

  async get<T>(url: string): Promise<ApiResponse<T>> {
    const response = await this.axiosInstance.get<ApiResponse<T>>(url);
    return response.data;
  }

  async post<T>(url: string, data?: any): Promise<ApiResponse<T>> {
    const response = await this.axiosInstance.post<ApiResponse<T>>(url, data);
    return response.data;
  }

  async put<T>(url: string, data?: any): Promise<ApiResponse<T>> {
    const response = await this.axiosInstance.put<ApiResponse<T>>(url, data);
    return response.data;
  }

  async delete(url: string): Promise<void> {
    await this.axiosInstance.delete(url);
  }
};

const apiClient = new ApiClient({
  baseURL: import.meta.env.VITE_API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
  withCredentials: true,
});

export default apiClient;

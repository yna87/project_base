#!/bin/bash

# 色付きの出力のための関数
print_status() {
  echo -e "\e[1;34m===> $1\e[0m"
}

print_error() {
  echo -e "\e[1;31m===> Error: $1\e[0m"
}

print_success() {
  echo -e "\e[1;32m===> $1\e[0m"
}

# バージョンチェック関数
version_gt() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# より詳細な依存関係チェック
check_dependencies() {
  print_status "システム要件をチェックしています..."

  # Voltaのチェック
  if ! command -v volta >/dev/null 2>&1; then
    print_error "Voltaがインストールされていません"
    print_status "curl https://get.volta.sh | bash で導入できます"
    exit 1
  fi

  # Node.jsのバージョンチェック
  if command -v node >/dev/null 2>&1; then
    node_version=$(node -v | cut -d'v' -f2)
    if version_gt "22.0.0" "$node_version"; then
      print_error "Node.js 22以上が必要です。現在のバージョン: $node_version"
      print_status "volta install node@22 で導入できます"
      exit 1
    fi
  else
    print_error "Node.jsがインストールされていません"
    print_status "volta install node@22 で導入できます"
    exit 1
  fi

  # Yarnのバージョンチェック
  if command -v yarn >/dev/null 2>&1; then
    yarn_version=$(yarn --version)
    if version_gt "4.0.0" "$yarn_version"; then
      print_error "Yarn 4以上が必要です。現在のバージョン: $yarn_version"
      print_status "volta install yarn@4 で導入できます"
      exit 1
    fi
  else
    print_error "Yarnがインストールされていません"
    print_status "volta install yarn@4 で導入できます"
    exit 1
  fi

  # SQLite3のチェック（必要な場合）
  if ! command -v sqlite3 >/dev/null 2>&1; then
    print_error "SQLite3がインストールされていません"
    exit 1
  fi

  print_success "全ての依存関係が満たされています"
}

# ディレクトリの存在チェック
check_directory() {
  print_status "ディレクトリをチェックしています..."

  if [ -e backend ] || [ -e frontend ]; then
    print_error "backend/またはfrontend/ディレクトリが既に存在します"
    exit 1
  fi
}

# エラーハンドリング関数
handle_error() {
  print_error "エラーが発生しました: $1"
  print_error "セットアップを中止します"
  exit 1
}

setup_backend() {
  print_status "バックエンドをセットアップしています..."

  mkdir -p backend
  cd backend

  # bundlerの設定を.bundleに初期化
  echo "📦 Bundlerの設定を初期化中..."
  mkdir -p .bundle
  cat >.bundle/config <<EOL
---
BUNDLE_PATH: ".bundle"
BUNDLE_BIN: ".bundle/bin"
EOL

  # Gemfileを作成
  echo "📝 Gemfileを作成中..."
  cat >Gemfile <<EOL
source 'https://rubygems.org'

gem "rails", "~> 8.0.0", ">= 8.0.0.1"
EOL

  # bundlerとrailsをローカルにインストール
  gem install bundler --no-document --install-dir .bundle
  bundle install || handle_error "Gemのインストールに失敗しました"

  # 最小構成でRailsアプリケーションを作成
  echo "🏗️ Railsアプリケーションを作成中..."
  bundle exec rails new . \
    --api \
    --minimal \
    --skip-bundle \
    --skip-git \
    --skip-keeps \
    --skip-action-mailer \
    --skip-action-mailbox \
    --skip-action-text \
    --skip-active-storage \
    --skip-action-cable \
    --skip-javascript \
    --skip-hotwire \
    --skip-jbuilder \
    --force

  # Gemfileを作成
  echo "📝 Gemfileを作成中..."

  cat >Gemfile <<EOL
source "https://rubygems.org"

gem "rails"
gem "sqlite3"
gem "puma"

gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "kamal", require: false
gem "thruster", require: false
gem "rack-cors"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end
EOL

  # 必要なディレクトリ構造を作成
  echo "📁 APIディレクトリ構造を作成中..."
  mkdir -p app/controllers/api/v1

  # ApplicationControllerを作成
  echo "🔧 コントローラを作成中..."
  cat >app/controllers/application_controller.rb <<EOL
class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    render json: { error: 'not_found' }, status: :not_found
  end
end
EOL

  # HealthControllerを作成
  echo "🔧 HealthControllerを作成中..."
  cat >app/controllers/api/v1/health_controller.rb <<EOL
module Api
  module V1
    class HealthController < ApplicationController
      def check
        render json: {
          data: {
            status: 'ok',
            message: 'Backend is running!',
            timestamp: Time.current,
            database: database_status
          }
        }
      end

      private

      def database_status
        ActiveRecord::Base.connection.active? ? 'connected' : 'disconnected'
      rescue StandardError
        'error'
      end
    end
  end
end
EOL

  # CORSの設定を追加
  echo "🔒 CORSの設定を追加中..."
  mkdir -p config/initializers
  cat >config/initializers/cors.rb <<EOL
require 'rack/cors'

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:5173'

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
EOL

  # データベースの設定を追加
  echo "🗄️ データベースの設定を追加中..."
  cat >config/database.yml <<EOL
default: &default
  adapter: sqlite3
  pool: 5
  timeout: 5000

development:
  <<: *default
  database: db/development.sqlite3

test:
  <<: *default
  database: db/test.sqlite3

production:
  <<: *default
  database: db/production.sqlite3
EOL

  # ルーティングを設定
  echo "🛣️ ルーティングを設定中..."
  cat >config/routes.rb <<EOL
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'health_check', to: 'health#check'
    end
  end
end
EOL

  # gemの依存関係を再インストール
  echo "📦 依存関係を再インストール中..."
  bundle install

  # データベースをセットアップ
  echo "🗄️ データベースをセットアップ中..."
  bundle exec rails db:create

  # .gitignoreを設定
  echo "📝 .gitignoreを設定中..."
  cat >.gitignore <<EOL
/.bundle
/log/*
/tmp/*
/db/*.sqlite3
/db/*.sqlite3-*
/config/master.key
EOL

  cd ..
}

setup_frontend() {
  print_status "Vueアプリケーションをセットアップしています..."

  # .yarnrc.ymlの作成
  cat >.yarnrc.yml <<EOL
nodeLinker: node-modules
enableGlobalCache: true
compressionLevel: 0

EOL

  # Vue 3プロジェクトの作成（Yarn 4対応）
  yarn dlx create-vite frontend --template vue-ts || handle_error "Vueプロジェクトの作成に失敗しました"

  cd frontend

  # Voltaの設定を追加
  cat >volta.json <<EOL
{
  "node": "22.x",
  "yarn": "4.x"
}
EOL

  # package.jsonの更新
  cat >package.json <<EOL
{
  "name": "frontend",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "packageManager": "yarn@4.0.2",
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc && vite build",
    "preview": "vite preview",
    "storybook": "storybook dev --port 6006",
    "lint": "eslint . --ext .vue,.js,.jsx,.cjs,.mjs,.ts,.tsx,.cts,.mts --fix",
    "format": "prettier --write src/"
  },
  "dependencies": {
    "@tailwindcss/forms": "^0.5.7",
    "@tailwindcss/typography": "^0.5.10",
    "axios": "^1.6.2",
    "lodash": "^4.17.21",
    "pinia": "^2.1.7",
    "vue": "^3.3.11",
    "vue-router": "^4.2.5"
  },
  "devDependencies": {
    "@rushstack/eslint-patch": "^1.3.3",
    "@storybook/vue3-vite": "^8.0.0",
    "@tsconfig/node22": "^22.0.0",
    "@types/lodash": "^4",
    "@types/node": "^20.10.4",
    "@vitejs/plugin-vue": "^4.5.2",
    "@vue/eslint-config-prettier": "^8.0.0",
    "@vue/eslint-config-typescript": "^12.0.0",
    "@vue/tsconfig": "^0.5.0",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.49.0",
    "eslint-plugin-vue": "^9.17.0",
    "postcss": "^8.4.32",
    "prettier": "^3.0.3",
    "storybook": "^8.0.0",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.3.3",
    "vite": "^5.0.10",
    "vue-tsc": "^1.8.25"
  }
}

EOL

  # パッケージのインストール（Yarn 4の構文で）
  yarn install || handle_error "パッケージのインストールに失敗しました"

  # Storybook設定ファイルの作成
  mkdir .storybook

  cat >.storybook/main.ts <<EOL
import { StorybookConfig } from "@storybook/vue3-vite";

const config: StorybookConfig = {
  framework: "@storybook/vue3-vite",
  stories: ["../src/**/*.stories.@(js|ts)"],
};

export default config;
EOL

  # Tailwind CSS初期化
  npx tailwindcss init -p

  # Tailwind CSS設定の更新
  cat >tailwind.config.js <<EOL
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [
    import('@tailwindcss/forms'),
    import('@tailwindcss/typography'),
  ],
}
EOL

  # CSS設定の追加
  cat >src/style.css <<EOL
@tailwind base;
@tailwind components;
@tailwind utilities;
EOL

  # 環境設定ファイルの作成
  cat >.env <<EOL
VITE_API_URL=http://localhost:3000/api/v1
EOL

  # APIクライアントの設定
  mkdir -p src/api
  cat >src/api/client.ts <<EOL
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
EOL

  cat >src/api/types.ts <<EOL
export interface ListResponse<T> {
    items: T[];
    count: number;
}

export interface SingleResponse<T> {
  data: T;
}

export type ApiResponse<T> = T extends any[] ? ListResponse<T[number]> : SingleResponse<T>;

EOL

  # TypeScript設定の更新
  cat >tsconfig.json <<EOL
{
  "extends": "@tsconfig/node22/tsconfig.json",
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "module": "ESNext",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "preserve",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*.ts", "src/**/*.d.ts", "src/**/*.tsx", "src/**/*.vue"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOL

  # tsconfig.node.json の更新
  cat >tsconfig.node.json <<EOL
{
  "extends": "@tsconfig/node22/tsconfig.json",
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "strict": true
  },
  "include": ["vite.config.ts"]
}
EOL

  # ESLint設定の追加
  cat >.eslintrc.cjs <<EOL
/* eslint-env node */
require('@rushstack/eslint-patch/modern-module-resolution')

module.exports = {
  root: true,
  extends: [
    'plugin:vue/vue3-recommended',
    'eslint:recommended',
    '@vue/eslint-config-typescript',
    '@vue/eslint-config-prettier/skip-formatting'
  ],
  parserOptions: {
    ecmaVersion: 'latest'
  },
  rules: {
    'vue/multi-word-component-names': 'off',
    '@typescript-eslint/no-unused-vars': ['error', { 'argsIgnorePattern': '^_' }]
  }
}
EOL

  # Prettier設定の追加
  cat >.prettierrc.json <<EOL
{
  "semi": false,
  "tabWidth": 2,
  "singleQuote": true,
  "printWidth": 100,
  "trailingComma": "none"
}
EOL

  # Vite設定の更新
  cat >vite.config.ts <<EOL
import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    port: 5173,
    strictPort: true,
    host: true
  }
})
EOL

  # App.vueを更新
  cat >src/App.vue <<EOL
<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <!-- ナビゲーションバー -->
    <nav class="bg-white shadow sticky top-0">
      <div class="max-w-7xl mx-auto px-4">
        <div class="flex space-x-4 h-14">
          <RouterLink to="/" class="flex items-center px-3 text-gray-600 hover:text-gray-900">
            Home
          </RouterLink>
          <RouterLink to="/system" class="flex items-center px-3 text-gray-600 hover:text-gray-900">
            System
          </RouterLink>
          <RouterLink to="/database" class="flex items-center px-3 text-gray-600 hover:text-gray-900">
            Database
          </RouterLink>
        </div>
      </div>
    </nav>

    <!-- メインコンテンツ -->
    <main class="max-w-7xl mx-auto px-4 py-4">
      <RouterView />
    </main>
  </div>
</template>

EOL

  # main.ts の更新
  cat >src/main.ts <<EOL
import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router'

const app = createApp(App)
app.use(router)
app.mount('#app')

EOL

  # composable の作成
  mkdir -p src/composables

  cat >src/composables/use_api.ts <<EOL
import Api from "@/api/api";

export function useApi() {
    const api = new Api();

    return api;
}

EOL

  # ルーティングの設定
  mkdir -p src/router/routes
  cat >src/router/index.ts <<EOL
import { createRouter, createWebHistory } from 'vue-router'
import { databaseRoutes } from './routes'
import HomeView from '@/views/HomeView.vue'
import SystemView from '@/views/SystemView.vue'

const routes = [
  {
    path: '/',
    name: 'home',
    component: HomeView,
  },
  {
    path: '/system',
    name: 'system',
    component: SystemView,
  },
  databaseRoutes,
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router

EOL

  cat >src/router/routes/index.ts <<EOL
export * from './database'

EOL

  cat >src/router/routes/database.ts <<EOL
import { RouteRecordRaw } from 'vue-router'
import BaseDataView from '@/views/BaseDataView.vue'

export const databaseRoutes: RouteRecordRaw = {
    path: '/database',
    component: BaseDataView,
    children: [
    ]
}

EOL

  # .gitignore の更新
  cat >.gitignore <<EOL
# Logs
logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

node_modules
.DS_Store
dist
dist-ssr
coverage
*.local

# Editor directories and files
.vscode/*
!.vscode/extensions.json
.idea
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?

# Yarn
.yarn/*
!.yarn/patches
!.yarn/plugins
!.yarn/releases
!.yarn/sdks
!.yarn/versions
EOL

  yarn install || handle_error "依存関係のインストールに失敗しました"

  cd ..
}

create_components() {
  cd frontend

  mkdir -p src/views

  cat >src/views/HomeView.vue <<EOL
<template>
    <div />
</template>

EOL

  cat >src/components/DataTable.vue <<EOL
<script setup lang="ts">
import { computed, ref } from 'vue'

interface TableHeader {
  key: string
  label: string
  sortable?: boolean
}

interface Props {
  data: Record<string, any>[]
  headers?: TableHeader[]
  autoHeaders?: boolean
  allSortable?: boolean
}

// Props の定義
const props = withDefaults(defineProps<Props>(), {
  data: () => [],
  headers: undefined,
  autoHeaders: false,
  allSortable: true
})

// ヘッダー情報の自動生成
const generatedHeaders = computed<TableHeader[]>(() => {
  if (props.headers) return props.headers
  if (props.data.length === 0) return []

  // オブジェクトの最初の要素からキーを取得
  const firstItem = props.data[0]
  return Object.keys(firstItem).map(key => ({
    key,
    label: formatLabel(key),
    sortable: props.allSortable
  }))
})

// キャメルケースやスネークケースを人が読みやすい形式に変換
const formatLabel = (key: string): string => {
  return key
    // アンダースコアとハイフンをスペースに変換
    .replace(/[_-]/g, ' ')
    // キャメルケースをスペース区切りに変換
    .replace(/([A-Z])/g, ' $1')
    // 文字列の最初を大文字に
    .replace(/^./, str => str.toUpperCase())
    .trim()
}

// ソート関連の状態管理
const sortColumn = ref<string>('')
const sortDirection = ref<'asc' | 'desc'>('asc')

// ソート関数
const sortBy = (key: string) => {
  if (sortColumn.value === key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortColumn.value = key
    sortDirection.value = 'asc'
  }
}

// ソート済みデータの計算
const sortedData = computed(() => {
  if (!sortColumn.value) return props.data

  return [...props.data].sort((a, b) => {
    const aValue = a[sortColumn.value]
    const bValue = b[sortColumn.value]

    if (typeof aValue === 'string' && typeof bValue === 'string') {
      return sortDirection.value === 'asc'
        ? aValue.localeCompare(bValue)
        : bValue.localeCompare(aValue)
    }

    return sortDirection.value === 'asc'
      ? aValue > bValue ? 1 : -1
      : aValue < bValue ? 1 : -1
  })
})
</script>

<template>
  <div class="w-full overflow-x-auto">
    <table v-if="data.length > 0" class="w-full min-w-full divide-y divide-gray-200">
      <thead class="bg-gray-50">
        <tr>
          <th
            v-for="header in generatedHeaders"
            :key="header.key"
            @click="header.sortable && sortBy(header.key)"
            class="px-6 py-3 text-left text-sm font-semibold text-gray-600"
            :class="[
              header.sortable && 'cursor-pointer hover:bg-gray-100 transition-colors',
              sortColumn === header.key && 'bg-gray-100'
            ]"
          >
            <div class="flex items-center space-x-1">
              <span>{{ header.label }}</span>
              <span v-if="header.sortable" class="text-gray-400">
                <span v-if="sortColumn === header.key" class="ml-1">
                  {{ sortDirection === 'asc' ? '↑' : '↓' }}
                </span>
                <span v-else class="ml-1 opacity-0 group-hover:opacity-50">↑</span>
              </span>
            </div>
          </th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200">
        <tr
          v-for="(item, index) in sortedData"
          :key="index"
          class="hover:bg-gray-50 transition-colors"
        >
          <td
            v-for="header in generatedHeaders"
            :key="header.key"
            class="px-6 py-4 text-sm text-gray-600 whitespace-nowrap"
          >
            {{ item[header.key] }}
          </td>
        </tr>
      </tbody>
    </table>
    <div
      v-else
      class="w-full p-8 text-center text-gray-500 bg-gray-50 rounded-lg"
    >
      データがありません
    </div>
  </div>
</template>

EOL

  cat >src/views/BaseDataView.vue <<EOL
<script setup lang="ts">
import { computed } from 'vue'
import { useRouter, useRoute, type RouteRecordRaw } from 'vue-router'

const router = useRouter()
const route = useRoute()

const displayRoutes = computed(() => {
  return router.getRoutes().filter((route): route is RouteRecordRaw => {
    return (
      !route.path.includes(':') &&
      !route.path.includes('*') &&
      route.path.startsWith('/database') &&
      route.path !== '/database'
    )
  })
})

const isActiveRoute = (path: string) => route.path === path

const formatRouteName = (route: RouteRecordRaw) => {
  const name = route.path.replace('/database/', '')
  return name.charAt(0).toUpperCase() + name.slice(1)
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
    <!-- サイドバー -->
    <aside class="fixed left-0 z-40 w-64 h-screen transition-transform" aria-label="Sidebar">
      <!-- ロゴエリア -->
      <div
        class="h-16 flex items-center justify-start px-6 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <span class="text-xl font-semibold text-gray-800 dark:text-white">Database</span>
      </div>

      <!-- ナビゲーション -->
      <div
        class="h-[calc(100%-4rem)] overflow-y-auto bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700">
        <nav class="p-4 space-y-2">
          <router-link v-for="route in displayRoutes" :key="route.path" :to="route.path" :class="[
            'flex items-center px-4 py-3 rounded-lg transition-all duration-200 text-sm font-medium',
            isActiveRoute(route.path)
              ? 'bg-blue-500 text-white shadow-md hover:bg-blue-600'
              : 'text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-700'
          ]">
            <span class="ml-3">{{ route.name || formatRouteName(route) }}</span>
          </router-link>
        </nav>
      </div>
    </aside>

    <!-- メインコンテンツ -->
    <main class="pl-64 min-h-screen">
      <!-- ヘッダー -->
      <header class="h-16 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div class="h-full px-6 flex items-center justify-between">
          <h1 class="text-lg font-medium text-gray-800 dark:text-white">
            {{ route.name || formatRouteName(route) }}
          </h1>
        </div>
      </header>

      <!-- コンテンツエリア -->
      <div class="p-6">
        <router-view />
      </div>
    </main>
  </div>
</template>

EOL

  cat >src/views/SystemView.vue <<EOL
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import apiClient from '@/api/client'

const backendStatus = ref<string>('Checking connection...')
const error = ref<string | null>(null)

const checkBackendConnection = async () => {
  try {
    const response = await apiClient.get('/health_check')
    backendStatus.value = response.data.message
    error.value = null
  } catch (e) {
    backendStatus.value = 'Connection failed'
    error.value = 'Could not connect to the backend server'
  }
}

onMounted(() => {
  checkBackendConnection()
})
</script>

<template>
  <div class="min-h-screen bg-gray-100 py-6 flex flex-col justify-center sm:py-12">
    <div class="relative py-3 sm:max-w-xl sm:mx-auto">
      <div
        class="absolute inset-0 bg-gradient-to-r from-cyan-400 to-light-blue-500 shadow-lg transform -skew-y-6 sm:skew-y-0 sm:-rotate-6 sm:rounded-3xl">
      </div>
      <div class="relative px-4 py-10 bg-white shadow-lg sm:rounded-3xl sm:p-20">
        <div class="max-w-md mx-auto">
          <div class="divide-y divide-gray-200">
            <div class="py-8 text-base leading-6 space-y-4 text-gray-700 sm:text-lg sm:leading-7">
              <h1 class="text-2xl font-bold mb-4">Backend Connection Status</h1>
              <p class="mb-2" :class="{ 'text-green-600': !error, 'text-red-600': error }">
                {{ backendStatus }}
              </p>
              <p v-if="error" class="text-red-500 text-sm">
                {{ error }}
              </p>
              <button @click="checkBackendConnection"
                class="mt-4 px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                Check Connection
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

EOL

  cd ..
}

create_autogen_script() {
  print_status "自動生成スクリプトを作成しています..."

  mkdir -p scripts

  cd scripts
  pyenv local 3.11
  python -m venv venv
  pip install jinja2
  cd ..

  cat >scripts/markdown_parser.py <<'EOL'
from typing import List, Dict
import re

class InflectionUtils:
    """Utility class for handling singular/plural word forms"""
    
    # 不規則な単数形/複数形のマッピング
    IRREGULAR_WORDS = {
        'person': 'people',
        'child': 'children',
        'foot': 'feet',
        'man': 'men',
        'woman': 'women',
        'tooth': 'teeth',
        'mouse': 'mice',
        'datum': 'data'
    }
    
    @classmethod
    def singularize(cls, word: str) -> str:
        """単数形に変換"""
        # 不規則形のチェック(逆引き)
        for singular, plural in cls.IRREGULAR_WORDS.items():
            if word.lower() == plural:
                return singular
        
        # 基本的な複数形のルールを逆適用
        if word.endswith('ies'):
            return word[:-3] + 'y'
        elif word.endswith('es'):
            if word.endswith('sses') or word.endswith('shes') or word.endswith('ches'):
                return word[:-2]
            return word[:-1]
        elif word.endswith('s'):
            return word[:-1]
        
        return word

    @classmethod
    def pluralize(cls, word: str) -> str:
        """複数形に変換"""
        # 不規則形のチェック
        if word.lower() in cls.IRREGULAR_WORDS:
            return cls.IRREGULAR_WORDS[word.lower()]
        
        # 基本的な複数形のルール
        if word.endswith('y'):
            if word[-2].lower() not in 'aeiou':
                return word[:-1] + 'ies'
            return word + 's'
        elif word.endswith(('s', 'sh', 'ch', 'x', 'z')):
            return word + 'es'
        else:
            return word + 's'
    
    @classmethod
    def to_camel_case(cls, snake_str: str) -> str:
        """スネークケースからキャメルケースに変換"""
        # 最初の_の前はそのまま、それ以降は_を削除して次の文字を大文字に
        components = snake_str.split('_')
        return components[0] + ''.join(x.title() for x in components[1:])
    
    @classmethod
    def to_snake_case(cls, camel_str: str) -> str:
        return re.sub(r'(?<!^)(?=[A-Z])', '_', camel_str).lower()
    
    @classmethod
    def to_pascal_case(cls, snake_str: str) -> str:
        """スネークケースからパスカルケースに変換"""
        # まず、キャメルケースに変換
        camel = InflectionUtils.to_camel_case(snake_str)
        # 最初の文字を大文字にして返す
        return camel[0].upper() + camel[1:]

class MarkdownParser:
    def parse_markdown(self, markdown_content: str) -> List[Dict]:
        tables = []
        current_table = None
        
        for line in markdown_content.split('\n'):
            line = line.strip()
            
            if line.startswith('## '):
                if current_table:
                    tables.append(current_table)
                table_name = line[3:]
                singular_name = InflectionUtils.singularize(table_name)
                current_table = {
                    'name': singular_name,
                    'plural_name': table_name,
                    'columns': []
                }
            
            elif line.startswith('- ') and current_table:
                column_def = line[2:]
                name, type_def = column_def.split(': ')
                ts_type = self._map_type_to_typescript(type_def)
                current_table['columns'].append({
                    'name': name,
                    'ts_type': ts_type
                })
        
        if current_table:
            tables.append(current_table)
            
        return tables
    
    def _map_type_to_typescript(self, md_type: str) -> str:
        """Map markdown type definitions to TypeScript types"""
        type_mapping = {
            'number': 'number',
            'string': 'string',
            'Date': 'Date',
            'boolean': 'boolean',
        }
        return type_mapping.get(md_type, 'any')
EOL

  cat >scripts/ts_generator.py <<'EOL'
from jinja2 import Environment, FileSystemLoader
import os
from typing import List, Dict
from markdown_parser import MarkdownParser, InflectionUtils

class TypeScriptGenerator:
    def __init__(self, template_dir='templates'):
        self.env = Environment(
            loader=FileSystemLoader(template_dir),
            trim_blocks=True,
            lstrip_blocks=True
        )
        self.markdown_parser = MarkdownParser()
        # カスタムフィルターを登録
        self.env.filters['pascalcase'] = InflectionUtils.to_pascal_case
        self.env.filters['camelcase'] = InflectionUtils.to_camel_case
        self.env.filters['snakecase'] = InflectionUtils.to_snake_case
    
    def generate_from_markdown(self, markdown_path: str, output_dir: str):
        with open(markdown_path, 'r', encoding='utf-8') as f:
            markdown_content = f.read()
        
        tables = self.markdown_parser.parse_markdown(markdown_content)
        
        models_dir = os.path.join(output_dir, 'models')
        os.makedirs(models_dir, exist_ok=True)

        views_dir = os.path.join(output_dir, 'views')
        os.makedirs(views_dir, exist_ok=True)
        
        for table in tables:
            model_content = self.generate_model(table)
            model_path = os.path.join(models_dir, f'{table["name"].lower()}.ts')
            with open(model_path, 'w', encoding='utf-8') as f:
                f.write(model_content)

            data_view_content = self.generate_data_view(table)
            data_view_path = os.path.join(views_dir, f'{InflectionUtils.to_pascal_case(table["plural_name"])}DataView.vue')
            with open(data_view_path, 'w', encoding='utf-8') as f:
                f.write(data_view_content)
        
        api_content = self.generate_api(tables)
        api_path = os.path.join(output_dir, 'api/api.ts')
        with open(api_path, 'w', encoding='utf-8') as f:
            f.write(api_content)

        routes_content = self.generate_routes(tables)
        routes_path = os.path.join(output_dir, 'router/routes/database.ts')
        with open(routes_path, 'w', encoding='utf-8') as f:
            f.write(routes_content)
    
    def generate_model(self, table_definition: dict) -> str:
        template = self.env.get_template('typescript/model.ts')
        return template.render(table=table_definition)
    
    def generate_api(self, tables: List[Dict]) -> str:
        template = self.env.get_template('typescript/api.ts')
        return template.render(tables=tables)
    
    def generate_routes(self, tables: List[Dict]) -> str:
        template = self.env.get_template('typescript/routes.ts')
        return template.render(tables=tables)
    
    def generate_data_view(self, table_definition: dict) -> str:
        template = self.env.get_template('vue/DataView.vue')
        return template.render(table=table_definition)

if __name__ == '__main__':
    generator = TypeScriptGenerator()
    generator.generate_from_markdown('../doc/erd.md', '../frontend/src')

EOL

  cat >scripts/rb_generator.py <<'EOL'
from jinja2 import Environment, FileSystemLoader
import os
import glob
import re
from typing import List, Dict
from markdown_parser import MarkdownParser, InflectionUtils
from datetime import datetime, timedelta

class RubyGenerator:
    def __init__(self, template_dir='templates'):
        self.env = Environment(
            loader=FileSystemLoader(template_dir),
            trim_blocks=True,
            lstrip_blocks=True
        )
        self.markdown_parser = MarkdownParser()
        self.env.filters['pascalcase'] = InflectionUtils.to_pascal_case
        self.env.filters['camelcase'] = InflectionUtils.to_camel_case
        self.env.filters['snakecase'] = InflectionUtils.to_snake_case
        self.current_timestamp = None
    
    def _map_type_to_ruby(self, ts_type: str) -> str:
        type_mapping = {
            'number': 'integer',
            'string': 'string',
            'Date': 'datetime',
            'boolean': 'boolean'
        }
        return type_mapping.get(ts_type, 'string')

    def _map_type_to_sqlite(self, ruby_type: str) -> str:
        type_mapping = {
            'integer': 'INTEGER',
            'string': 'TEXT',
            'datetime': 'DATETIME',
            'boolean': 'BOOLEAN',
            'decimal': 'DECIMAL',
            'float': 'FLOAT'
        }
        return type_mapping.get(ruby_type, 'TEXT')

    def _remove_existing_migration(self, output_dir: str, table_name: str):
        """
        Remove existing migration files for a given table name
        """
        migration_dir = os.path.join(output_dir, 'db/migrate')
        if not os.path.exists(migration_dir):
            return

        # マイグレーションファイルのパターン: [timestamp]_create_[table_name].rb
        pattern = os.path.join(migration_dir, f'*_create_{table_name}.rb')
        existing_files = glob.glob(pattern)
        
        for file_path in existing_files:
            try:
                os.remove(file_path)
            except OSError as e:
                print(f"Error removing file {file_path}: {e}")

    def _generate_timestamp(self) -> str:
        """
        Generate unique timestamp for migration files
        Each call returns a timestamp 1 second later than the previous one
        """
        if self.current_timestamp is None:
            self.current_timestamp = datetime.now()
        else:
            self.current_timestamp += timedelta(seconds=1)
        
        return self.current_timestamp.strftime('%Y%m%d%H%M%S')

    def generate_from_markdown(self, markdown_path: str, output_dir: str):
        """Generate Ruby files from markdown definition"""
        self.current_timestamp = None
        
        with open(markdown_path, 'r', encoding='utf-8') as f:
            markdown_content = f.read()
        
        tables = self.markdown_parser.parse_markdown(markdown_content)

        self.save_files({'config/routes.rb': self.generate_routes(tables)}, output_dir)
        
        for table in tables:
            for column in table['columns']:
                ruby_type = self._map_type_to_ruby(column['ts_type'])
                sqlite_type = self._map_type_to_sqlite(ruby_type)
                column.update({
                    'ruby_type': ruby_type,
                    'sqlite_type': sqlite_type
                })
            
            # マイグレーションファイルを生成する前に既存のファイルを削除
            self._remove_existing_migration(output_dir, table['plural_name'].lower())
            
            files = self.generate_files(table)
            self.save_files(files, output_dir)

    def generate_files(self, table_definition: dict) -> dict:
        model_name = table_definition['name'].lower()
        plural_name = table_definition['plural_name'].lower()
        
        return {
            f'app/models/{model_name}.rb': self.generate_model(table_definition),
            f'app/controllers/api/v1/{plural_name}_controller.rb': self.generate_controller(table_definition),
            f'db/migrate/{self._generate_timestamp()}_create_{plural_name}.rb': self.generate_migration(table_definition)
        }

    def generate_model(self, table_definition: dict) -> str:
        template = self.env.get_template('ruby/model.rb')
        return template.render(table=table_definition)
    
    def generate_controller(self, table_definition: dict) -> str:
        template = self.env.get_template('ruby/controller.rb')
        return template.render(table=table_definition)
    
    def generate_routes(self, tables: List[Dict]) -> str:
        template = self.env.get_template('ruby/routes.rb')
        return template.render(tables=tables)
    
    def generate_migration(self, table_definition: dict) -> str:
        template = self.env.get_template('ruby/migration.rb')
        return template.render(table=table_definition)
    
    def save_files(self, files: dict, output_dir: str):
        for path, content in files.items():
            full_path = os.path.join(output_dir, f'{path}')
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(content)

if __name__ == '__main__':
    generator = RubyGenerator()
    generator.generate_from_markdown('../doc/erd.md', '../backend')

EOL

  print_success "自動生成スクリプトを作成しました"
}

create_autogen_template() {
  print_status "自動生成テンプレートを作成しています..."

  mkdir -p scripts/templates
  mkdir -p scripts/templates/vue
  mkdir -p scripts/templates/typescript
  mkdir -p scripts/templates/ruby

  cat >scripts/templates/vue/DataView.vue <<'EOL'
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

EOL

  cat >scripts/templates/typescript/api.ts <<'EOL'
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

EOL

  cat >scripts/templates/typescript/model.ts <<'EOL'
export class {{ table.name }} { 
    constructor(init?: Partial<{{ table.name }}>) {
        Object.assign(this, init);
    }

    {% for column in table.columns %}
    {{ column.name | camelcase }}?: {{ column.ts_type }};
    {% endfor %}
}

EOL

  cat >scripts/templates/typescript/routes.ts <<'EOL'
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

EOL

  cat >scripts/templates/ruby/routes.rb <<'EOL'
Rails.application.routes.draw do
    namespace :api do
      namespace :v1 do
        get 'health_check', to: 'health#check'
        {% for table in tables %}
        resources :{{ table.plural_name | lower }}
        {% endfor %}
      end
    end
  end

EOL

  cat >scripts/templates/ruby/controller.rb <<'EOL'
module Api
  module V1
    class {{ table.plural_name | pascalcase }}Controller < ApplicationController
      before_action :set_{{ table.name | lower }}, only: [:show, :update, :destroy]

      # GET /api/v1/{{ table.plural_name | lower }}
      def index
        {{ table.plural_name | lower }} = {{ table.name | pascalcase }}.all
        render json: {
          status: 'success',
          items: {{ table.plural_name | lower }},
          count: {{ table.plural_name | lower }}.count
        }
      end

      # GET /api/v1/{{ table.plural_name | lower }}/:id
      def show
        render json: {
          status: 'success',
          data: @{{ table.name | lower }}
        }
      end

      # POST /api/v1/{{ table.plural_name | lower }}
      def create
        {{ table.name | lower }} = {{ table.name | pascalcase }}.new({{ table.name | lower }}_params)
        if {{ table.name | lower }}.save
          render json: {
            status: 'success',
            data: {{ table.name | lower }}
          }, status: :created
        else
          render json: {
            status: 'error',
            message: {{ table.name | lower }}.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/{{ table.plural_name | lower }}/:id
      def update
        if @{{ table.name | lower }}.update({{ table.name | lower }}_params)
          render json: {
            status: 'success',
            data: @{{ table.name | lower }}
          }
        else
          render json: {
            status: 'error',
            message: @{{ table.name | lower }}.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/{{ table.plural_name | lower }}/:id
      def destroy
        @{{ table.name | lower }}.destroy
        render json: {
          status: 'success',
          message: '{{ table.name | pascalcase }} was successfully deleted'
        }
      end

      private

      def set_{{ table.name | lower }}
        @{{ table.name | lower }} = {{ table.plural_name | pascalcase }}.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: 'error',
          message: '{{ table.name | pascalcase }} not found'
        }, status: :not_found
      end

      def {{ table.name | lower }}_params
        params.require(:{{ table.name | lower }}).permit(:name, :email)
      end
    end
  end
end

EOL

  cat >scripts/templates/ruby/migration.rb <<'EOL'
class Create{{ table.plural_name | pascalcase }} < ActiveRecord::Migration[8.0]
  def change
    create_table :{{ table.plural_name | lower }} do |t|
      {% for column in table.columns %}
      {% if column.name not in ['id', 'created_at', 'updated_at'] %}
      t.{{ column.ruby_type }} :{{ column.name | lower }}
      {% endif %}
      {% endfor %}

      t.timestamps
    end
  end
end

EOL

  cat >scripts/templates/ruby/model.rb <<'EOL'
class {{ table.name | pascalcase }} < ApplicationRecord
end

EOL
}

create_dev_script() {
  print_status "開発サーバー起動スクリプトを作成しています..."

  cat >dev.sh <<'EOL'
#!/bin/bash
# フロントエンドとバックエンドを同時に起動

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 関数定義
cleanup() {
    echo "サーバーを停止しています..."
    kill $BACKEND_PID
    kill $FRONTEND_PID
    exit
}

# Ctrl+Cのシグナルをトラップ
trap cleanup INT TERM

echo "バックエンドサーバーを起動しています..."
cd "$SCRIPT_DIR/backend" && bundle exec rails server & 
BACKEND_PID=$!

echo "フロントエンドサーバーを起動しています..."
cd "$SCRIPT_DIR/frontend" && yarn dev & 
FRONTEND_PID=$!

echo "開発サーバーが起動しました！"
echo "バックエンド: http://localhost:3000"
echo "フロントエンド: http://localhost:5173"

# プロセスが終了するまで待機
wait
EOL

  chmod +x dev.sh
  print_success "開発サーバー起動スクリプトを作成しました"

  print_status "マイグレーションスクリプトを作成しています..."

  cat >migrate.sh <<'EOL'
#!/bin/bash

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "マイグレーションしています..."
cd backend
bundle exec rails db:migrate

echo "マイグレーションが完了しました"
bundle exec rails db:migrate:status
EOL

  chmod +x migrate.sh
  print_success "マイグレーションスクリプトを作成しました"

  print_status "自動生成スクリプトを作成しています..."

  cat >generate.sh <<'EOL'
#!/bin/bash
# erd.mdからコードを自動生成

# スクリプトのディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "ソースコードを生成しています..."

cd scripts

python ./rb_generator.py
python ./ts_generator.py

cd ..

echo "ソースコードの生成が完了しました"

EOL

  chmod +x generate.sh
  print_success "自動生成スクリプトを作成しました"
}

create_documents() {
  print_status "ドキュメントを作成しています..."

  mkdir -p doc

  cat >doc/erd.md <<'EOL'
# Tables
## Users
- id: number
- name: string
- email: string
- created_at: Date
- updated_at: Date

## Tasks
- id: number
- name: string
- description: string
- due_date: Date
- priority: number
- created_at: Date
- updated_at: Date

EOL

  print_success "ドキュメントを作成しました"
}

# メイン処理
main() {
  print_status "開発環境のセットアップを開始します..."

  check_dependencies
  check_directory

  setup_backend
  setup_frontend

  create_components
  create_autogen_script
  create_autogen_template

  create_documents
  create_dev_script

  print_success "セットアップが完了しました！"
  print_status "以下のコマンドで開発サーバーを起動できます:"
  print_status "./dev.sh"
}

# エラーハンドリングの設定
set -e
trap 'handle_error "予期せぬエラーが発生しました"' ERR

# スクリプトの実行
main

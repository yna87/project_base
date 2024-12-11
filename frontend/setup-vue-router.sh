#!/bin/bash

# プロジェクトのソースディレクトリを作成
mkdir -p src/views
mkdir -p src/router

# App.vueファイルを作成
cat << 'EOF' > src/App.vue
<template>
  <div id="app">
    <nav>
      <router-link to="/projects">プロジェクト一覧</router-link> |
      <router-link to="/calendar">カレンダー</router-link> |
      <router-link to="/tasks">タスク一覧</router-link>
    </nav>
    <router-view/>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'App'
});
</script>

<style>
#app {
  font-family: Arial, sans-serif;
}

nav {
  padding: 30px;
}

nav a {
  font-weight: bold;
  color: #2c3e50;
  text-decoration: none;
  padding: 10px;
}

nav a.router-link-exact-active {
  color: #42b983;
}
</style>
EOF

# 各Viewコンポーネントのテンプレートを作成
cat << 'EOF' > src/views/ProjectListView.vue
<template>
  <div class="projects">
    <h1>プロジェクト一覧</h1>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'ProjectListView'
});
</script>
EOF

cat << 'EOF' > src/views/CalendarView.vue
<template>
  <div class="calendar">
    <h1>カレンダー</h1>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'CalendarView'
});
</script>
EOF

cat << 'EOF' > src/views/TaskListView.vue
<template>
  <div class="tasks">
    <h1>タスク一覧</h1>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'TaskListView'
});
</script>
EOF

# router/index.tsファイルを作成
cat << 'EOF' > src/router/index.ts
import { createRouter, createWebHistory, RouteRecordRaw } from 'vue-router';
import ProjectListView from '../views/ProjectListView.vue';
import CalendarView from '../views/CalendarView.vue';
import TaskListView from '../views/TaskListView.vue';

const routes: Array<RouteRecordRaw> = [
  {
    path: '/',
    redirect: '/projects'
  },
  {
    path: '/projects',
    name: 'projects',
    component: ProjectListView
  },
  {
    path: '/calendar',
    name: 'calendar',
    component: CalendarView
  },
  {
    path: '/tasks',
    name: 'tasks',
    component: TaskListView
  }
];

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes
});

export default router;
EOF

# main.tsファイルを作成
cat << 'EOF' > src/main.ts
import { createApp } from 'vue';
import App from './App.vue';
import router from './router';

const app = createApp(App);
app.use(router);
app.mount('#app');
EOF

# 実行権限を付与
chmod +x setup-vue-router.sh

echo "Vue Router setup completed successfully!"
EOF
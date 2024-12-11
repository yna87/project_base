<script lang="ts">
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'App'
});
</script>

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

<style scoped>
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


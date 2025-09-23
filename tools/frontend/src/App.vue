<template>
  <div id="app">
    <Login v-if="!isAuthenticated" />
    <MainApp v-else />
  </div>
</template>

<script>
import Login from './components/Login.vue'
import MainApp from './components/MainApp.vue'

export default {
  name: 'App',
  components: {
    Login,
    MainApp
  },
  data() {
    return {
      isAuthenticated: false
    }
  },
  mounted() {
    // Check if user is already authenticated
    const auth = localStorage.getItem('auth')
    if (auth) {
      this.isAuthenticated = true
    }
  }
}
</script>
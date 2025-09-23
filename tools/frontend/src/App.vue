<template>
  <div id="app" :class="themeClass">
    <Login v-if="!isAuthenticated" />
    <MainApp v-else :theme="theme" @theme-changed="changeTheme" />
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
      isAuthenticated: false,
      theme: 'dark' // Default to dark theme
    }
  },
  computed: {
    themeClass() {
      return `theme-${this.theme}`
    }
  },
  mounted() {
    // Check if user is already authenticated
    const auth = localStorage.getItem('auth')
    if (auth) {
      this.isAuthenticated = true
    }
    
    // Load theme from localStorage or default to dark
    const savedTheme = localStorage.getItem('theme')
    if (savedTheme) {
      this.theme = savedTheme
    }
  },
  methods: {
    changeTheme(newTheme) {
      this.theme = newTheme
      localStorage.setItem('theme', newTheme)
    }
  }
}
</script>

<style>
/* Dark theme styles */
.theme-dark {
  --bg-primary: #1a202c;
  --bg-secondary: #2d3748;
  --text-primary: #f7fafc;
  --text-secondary: #e2e8f0;
  --border-color: #4a5568;
  --button-primary: #4299e1;
  --button-primary-hover: #3182ce;
  --button-danger: #e53e3e;
  --button-danger-hover: #c53030;
  --button-success: #48bb78;
  --button-success-hover: #38a169;
  --status-running: #48bb78;
  --status-stopped: #e53e3e;
  --status-pending: #ed8936;
}

/* Light theme styles */
.theme-light {
  --bg-primary: #f7fafc;
  --bg-secondary: #edf2f7;
  --text-primary: #1a202c;
  --text-secondary: #4a5568;
  --border-color: #cbd5e0;
  --button-primary: #4299e1;
  --button-primary-hover: #3182ce;
  --button-danger: #e53e3e;
  --button-danger-hover: #c53030;
  --button-success: #48bb78;
  --button-success-hover: #38a169;
  --status-running: #48bb78;
  --status-stopped: #e53e3e;
  --status-pending: #ed8936;
}

/* Apply theme variables */
body {
  background-color: var(--bg-primary);
  color: var(--text-primary);
  transition: background-color 0.3s, color 0.3s;
}

/* Update button styles to use theme variables */
.bg-indigo-600 {
  background-color: var(--button-primary);
}

.bg-indigo-600:hover {
  background-color: var(--button-primary-hover);
}

.bg-red-600 {
  background-color: var(--button-danger);
}

.bg-red-600:hover {
  background-color: var(--button-danger-hover);
}

.bg-green-600 {
  background-color: var(--button-success);
}

.bg-green-600:hover {
  background-color: var(--button-success-hover);
}
</style>
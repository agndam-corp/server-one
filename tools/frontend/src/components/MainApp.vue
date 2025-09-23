<template>
  <div class="min-h-screen flex flex-col" :class="themeClass">
    <header class="shadow">
      <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8 flex justify-between items-center">
        <h1 class="text-3xl font-bold">VPN Control Panel</h1>
        <div class="flex items-center space-x-4">
          <div class="flex items-center">
            <span class="mr-2">Light</span>
            <button 
              @click="toggleTheme"
              class="relative inline-flex h-6 w-11 items-center rounded-full"
              :class="theme === 'dark' ? 'bg-indigo-600' : 'bg-gray-300'"
            >
              <span class="sr-only">Toggle theme</span>
              <span 
                class="inline-block h-4 w-4 transform rounded-full bg-white transition"
                :class="theme === 'dark' ? 'translate-x-6' : 'translate-x-1'"
              ></span>
            </button>
            <span class="ml-2">Dark</span>
          </div>
          <button 
            @click="logout"
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
          >
            Logout
          </button>
        </div>
      </div>
    </header>
    <main class="flex-grow">
      <div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="px-4 py-6 sm:px-0">
          <div class="shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h2 class="text-lg leading-6 font-medium">VPN Instance Control</h2>
              <div class="mt-4">
                <div class="flex items-center">
                  <span class="text-sm font-medium">Status:</span>
                  <span class="ml-2 px-2 inline-flex text-xs leading-5 font-semibold rounded-full" 
                        :class="{
                          'bg-green-100 text-green-800': status === 'running',
                          'bg-red-100 text-red-800': status === 'stopped',
                          'bg-yellow-100 text-yellow-800': status === 'pending' || status === 'stopping'
                        }">
                    {{ status }}
                  </span>
                </div>
                <div class="mt-4 flex space-x-4">
                  <button 
                    @click="startInstance"
                    :disabled="status === 'running' || status === 'pending'"
                    class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50"
                  >
                    Start VPN
                  </button>
                  <button 
                    @click="stopInstance"
                    :disabled="status === 'stopped' || status === 'stopping'"
                    class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-50"
                  >
                    Stop VPN
                  </button>
                  <button 
                    @click="refreshStatus"
                    class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    :class="theme === 'dark' ? 'text-white bg-gray-700 hover:bg-gray-600 border-gray-600' : 'text-gray-700 bg-white hover:bg-gray-50 border-gray-300'"
                  >
                    Refresh
                  </button>
                </div>
              </div>
              <div v-if="message" class="mt-4 p-4 rounded-md" :class="{
                'bg-green-50 text-green-800': messageType === 'success',
                'bg-red-50 text-red-800': messageType === 'error'
              }">
                <p>{{ message }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<script>
import axios from 'axios'

export default {
  props: {
    theme: {
      type: String,
      default: 'dark'
    }
  },
  data() {
    return {
      status: 'unknown',
      message: '',
      messageType: 'success'
    }
  },
  computed: {
    themeClass() {
      return `theme-${this.theme}`
    }
  },
  mounted() {
    // Set up axios with basic auth credentials
    const auth = localStorage.getItem('auth')
    if (auth) {
      axios.defaults.headers.common['Authorization'] = `Basic ${auth}`
    }
    this.refreshStatus()
  },
  methods: {
    toggleTheme() {
      const newTheme = this.theme === 'dark' ? 'light' : 'dark'
      this.$emit('theme-changed', newTheme)
    },
    async refreshStatus() {
      try {
        const response = await axios.get('https://api.djasko.com/status')
        this.status = response.data.state
        this.message = ''
      } catch (error) {
        this.message = `Error: ${error.response?.data?.error || error.message}`
        this.messageType = 'error'
      }
    },
    async startInstance() {
      try {
        await axios.post('https://api.djasko.com/start')
        this.message = 'Start command sent successfully'
        this.messageType = 'success'
        // Refresh status after a short delay
        setTimeout(() => this.refreshStatus(), 2000)
      } catch (error) {
        this.message = `Error: ${error.response?.data?.error || error.message}`
        this.messageType = 'error'
      }
    },
    async stopInstance() {
      try {
        await axios.post('https://api.djasko.com/stop')
        this.message = 'Stop command sent successfully'
        this.messageType = 'success'
        // Refresh status after a short delay
        setTimeout(() => this.refreshStatus(), 2000)
      } catch (error) {
        this.message = `Error: ${error.response?.data?.error || error.message}`
        this.messageType = 'error'
      }
    },
    logout() {
      // Remove auth credentials and reload page
      localStorage.removeItem('auth')
      window.location.reload()
    }
  }
}
</script>

<style scoped>
/* Apply theme variables */
.shadow {
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
}

.theme-dark .shadow.overflow-hidden {
  background-color: #2d3748;
  color: #f7fafc;
  border: 1px solid #4a5568;
}

.theme-light .shadow.overflow-hidden {
  background-color: #edf2f7;
  color: #1a202c;
  border: 1px solid #cbd5e0;
}

.shadow.overflow-hidden.sm\:rounded-lg {
  border-radius: 0.5rem;
}

.bg-green-100 {
  background-color: #48bb78;
  opacity: 0.2;
}

.text-green-800 {
  color: #48bb78;
}

.bg-red-100 {
  background-color: #e53e3e;
  opacity: 0.2;
}

.text-red-800 {
  color: #e53e3e;
}

.bg-yellow-100 {
  background-color: #ed8936;
  opacity: 0.2;
}

.text-yellow-800 {
  color: #ed8936;
}

.bg-green-600 {
  background-color: #48bb78;
}

.bg-green-600:hover {
  background-color: #38a169;
}

.bg-red-600 {
  background-color: #e53e3e;
}

.bg-red-600:hover {
  background-color: #c53030;
}

header {
  background-color: var(--bg-secondary, #2d3748);
  color: var(--text-primary, #f7fafc);
}

/* Theme variables */
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
</style>
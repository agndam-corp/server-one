<template>
  <div class="min-h-screen bg-gray-100 flex flex-col">
    <header class="bg-white shadow">
      <div class="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
        <h1 class="text-3xl font-bold text-gray-900">VPN Control Panel</h1>
      </div>
    </header>
    <main class="flex-grow">
      <div class="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        <div class="px-4 py-6 sm:px-0">
          <div class="bg-white shadow overflow-hidden sm:rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <h2 class="text-lg leading-6 font-medium text-gray-900">VPN Instance Control</h2>
              <div class="mt-4">
                <div class="flex items-center">
                  <span class="text-sm font-medium text-gray-500">Status:</span>
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
                    class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md shadow-sm text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
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

// Configure axios with credentials
axios.defaults.withCredentials = true

export default {
  data() {
    return {
      status: 'unknown',
      message: '',
      messageType: 'success'
    }
  },
  mounted() {
    this.refreshStatus()
  },
  methods: {
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
    }
  }
}
</script>
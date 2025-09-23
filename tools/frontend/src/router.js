import { createRouter, createWebHistory } from 'vue-router'
import Login from './components/Login.vue'
import MainApp from './components/MainApp.vue'

const routes = [
  {
    path: '/',
    name: 'MainApp',
    component: MainApp
  },
  {
    path: '/login',
    name: 'Login',
    component: Login
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Navigation guard to protect routes
router.beforeEach((to, from, next) => {
  const auth = localStorage.getItem('auth')
  
  // If trying to access main app without auth, redirect to login
  if (to.name !== 'Login' && !auth) {
    next({ name: 'Login' })
  } 
  // If trying to access login while authenticated, redirect to main app
  else if (to.name === 'Login' && auth) {
    next({ name: 'MainApp' })
  } 
  // Otherwise, proceed normally
  else {
    next()
  }
})

export default router
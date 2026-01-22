<template>
  <div>
    <h1>Login</h1>
    <form @submit.prevent="handleLogin">
      <div>
        <label for="username">Username:</label>
        <input type="text" id="username" v-model="loginForm.login" required />
      </div>
      <div>
        <label for="password">Password:</label>
        <input type="password" id="password" v-model="loginForm.password" required />
      </div>
      <button type="submit">Log In</button>
    </form>
    <p v-if="errorMessage" class="error-message">{{ errorMessage }}</p>
  </div>
</template>


<script lang="ts">
export default {
  name: 'LoginView',
  inject: [
    'accountService'
  ],
  data() {
    return {
      loginForm: {
        login: '',
        password: '',
      },
      errorMessage: '',
    };
  },
  methods: {
    async handleLogin() {
      //try {
        this.accountService.login(this.loginForm)
      //} catch (e) {
      //  this.errorMessage = `${e}`
      //}
      this.$router.push('/matches');
    },
  },
};
</script>

<style scoped>
.error-message {
  color: red;
  margin-top: 10px;
}
</style>

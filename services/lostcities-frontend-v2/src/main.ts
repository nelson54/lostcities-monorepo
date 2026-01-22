import "./assets/main.css";

import { createApp } from "vue";
import { createPinia } from "pinia";

import App from "./App.vue";
import router from "./router.ts";
import AccountService from "@/shared/AccountService.ts";
import LocalAuthRepository from "@/shared/LocalAuthRepository.ts";

const app = createApp(App);

app.use(createPinia());
app.use(router);

app.mount("#app");

const localAuthRepo = new LocalAuthRepository()
const accountService = new AccountService(localAuthRepo)

app.provide('accountService', accountService)
app.provide('localAuthRepo', localAuthRepo)

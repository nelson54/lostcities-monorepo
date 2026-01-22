import { createRouter, createWebHistory } from "vue-router";
import HomeView from "./views/HomeView.vue";
import LoginView from "./views/LoginView.vue";
import LocalAuthRepository from "@/shared/LocalAuthRepository.ts";

const localAuthRepo = new LocalAuthRepository()

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: "/",
      name: "home",
      component: HomeView,
    },
    {
      path: "/login",
      name: "login",
      component: LoginView,
    },
    {
      path: "/matches",
      name: "matches",
      // route level code-splitting
      // this generates a separate chunk (About.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: () => import("./views/Matches/MatchesView.vue"),
      meta: { requiresAuth: true },

    },
    {
      path: "/game/:id",
      name: "game",
      // route level code-splitting
      // this generates a separate chunk (About.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: () => import("./views/Game/GameView.vue"),
      meta: { requiresAuth: true },

    },
  ],
});

router.beforeEach((to, from, next) => {
  const isAuthenticated = localAuthRepo.get().isAuthenticated
  const requiresAuth = to.meta.requiresAuth;

  if (requiresAuth && !isAuthenticated) {
    next('/login');
  } else {
    next()
  }
});

export default router;

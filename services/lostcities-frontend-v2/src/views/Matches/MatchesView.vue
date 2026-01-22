<template>
  <div>
    <h1>Matches</h1>
    <button v-on:click="createMatch(false)">Create Ranked Match</button>
    <button v-on:click="createMatch(true)">Create AI Match</button>
    <p v-if="errorMessage" class="error-message">{{ errorMessage }}</p>
    <div v-if="isLoading">
      Loading
    </div>
    <div v-else-if="activeMatches.empty === false">
      <ul>
        <li v-for="match in activeMatches.content" :key="match.id">
          <div>
            <div>
              <p :class="{active: match.players.user1 === match.currentPlayer}">{{match.players.user1}}</p>
              <p :class="{active: match.players.user2 === match.currentPlayer}">{{match.players.user2}}</p>
            </div>
            <button>Resign</button>
            <router-link :to="{name: 'game', params: {id: match.id}}" class="button-style">
              Play
            </router-link>

          </div>
        </li>
      </ul>
      <div>
        <button :disabled="activeMatches.first"><</button>
        <span>{{activeMatches.number + 1}} of {{activeMatches.totalPages}}</span>
        <button :disabled="activeMatches.last">></button>
      </div>
    </div>
    <div v-else>
      No Active Matches
    </div>

    <div v-if="isLoading">
      Loading Available Matches
    </div>
    <div v-else-if="availableMatches.empty === false">
      <ul >
        <li v-for="match in availableMatches.content" :key="match.id">

          <p>
            <span>{{match.players.player1}}</span>
            <span>{{match.players.player2}}</span>
          </p>
          <button>Join {{ match.id }}</button>
        </li>
      </ul>
      <div>
        <button :disabled="availableMatches.first"><</button>
        <span>{{availableMatches.number + 1}} of {{availableMatches.totalPages}}</span>
        <button :disabled="availableMatches.last">></button>
      </div>
    </div>
    <div v-else>
      No Available Matches
    </div>

  </div>
</template>

<script>

import axios from 'axios';

import MatchesService from "./MatchesService.js"
import GameView from "@/views/Game/GameView.vue";
export default {
  name: 'MatchesView',
  computed: {
    GameView() {
      return GameView
    }
  },
  data() {
    return {
      isLoading: true,
      matches: [],
      currentPage: 0,
      totalPages: 0,
      errorMessage: null,
      activeMatches: {
        empty: true
      },
      availableMatches: {
        empty: true
      }
    };
  },
  mounted() {
    this.matchesService = new MatchesService()
    this.loadMatches()
  },
  methods: {
    async loadMatches() {
      this.activeMatches = await this.matchesService.getActiveMatches()
      this.availableMatches = await this.matchesService.getAvailableMatches()

      console.dir(this.activeMatches)
      console.dir(this.availableMatches)
      this.isLoading = false
    },
    async createMatch(isAi) {
      this.isLoading = true
      await this.matchesService.create(isAi)
      return this.loadMatches()
    }
  },
};




</script>

<style scoped>
.active {
  font-weight: bolder;
}
.error-message {
  color: red;
  margin-top: 10px;
}
</style>

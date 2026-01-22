<template>
  <div class="game">
    <h1>Game View</h1>
  </div>
</template>

<script lang="ts">
import GameService from "./GameService.ts";

interface GameViewModel {
  isLoading: Boolean,
  gameId: string | null,
  gameService: GameService | null,
  game: Object | null

}

export default {
  name: 'GameView',
  data(): GameViewModel {
    return {
      isLoading: true,
      gameId: null,
      gameService: null,
      game: null
    };
  },
  mounted() {
    this.gameService = new GameService()
    this.gameId = this.$route.params.id as string
    this.loadGame().then((game) => {
      this.game = game
    })
  },
  methods: {
    async loadGame() {
      if(this.gameId != null) {
        this.isLoading = true
        return this.gameService?.retrieveGameState(Number.parseInt(this.gameId))
      }
    }
  }
}

</script>
<style>

</style>

import axios, {type AxiosInstance} from 'axios';
import SockJS from "sockjs-client"
import Stomp from "stompjs"

import LocalAuthRepository from "@/shared/LocalAuthRepository.ts";


const localAuthRepo = new LocalAuthRepository()

interface Card {
  id: string
}
interface GameCommand {
  card: Card,
  draw: string,
}
interface Command {
  card: String,
  draw: string,
}
export default class GameService {
  private axios: AxiosInstance
  private stomp?: Stomp.Client
  private sock?: WebSocket


  constructor() {
    this.axios = axios.create({
      baseURL: import.meta.env.GAME_API,
      timeout: 2000

    })

    this.axios.interceptors.request.use(function (config) {

      if (localAuthRepo.isAuthenticated()) {
        config.headers["Authorization"] = `Bearer ${localAuthRepo.get().token}`
      } else {
        config.headers["Authorization"] = null;
      }

      return config;
    }, function (error) {
      console.log(error);
      return Promise.reject(error);
    })
  }

  disconnect() {
    if (this.stomp !== null) {
      this.stomp?.disconnect(() => {
        console.log("Disconnected");
      });
    }


  }

  listenForChanges(id: Number, login: String) {
    this.sock = new SockJS('/api/player-events/lost-cities')

    this.stomp = Stomp.over(this.sock)

    this.stomp.connect({}, (frame) => {
      console.log('Connected: ' + frame);
      this.stomp?.subscribe(`/games-broker/${id}/${login}`, async (gamestate) => {
        let gameState = JSON.parse(gamestate.body)
        //await store._actions["gameInfo/reset"][0]()
        //await store._actions["gameInfo/mergeGame"][0](gameState)
      });

      this.stomp?.subscribe(`/games-broker/${id}/${login}/errors`, async (errorResponse) => {
        let errorMessage = JSON.parse(errorResponse.body)
        console.dir({
          text: errorMessage.error,
          type: 'success'
        })
      });
    });
  }

  async retrieveGameState(id: Number) {
    try {
      //await store._actions["gameInfo/reset"][0]()
      //await store._actions["gameInfo/startLoading"][0]()
      let response = await this.axios.get(`/api/gamestate/${id}`)
      //this.store = store;
      //await store._actions["gameInfo/mergeGame"][0](response.data)
      //await store._actions["gameInfo/doneLoading"][0]()

      return response.data
    } catch(e) {
      console.error(e)
      throw new Error("Unable to get game.")
    }
  }

  async playCommand(id: Number , gameCommand: GameCommand) {
    try {
      let command: Command = {
        card: gameCommand.card.id,
        draw: gameCommand.draw
      }


      //await store._actions["gameInfo/startLoading"][0]()
      let response = await this.axios.patch(`/api/gamestate/${id}`, command)
      //await store._actions["gameInfo/doneLoading"][0]()

      return response.data
    } catch(e) {
      throw new Error("Unable to get game.")
    }
  }

}

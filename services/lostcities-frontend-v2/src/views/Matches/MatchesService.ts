import LocalAuthRepository from "@/shared/LocalAuthRepository.ts";
import axios, {type AxiosInstance} from "axios";

export default class MatchesService {
  private axios: AxiosInstance
  constructor() {
    let localAuthRepo = new LocalAuthRepository()
    this.axios = axios.create({
      baseURL: import.meta.env.MATCHES_API,
      timeout: 2000

    })

    //this.axios.defaults.trailingSlash = false;

    this.axios.interceptors.request.use(function (config) {
      if(localAuthRepo.isAuthenticated()) {
        config.headers['Authorization'] = `Bearer ${localAuthRepo.get().token}`
      } else {
        config.headers['Authorization'] = null;
      }

      return config;
    }, function (error) {
      console.log(error);
      return Promise.reject(error);
    })
  }

  async create(isAi: Boolean) {
    let url = `/api/matches`

    try {
      let response = await this.axios.post(url, {isAi: !!isAi})
      return response.data
    } catch(e) {
      throw new Error("Unable to create match.")
    }
  }

  async createBatchAiMatches(count=1000) {
    let url = `/api/matches/admin/ai/matches`

    try {
      let response = await this.axios.post(url, {isAi: true, count: count})
      return response.data
    } catch(e) {
      throw new Error("Unable to create match.")
    }
  }

  async join(id: Number) {
    try {
      let response = await this.axios.patch(`/api/matches/${id}`)
      return response.data
    } catch(e) {
      throw new Error("Unable to create match.")
    }
  }

  async getActiveMatches() {
    try {
      let response = await this.axios.get('/api/matches/active')
      return response.data
    } catch(e) {
      throw new Error("Unable to get matches.")
    }
  }

  async getAvailableMatches() {
    try {
      let response = await this.axios.get('/api/matches/available')
      return response.data
    } catch(e) {
      throw new Error("Unable to get matches.")
    }
  }

  async resendMatches() {
    try {
      return await this.axios.get('/api/matches/resend')

    } catch(e) {
      throw new Error("Unable to get matches.")
    }
  }
}

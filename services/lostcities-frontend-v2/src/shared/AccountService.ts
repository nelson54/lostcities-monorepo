import axios from 'axios';
import type { AxiosInstance } from 'axios';
import type LocalAuthRepository from "@/shared/LocalAuthRepository.ts";

interface LoginForm {
  login: string;
  password: string;
}

interface LoginResponse {
  login?: string
  token?: string
}

interface RegistrationForm {
  login: string,
  password: string,
  email: string,
}

export default class AccountService {
  private axios: AxiosInstance;
  private localAuthRepo: LocalAuthRepository

  constructor(localAuthRepo: LocalAuthRepository) {
    this.axios = axios.create({
      baseURL: import.meta.env.ACCOUNTS_API
    })
    this.localAuthRepo = localAuthRepo
  }

  async login(loginForm: LoginForm) {
    if(!this._isValidLogin(loginForm)) {
      throw new Error("Invalid login.")
    }

    try {
      let response = await this.axios.post<LoginResponse>('/api/accounts/authenticate', loginForm)

      if(response.data.login && response.data.token) {
        this.localAuthRepo.store({
          isAuthenticated: true,
          ...response.data
        })
      }

      return response.data
    } catch(e) {
      console.dir(e)
      throw new Error("Unable to authenticate.")
    }
  }

  logout() {
    this.localAuthRepo.clear()
  }

  async register(registrationForm: RegistrationForm) {
    if(!this._isValidRegistration(registrationForm)) {
      throw new Error("Invalid registeration form.")
    }

    try {
      return this.axios.post<RegistrationForm>(
        '/api/accounts/register',
        registrationForm
      )
    } catch(e: unknown) {
      throw new Error(`Unable to register, ${e}`)
    }
  }

  _isValidLogin(loginRequest: LoginForm) {
    return this.validateField(loginRequest.login) &&
      this.validateField(loginRequest.password);
  }

  _isValidRegistration(registrationForm: RegistrationForm) {
    return this.validateField(registrationForm.login) &&
      this.validateField(registrationForm.email) &&
      this.validateField(registrationForm.password)
  }


  validateField(field: string | unknown) {
    return typeof field === "string" && field.length > 2;
  }
}

const AUTH_VALUE = 'auth'

interface Authentication {
  isAuthenticated: boolean
  login?: string
  token?: string
}

export default class LocalAuthRepository {
    isAuthenticated() {
        return this.get() && this.get().token
    }

    get(): Authentication {
        let auth = localStorage.getItem(AUTH_VALUE)

        if(!auth) {
            return {
              isAuthenticated: false
            }
        }

        return JSON.parse(auth);
    }

    store(auth: Authentication) {
        if(!auth) {
            return
        }

        localStorage.setItem(AUTH_VALUE, JSON.stringify(auth));
    }

    clear() {
        localStorage.removeItem(AUTH_VALUE)
    }
}

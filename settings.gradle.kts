rootProject.name = "lostcities-composite"

include(":lostcities-accounts")
project(":lostcities-accounts").projectDir = File(settingsDir, "./services/lostcities-accounts")

include(":lostcities-gamestate")
project(":lostcities-gamestate").projectDir = File(settingsDir, "./services/lostcities-gamestate")

include(":lostcities-matches")
project(":lostcities-matches").projectDir = File(settingsDir, "./services/lostcities-matches")

include(":lostcities-player-events")
project(":lostcities-player-events").projectDir = File(settingsDir, "./services/lostcities-player-events")

include(":lostcities-frontend")
project(":lostcities-frontend").projectDir = File(settingsDir, "./services/lostcities-frontend")

include(":lostcities-frontend-v2")
project(":lostcities-frontend-v2").projectDir = File(settingsDir, "./services/lostcities-frontend-v2")


include(":lostcities-common")
project(":lostcities-common").projectDir = File(settingsDir, "./services/lostcities-common")

include(":lostcities-models")
project(":lostcities-models").projectDir = File(settingsDir, "./services/lostcities-models")



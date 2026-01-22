git submodule deinit services/lostcities-accounts
git submodule deinit services/lostcities-common
git submodule deinit services/lostcities-frontend
git submodule deinit services/lostcities-gamestate
git submodule deinit services/lostcities-infrastructure
git submodule deinit services/lostcities-matches
git submodule deinit services/lostcities-models
git submodule deinit services/lostcities-player-events


git rm services/lostcities-accounts
git rm services/lostcities-common
git rm services/lostcities-frontend
git rm services/lostcities-gamestate
git rm services/lostcities-infrastructure
git rm services/lostcities-matches
git rm services/lostcities-models
git rm services/lostcities-player-events


git subtree add --prefix=services/lostcities-accounts
git subtree add --prefix=services/lostcities-common
git subtree add --prefix=services/lostcities-frontend
git subtree add --prefix=services/lostcities-gamestate
git subtree add --prefix=services/lostcities-infrastructure
git subtree add --prefix=services/lostcities-matches
git subtree add --prefix=services/lostcities-models
git subtree add --prefix=services/lostcities-player-events


rm -rf services/lostcities-accounts/.git
rm -rf services/lostcities-common/.git
rm -rf services/lostcities-frontend/.git
rm -rf services/lostcities-gamestate/.git
rm -rf services/lostcities-infrastructure/.git
rm -rf services/lostcities-matches/.git
rm -rf services/lostcities-models/.git
rm -rf services/lostcities-player-events/.git
git rm --cached services/lostcities-accounts

git rm --cached services/lostcities-accounts -f
git rm --cached services/lostcities-common  -f
git rm --cached services/lostcities-frontend  -f
git rm --cached services/lostcities-gamestate  -f
git rm --cached services/lostcities-infrastructure -f
git rm --cached services/lostcities-matches -f
git rm --cached services/lostcities-models -f
git rm --cached services/lostcities-player-events -f

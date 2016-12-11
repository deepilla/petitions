
### Build Instructions

elm-make [--warn] --output=assets/js/elm.js src/elm/Main.elm

sass [--watch] [--sourcemap=none] src/scss/main.scss:assets/css/main.css

### TODO

#### Features

- Search for a petition
- Handle edge cases (no signatures, 1 signature, all signatures in country etc.)
- Remove petitions from saved/recent petition lists
- Auto-load petitions specified in the url query parameters
- Show a "try again" link when petitions fail to load
- At the minimum, warn the user if localStorage is unavailable

#### Design

- Make responsive

#### Project

- Tests
- Automated build and deploy

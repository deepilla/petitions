# Petitions

Petitions is a viewer for UK Government Petitions data.

The [UK Government Petitions](https://petition.parliament.uk/) website is like change.org for political issues affecting the UK. This app shows petition signatures broken out by country and by UK constituency. Try it out [here](http://petitions.deepilla.com).

### Build Instructions

Building is currently a manual process. I'm looking into ways to automate it.

Compile Elm code:

`elm-make [--warn] --output=assets/js/elm.js src/elm/Main.elm`

Compile Sass:

`sass [--watch] src/scss/main.scss:assets/css/main.css`

### TODO

#### Features

- Search for a petition
- Show a "Try again" link when a petition fails to load
- Warn the user if localStorage is unavailable
- Add links to petition lists for removing/clearing petitions
- Make sure edge cases are handled sensibly (no signatures, 1 signature, all signatures in 1 country etc.)

#### Design

- Responsiveness

#### Project

- Automate the build (e.g. with Brunch, Gulp, NPM, make...?)
- Unit tests (with elm-test)

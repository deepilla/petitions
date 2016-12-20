# Petitions

Petitions is a viewer for UK Government Petitions data.

The [UK Government Petitions](https://petition.parliament.uk/) website is like change.org for political issues affecting the UK. This app shows petition signatures broken out by country and by UK constituency. Try it out [here](http://petitions.deepilla.com).

### Build Instructions

Building is currently a manual process. I'm looking into ways to automate it.

Compile Elm code:

`elm-make [--warn] --output=assets/js/elm.js src/elm/Main.elm`

Compile Sass:

`sass [--watch] src/scss/styles.scss:assets/css/styles.css`

### TODO

#### Features

- Navigation (via History API and document title)
- Petition search
- Transitions between screens
- Show a "Try again" link when a petition fails to load
- Handle edge cases sensibly (e.g. no signatures, 1 signature, all signatures in 1 country)
- Warn if localStorage is unavailable
- Add remove/clear petitions links to petition lists

#### Design

- Responsiveness

#### Project

- Automated build
- Tests

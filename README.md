# Petitions

Petitions is a viewer for UK Government Petitions data.

The [UK Government Petitions](https://petition.parliament.uk/) website is like change.org for political issues affecting the UK. This app shows petition signatures broken out by country and by UK constituency. Try it out [here](http://petitions.deepilla.com).

## Install/Build

Builds are automated via NPM scripts. If you don't have/like NPM, it's easy enough to build the project manually. Either way, start by cloning the repo and then do one of the following:

### Build With NPM (Recommended)

1. Run `npm install` in the root directory to install Elm, Sass and other build dependencies
2. Run `npm start` to build the project and serve it from localhost:3000
3. For development, run `npm run watch` which is the same as `npm start` but with automatic rebuilding of Sass/Elm files whenever they change

### Build Manually

1. Make sure you have [Elm](http://elm-lang.org/) and [Sass](http://sass-lang.com/install) installed
2. Create a build folder for the project
3. Copy the contents of `assets` to the build folder
4. From the project root, compile the Elm code with `elm-make --output=path/to/build/folder/assets/js/elm.js src/elm/Main.elm`
5. Compile the Sass files with `sass src/scss/styles.scss:path/to/build/folder/assets/css/styles.css`
6. You can now serve/deploy from the build folder (or navigate to the files directly with file:///path/to/build/folder/index.html)

## TODO

### Features

- Working browser history/title (via History API and document.title)
- Petition search
- Transitions between screens
- Show a "Try again" link when a petition fails to load
- Handle edge cases sensibly (e.g. no signatures, 1 signature, all signatures in 1 country)
- Warn if localStorage is unavailable
- Add remove/clear links to petition lists

### Design

- Responsiveness

### Project

- Tests

### Build

- Make sure the build scripts work on Windows
- [Uglify](https://www.npmjs.com/package/uglify-js) Elm JS
- Add [live reload](https://www.npmjs.com/package/live-server)
- Switch to Yarn?

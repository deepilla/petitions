# Petitions

Petitions is a web app for viewing UK Parliament petition data.

The UK's [Parliamentary Petitions](https://petition.parliament.uk/) website is like change.org for political issues affecting the UK. Any UK resident can create a petition and, providing they get enough signatures, have their issue debated in Parliament. This app shows signatures broken out by country and by parliamentary constituency. Try it out [here](http://petitions.deepilla.com).

## Install/Build

Petitions is made with [Elm](http://elm-lang.org/) and [Sass](http://sass-lang.com/). The easiest way to build it is with the provided [NPM](https://www.npmjs.com/) scripts (also compatible with [Yarn](https://yarnpkg.com/)). But if you don't have NPM/Yarn, it's easy enough to build the project manually.

Start by cloning/downloading the repo. Then do one of the following:

### Build With NPM/Yarn (Recommended)

1. Run `npm install` (or `yarn`) in the root directory to install Elm, Sass and other build dependencies
2. Run `npm start` (or `yarn start`) to build the project and serve it from localhost:8080
3. For development, run `npm run watch` (or `yarn run watch`) which is the same as the start command but with live reloading whenever the Sass/Elm source files change

### Build Manually

1. Make sure you have Elm and Sass installed
2. Create a build folder for the project
3. Copy the contents of `static` to your build folder
4. From the project root, compile the Elm code with `elm-make --output=path/to/build/folder/assets/js/elm.js src/elm/Main.elm`
5. Compile the Sass files with `sass src/scss/styles.scss:path/to/build/folder/assets/css/styles.css`
6. You can now serve the project from your build folder (or navigate to the files directly with file:///path/to/build/folder/index.html)

## TODO

### Functionality

- Petition search
- Indicate closed/rejected status in the petition title
- Indicate totals mismatches on the summary page
- Indicate government/parliament response status on the details page
- Browser history and titles (see [Elm's Navigation package](http://package.elm-lang.org/packages/elm-lang/navigation/latest), [History API](https://developer.mozilla.org/en-US/docs/Web/API/History_API), document.title)
- Transitions between screens
- Provide a "Try again" link if a petition fails to load
- Handle edge cases sensibly (e.g. no signatures, one signature, all signatures in one country)
- Warn user if localStorage is unavailable
- Add remove/clear links to petition lists

### Project

- Tests
- [Uglify](https://www.npmjs.com/package/uglify-js) Elm JS
- Make sure the build scripts work on Windows

## Licensing

Petitions is provided under an [MIT License](http://choosealicense.com/licenses/mit/). See the [LICENSE](LICENSE) file for details.

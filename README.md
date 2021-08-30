Vim Presentation Mode (VPM)
===========================

This plugin provides a minimal presentation mode for Vim, supporting stepping
through files and conditionally highlighting regions of the current file.

## Configuration

The plugin exposes a vimscript function, `VpmRegister` which allows you to
configure the files and highlights. There are a handful of other mappings that
can be configured to then step through the presentation.

See the following example which comes from [a presentation I
gave](https://github.com/christoomey/boston-react-conf-2018-graphql-talk):

``` vim
call VpmRegister(
      \ {
      \   'file_list': [
      \     {
      \       'files': 'edit src/index.js',
      \       'highlights': [
      \         { 'ranges': [[8, 17]], 'cursorLine': 8 },
      \         { 'ranges': [[19, 29]], 'cursorLine': 19 },
      \         { 'ranges': [[20, 20], [28, 28]], 'cursorLine': 20 },
      \       ],
      \     },
      \     'edit src/components/UserList.js',
      \     'vsplit src/components/UserTile.js',
      \     'Only src/pages/UserPage.js',
      \     'vsplit src/components/UserHeader.js',
      \     'Only src/pages/UserPage.js | vsplit src/components/Org.js',
      \     'Only src/pages/UserPage.js | vsplit src/components/Repo.js',
      \     'vsplit src/components/RepoStats.js',
      \     'vsplit src/components/Language.js',
      \     'Only src/components/RepoHeader.js',
      \     'vsplit src/components/ToggleStarButton.js',
      \     'Only queries/01-original.graphql',
      \     'Only queries/02-inlined.graphql',
      \     'vsplit queries/03-rest-api.txt',
      \     'Only queries/02-inlined.graphql | vsplit queries/rest/repos-10.json',
      \   ],
      \   'highlights': {
      \     'src/index.js': [
      \       { 'ranges': [[8, 17]], 'cursorLine': 8 },
      \       { 'ranges': [[19, 29]], 'cursorLine': 19 },
      \       { 'ranges': [[20, 20], [28, 28]], 'cursorLine': 20 },
      \     ],
      \     'src/components/UserList.js': [
      \       { 'ranges': [[8, 24]], 'cursorLine': 8 },
      \       { 'ranges': [[26, 42]], 'cursorLine': 26 },
      \       { 'ranges': [[8, 24]], 'cursorLine': 9 },
      \       { 'ranges': [[9, 9], [23, 23]], 'cursorLine': 9 },
      \       { 'ranges': [[9, 10], [22, 23]], 'cursorLine': 10 },
      \       { 'ranges': [[11, 21]], 'cursorLine': 11 },
      \       { 'ranges': [[1, 99]], 'cursorLine': 10 },
      \       { 'ranges': [[14, 14]], 'cursorLine': 14 },
      \     ],
      \     'src/components/UserTile.js': [
      \       { 'ranges': [[28, 33]], 'cursorLine': 28 },
      \       { 'ranges': [[27, 34]], 'cursorLine': 27 },
      \     ],
      \     'src/pages/UserPage.js': [
      \       { 'ranges': [[31, 57]], 'cursorLine': 31 },
      \       { 'ranges': [[34, 34], [38, 38], [48, 48], [54, 56]], 'cursorLine': 31 },
      \     ],
      \     'src/components/UserHeader.js': [
      \       { 'ranges': [[19, 25]], 'cursorLine': 19 },
      \     ],
      \     'src/components/Org.js': [
      \       { 'ranges': [[10, 14]], 'cursorLine': 10 },
      \     ],
      \     'src/components/Repo.js': [
      \       { 'ranges': [[17, 26]], 'cursorLine': 17 },
      \       { 'ranges': [[20, 21]], 'cursorLine': 20 },
      \       { 'ranges': [[21, 21]], 'cursorLine': 21 },
      \     ],
      \     'src/components/RepoStats.js': [
      \       { 'ranges': [[22, 33]], 'cursorLine': 22 },
      \       { 'ranges': [[29, 29]], 'cursorLine': 29 },
      \     ],
      \     'src/components/Language.js': [
      \       { 'ranges': [[13, 17]], 'cursorLine': 13 },
      \     ],
      \     'src/components/RepoHeader.js': [
      \       { 'ranges': [[11, 11]], 'cursorLine': 11 },
      \       { 'ranges': [[18, 25]], 'cursorLine': 18 },
      \       { 'ranges': [[23, 23]], 'cursorLine': 23 },
      \     ],
      \     'src/components/ToggleStarButton.js': [
      \       { 'ranges': [[6, 19]], 'cursorLine': 6 },
      \       { 'ranges': [[21, 29]], 'cursorLine': 21 },
      \       { 'ranges': [[22, 22], [28, 28]], 'cursorLine': 22 },
      \       { 'ranges': [[22, 23], [27, 28]], 'cursorLine': 23 },
      \       { 'ranges': [[24, 26]], 'cursorLine': 24 },
      \       { 'ranges': [[31, 39]], 'cursorLine': 31 },
      \       { 'ranges': [[41, 61]], 'cursorLine': 41 },
      \     ],
      \     'queries/rest/repos-10.json': [
      \       { 'ranges': [[7, 26]], 'cursorLine': 7 },
      \       { 'ranges': [[106, 125]], 'cursorLine': 106 },
      \       { 'ranges': [[199, 218]], 'cursorLine': 199 },
      \       { 'ranges': [[292, 311]], 'cursorLine': 292 },
      \       { 'ranges': [[385, 404]], 'cursorLine': 385 },
      \       { 'ranges': [[484, 503]], 'cursorLine': 484 },
      \     ],
      \   },
      \ })

nnoremap <Down> :VpmOff<cr>
nnoremap <Right> :VpmNextHighlight<cr>
nnoremap <CR> :VpmNextHighlight<cr>
nnoremap <Left> :VpmPreviousHighlight<cr>
nnoremap <Tab> :VpmOpenNextFile<cr>

nnoremap <PageDown> :VpmNextHighlight<cr>
nnoremap <PageUp> :VpmOpenNextFile<cr>

VpmEnableDimOnLeave
```

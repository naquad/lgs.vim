""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
""  LGS
""
""  VIM interface for Laravel 4 generator bundle
""          (https://github.com/JeffreyWay/Laravel-4-Generators)
""
""  Copyright 2013 Naquad.
""
""  This program is free software; you can redistribute it and/or modify
""  it under the terms of the GNU General Public License as published by
""  the Free Software Foundation; either version 3 of the License, or
""  (at your option) any later version.
""
""  This program is distributed in the hope that it will be useful,
""  but WITHOUT ANY WARRANTY; without even the implied warranty of
""  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
""  GNU General Public License <http://www.gnu.org/licenses/>
""  for more details.
""
""
""  Pack of Artisan-related functions. Running, parsing output
""  of generators etc...
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if &cp || exists('g:lgs_artisan_autoload_done')
  finish
endif

" Look through directories from current up to root
" for file artisan .
function! lgs#artisan#FindArtisan(start)
  let path = fnamemodify(a:start, ':p')

  if !isdirectory(path)
    let path = fnamemodify(path, ':h')
  endif

  let min_len = has('win32') + 1

  while strlen(path) > min_len
    let artisan = path . '/artisan'

    if filereadable(artisan)
      return artisan
    endif

    let path = fnamemodify(path, ':h')
  endwhile

  return ''
endfunction

" Checks if buffer has associated artisan file path.
" Adds association if not.
function! lgs#artisan#SetArtisanPathIfNeed()
  if !exists('b:artisan')
    let b:artisan = lgs#artisan#FindArtisan(expand('%'))
    return b:artisan != ''
  elseif b:artisan != ''
    return filereadable(b:artisan)
  else
    return 0
  endif
endfunction

" Output of generators shows
"   app/database/migrations/Create_Xyz_table.php
" while really it name is
"   app/database/migrations/time_stamp_create_xyz_table.php
"
" To handle this case whenever path with /database/migrations/ substring
" is encountered it is transformed for glob() function and first globbed
" file is.
function! s:MigrationPattern(path)
  return substitute(a:path, '\(/database/migrations/\)\(.\+\)', '\=submatch(1) . "*_" . tolower(submatch(2))', '')
endfunction

" Runs artisan analyzing its output.
" Lots of mess here, definitely requires refactoring. Once.
function! lgs#artisan#RunArtisan(cmd, parse)
  let result = system(a:cmd . ' 2>&1')

  if v:shell_error " exception raised
    let error = matchlist(result, '\[.*Exception\]\_s\+\([^\n]\+\)')

    if empty(error) " can we figure out what is the error?
      return [0, insert(lgs#utils#StringList(result), 'UNKNOWN ERROR', 0)]
    else " if yes then show pretty error
      return [0, [substitute(error[1], '^\_s\+\|\_\s\+$', '', 'g')]
    endif
  elseif a:parse
    let files = [1, []]

    let base = fnamemodify(b:artisan, ':p:h') . '/'
    let bl = strlen(base) - 1

    " Here we're looking a file name in string.
    " It is indeed possible to use known prefixes ("Created ", "Updated ", ...)
    " but I didn't wan't to have hardcoded strings.
    for line in lgs#utils#StringList(result)
      let i = 0
      let added = 0

      while 1
        let path = line[i :]
        if path[: bl] == base " make path relative if possible
          let path = path[bl + 1 : ]
        endif

        if match(path, '/database/migrations/') != -1 " is that migration?
          let t = glob(s:MigrationPattern(path), 0, 1) " glob it first
          if !empty(t) " file found, use it
            let path = t[0]
          endif
        endif

        if filereadable(path)
          let added = 1
          call add(files[1], {'filename': path, 'nr': len(files[1]), 'text': tolower(line[: i - 1])})
          break
        endif

        let i = match(line, '\s', i + 1) + 1
        if i == 0
          break
        endif
      endwhile

      if !added
        call add(files[1], {'nr': len(files[1]), 'text': line})
      endif
    endfor

    return files
  else
    return [1, lgs#utils#StringList(result)]
  endif
endfunction

" Builds command line for invoking artisan
function! lgs#artisan#MakeArtisanCommand(...)
  let cmd = ''

  if !executable(b:artisan)
    let cmd = shellescape(g:lg_php) . ' '
  endif

  return shellescape(b:artisan) . ' ' . join(map(copy(a:000), 'shellescape(v:val)'), ' ')
endfunction

let g:lgs_artisan_autoload_done = 1

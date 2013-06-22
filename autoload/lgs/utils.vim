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
""  Some utility functions.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if &cp || exists('g:lgs_utils_autoload_done')
  finish
endif

function! lgs#utils#Warn(...)
  echoerr join(map(copy(a:000), 'string(v:val)'), ' ')
endfunction

" Sorts and filters list with completion options
function! lgs#utils#StartsWith(lst, start, prefix)
  let sl = strlen(a:start) - 1
  call sort(a:lst)

  if sl < 0
    let ret = a:lst
  else
    let ret = filter(a:lst, 'v:val[:sl] ==? a:start')
  end

  if !empty(a:prefix)
    let ret = map(ret, 'a:prefix . v:val')
  endif

  return ret
endfunction

" Splits string into individual lines removing empty ones.
function! lgs#utils#StringList(str)
  return filter(split(a:str, '\r\?\n'), '!empty(v:val)')
endfunction

let g:lgs_utils_autoload_done = 1

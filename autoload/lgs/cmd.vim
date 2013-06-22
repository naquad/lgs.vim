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
""  HARDCORE! This is implemnetation of parser for command line arguments.
""  Problem is that to provide reliable completion for commands
""  one needs to know all arguments. I didn't find anything in VIM
""  so had to write one.
""
""  Not sure this is a the best possible implementation, but it works.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if &cp || exists('g:lgs_cmd_autoload_done')
  finish
endif

" Double quoted escape characters
let s:escaped = {
  \ 't': "\t",
  \ 'n': "\n",
  \ 'r': "\r",
  \ 'e': "\e",
  \ 'b': "\b",
  \ '"': "\"",
  \ '\': "\\"
  \ }

" Used in substitution
function! lgs#cmd#UnquoteString(m)
  if empty(a:m)
    return ''
  endif

  return get(s:escaped, a:m, a:m)
endfunction

" Here come the dragons.
" This is function implements finite state machine for parsing command line
" AND unquoting functionality.
" I think it is possible to make some more generic implementation of
" completion so this won't be needed, but same time I wanted more
" general solution that could be reused later.
function! lgs#cmd#Str2ParamList(str)
  let len = strlen(a:str)
  let slider = max([0, match(a:str, '\S')])
  let start = slider
  let stack = []

  let params = []

  while slider < len
    let c = a:str[slider]

    if c == ' ' && empty(stack) && slider > start
      call add(params, [start, slider - 1, a:str[start : slider - 1]])

      let slider = match(a:str, '\S', slider) - 1
      if slider < 0
        break
      endif

      let start = slider + 1
    elseif c == '\'
      if empty(stack) || stack[-1] == '"'
        let slider = slider + 1
      endif
    elseif c == '"' || c == "'"
      if empty(stack)
        call add(stack, c)
      elseif stack[-1] == c
        call remove(stack, -1)

        call add(params, [start, slider, a:str[start : slider]])
        let start = max([slider + 1, match(a:str, '\S', slider + 1)])
      endif
    endif

    let slider = slider + 1
  endwhile

  if start != slider && slider > 0
    call add(params, [start, len, a:str[start :]])
  endif

  for param in params
    let qtype = param[2][0]

    if qtype == "'"
      let param[2] =
        \ substitute(substitute(param[2], "^'\\|'$", '', 'g'), "''", "'", 'g')
    elseif qtype == '"'
      let end = matchstr(param[2], '\\*"$')

      if !empty(end) && strlen(end) % 2 == 1
        let param[2] = param[2][:-2]
      endif

      let param[2] = substitute(param[2][1:], '\\\(.\?\)', '\=lgs#cmd#UnquoteString(submatch(1))', 'g')
    endif
  endfor

  return params
endfunction

" Takes result of lgs#cmd#Str2ParamList and position in line
" returns number of argument that position is in.
function! lgs#cmd#Pos2ArgNo(params, pos)
  let cnt = 0

  for param in a:params
    if param[1] >= a:pos
      return cnt
    endif

    let cnt = cnt + 1
  endfor

  return cnt
endfunction

let g:lgs_cmd_autoload_done = 1

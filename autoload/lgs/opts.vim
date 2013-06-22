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
""  Option parse (a-la getopts w/o short and flag options).
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if &cp || exists('g:lgs_opts_autoload_done')
  finish
endif

" Remove leading --
function! lgs#opts#OptionName(opt)
  return substitute(a:opt, '^--\?', '', '')
endfunction

" Walk through argument list and make dictionary with arguments and
" options with their values.
function! lgs#opts#ParseOptions(params)
  let arguments = []
  let options = {}
  let discard_next = 0

  let i = 0
  let pl = len(a:params)
  
  while i < pl
    if a:params[i][0] == '-' && !discard_next
      if a:params[i] == '--'
        let discard_next = 1
        continue
      endif

      let option = lgs#opts#OptionName(a:params[i])
      let argpos = stridx(option, '=')

      if argpos == -1
        if i == pl - 1
          return {'success': 0, 'error': '--' . option . ' requires argument!'}
        else
          let options[option] = a:params[i + 1]
          let i = i + 1
        endif
      else
        let options[option[: argpos - 1]] = option[argpos + 1 :]
      endif
    else
      call add(arguments, a:params[i])
    endif

    let i = i + 1
  endwhile

  return {'success': 1, 'options': options, 'arguments': arguments}
endfunction

" Checks that given options comply to generator description.
function! lgs#opts#ValidateOptions(name, generator, params)
  if (!has_key(a:generator, 'options') || 
        \ empty(a:generator.options)) && !empty(a:params.options)
    call lgs#utils#Warn('Generator ' . name . ' takes no options!')
    return 0
  endif

  for o in keys(a:params.options)
    if !has_key(a:generator.options, o)
      call lgs#utils#Warn('Generator ' . name . ' has no option ' . o)
      return 0
    endif
  endfor

  return 1
endfunction

" Takes dictionary and makes shellescape()d string with options
function! lgs#opts#SerializeOptions(opts)
  let result = []

  for [k, v] in items(a:opts)
    call add(result, shellescape('--' . k) . '=' . shellescape(v))
  endfor

  return join(result, ' ')
endfunction

let g:lgs_opts_autoload_done = 1

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
""  Completion for LG command. Works with g:lgs_generators variable
""  to figure out what to complete and how to complete.
""  Also respects argument positions.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if &cp || exists('g:lgs_cmpl_autoload_done')
  finish
endif

" Figures out what to do with completion source.
" Runs functions, uses lists and returns nothing
" if is a number.
function! s:CallCompleter(what, lead, prefix)
  let t = type(a:what)

  if t == 0
    return []
  elseif t == 3
    return lgs#utils#StartsWith(copy(a:what), a:lead, a:prefix)
  elseif t == 1
    return lgs#utils#StartsWith([a:what], a:lead, a:prefix)
  elseif t == 2
    return lgs#utils#StartsWith(a:what(a:lead), a:lead, a:prefix)
  elseif
    echoerr 'Dont know how to complete with ' . t
  endif

  return []
endfunction

" Completion for argument at position.
" If argument number is not described in generation configuration
" then tries to use '*' instead.
function! s:CallArgument(generator, argno, lead)
  if !has_key(g:lgs_generators[a:generator], 'arguments')
    return []
  elseif has_key(g:lgs_generators[a:generator].arguments, a:argno)
    return s:CallCompleter(g:lgs_generators[a:generator].arguments[a:argno], a:lead, '')
  elseif has_key(g:lgs_generators[a:generator].arguments, '*')
    return s:CallCompleter(g:lgs_generators[a:generator]['arguments']['*'], a:lead, '')
  endif

  return []
endfunction

" Completes options and their values.
function! s:CallOption(generator, option_name, value, prefix, param)
  if !has_key(g:lgs_generators[a:generator], 'options')
    return []
  endif

  if type(a:value) == 0 && a:value == 0
    let lst = keys(g:lgs_generators[a:generator].options)

    if a:param
      let lst = map(lst, 'v:val . "="')
    endif

    return lgs#utils#StartsWith(lst, a:option_name, '--')
  elseif has_key(g:lgs_generators[a:generator].options, a:option_name)
    return s:CallCompleter(g:lgs_generators[a:generator].options[a:option_name], a:value, a:prefix)
  endif

  return []
endfunction

" Determines are we completing option or argument?
" Pretty slopy, but I didn't see another way.
function! s:IsOption(params, argno, lead)
  let last_option = ''

  for p in a:params[2 : a:argno - 1]
    if p[2] == '--'
      return 0
    endif

    if p[2][0] == '-' && stridx(p[2], '=') == -1
      let last_option = lgs#opts#OptionName(p[2])
    else
      let last_option = ''
    endif
  endfor

  if last_option == ''
    if a:lead[0] == '-'
      let val = stridx(a:lead, '=')

      if val == -1
        return [lgs#opts#OptionName(a:lead), 0, '', len(a:params) > a:argno]
      else
        return [lgs#opts#OptionName(a:lead[: val - 1]), a:lead[val + 1 :], a:lead[: val], 0]
      endif
    else
      return 1
    endif
  else
    return [lgs#opts#OptionName(last_option), a:lead, '', 0]
  endif
endfunction

" Tells position of completed argument excluding options.
function! s:ValueNo(params, argno)
  let cnt = 0
  let skip = 0

  for p in a:params[0 : a:argno - 1]
    if p[2][0] == '-' && !skip
      if p[2] == '--'
        let skip = 1
      elseif stridx(p[2], '=') == -1
        let cnt = cnt - 1
      endif
    else
      let cnt = cnt + 1
    endif
  endfor

  return max([0, cnt - 1])
endfunction

" Completion function itself
function! lgs#cmpl#Completion(lead, line, pos)
  if !lgs#artisan#SetArtisanPathIfNeed()
    return []
  endif

  let params = lgs#cmd#Str2ParamList(a:line)
  let argno = lgs#cmd#Pos2ArgNo(params, a:pos)

  if argno == 0
    return []
  elseif argno == 1
    return lgs#utils#StartsWith(keys(g:lgs_generators), a:lead, '')
  endif

  let generator = params[1][2]

  if has_key(g:lgs_generators, generator)
    let option = s:IsOption(params, argno, a:lead)
    let ot = type(option)

    if empty(a:lead) && ot == 0
      let ret = option == 1 ? s:CallOption(generator, '', 0, '', 1) : []
      return extend(ret, s:CallArgument(generator, s:ValueNo(params, argno), a:lead))
    elseif ot == 0 || empty(option)
      return s:CallArgument(generator, s:ValueNo(params, argno), a:lead)
    else
      return s:CallOption(generator, option[0], option[1], option[2], option[3])
    endif
  endif

  return []
endfunction

let g:lgs_cmpl_autoload_done = 1

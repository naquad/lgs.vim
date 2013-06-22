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
""  Completion sources.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if &cp || exists('g:lgs_cmplf_autoload_done')
  finish
endif

" Auxiliary functions to get output from external commands
" and split them. Fails silently.
function! s:QuietCommand(cmd)
  if has('win32')
    return a:cmd . ' 2>NUL'
  else
    return a:cmd . ' 2>/dev/null'
  endif
endfunction

function! s:ReadOptionsFromOutput(cmd, input)
  let output = system(s:QuietCommand(a:cmd), a:input)

  if v:shell_error
    return []
  else
    return filter(lgs#utils#StringList(output), '!empty(v:val)')
  endif
endfunction

let s:environments_listing = expand('<sfile>:p:h') . '/../../misc/get_envs.php'

" I didn't find anything better than just faking out Application
" class and printing given environments in detectEvnrioment().
" Script is very basic and should be rewritten.
function! lgs#cmplf#Environments(lead)
  let cmd = [
        \ g:lg_php,
        \ s:environments_listing,
        \ fnamemodify(b:artisan, ':p:h') . '/bootstrap/start.php'
        \ ]

  return s:ReadOptionsFromOutput(join(map(cmd, 'shellescape(v:val)'), ' '), ' ')
endfunction

let s:model_listing = join(readfile(expand('<sfile>:p:h') . '/../../misc/get_models.php'), '')

" Models script is ran in artisan tinker console.
" Not sure thats the best solution.
function! lgs#cmplf#Models(lead)
  return s:ReadOptionsFromOutput(lgs#artisan#MakeArtisanCommand('tinker', '-q'), s:model_listing)
endfunction

let s:field_types = [
      \ 'increments',
      \ 'bigIncrements',
      \ 'index',
      \ 'foreign',
      \ 'string',
      \ 'text',
      \ 'integer',
      \ 'integer',
      \ 'bigInteger',
      \ 'mediumInteger',
      \ 'tinyInteger',
      \ 'smallInteger',
      \ 'unsignedInteger',
      \ 'unsignedBigInteger',
      \ 'float',
      \ 'decimal',
      \ 'boolean',
      \ 'enum',
      \ 'date',
      \ 'dateTime',
      \ 'time',
      \ 'timestamp',
      \ 'binary',
      \ ]

" Just filter the list of possible types
function! lgs#cmplf#FieldTypeCompletion(lead)
  let idx = strridx(a:lead, ':')

  if idx != -1
    return lgs#utils#StartsWith(copy(s:field_types), a:lead[idx + 1 : ], a:lead[: idx])
  endif

  return []
endfunction

" Auxiliary option to choose directory if its the only option
function! s:EnterDir(lst)
  if len(a:lst) == 1 && isdirectory(a:lst[0])
    return [a:lst[0] . '/']
  endif

  return a:lst
endfunction

" File path completion 
function! lgs#cmplf#FileCompletion(lead)
  return s:EnterDir(glob(escape(a:lead, '*?[]\') . '*', 0, 1))
endfunction

" Directory path completion
function! lgs#cmplf#DirCompletion(lead)
  return s:EnterDir(filter(glob(escape(a:lead, '*?[]\') . '*', 0, 1), 'isdirectory(v:val)'))
endfunction

let g:lgs_cmplf_autoload_done = 1

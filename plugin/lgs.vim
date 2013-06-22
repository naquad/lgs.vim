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
""  Main file defining command and generators configuration.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

if &cp || exists('g:loaded_lgs')
  finish
endif

" PHP is needed to get completions for models and environments
" + run artisan if we're on windows or artisan file itself is just
" not executable
if !exists('g:lg_php')
  let g:lg_php = 'php'
endif

" some default options
let s:default_options = {
  \ 'env'  : function('lgs#cmplf#Environments'),
  \ 'path' : function('lgs#cmplf#DirCompletion'),
  \ }

" more defaults
let s:default_with_template = copy(s:default_options)
let s:default_with_template['template'] = function('lgs#cmplf#FileCompletion')

" Field type completer. First argument is name of generated
" entity so we don't complete it.
" Everything is a field type. Used by migration, scaffold and resource.
"
" 1: 0 here means don't complete 1st argument in any way
let s:field_type_completion_after_name = {
  \ 1: 0,
  \ '*': function('lgs#cmplf#FieldTypeCompletion'),
  \ }

" command line specification for each generator
let g:lgs_generators = {
  \   'form': {
  \     'options': {
  \       'method': ['create', 'edit'],
  \       'html': ['ul', 'ol', 'li'],
  \       'env': function('lgs#cmplf#Environments')
  \     },
  \     'arguments': {
  \       1: function('lgs#cmplf#Models')
  \     },
  \     'requires': 'model name',
  \   },
  \   'model': {
  \     'options': s:default_with_template,
  \   },
  \   'migration': {
  \     'options': s:default_options,
  \     'arguments': s:field_type_completion_after_name,
  \     'fields': 1,
  \   },
  \   'resource': {
  \     'options': s:default_options,
  \     'arguments': s:field_type_completion_after_name,
  \     'fields': 1,
  \   },
  \   'scaffold': {
  \     'options': s:default_options,
  \     'arguments': s:field_type_completion_after_name,
  \     'fields': 1,
  \   },
  \   'seed': {
  \     'options': s:default_with_template,
  \     'arguments': {
  \       1: function('lgs#cmplf#Models')
  \     }
  \   },
  \   'test': {
  \     'options': s:default_with_template,
  \   },
  \   'view': {
  \     'options': s:default_with_template,
  \   },
  \   'controller': {
  \     'options': s:default_with_template
  \   },
  \ }

function! s:LG(...)
  if !lgs#artisan#SetArtisanPathIfNeed()
    call lgs#artisan#Warn('Not a Laravel 4 file')
    return
  endif

  let params = lgs#opts#ParseOptions(a:000)

  if params.success == 0
    call lgs#utils#Warn(params.error)
    return
  endif

  if empty(params.arguments)
    call lgs#utils#Warn('Generator name required')
    return
  endif

  let generator = remove(params.arguments, 0)

  if !has_key(g:lgs_generators, generator)
    call lgs#utils#Warn('Unknown generator ' . generator)
    return
  endif

  if !lgs#opts#ValidateOptions(generator, g:lgs_generators[generator], params)
    return
  endif

  if get(g:lgs_generators[generator], 'fields', 0) && len(params.arguments) > 1
    let params.options['fields'] = join(params.arguments[1:], ', ')
    let params.arguments = params.arguments[:0]
  endif

  let cmd = lgs#artisan#MakeArtisanCommand('generate:' . generator, '-n', '--no-ansi')

  let capitalized = substitute(generator, '^.', '\U&\E', '')
  let requires = get(g:lgs_generators[generator], 'requires', generator)
  if empty(params.arguments)
    call lgs#utils#Warn(capitalized . ' requires ' . requires . ' name')
  elseif len(params.arguments) > 1
    call lgs#utils#Warn(capitalized . ' takes only ' . requires . ' name')
  else
    let cmd .= ' ' . lgs#opts#SerializeOptions(params.options) . ' ' .
          \ shellescape(params.arguments[0])

    let files = lgs#artisan#RunArtisan(cmd, generator != 'form')

    if files[0] == 0
      call lgs#utils#Warn(join(files[1], "\n"))
      return
    endif

    if generator == 'form'
      call append('.', files[1])
    else
      if exists('g:lg_postfactum')
        let Func = function(g:lg_postfactum)
        call Func(filter(map(copy(files[1]), 'v:val["filename"]'), '!empty(v:val)'))
      endif

      call setqflist(files[1], 'a')
      let artisan = b:artisan
      copen
      exec 'cd ' . fnameescape(fnamemodify(artisan, ':p:h'))
    endif
  endif
endfunction

command -nargs=+ -complete=customlist,lgs#cmpl#Completion LG :call s:LG(<f-args>)

let g:loaded_lgs = 1

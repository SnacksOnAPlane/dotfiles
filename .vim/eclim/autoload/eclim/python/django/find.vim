" Author:  Eric Van Dewoestine
"
" Description: {{{
"   see http://eclim.sourceforge.net/vim/python/django.html
"
" License:
"
" Copyright (C) 2005 - 2009  Eric Van Dewoestine
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" }}}

" Global Variables {{{
if !exists('g:EclimDjangoFindAction')
  let g:EclimDjangoFindAction = 'split'
endif
if !exists('g:EclimDjangoStaticPaths')
  let g:EclimDjangoStaticPaths = []
endif
" }}}

" FindFilterOrTag(project_dir, element, type) {{{
" Finds and opens the supplied filter or tag definition.
function eclim#python#django#find#FindFilterOrTag(project_dir, element, type)
  let loaded = eclim#python#django#util#GetLoadList(a:project_dir)
  let cmd = 'lvimgrep /\<def\s\+' . a:element . '\>/j '
  for file in loaded
    let cmd .= ' ' . file
  endfor

  silent exec cmd

  let results = getloclist(0)
  if len(results) > 0
    call eclim#util#GoToBufferWindowOrOpen(
      \ bufname(results[0].bufnr), g:EclimDjangoFindAction)
    lfirst
    return 1
  endif
  call eclim#util#EchoError(
    \ 'Unable to find the definition for tag/file "' . a:element . '"')
endfunction " }}}

" FindFilterTagFile(project_dir, file) {{{
" Finds and opens the supplied tag/file definition file.
function eclim#python#django#find#FindFilterTagFile(project_dir, file)
  let file = findfile(a:file . '.py', a:project_dir . '*/templatetags/')
  if file != ''
    call eclim#util#GoToBufferWindowOrOpen(file, g:EclimDjangoFindAction)
    return 1
  endif
  call eclim#util#EchoError('Could not find tag/filter file "' . a:file . '.py"')
endfunction " }}}

" FindSettingDefinition(project_dir, value) {{{
" Finds and opens the definition for the supplied setting middleware, context
" processor or template loader.
function eclim#python#django#find#FindSettingDefinition(project_dir, value)
  let file = substitute(a:value, '\(.*\)\..*', '\1', '')
  let def = substitute(a:value, '.*\.\(.*\)', '\1', '')
  let file = substitute(file, '\.', '/', 'g') . '.py'
  let project_dir = fnamemodify(a:project_dir, ':h')
  let found = findfile(file, project_dir)
  if found == ''
    let file = substitute(file, '\.py', '/__init__.py', '')
    let found = findfile(file, project_dir)
  endif
  if found != ''
    call eclim#util#GoToBufferWindowOrOpen(found, g:EclimDjangoFindAction)
    call search('\(def\|class\)\s\+' . def . '\>', 'cw')
    return 1
  endif
  call eclim#util#EchoError('Could not definition of "' . a:value . '"')
endfunction " }}}

" FindStaticFile(project_dir, file) {{{
" Finds and opens the supplied static file name.
function eclim#python#django#find#FindStaticFile(project_dir, file)
  if !len(g:EclimDjangoStaticPaths)
    call eclim#util#EchoWarning(
      \ 'Attemping to find static file but your g:EclimDjangoStaticPaths is not set.')
    return
  endif

  for path in g:EclimDjangoStaticPaths
    if path !~ '^\(/\|\w:\)'
      let path = a:project_dir . '/' . path
    endif
    let file = findfile(a:file, path)
    if file != ''
      call eclim#util#GoToBufferWindowOrOpen(file, g:EclimDjangoFindAction)
      return 1
    endif
  endfor
  call eclim#util#EchoError('Could not find the static file "' . a:file . '"')
endfunction " }}}

" FindTemplate(project_dir, template) {{{
" Finds and opens the supplied template definition.
function eclim#python#django#find#FindTemplate(project_dir, template)
  let dirs = eclim#python#django#util#GetTemplateDirs(a:project_dir)
  for dir in dirs
    let file = findfile(a:template, a:project_dir . '/' . dir)
    if file != ''
      call eclim#util#GoToBufferWindowOrOpen(file, g:EclimDjangoFindAction)
      return 1
    endif
  endfor
  call eclim#util#EchoError('Could not find the template "' . a:template . '"')
endfunction " }}}

" FindView(project_dir, template) {{{
" Finds and opens the supplied view.
function eclim#python#django#find#FindView(project_dir, view)
  let view = a:view
  let function = ''

  " basic check to see if on a url pattern instead of the view.
  if view =~ '[?(*^$]'
    call eclim#util#EchoError(
      \ 'String under the curser does not appear to be a view: "' . view . '"')
    return
  endif

  if getline('.') !~ "\\(include\\|patterns\\)\\s*(\\s*['\"]" . view
    " see if a view prefix was defined.
    let result = search('patterns\s*(', 'bnW')
    if result
      let prefix = substitute(
        \ getline(result), ".*patterns\\s*(\\s*['\"]\\(.\\{-}\\)['\"].*", '\1', '')
      if prefix != ''
        let view = prefix . '.' . view
      endif
    endif

    let function = split(view, '\.')[-1]
    let view = join(split(view, '\.')[0:-2], '.')
  endif

  let view = join(split(substitute(view, '\.', '/', 'g') . '.py', '/')[1:], '/')
  let file = findfile(view, a:project_dir)
  if file != ''
    call eclim#util#GoToBufferWindowOrOpen(file, g:EclimDjangoFindAction)
    if function != ''
      call search('def\s\+' . function . '\>', 'cw')
    endif
    return 1
  endif
  call eclim#util#EchoError('Could not find the view "' . view . '"')
endfunction " }}}

" TemplateFind() {{{
" Find the template, tag, or filter under the cursor.
function eclim#python#django#find#TemplateFind()
  let project_dir = eclim#python#django#util#GetProjectPath()
  if project_dir == ''
    call eclim#util#EchoError(
      \ 'Unable to locate django project path with manage.py and settings.py')
    return
  endif

  let line = getline('.')
  let element = eclim#util#GrabUri()
  if element =~ '|'
    let element = substitute(element, '.\{-}|\(\w*\).*', '\1', 'g')
    return eclim#python#django#find#FindFilterOrTag(project_dir, element, 'filter')
  elseif line =~ '{%\s*' . element . '\>'
    return eclim#python#django#find#FindFilterOrTag(project_dir, element, 'tag')
  elseif line =~ '{%\s*load\s\+' . element . '\>'
    return eclim#python#django#find#FindFilterTagFile(project_dir, element)
  elseif line =~ "{%\\s*\\(extends\\|include\\)\\s\\+['\"]" . element . "['\"]"
    return eclim#python#django#find#FindTemplate(project_dir, element)
  elseif line =~ "\\(src\\|href\\)\\s*=\\s*['\"]\\?\\s*" . element
    let element = substitute(element, '^/', '', '')
    let element = substitute(element, '?.*', '', '')
    return eclim#python#django#find#FindStaticFile(project_dir, element)
  endif
  call eclim#util#EchoError(
    \ 'Element under the cursor does not appear to be a ' .
    \ 'valid tag, filter, or template reference.')
endfunction " }}}

" ContextFind() {{{
" Execute DjangoViewOpen, DjangoTemplateOpen, or PythonFindDefinition based on
" the context of the text under the cursor.
function! eclim#python#django#find#ContextFind()
  if getline('.') =~ "['\"][^'\" ]*\\%" . col('.') . "c[^'\" ]*['\"]"
    if search('urlpatterns\s\+=\s\+patterns(', 'nw') &&
        \ eclim#util#GrabUri() !~ '\.html'
      return eclim#python#django#find#FindView(
        \ eclim#python#django#util#GetProjectPath(), eclim#util#GrabUri())
    elseif expand('%:t') == 'settings.py'
      return eclim#python#django#find#FindSettingDefinition(
        \ eclim#python#django#util#GetProjectPath(), eclim#util#GrabUri())
    else
      return eclim#python#django#find#FindTemplate(
        \ eclim#python#django#util#GetProjectPath(), eclim#util#GrabUri())
    endif
  "else
  "  PythonFindDefinition
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker

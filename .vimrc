" Set syntax on
syntax on

call pathogen#infect()
let g:pyflakes_use_quickfix = 0

set backupdir=~/tmp
set dir=~/tmp

" Indent automatically depending on filetype
filetype indent on
filetype plugin on
set autoindent
set mouse=a
" Case insensitive search
set ic
set smartcase

" Higlhight search
set hls
set incsearch
set hidden

" Wrap text instead of being on one line
set lbr

" vimrc file for following the coding standards specified in PEP 7 & 8.
"
" To use this file, source it in your own personal .vimrc file (``source
" <filename>``) or, if you don't have a .vimrc file, you can just symlink to it
" (``ln -s <this file> ~/.vimrc``).  All options are protected by autocmds
" (read below for an explanation of the command) so blind sourcing of this file
" is safe and will not affect your settings for non-Python or non-C files.
"
"
" All setting are protected by 'au' ('autocmd') statements.  Only files ending
" in .py or .pyw will trigger the Python settings while files ending in *.c or
" *.h will trigger the C settings.  This makes the file "safe" in terms of only
" adjusting settings for Python and C files.
"
" Only basic settings needed to enforce the style guidelines are set.
" Some suggested options are listed but commented out at the end of this file.


" Number of spaces to use for an indent.
" This will affect Ctrl-T and 'autoindent'.
" Python: 4 spaces
" C: 8 spaces (pre-existing files) or 4 spaces (new files)
set shiftwidth=2

" Number of spaces that a pre-existing tab is equal to.
" For the amount of space used for a new tab use shiftwidth.
" Python: 8
" C: 8
set tabstop=2

" Replace tabs with the equivalent number of spaces.
" Also have an autocmd for Makefiles since they require hard tabs.
" Python: yes
" C: no
" Makefile: no
au BufRead,BufNewFile *.py,*.pyw,*.js set expandtab
au BufRead,BufNewFile *.c,*.h set noexpandtab
au BufRead,BufNewFile Makefile* set noexpandtab
au BufRead,BufNewFile *.coffee set noexpandtab
au BufRead,BufNewFile *.md set expandtab
au BufRead,BufNewFile *.scss set expandtab

" Turn off settings in 'formatoptions' relating to comment formatting.
" - c : do not automatically insert the comment leader when wrapping based on
"    'textwidth'
" - o : do not insert the comment leader when using 'o' or 'O' from command mode
" - r : do not insert the comment leader when hitting <Enter> in insert mode
" Python: not needed
" C: prevents insertion of '*' at the beginning of every line in a comment
au BufRead,BufNewFile *.c,*.h set formatoptions-=c formatoptions-=o formatoptions-=r

" Use UNIX (\n) line endings.
" Only used for new files so as to not force existing files to change their
" line endings.
" Python: yes
" C: yes
au BufNewFile *.py,*.pyw,*.c,*.h set fileformat=unix


" ----------------------------------------------------------------------------
" The following section contains suggested settings.  While in no way required
" to meet coding standards, they are helpful.

" Set the default file encoding to UTF-8: ``set encoding=utf-8``

" Puts a marker at the beginning of the file to differentiate between UTF and
" UCS encoding (WARNING: can trick shells into thinking a text file is actually
" a binary file when executing the text file): ``set bomb``

" For full syntax highlighting:
"``let python_highlight_all=1``
"``syntax on``

" Automatically indent based on file type: ``filetype indent on``
" Keep indentation level from previous line: ``set autoindent``

" Folding based on indentation: ``set foldmethod=indent``

let g:LookupFile_TagExpr = '"./filenametags"'

function! JumpAndSwap()
	let l:currBuf = bufnr('%')
	exec 'buffer ' . g:jmpToBuffer
	let g:jmpToBuffer = currBuf
endfunction

nmap <F9>  :FufRenewCache<CR>
nmap <F10> :call JumpAndSwap()<CR>
nmap <F11> :bprevious<CR>
nmap <F12> :bnext<CR>

nmap <F5> :FufCoverageFile<CR>
nmap <F6> :NERDTreeToggle<CR>
"nmap <F6> :grep --js --xul <cword><CR>
"nmap <F7> :grep -a <cword><CR>
nmap <F8> :call FindParentFolds()<CR>

cmap %/ <C-R>=expand("%:p:h") . '/'<CR>

set grepprg=ack-grep

autocmd FileType javascript set omnifunc=javascriptcomplete#CompleteJS

function! DoPrettyXML()
  " save the filetype so we can restore it later
  let l:origft = &ft
  set ft=
  " delete the xml header if it exists. This will
  " permit us to surround the document with fake tags
  " without creating invalid xml.
  1s/<?xml .*?>//e
  " insert fake tags around the entire document.
  " This will permit us to pretty-format excerpts of
  " XML that may contain multiple top-level elements.
  0put ='<PrettyXML>'
  $put ='</PrettyXML>'
  silent %!xmllint --format -
  " xmllint will insert an <?xml?> header. it's easy enough to delete
  " if you don't want it.
  " delete the fake tags
  2d
  $d
  " restore the 'normal' indentation, which is one extra level
  " too deep due to the extra tags we wrapped around the document.
  silent %<
  " back to home
  1
  " restore the filetype
  exe "set ft=" . l:origft
endfunction
command! PrettyXML call DoPrettyXML()

" up/down go by screen lines, not text lines (for line wrapping)
"nnoremap j gj
"nnoremap k gk
"vnoremap j gj
"vnoremap k gk
"nnoremap <Down> gj
"nnoremap <Up> gk
"vnoremap <Down> gj
"vnoremap <Up> gk
"inoremap <Down> <C-o>gj
"inoremap <Up> <C-o>gk

set background=dark
set t_Co=256
let g:zenburn_high_Contrast = 1
colorscheme zenburn
hi search ctermbg=223 ctermfg=238
hi incsearch ctermbg=216 ctermfg=242
"colorscheme vividchalk

set foldlevel=40

" javascript folding
function! JavaScriptFold() 
    setl foldmethod=syntax
    setl foldlevelstart=0
    syn region foldBraces start=/{/ end=/}/ transparent fold keepend extend

    function! FoldText()
        return substitute(getline(v:foldstart), '{.*', '{...}', '')
    endfunction
    setl foldtext=FoldText()
endfunction

set foldcolumn=2

au FileType javascript call JavaScriptFold()
au FileType javascript setl fen

function! CloseHiddenBuffers()
  let i = 0
  let n = bufnr('$')
  while i < n
    let i = i + 1
    if bufloaded(i) && bufwinnr(i) < 0
      exe 'bd ' . i
    endif
  endwhile
endfun

command! CloseHiddenBuffers call CloseHiddenBuffers()

function! SetJmpBuffer()
	if g:jmpToBuffer != bufnr('%')
		let g:jmpToBuffer = g:lastSavedBuffer
	endif
endfun

let g:lastSavedBuffer = 1
let g:jmpToBuffer = 1
autocmd BufWritePost * let g:lastSavedBuffer = expand('<abuf>')
autocmd BufEnter * call SetJmpBuffer()

augroup objective-j
au! BufRead,BufNewFile *.j set filetype=objective-j
au! Syntax objective-j source /home/rsmiley/.vim/plugin/objj.vim
augroup END

au! BufRead,BufNewFile *.json set filetype=json 

augroup json_autocmd 
  autocmd! 
  autocmd FileType json set autoindent 
  autocmd FileType json set formatoptions=tcq2l 
  autocmd FileType json set textwidth=78 shiftwidth=2 
  autocmd FileType json set softtabstop=2 tabstop=8 
  autocmd FileType json set expandtab 
  autocmd FileType json set foldmethod=syntax 
augroup END 

" don't select pasted-over text on paste
xnoremap p pgvy

highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

if exists("+colorcolumn")
	set colorcolumn=80
endif

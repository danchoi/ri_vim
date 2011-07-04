" Vim script that add ability to search and play iTunes tracks from Vim
" Maintainer:	Daniel Choi <dhchoi@gmail.com>
" License: MIT License (c) 2011 Daniel Choi
"
" Buid this path with plugin install program

if exists("g:rdoc_tool")
  let s:rdoc_tool = g:rdoc_tool
else
  " This is the development version (specific to D Choi's setup)
  let s:rdoc_tool = 'ruby -Ilib rivim.rb '
  " Maybe I should make this a relative path
endif

let s:selectionPrompt = ""
let s:lastQuery = ""
let s:history = []

func! s:trimString(string)
  let string = substitute(a:string, '\s\+$', '', '')
  return substitute(string, '^\s\+', '', '')
endfunc

function! s:runCommand(command)
  " echom a:command " can use for debugging
  let res = system(a:command)
  return res
endfunction

function! RDocStatusLine()
  return "%<%f\ Press ? for help. "."%r%=%-14.(%l,%c%V%)\ %P"
endfunction

function! StartRDocQuery()
  if s:lastQuery != ''
    let line = s:selectionPrompt . s:lastQuery
  else
    let line = s:selectionPrompt
  endif
  leftabove split SearchRDocs
  setlocal textwidth=0
  setlocal completefunc=RDocAutoComplete
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal modifiable
  setlocal nowrap
  resize 1
  inoremap <buffer> <cr> <Esc>:call <SID>doSearch()<cr>
  noremap <buffer> <cr> <Esc>:call <SID>doSearch()<cr>
  noremap <buffer> q <Esc>:close
  inoremap <buffer> <Tab> <C-x><C-u>
  
  "inoremap <buffer> <Esc> <Esc>:close<CR>
  "noremap <buffer> <Esc> <Esc>:close<CR>
  call setline(1, line)
  normal $
  call feedkeys("a", 't')
  " call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
  " autocmd CursorMovedI <buffer> call feedkeys("\<c-x>\<c-u>\<c-p>", 't')
endfunction

function! s:openDocWindow()
  if exists("s:doc_bufnr") 
    let doc_winnr = bufwinnr(s:doc_bufnr) 
    if doc_winnr == winnr() 
      return
    endif
    if doc_winnr != -1
      exec doc_winnr . "wincmd w"
      return
    endif
  endif
  leftabove split RDocBuffer
  setlocal nowrap
  setlocal textwidth=0
  noremap <buffer> <Leader>s :call <SID>openQueryWindow()<cr>
  noremap <buffer> <Leader>i :close<CR>
  noremap <buffer> ? :call <SID>help()<CR>
  noremap <buffer> <cr> :call <SID>playTrack()<cr>
  setlocal nomodifiable
  setlocal statusline=%!RDocStatusLine()
  noremap <buffer> ,r :call <SID>openREADME()<CR>
  noremap <buffer> K :call <SID>lookupName()<CR>

  command! -nargs=+ HtmlHiLink highlight def link <args>

  noremap <buffer> <C-i> :call <SID>jumpForward()<CR>
  noremap <buffer> <C-o> :call <SID>jumpBack()<CR>

  let s:doc_bufnr = bufnr('%')
endfunction

function! s:help()
  " This just displays the README
  let res = system("rdoc-help") 
  echo res  
endfunction

function! RDocAutoComplete(findstart, base)
  if a:findstart
    let prompt = s:selectionPrompt
    let start = len(prompt) 
    return start
  else
    if (a:base == '')
      return s:matchingNames("")
    else
      let res = [] " find tracks matching a:base
      for m in s:matchingNames(a:base)
        call add(res, m)
      endfor
      return res
    endif
  endif
endfun

function! s:matchingNames(query)
  let command = s:rdoc_tool . shellescape(a:query)
  echom command
  return split(system(command), '\n')
endfunction

" selection window pick or search window query
function! s:doSearch()
  if (getline('.') =~ '^\s*$')
    close
    return
  endif
  let query = getline('.')[len(s:selectionPrompt):] " get(split(getline('.'), ':\s*'), 1)
  close
  " echom query
  if (len(query) == 0 || query =~ '^\s*$')
    return
  endif

  if query =~ '\S\s\+\S'
    let parts = split(query)
    let query = get(parts, 1)
  endif
  call s:displayDoc(query)
endfunction

function! s:displayDoc(query)
  let s:lastQuery = a:query
  call add(s:history, a:query)
  call s:openDocWindow()
  let bcommand = s:rdoc_tool.'-d '.shellescape(a:query)
  let res = s:runCommand(bcommand)
  setlocal modifiable
  silent! 1,$delete
  silent! put =res
  silent! 1delete
  write
  normal gg
endfunction

function! s:openREADME()
  call search('^(from gem \S\+)', 'w')
  let gem = matchstr(getline(line('.')), '[[:alnum:]]\+-[0-9.]\+')
  echo gem
  let bcommand = s:rdoc_tool.'-r '.shellescape(gem)
  let res = s:runCommand(bcommand)
  setlocal modifiable
  silent! 1,$delete
  silent! put =res
  silent! 1delete
  write
  normal gg
endfunction

function! s:lookupName()
  let query = expand("<cWORD>")
  call s:displayDoc(query)
endfunction

func! s:jumpBack()
  echo get(s:history, -2)
endfunc

func! s:jumpForward()
  echo get(s:history, -2)
endfunc

nnoremap <silent> <leader>j :call StartRDocQuery()<cr>
echo "vim_rdoc loaded"

let g:RDocLoaded = 1


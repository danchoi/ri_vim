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
  "inoremap <buffer> <Esc> <Esc>:close<CR>
  "noremap <buffer> <Esc> <Esc>:close<CR>
  call setline(1, line)
  normal $
  call feedkeys("a", 't')
  " call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
  " autocmd CursorMovedI <buffer> call feedkeys("\<c-x>\<c-u>\<c-p>", 't')
endfunction

function! s:open_doc_window()
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

  command! -nargs=+ HtmlHiLink highlight def link <args>

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
      let res = []
      " find tracks matching a:base
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
  let s:lastQuery = query
  call s:open_doc_window()
  let bcommand = s:rdoc_tool.'-d '.shellescape(query)
  let res = s:runCommand(bcommand)
  setlocal modifiable
  silent! 1,$delete
  silent! put =res
  silent! 1delete
  write
  normal gg
endfunction

nnoremap <silent> <leader>j :call StartRDocQuery()<cr>
echo "vim_rdoc loaded"

let g:RDocLoaded = 1


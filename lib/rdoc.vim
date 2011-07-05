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

let s:ri_tool = 'ri --format=rdoc '

let s:selectionPrompt = ""
let s:cacheDir = $HOME."/.rdoc_vim/cache"

func! s:trimString(string)
  let string = substitute(a:string, '\s\+$', '', '')
  return substitute(string, '^\s\+', '', '')
endfunc

func! s:createCacheDir()
  call system("mkdir -p ".s:cacheDir)
endfunc

function! s:runCommand(command)
  " echom a:command " can use for debugging
  let res = system(a:command)
  return res
endfunction

function! StartRDocQuery()
  let classname = s:classname()
  if classname != ''
    let line = s:selectionPrompt . classname
  else
    let line = s:selectionPrompt
  endif
  leftabove split SearchRubyDocumentation
  setlocal textwidth=0
  setlocal completefunc=RDocAutoComplete
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal modifiable
  setlocal nowrap
  resize 1
  inoremap <buffer> <cr> <Esc>:call <SID>doSearch()<cr>
  noremap <buffer> <cr> <Esc>:call <SID>doSearch()<cr>
  noremap <buffer> q <Esc>:close<cr>
  inoremap <buffer> <Tab> <C-x><C-u>
  call setline(1, line)
  normal $
  call feedkeys("a", 't')
endfunction

function! s:prepareBuffer()
  setlocal nowrap
  setlocal textwidth=0
  noremap <buffer> <Leader>m :call <SID>selectMethod()<cr>
  noremap <buffer> <cr> :call <SID>playTrack()<cr>
  noremap <buffer> K :call <SID>lookupNameUnderCursor()<CR>
  noremap <buffer> <CR> :call <SID>lookupNameUnderCursor()<CR>
  let s:doc_bufnr = bufnr('%')
  autocmd BufRead <buffer> call <SID>syntaxLoad()
  call s:syntaxLoad()
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



" select a method from current class
function! s:selectMethod()
  let classname = s:classname()
  if classname == ''
    return
  endif
  let s:classname = classname
  let s:classMethods = s:matchingMethods(s:classname)
  let line = ""
  leftabove split SelectMethod
  setlocal textwidth=0
  setlocal completefunc=RubyClassMethodComplete
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal modifiable
  setlocal nowrap
  resize 1
  inoremap <buffer> <cr> <Esc>:call <SID>doSearch()<cr>
  noremap <buffer> <cr> <Esc>:call <SID>doSearch()<cr>
  noremap <buffer> q <Esc>:close<cr>
  inoremap <buffer> <Tab> <C-x><C-u>
  call setline(1, line)
  normal $
  call feedkeys("a\<c-x>\<c-u>\<c-p>", 't')
endfunction

function! RubyClassMethodComplete(findstart, base)
  if a:findstart
    let start = 0
    return start
  else
    if (a:base == '')
      return s:classMethods
    else
      let res = [] " find tracks matching a:base
      for m in s:classMethods
        " why doesn't case insensitive flag work?
        if m =~ '^\c' . a:base 
          call add(res, m)
        endif
      endfor
      return res
    endif
  endif
endfun

function! s:matchingMethods(classname)
  let command = s:rdoc_tool . '-m '. shellescape(a:classname)
  echom command
  return split(system(command), '\n')
endfunction


function! s:doSearch()
  if (getline('.') =~ '^\s*$')
    close
    return
  endif
  let query = s:trimString(getline('.')[len(s:selectionPrompt):])
  close
  " echom query
  if (len(query) == 0 || query =~ '^\s*$')
    return
  endif
  " clean up query string

  let query = substitute(query, '\s*(\d\+)$', '', '')
  let query = substitute(query, '::$', '', '')

  " for search for method
  if query =~ '\S\s\+\S'
    let parts = split(query)
    let query = get(parts, 1)
  endif

  " for select method of class
  if query =~ '^\.\|#'
    let query = s:classname . query
  endif

  wincmd p
  call s:displayDoc(query)
endfunction

function! s:displayDoc(query)
  let bcommand = s:rdoc_tool.'-d '.shellescape(a:query)
  let res = s:runCommand(bcommand)
  " We're caching is strictly so we can use CTRL-o and CTRL-i
  let cacheFile = substitute(s:cacheDir.'/'.a:query, '#', ',','')

  call writefile(split(res, "\n"), cacheFile)

  exec "edit ".cacheFile
  call s:prepareBuffer()
endfunction

func! s:syntaxLoad()
  syntax clear
  syntax region rdoctt  matchgroup=ttTags start="<tt[^>]*>" end="</tt>"
  syntax region rdoctt  matchgroup=ttTags start="<em[^>]*>" end="</em>"
  highlight link rdoctt Type
  highlight link ttTags Comment
  syntax region h1  start="^="       end="\($\)" contains=@Spell
  syntax region h2  start="^=="      end="\($\)" contains=@Spell
  syntax region h3  start="^==="     end="\($\)" contains=@Spell
  highlight link h1         Constant
  highlight link h2         Constant
  highlight link h3         Constant
endfunc

function! s:lookupNameUnderCursor()
  let query = substitute(expand("<cWORD>"), '[.,]$', '', '')
  let query = substitute(query, '</\?tt>', '', 'g')
  let classname = s:classname()
  " look up class
  if query =~ '^\.'
    let query = classname.query
  elseif query =~ '^#'
    let query = classname.query
  elseif query =~ '^[^A-Z]'
    let query = classname.'#'.query
  endif
  call s:displayDoc(query)
endfunction

" parses the first line of the doc
" e.g. ^= ActiveRecord::Base
" and returns ActiveRecord::Base
function! s:classname()
  let x = matchstr(getline(1) , '= [A-Z]\S\+')
  if x != ''
    return substitute(x, "^= ", '', '')
  else
    return ''
  endif
endfunction

nnoremap <silent> <leader>j :call StartRDocQuery()<cr>
echo "vim_rdoc loaded"

call s:createCacheDir()

let g:RDocLoaded = 1


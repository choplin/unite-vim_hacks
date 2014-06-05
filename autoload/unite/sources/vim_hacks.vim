" vim-hacks source for unite.vim
" Version:     0.0.1
" Last Change: 17 Nov 2011
" Author:      choplin <choplin.public+vim@gmail.com>
" Licence:     The MIT License {{{
"     Permission is hereby granted, free of charge, to any person obtaining a copy
"     of this software and associated documentation files (the "Software"), to deal
"     in the Software without restriction, including without limitation the rights
"     to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
"     copies of the Software, and to permit persons to whom the Software is
"     furnished to do so, subject to the following conditions:
"
"     The above copyright notice and this permission notice shall be included in
"     all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
"     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
"     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
"     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
"     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
"     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
"     THE SOFTWARE.
" }}}

" define source
function! unite#sources#vim_hacks#define()
  return s:source
endfunction

" buffer
let s:openbuf = openbuf#new('vim-hacks')

" cache
let s:cache = []
function! unite#sources#vim_hacks#refresh()
  let s:cache = []
endfunction

" source
let s:source = {
\ 'name': 'vim_hacks',
\ 'action_table': {},
\ 'default_action': {'uri': 'show'}
\}
function! s:source.gather_candidates(args, context)
  let should_refresh = a:context.is_redraw
  if should_refresh
    call unite#sources#vim_hacks#refresh()
  endif

  if empty(s:cache)
    let hacks = s:get_vim_hacks()
    for hack in hacks
      call add(s:cache, {
      \ 'word':   hack['date'] . ' ' . hack['title'],
      \ 'kind':   'uri',
      \ 'source': 'vim_hacks',
      \ 'action__path': hack['url']
      \})
    endfor
    call reverse(s:cache)
  endif

  return s:cache
endfunction

" action
let s:action_table = {}

let s:action_table.show = {
\   'description': 'show selected vim hack in a buffer'
\}

let s:source.action_table.uri = s:action_table

function! s:action_table.show.func(candidate)
  let scrape = ['h1', ['div', {'class':'post'}]]

  let content = s:get_vim_hacks_body(a:candidate.action__path)
  let dom = webapi#html#parse(iconv(content, 'utf-8', &encoding))

  let ret = []
  for s in scrape
    if type(s) == type([])
      call add(ret, dom.find(s[0], s[1]))
    elseif type(s) == type('')
      call add(ret, dom.find(s))
    endif
    call add(ret, "\n")
    unlet s
  endfor
  
  call s:print_buf(wwwrenderer#render_dom(ret))
endfunction

function! s:get_vim_hacks_body(url)
  let content = webapi#http#get(a:url).content
  let content = matchstr(content, '\zs<body[^>]*>.*<\/body>\ze')
  return content
endfunction

function! s:get_vim_hacks()
  let url = "http://vim-jp.org/vim-users-jp/hack.json"
  let content = iconv(webapi#http#get(url).content, 'utf-8', &encoding)
  let ret = webapi#html#decodeEntityReference(content)
  return webapi#json#decode(ret)
endfunction

function! s:print_buf(data)
  call s:openbuf.open('vim-hacks')
  setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted readonly
  setlocal filetype=vim-hacks
  silent % delete _
  silent 1 put =a:data
  silent 1,2 delete _
  silent $-2,$ delete _
  call cursor(1,1)
endfunction

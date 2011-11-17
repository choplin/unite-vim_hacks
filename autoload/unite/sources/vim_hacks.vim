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
      \ 'word':   hack['title'],
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
  let scrape = ['h1', ['ul', {'class':'info'}], ['div', {'class':'textBody'}]]

  let content = s:get_vim_hacks_body(a:candidate.action__path)
  let dom = html#parse(iconv(content, 'utf-8', &encoding))

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
  
  call s:print_buf(s:render(ret, 0))
endfunction

function! s:get_vim_hacks_body(url)
  let content = http#get(a:url).content
  let content = matchstr(content, '\zs<body[^>]\+>.*</body>\ze')
  return content
endfunction

function! s:get_vim_hacks()
  let content = s:get_vim_hacks_body('http://vim-users.jp/vim-hacks-project/')
  let dom = html#parse(iconv(content, 'utf-8', &encoding))
  let ret = []
  for li in dom.findAll('ul')[1].childNodes('li')
    let url = li.find('a').attr['href']
    call add(ret, {'url':url, 'title':li.value()})
    unlet li
  endfor
  return ret
endfunction

function! s:print_buf(data)
  call s:openbuf.open('vim-hacks')
  setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted readonly
  setlocal filetype=vim-hacks
  silent % delete _
  silent 1 put =a:data
  silent 1,2 delete _
  silent $-2,$ delete _
endfunction

function! s:render(dom, pre)
  let dom = a:dom
  if type(dom) == 0 || type(dom) == 1 || type(dom) == 5
    let html = html#decodeEntityReference(dom)
    let html = substitute(html, '\r', '', 'g')
    if a:pre == 0
      let html = substitute(html, '\n\+\s*', '', 'g')
    endif
    let html = substitute(html, '\t', '  ', 'g')
    return html
  elseif type(dom) == 3
    let html = ''
    for d in dom
      let html .= s:render(d, a:pre)
      unlet d
    endfor
    return html
  elseif type(dom) == 4
    if empty(dom)
      return ""
    endif
    if dom.name != 'script' && dom.name != 'style' && dom.name != 'head'
      let html = s:render(dom.child, a:pre || dom.name == 'pre')
      if dom.name =~ '^h[1-6]$' || dom.name == 'br' || dom.name == 'dt' || dom.name == 'dl' || dom.name == 'li' || dom.name == 'p'
        let html = "\n".html."\n"
      endif
      if dom.name == 'pre' || dom.name == 'blockquote'
        let html = "\n  ".substitute(html, "\n", "\n  ", 'g')."\n"
      endif
      return html
    endif
    return ''
  endif
endfunction

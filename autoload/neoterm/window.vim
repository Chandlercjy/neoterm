let s:default_opts = {
      \ 'handlers': {},
      \ 'source': '',
      \ 'buffer_Id': -1,
      \ 'mod': ''
      \ }

function! neoterm#window#create(opts)
  let l:origin = exists('*win_getid') ? win_getid() : 0
  let l:opts = extend(a:opts, s:default_opts, 'keep')

  if !has_key(g:neoterm, 'term')
    call neoterm#term#load()
  end

  if g:neoterm_split_on_tnew || l:opts.source !=# 'tnew'
    let l:hidden=&hidden
    let &hidden=0

    call s:split_cmd(l:opts)

    let &hidden=l:hidden
  end

  call g:neoterm.term.new({ 'handlers': l:opts.handlers, 'origin': l:origin })
  call s:after_open(l:origin)
endfunction

function! s:split_cmd(opts)
  let l:opts = extend(a:opts, s:default_opts, 'keep')
  let l:splitmod = get(a:opts, 'mod',
        \ g:neoterm_position ==# 'horizontal' ? 'botright' : 'vertical')
  let l:mod = get(a:opts, 'mod', '')

  " Always split when it is not using :Tnew
  if l:opts.source !=# 'tnew'
    let l:cmd = printf('%s %snew', l:splitmod, g:neoterm_size)
    if l:opts.buffer_id > 0
      exec printf('%s +buffer%s', l:cmd, l:opts.buffer_id)
    else
      exec l:cmd
    end
  elseif l:mod !=# ''
    exec printf('%s new', l:mod)
  end
endfunction

function! neoterm#window#reopen(opts)
  call s:split_cmd(extend(a:opts, { 'buffer_id': a:opts.instance.buffer_id }))
  call s:after_open(a:opts.instance.origin)
endfunction

function! s:after_open(origin)
  setf neoterm
  setlocal nonumber norelativenumber

  if g:neoterm_fixedsize
    setlocal winfixheight winfixwidth
  end

  if g:neoterm_autoinsert
    startinsert
  elseif !g:neoterm_autojump
    if a:origin
      call win_gotoid(a:origin)
    else
      wincmd p
    end
  end
endfunction

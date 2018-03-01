" Creates a new neoterm
" Arguments:
" optional dictionary with the following keys:
"     * handlers - dictionary with custom handlers for the terminal, keys:
"       * on_stdout
"       * on_stderr
"       * on_exit
"     * source - Indicates if a new neoterm is being created by `:Tnew` or
"     not, if it's being created by `:Tnew`, source must be `tnew`.
function! neoterm#new(...)
  call neoterm#window#create(get(a:, 1, {}))
endfunction

function! neoterm#toggle(mod)
  call s:toggle({ 'instance': g:neoterm.last(), 'mod': a:mod })
endfunction

function! neoterm#toggleAll()
  for l:instance in values(g:neoterm.instances)
    call s:toggle({ 'instance': l:instance })
  endfor
endfunction

function! s:toggle(opts)
  let l:opts = extend(a:opts, { 'mod': '' }, 'keep')
  if g:neoterm.has_any()
    let l:opts.instance.origin = exists('*win_getid') ? win_getid() : 0

    if neoterm#tab_has_neoterm()
      call l:opts.instance.close()
    else
      call l:opts.instance.open({ 'mod': l:opts.mod })
    end
  else
    call neoterm#new({ 'mod': l:opts.mod })
  end
endfunction

function! neoterm#open(opts)
  if !neoterm#tab_has_neoterm()
    if !g:neoterm.has_any()
      call neoterm#new(a:opts)
    else
      call g:neoterm.last().open(a:opts)
    end
  end
endfunction

function! neoterm#close(...)
  let l:instance = g:neoterm.last()
  let l:instance.origin = exists('*win_getid') ? win_getid() : 0

  let l:force = get(a:, '1', 0)
  if g:neoterm.has_any()
    call l:instance.close(l:force)
  end
endfunction

function! neoterm#closeAll(...)
  let l:origin = exists('*win_getid') ? win_getid() : 0

  let l:force = get(a:, '1', 0)
  for l:instance in values(g:neoterm.instances)
    let l:instance.origin = l:origin
    call l:instance.close(l:force)
  endfor
endfunction

function! neoterm#do(opts)
  let l:cmd = [neoterm#expand_cmd(a:opts.cmd), g:neoterm_eof]
  call neoterm#exec({'cmd': l:cmd, 'mod': a:opts.mod})
endfunction

function! neoterm#exec(opts)
  if !g:neoterm.has_any() || g:neoterm_open_in_all_tabs
    call neoterm#open({ 'mod': a:opts.mod })
  end

  call g:neoterm.last().exec(a:opts.cmd)
endfunction

function! neoterm#map_for(command)
  exec 'nnoremap <silent> '
        \ . g:neoterm_automap_keys .
        \ ' :T ' . neoterm#expand_cmd(a:command) . '<cr>'
endfunction

function! neoterm#expand_cmd(command)
  let l:command = substitute(a:command, '%\(:[phtre]\)\+', '\=expand(submatch(0))', 'g')

  if g:neoterm_use_relative_path
    let l:path = expand('%')
  else
    let l:path = expand('%:p')
  end

  return substitute(l:command, '%', l:path, 'g')
endfunction

function! neoterm#tab_has_neoterm()
  if g:neoterm.has_any()
    let l:buffer_id = g:neoterm.last().buffer_id
    return bufexists(l:buffer_id) > 0 && bufwinnr(l:buffer_id) != -1
  end
endfunction

function! neoterm#clear()
  silent call g:neoterm.last().clear()
endfunction

" Only executes if the window is opened.
function! neoterm#normal(cmd)
  silent call g:neoterm.last().normal(a:cmd)
endfunction

" Only executes if the window is opened.
function! neoterm#vim_exec(cmd)
  silent call g:neoterm.last().vim_exec(a:cmd)
endfunction

function! neoterm#kill()
  silent call g:neoterm.last().kill()
endfunction

function! neoterm#list(arg_lead, cmd_line, cursor_pos)
  return filter(keys(g:neoterm.instances), 'v:val =~? "'. a:arg_lead. '"')
endfunction

function! neoterm#next()
  function! s:next(buffers, index)
    let l:next_index = a:index + 1
    let l:next_index = l:next_index > (len(a:buffers) - 1) ? 0 : l:next_index
    exec printf('%sbuffer', a:buffers[l:next_index])
  endfunction

  call s:can_navigate(function('s:next'))
endfunction

function! neoterm#previous()
  function! s:previous(buffers, index)
    let l:previous_index = a:index - 1
    let l:previous_index = l:previous_index < 0 ? (len(a:buffers) - 1) : l:previous_index
    exec printf('%sbuffer', a:buffers[l:previous_index])
  endfunction

  call s:can_navigate(function('s:previous'))
endfunction

function! s:can_navigate(navigate)
  if &buftype ==? 'terminal'
    if len(g:neoterm.instances) > 1
      let l:buffers = map(copy(g:neoterm.instances), { _, instance -> instance.buffer_id })
      let l:buffers_ids = values(l:buffers)
      let l:current_buffer = l:buffers[b:neoterm_id]
      let l:current_index = index(l:buffers_ids, l:current_buffer)
      let l:hidden = &hidden

      set hidden
      call a:navigate(l:buffers_ids, l:current_index)
      let &hidden = l:hidden
    else
      echo 'You do not have other terminals'
    end
  else
    echo 'You must be in a terminal to use this command'
  end
endfunction

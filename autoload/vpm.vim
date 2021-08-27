let s:MATCH_GROUP = 'Vpm'
let s:UNSTARTED = 'unstarted'
let s:FINISHED = 'finished'
let s:ACTIVE = 'active'
let s:DISABLED = 'disabled'
let s:DIMMED = 'dimmed'
let s:NULL_HIGHLIGHT = {}
let s:ZERO_STATE = { 'state': s:UNSTARTED, 'highlight': s:NULL_HIGHLIGHT }
let s:STATE = {}
let s:CURRENT_FILE_STATE = { 'state': s:UNSTARTED, 'index': -1 }
let s:FILE_LIST = []
let s:HIGHLIGHT_COLOR = get(g:, 'vpm_highlight_color', 240)

" type State
"   = Unstarted
"   | Finished
"   | Active highlight
"   | Disabled highlight

function! vpm#state_for_current_file() abort
  if vpm#in_highlightable_file()
    return s:STATE[vpm#current_file_name()]
  else
    return s:ZERO_STATE
  endif
endfunction

function! vpm#current_file_highlights() abort
  return s:FILE_HIGHLIGHTS[vpm#current_file_name()]
endfunction

function! vpm#dim_whole_buffer()
  call vpm#dim_other_lines({ 'ranges': [] })
endfunction

function! vpm#undim()
  if vpm#state_for_current_file().state == s:ACTIVE
    call vpm#highlight(s:STATE[vpm#current_file_name()].highlight)
  else
    call vpm#remove_matches()
  endif
endfunction

function! vpm#current_file_name() abort
  return expand('%')
endfunction

function! vpm#vpm_register(configuration) abort
  for file in keys(a:configuration.highlights)
    let s:STATE[file] = s:ZERO_STATE
  endfor
  let s:FILE_HIGHLIGHTS = a:configuration.highlights
  let s:FILE_LIST = a:configuration.file_list
  execute printf('hi '.s:MATCH_GROUP.' ctermfg=%s', s:HIGHLIGHT_COLOR)
endfunction

function! vpm#register_config(path) abort
  call vpm#vpm_register(json_decode(system('yq eval . -o=json ' . a:path)))
endfunction

function! vpm#vpm_statusline() abort
  if vpm#in_highlightable_file()
    let current = vpm#highlight_number_for_current_file()
    return "[vpm: " . current . "/" . len(vpm#current_file_highlights()) . "]"
  else
    return ""
  endif
endfunction

function! vpm#highlight_number_for_current_file() abort
  let state = vpm#state_for_current_file().state
  if state == s:UNSTARTED
    return "-"
  elseif state == s:FINISHED
    return "="
  else
    return index(
          \ vpm#current_file_highlights(),
          \ vpm#state_for_current_file().highlight
          \ ) + 1
  endif
endfunction

function! vpm#open_next_file() abort
  if vpm#can_go_to_next_file()
    let [state, index, next_open_command] = vpm#next_open_state()
    execute next_open_command
    let s:CURRENT_FILE_STATE = { 'state': state, 'index': index }
  endif
endfunction

function! vpm#can_go_to_next_file() abort
  return !empty(s:FILE_LIST) && s:CURRENT_FILE_STATE.state != s:FINISHED
endfunction

function! vpm#next_open_state() abort
  if s:CURRENT_FILE_STATE.state == s:UNSTARTED
    return [s:ACTIVE, 0, s:FILE_LIST[0]]
  else
    let next_index = s:CURRENT_FILE_STATE.index + 1
    let next_state = (next_index == len(s:FILE_LIST) - 1) ? s:FINISHED : s:ACTIVE
    return [next_state, next_index, s:FILE_LIST[next_index]]
  endif
endfunction

function! vpm#enable_dim_on_leave() abort
  augroup Vpm
    autocmd!
    autocmd WinEnter,BufEnter * VpmUndim
    autocmd WinLeave,BufLeave * VpmDim
  augroup END
endfunction

function! vpm#highlight(highlight) abort
  call vpm#dim_other_lines(a:highlight)
  call vpm#move_cursor_to_highlight_focus_line(a:highlight)
  call vpm#set_state(s:ACTIVE, a:highlight)
endfunction

function! vpm#move_cursor_to_highlight_focus_line(highlight)
  call cursor(a:highlight.cursorLine, 1)
  normal! ^zt
endfunction

function! vpm#set_state(state, ...) abort
  let highlight = get(a:, 1, s:NULL_HIGHLIGHT)
  let s:STATE[expand('%')] = { 'state': a:state, 'highlight': highlight }
endfunction

function! vpm#dim_other_lines(highlight) abort
  call vpm#remove_matches()
  let lines_to_dim = vpm#lines_to_dim_from_ranges(a:highlight.ranges)
  for line in lines_to_dim
    call matchaddpos(s:MATCH_GROUP, [line], 10)
  endfor
endfunction

function! vpm#remove_matches() abort
  let matches = filter(getmatches(), 'v:val.group == "'.s:MATCH_GROUP.'"')
  for id in map(matches, 'v:val.id')
    call matchdelete(id)
  endfor
endfunction

function! vpm#disable() abort
  if vpm#state_for_current_file().state != s:UNSTARTED
    call vpm#set_state(s:DISABLED, vpm#state_for_current_file().highlight)
  endif
  call vpm#remove_matches()
endfunction! abort

function! vpm#enable() abort
  call vpm#highlight(vpm#state_for_current_file().highlight)
endfunction

function! vpm#highlight_first() abort
  call vpm#highlight(vpm#current_file_highlights()[0])
endfunction

function! vpm#highlight_last() abort
  call vpm#highlight(vpm#current_file_highlights()[len(vpm#current_file_highlights()) - 1])
endfunction

function! vpm#lines_to_dim_from_ranges(ranges) abort
  let lines = range(1, line('$'))
  for range in a:ranges
    for line in range(range[0], range[1])
      let index = index(lines, line)
      if index == -1
        break
      else
        call remove(lines, index(lines, line))
      end
    endfor
  endfor
  return lines
endfunction

function! vpm#finish_highlights() abort
  call vpm#remove_matches()
  call vpm#set_state(s:FINISHED)
endfunction

function! vpm#reset_to_unstarted() abort
  call vpm#remove_matches()
  call vpm#set_state(s:UNSTARTED)
endfunction

function! vpm#in_highlightable_file() abort
  return has_key(s:STATE, vpm#current_file_name())
endfunction

function! vpm#next_highlight() abort
  if vpm#in_highlightable_file()
    if vpm#state_for_current_file().state == s:UNSTARTED
      call vpm#highlight_first()
    elseif vpm#state_for_current_file().state == s:FINISHED " no-op
    elseif vpm#state_for_current_file().state == s:ACTIVE
      call vpm#actually_highlight_next()
    elseif vpm#state_for_current_file().state == s:DISABLED
      call vpm#enable()
    else
      throw "Unexpected state type"
    endif
  endif
endfunction

function! vpm#previous_highlight() abort
  if vpm#in_highlightable_file()
    if vpm#state_for_current_file().state == s:UNSTARTED " no-op
    elseif vpm#state_for_current_file().state == s:FINISHED
      call vpm#highlight_last()
    elseif vpm#state_for_current_file().state == s:ACTIVE
      call vpm#actually_highlight_previous()
    elseif vpm#state_for_current_file().state == s:DISABLED
      call vpm#enable()
    else
      throw "Unexpected state type"
    endif
  endif
endfunction

function! vpm#actually_highlight_previous() abort
  let index = index(vpm#current_file_highlights(), vpm#state_for_current_file().highlight)
  if index == 0
    call vpm#reset_to_unstarted()
  else
    if index > 0
      call vpm#highlight(vpm#current_file_highlights()[index - 1])
    endif
  endif
endfunction

function! vpm#actually_highlight_next() abort
  let index = index(vpm#current_file_highlights(), vpm#state_for_current_file().highlight)
  if index + 1 < len(vpm#current_file_highlights())
    call vpm#highlight(vpm#current_file_highlights()[index + 1])
  else
    call vpm#finish_highlights()
  endif
endfunction

function! vpm#ActivateWindowByName(name)
  let bufid = bufnr(a:name)
  let winids = win_findbuf(l:bufid)
  if !empty(winids)
    call win_gotoid(winids[0])
  else
    execute "edit ".a:name
  endif
endfunction

function! vpm#Only(file) abort
  call vpm#ActivateWindowByName(a:file)
  silent! only
endfunction

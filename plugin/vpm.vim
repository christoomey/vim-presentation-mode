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

function! s:state_for_current_file() abort
  if s:in_highlightable_file()
    return s:STATE[s:current_file_name()]
  else
    return s:ZERO_STATE
  endif
endfunction

function! s:current_file_highlights() abort
  return s:FILE_HIGHLIGHTS[s:current_file_name()]
endfunction

function! s:dim_whole_buffer()
  call s:dim_other_lines({ 'ranges': [] })
endfunction

function! s:undim()
  if s:state_for_current_file().state == s:ACTIVE
    call s:highlight(s:STATE[s:current_file_name()].highlight)
  else
    call s:remove_matches()
  endif
endfunction

function! s:current_file_name() abort
  return expand('%')
endfunction

function! VpmRegister(configuration) abort
  for file in keys(a:configuration.highlights)
    let s:STATE[file] = s:ZERO_STATE
  endfor
  let s:FILE_HIGHLIGHTS = a:configuration.highlights
  let s:FILE_LIST = a:configuration.file_list
  execute printf('hi '.s:MATCH_GROUP.' ctermfg=%s', s:HIGHLIGHT_COLOR)
endfunction

function! VpmStatusline() abort
  if s:in_highlightable_file()
    let current = s:highlight_number_for_current_file()
    return "[vpm: " . current . "/" . len(s:current_file_highlights()) . "]"
  else
    return ""
  endif
endfunction

function! s:highlight_number_for_current_file() abort
  let state = s:state_for_current_file().state
  if state == s:UNSTARTED
    return "-"
  elseif state == s:FINISHED
    return "="
  else
    return index(
          \ s:current_file_highlights(),
          \ s:state_for_current_file().highlight
          \ ) + 1
  endif
endfunction

function! s:open_next_file() abort
  if s:can_go_to_next_file()
    let [state, index, next_open_command] = s:next_open_state()
    execute next_open_command
    let s:CURRENT_FILE_STATE = { 'state': state, 'index': index }
  endif
endfunction

function! s:can_go_to_next_file() abort
  return !empty(s:FILE_LIST) && s:CURRENT_FILE_STATE.state != s:FINISHED
endfunction

function! s:next_open_state() abort
  if s:CURRENT_FILE_STATE.state == s:UNSTARTED
    return [s:ACTIVE, 0, s:FILE_LIST[0]]
  else
    let next_index = s:CURRENT_FILE_STATE.index + 1
    let next_state = (next_index == len(s:FILE_LIST) - 1) ? s:FINISHED : s:ACTIVE
    return [next_state, next_index, s:FILE_LIST[next_index]]
  endif
endfunction

function! s:vpm_enable_dim_on_leave() abort
  augroup Vpm
    autocmd!
    autocmd WinEnter,BufEnter * VpmUndim
    autocmd WinLeave,BufLeave * VpmDim
  augroup END
endfunction

function! s:highlight(highlight) abort
  call s:dim_other_lines(a:highlight)
  call s:move_cursor_to_highlight_focus_line(a:highlight)
  call s:set_state(s:ACTIVE, a:highlight)
endfunction

function! s:move_cursor_to_highlight_focus_line(highlight)
  call cursor(a:highlight.cursorLine, 1)
  normal! ^zt
endfunction

function! s:set_state(state, ...) abort
  let highlight = get(a:, 1, s:NULL_HIGHLIGHT)
  let s:STATE[expand('%')] = { 'state': a:state, 'highlight': highlight }
endfunction

function! s:dim_other_lines(highlight) abort
  call s:remove_matches()
  let lines_to_dim = s:lines_to_dim_from_ranges(a:highlight.ranges)
  for line in lines_to_dim
    call matchaddpos(s:MATCH_GROUP, [line], 10)
  endfor
endfunction

function! s:remove_matches() abort
  let matches = filter(getmatches(), 'v:val.group == "'.s:MATCH_GROUP.'"')
  for id in map(matches, 'v:val.id')
    call matchdelete(id)
  endfor
endfunction

function! s:disable() abort
  if s:state_for_current_file().state != s:UNSTARTED
    call s:set_state(s:DISABLED, s:state_for_current_file().highlight)
  endif
  call s:remove_matches()
endfunction! abort

function! s:enable() abort
  call s:highlight(s:state_for_current_file().highlight)
endfunction

function! s:highlight_first() abort
  call s:highlight(s:current_file_highlights()[0])
endfunction

function! s:highlight_last() abort
  call s:highlight(s:current_file_highlights()[len(s:current_file_highlights()) - 1])
endfunction

function! s:lines_to_dim_from_ranges(ranges) abort
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

function! s:finish_highlights() abort
  call s:remove_matches()
  call s:set_state(s:FINISHED)
endfunction

function! s:reset_to_unstarted() abort
  call s:remove_matches()
  call s:set_state(s:UNSTARTED)
endfunction

function! s:in_highlightable_file() abort
  return has_key(s:STATE, s:current_file_name())
endfunction

function! s:vpm_next_highlight() abort
  if s:in_highlightable_file()
    if s:state_for_current_file().state == s:UNSTARTED
      call s:highlight_first()
    elseif s:state_for_current_file().state == s:FINISHED " no-op
    elseif s:state_for_current_file().state == s:ACTIVE
      call s:actually_highlight_next()
    elseif s:state_for_current_file().state == s:DISABLED
      call s:enable()
    else
      throw "Unexpected state type"
    endif
  endif
endfunction

function! s:vpm_previous_highlight() abort
  if s:in_highlightable_file()
    if s:state_for_current_file().state == s:UNSTARTED " no-op
    elseif s:state_for_current_file().state == s:FINISHED
      call s:highlight_last()
    elseif s:state_for_current_file().state == s:ACTIVE
      call s:actually_highlight_previous()
    elseif s:state_for_current_file().state == s:DISABLED
      call s:enable()
    else
      throw "Unexpected state type"
    endif
  endif
endfunction

function! s:actually_highlight_previous() abort
  let index = index(s:current_file_highlights(), s:state_for_current_file().highlight)
  if index == 0
    call s:reset_to_unstarted()
  else
    if index > 0
      call s:highlight(s:current_file_highlights()[index - 1])
    endif
  endif
endfunction

function! s:actually_highlight_next() abort
  let index = index(s:current_file_highlights(), s:state_for_current_file().highlight)
  if index + 1 < len(s:current_file_highlights())
    call s:highlight(s:current_file_highlights()[index + 1])
  else
    call s:finish_highlights()
  endif
endfunction

function! s:ActivateWindowByName(name)
  let bufid = bufnr(a:name)
  let winids = win_findbuf(l:bufid)
  if !empty(winids)
    call win_gotoid(winids[0])
  else
    execute "edit ".a:name
  endif
endfunction

function! s:Only(file) abort
  call s:ActivateWindowByName(a:file)
  silent! only
endfunction

command! -bar -nargs=1 -complete=file Only call s:Only(<q-args>)
command! VpmDim call s:dim_whole_buffer()
command! VpmUndim call s:undim()
command! VpmOff call s:disable()
command! VpmOpenNextFile call s:open_next_file()
command! VpmEnableDimOnLeave call s:vpm_enable_dim_on_leave()
command! VpmNextHighlight call s:vpm_next_highlight()
command! VpmPreviousHighlight call s:vpm_previous_highlight()

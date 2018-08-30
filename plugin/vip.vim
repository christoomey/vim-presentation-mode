let s:VIP_NO_HIGHLIGHT_START = { 'start': 1 }
let s:VIP_NO_HIGHLIGHT_END = { 'start': 0 }
let s:VIP_CURRENT_HIGHLIGHT = s:VIP_NO_HIGHLIGHT_START
let s:MATCH_GROUP = 'Vip'

" type CurrentHighlight
"   = Unstarted
"   | Finished
"   | Active highlight
"   | Disabled highlight

execute printf('hi '.s:MATCH_GROUP.' ctermfg=%s', 240)

function! s:remove_matches()
  let matches = filter(getmatches(), 'v:val.group == "'.s:MATCH_GROUP.'"')
  for id in map(matches, 'v:val.id')
    call matchdelete(id)
  endfor
endfunction

function! Highlight(highlight)
  let s:VIP_CURRENT_HIGHLIGHT = a:highlight

  call s:remove_matches()
  let lines_to_dim = s:range_inverse(a:highlight.ranges)
  for line in lines_to_dim
    call matchaddpos(s:MATCH_GROUP, [line], 10)
  endfor

  call cursor(a:highlight.cursorLine, 1)
  " normal! ^zz
endfunction

function! s:range_inverse(ranges)
  let lines = range(1, line('$'))
  for range in a:ranges
    for line in range(range[0], range[1])
      call remove(lines, index(lines, line))
    endfor
  endfor
  return lines
endfunction

function! s:VipNextHighlight()
  if s:VIP_CURRENT_HIGHLIGHT != s:VIP_NO_HIGHLIGHT_END
    if s:VIP_CURRENT_HIGHLIGHT == s:VIP_NO_HIGHLIGHT_START
      call Highlight(g:vip_ranges[0])
    else
      let index = index(g:vip_ranges, s:VIP_CURRENT_HIGHLIGHT)
      if index + 1 < len(g:vip_ranges)
        let next_highlight = g:vip_ranges[index + 1]
        call Highlight(next_highlight)
      else
        call s:remove_matches()
        let s:VIP_CURRENT_HIGHLIGHT = s:VIP_NO_HIGHLIGHT_END
      endif
    endif
  endif
endfunction

function! s:VipPreviousHighlight()
  if s:VIP_CURRENT_HIGHLIGHT != s:VIP_NO_HIGHLIGHT_START
    if s:VIP_CURRENT_HIGHLIGHT == s:VIP_NO_HIGHLIGHT_END
      call Highlight(g:vip_ranges[len(g:vip_ranges) - 1])
    else
      let index = index(g:vip_ranges, s:VIP_CURRENT_HIGHLIGHT)
      if index == 0
        call s:remove_matches()
        let s:VIP_CURRENT_HIGHLIGHT = s:VIP_NO_HIGHLIGHT_START
      else
        if index > 0
          let next_highlight = g:vip_ranges[index - 1]
          call Highlight(next_highlight)
        endif
      endif
    end
  endif
endfunction

command! VipOff silent! call s:remove_matches()
command! VipNextHighlight silent! call s:VipNextHighlight()
command! VipPreviousHighlight silent! call s:VipPreviousHighlight()

nnoremap <Left> :VipPreviousHighlight<cr>
nnoremap <Right> :VipNextHighlight<cr>

nnoremap <Down> :VipOff<cr>

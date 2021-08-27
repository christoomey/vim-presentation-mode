function! VpmRegister(configuration) abort
  call vpm#vpm_register(a:configuration)
endfunction

function! VpmStatusline() abort
  return vpm#vpm_statusline()
endfunction

command! -bar -nargs=1 -complete=file Only call vpm#Only(<q-args>)
command! VpmDim call vpm#dim_whole_buffer()
command! VpmUndim call vpm#undim()
command! VpmOff call vpm#disable()
command! VpmOpenNextFile call vpm#open_next_file()
command! VpmEnableDimOnLeave call vpm#enable_dim_on_leave()
command! VpmNextHighlight call vpm#next_highlight()
command! VpmPreviousHighlight call vpm#previous_highlight()

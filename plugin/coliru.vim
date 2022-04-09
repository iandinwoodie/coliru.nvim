if exists('g:loaded_coliru')
  finish
endif
let g:loaded_coliru = 1

scriptencoding utf-8

command! Coliru lua require('coliru').coliru()

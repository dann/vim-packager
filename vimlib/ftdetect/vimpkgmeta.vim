" meta filetype -----
au BufNewFile,BufRead META :call s:DetectMeta()
fun! s:DetectMeta()
  if getline(1) =~ 'vim-package-meta'
    setfiletype 'vimpkgmeta'
  endif
endf

" VIM syntax file
" Language: VIM Package Meta file
" Maintainer:   Cornelius (c9s)
" Last Change:  Sun Oct 25 02:12:21 2009

if version < 600
  syntax clear
elseif exists("b:current_syntax")
  "finish
endif

syn match Property !^=\w\+!
syn match Comment  !^#.*$!
syn match Inner    !^\s\+.*$!

hi link Property Identifier
hi link Comment  Comment
hi link Inner    Comment

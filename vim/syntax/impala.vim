" Vim syntax file
" Language:   impala
" Maintainer: Immanuel Haffner
" Version:

if exists("b:current_syntax")
    finish
endif

syn keyword     impalaKeyword       if else while for return break continue let
syn keyword     impalaType          bool int mut
syn match       impalaNumber        '\<\d\+\>'
syn keyword     impalaFunction      fn


let b:current_syntax = "impala"

hi def link impalaKeyword   Keyword
hi def link impalaType      Type
hi def link impalaFunction  Function
hi def link impalaNumber    Number

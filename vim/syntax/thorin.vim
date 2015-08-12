" Vim syntax file
" Language:   thorin
" Maintainer: Immanuel Haffner
" Version:

if exists("b:current_syntax")
    finish
endif


" Lambdas: everything at the beginning of a line is considered a lambda
syn match   thorinLambda    '^\s*[0-9a-zA-Z_]\+' contains=ALLBUT,thorinLambda

" Keywords:
syn keyword thorinKeyword   eq ne gt ge lt le
syn keyword thorinKeyword   add sub mul div rem
syn keyword thorinKeyword   and or xor shl shr
syn keyword thorinKeyword   bottom alloc load store enter leave map select global slot cast bitcast definite_array indefinite_array tuple struct_agg vector extract insert lea run hlt end_run end_hlt
syn keyword thorinKeyword   extern
" Special treatment for fn as type constructor and br as intrinsic function
syn keyword thorinKeyword   br fn

" Numbers:
syn match   thorinNumber    '\<\d\+\>'

" Types:
syn keyword thorinType      ps8 ps16 ps32 ps64 pu8 pu16 pu32 pu64
syn keyword thorinType      qs8 qs16 qs32 qs64 qu8 qu16 qu32 qu64
syn keyword thorinType      pf32 pf64 qf32 qf64
syn keyword thorinType      bool mem


let b:current_syntax = "thorin"

hi def link thorinType      Type
hi def link thorinKeyword   Keyword
hi def link thorinNumber    Number
hi def link thorinLambda    Function

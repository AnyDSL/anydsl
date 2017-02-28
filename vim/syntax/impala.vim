" Vim syntax file
" Language:   impala
" Maintainer: Immanuel Haffner
" Version:

if exists("b:current_syntax")
    finish
endif

syn keyword     impalaConditional   if else
syn keyword     impalaException     return break continue
syn keyword     impalaLoop          while for with
syn keyword     impalaStorageClass  let extern mut static
syn keyword     impalaStructure     struct trait impl
syn keyword     impalaTypedef       type
syn keyword     impalaType          bool int uint float f32 f64 i8 i16 i32 i64 u8 u16 u32 u64
syn keyword     impalaOperator      as
syn keyword     impalaFunction      fn
syn keyword     impalaTodo          TODO FIXME containedin=impalaBlockComment,impalaLineComment
syn match       impalaNumber        '\v<\d(\d|_)*(i8|u8|i16|u16|i32|u32|i64|u64){0,1}>'
syn match       impalaLineComment   '\v\s*//.*$'
syn region      impalaBlockComment  start='/\*'  end='\*/'
syn region      impalaString        start=+"+    end=+"+
syn match       impalaPartialEval   '\v[@$]'
syn match       impalaAddressOf     '\v[&]'
syn match       impalaArrow         '->' conceal cchar=→

let b:current_syntax = "impala"

hi def link impalaConditional   Conditional
hi def link impalaException     Exception
hi def link impalaLoop          Loop
hi def link impalaStorageClass  StorageClass
hi def link impalaStructure     Structure
hi def link impalaTypedef       Keyword
hi def link impalaType          Type
hi def link impalaNumber        Number
hi def link impalaOperator      Keyword
hi def link impalaAddressOf     Operator
hi def link impalaPartialEval   PreProc
hi def link impalaFunction      Keyword
hi def link impalaLineComment   Comment
hi def link impalaBlockComment  Comment
hi def link impalaString        String
hi def link impalaTodo          Todo

hi impalaArrow gui=bold

" Vim syntax file
" Language:   impala
" Maintainer: Immanuel Haffner
" Version:

if exists("b:current_syntax")
    finish
endif

syn keyword     impalaConditional   if else
syn keyword     impalaException     return break continue
syn keyword     impalaLoop          while for
syn keyword     impalaStorageClass  let extern mut static
syn keyword     impalaStructure     struct trait impl
syn keyword     impalaTypedef       type
syn keyword     impalaType          bool int uint float f32 f64 i8 i16 i32 i64 u8 u16 u32 u64
syn keyword     impalaOperator	    as
syn match       impalaNumber        '\<\d\+\>'
syn keyword     impalaFunction      fn


let b:current_syntax = "impala"

hi def link impalaConditional   Conditional  
hi def link impalaException     Exception    
hi def link impalaLoop          Loop         
hi def link impalaStorageClass  StorageClass 
hi def link impalaStructure     Structure    
hi def link impalaTypedef       Typedef      
hi def link impalaType          Type           
hi def link impalaNumber        Number        
hi def link impalaOperator      Operator        
hi def link impalaFunction      Function     

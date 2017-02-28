augroup Impala
  autocmd!
  autocmd BufRead,BufNewFile *.impala set filetype=impala
  autocmd BufRead,BufNewFile *.impala set commentstring=//\ %s
  "autocmd BufRead,BufNewFile *.impala set filetype=rust
augroup end

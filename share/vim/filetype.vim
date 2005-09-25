if exists("did_load_filetypes")
    finish
endif
" let did_load_filetypes=1

augroup filetypedetect
    
    au BufRead,BufNewFile * let Comment="# " | let EndComment=""
    
    au BufRead,BufNewFile *.inc,*.ihtml,*.html,*.tpl,*.class setlocal filetype=php | let Comment="<!-- " | let EndComment=" -->"
    
    au BufRead,BufNewFile *.sh,*.pl,*.tcl let Comment="#" | let EndComment="" | setlocal commentstring=\#\ %s 
    
    au BufRead,BufNewFile *.js setlocal filetype=html | let Comment="//" | let EndComment=""

    au BufRead,BufNewFile *.cc,*.php,*.class,*.cxx let Comment="//" | let EndComment=""

    au BufRead,BufNewFile *.c,*.h let Comment="/*" | let EndComment="*/"

    " set fold type to syntax for these known filetypes
    au BufRead,BufNewFile *.pl,*.pm,*.pod  let perl_fold=1 
    " these are set automatically | set ft=perl | set foldmethod=syntax 
    au BufRead,BufNewFile *.php,*.phps,*.class  let php_folding=1 
    " these are set automatically | set ft=php | set foldmethod=syntax 
    " no syntax support for these:
    au BufRead,BufNewFile *.tcl,*.tk,*.sh setlocal foldmethod=marker

    au BufRead,BufNewFile *.bat let Comment="::" | let EndComment=""

augroup END

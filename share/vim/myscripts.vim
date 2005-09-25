" Perl
if getline(1) =~ '^#!.*[/\\][^/\\]*perl[^/\\]*\>'
  do perl BufReadPre x.pl
  set ft=perl
endif

" Python
if getline(1) =~ '^#!.*[/\\][^/\\]*python[^/\\]*\>'
  do python BufReadPre x.py
  set ft=python
endif

" Bourne-like shell scripts: sh ksh bash
if getline(1) =~ '^#!.*[/\\][bk]\=a\=sh\>'
  do shell BufRead x.sh
  if exists("is_bash")
    unlet is_bash
  endif
  if exists("is_kornshell")
    unlet is_kornshell
  endif
  " if bash is sh on your system as on Linux, you may prefer to
  " add the following in your .vimrc file:
  " let bash_is_sh=1
  if exists("bash_is_sh") || getline(1) =~ '^#!.*[/\\]bash\>'
    let is_bash=1
  elseif getline(1) =~ '^#!.*[/\\]ksh\>'
    let is_kornshell=1
  endif
  set ft=sh

" csh and tcsh scripts
elseif getline(1) =~ '^#!.*[/\\]t\=csh\>'
  do shell BufRead x.sh
  set ft=csh

" Z shell scripts
elseif getline(1) =~ '^#!.*[/\\]zsh\>'
	\ || getline(1) =~ '^#compdef\>'
	\ || getline(1) =~ '^#autoload\>'
  do shell BufRead x.sh
  set ft=zsh
endif

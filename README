# Overview
nvim-slime is a pure Lua implementation of https://common-lisp.net/project/slime/ for Neovim. It was adapted from this Textadept version https://github.com/chadvoegele/textadept-slime, which was originally inspired by https://github.com/jpalardy/vim-slime.

# Status
I just threw this together as a proof-of-concept. Probably a lot of things don't work. PRs welcome.

# Installation
```
$ git clone https://github.com/chadvoegele/nvim-slime.git ~/.local/share/nvim/site/lua/nvim-slime
$ cat << FOE >> ~/.config/nvim/init.vim
lua << EOF
nvis = require('nvim-slime')
EOF

xmap <c-c><c-c> :lua nvis.paste.text() <CR>
FOE
```

# License
MIT

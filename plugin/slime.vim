lua << EOF
nvis = require('nvim-slime')
EOF

xnoremap <silent> <Plug>SlimeVisual :lua nvis.paste() <CR>

if !hasmapto('<Plug>SlimeVisual')
  xmap <c-c><c-c> <Plug>SlimeVisual
endif

lua << EOF
nvis = require('nvim-slime')
EOF

xnoremap <silent> <Plug>SlimeVisual :lua nvis.paste_selected() <CR>
nnoremap <silent> <Plug>SlimeAll :lua nvis.paste_all() <CR>

if !hasmapto('<Plug>SlimeVisual')
  xmap <c-c><c-c> <Plug>SlimeVisual
endif

if !hasmapto('<Plug>SlimeAll')
  nmap <c-c><c-c> <Plug>SlimeAll
endif

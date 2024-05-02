" Vim configuration file for text editing.
"
" For more information, visit https://vimhelp.org/usr_05.txt.html.

" General settings.

highlight linenr ctermbg=lightgrey
set hlsearch " Highlight all search results
set laststatus=2 " Always show the status line.
set number " Show line numbers.
set ruler " Show row and column rulers.
set showmatch " Highlight matching braces.
set statusline=\ %f\ %m%=%l:%c\ \ %{&fileformat}\ 
set wildmenu " Enable tab completion menu in command prompt.
syntax enable " Enable syntax highlighting.

" Cursor settings.

set guicursor=a:ver100

" Indentation settings.

set autoindent " Auto-indent new lines.
set expandtab
set shiftwidth=4 " Number of auto-indent spaces.
set smartindent " Enable smart-indent.
set smarttab " Enable smart-tabs.
set softtabstop=4 " Number of spaces per Tab.
set tabstop=4

" Keybinding settings.

noremap <C-Left> <C-o> " Change goto previous location.
noremap <C-Right> <C-i> " Change goto next location.

" Change navigation.
noremap ; l
noremap l k
noremap k j
noremap j h


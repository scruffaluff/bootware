" Neovim configuration file.


" General settings.

set hlsearch  " Highlight all search results
set number  " Show line numbers.
set ruler  " Show row and column rulers.
set showmatch  " Highlight matching braces.


" Cursor settings.

set guicursor=a:ver100


" Indentation settings.

set autoindent  " Auto-indent new lines.
set expandtab
set shiftwidth=4  " Number of auto-indent spaces.
set smartindent  " Enable smart-indent.
set smarttab  " Enable smart-tabs.
set softtabstop=4  " Number of spaces per Tab.
set tabstop=4


" Keybinding settings.

noremap ; l
noremap l k
noremap k j
noremap j h


" Neosolarized settings.

colorscheme NeoSolarized
set background=light
set termguicolors

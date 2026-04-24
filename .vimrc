" dotfiles — vim config

set nocompatible
set encoding=utf-8
set history=1000

" Display
set number relativenumber
set cursorline
set showmatch
set ruler

" Indentation
set tabstop=4 shiftwidth=4 expandtab
set smartindent autoindent
autocmd FileType javascript,typescript,json,html,css,yaml setlocal tabstop=2 shiftwidth=2

" Search
set ignorecase smartcase
set hlsearch incsearch

" Usability
set mouse=a
set clipboard=unnamed
syntax on
colorscheme desert

" Strip trailing whitespace on save
autocmd BufWritePre * :%s/\s\+$//e

" Key mappings
let mapleader = ","
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <Esc> :noh<CR>
vnoremap <C-c> "+y

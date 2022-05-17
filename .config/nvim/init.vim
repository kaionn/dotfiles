"-----------------
" plugins
"-----------------
call plug#begin('~/.local/share/nvim/plugged')
" common
Plug 'nathanaelkane/vim-indent-guides'
Plug 'ntpeters/vim-better-whitespace'
Plug 'tomtom/tcomment_vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'szw/vim-tags',{ 'for': 'ruby' }
Plug 'sheerun/vim-polyglot' " language syntax highlight
Plug 'tpope/vim-dispatch'
Plug 'itchyny/lightline.vim'
Plug 'edkolev/tmuxline.vim', { 'on': 'Tmuxline' }
Plug 'vim-test/vim-test', { 'on': ['TestFile', 'TestNearest', 'TestLast', 'TestSuite'] }
Plug 'ojroques/vim-oscyank', { 'on': ['OSCYank', 'OSCYankReg'] }
" fern
Plug 'lambdalisue/fern.vim'
Plug 'lambdalisue/fern-git-status.vim'
Plug 'lambdalisue/nerdfont.vim'
Plug 'lambdalisue/glyph-palette.vim'
Plug 'lambdalisue/fern-renderer-nerdfont.vim'
" git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
" lsp
Plug 'neoclide/coc.nvim', {'branch': 'release'}
" go
Plug 'mattn/vim-goimports', { 'for': 'go' }
Plug 'sebdah/vim-delve', { 'for': 'go' }
" markdown
Plug 'mattn/vim-maketable', { 'for': 'markdown' }
Plug 'junegunn/goyo.vim', { 'for': 'markdown' }
" theme
Plug 'morhetz/gruvbox'
call plug#end()

" vim-test
let test#strategy = "dispatch"

" fern
nnoremap <C-n> :Fern . -reveal=% -drawer -toggle -width=40<CR>1
let g:fern#renderer = 'nerdfont'
augroup my-glyph-palette
  autocmd! *
  autocmd FileType fern call glyph_palette#apply()
  autocmd FileType nerdtree,startify call glyph_palette#apply()
augroup END

" coc
function! s:completion_check_bs()
    let l:col = col('.') - 1
    return !l:col || getline('.')[l:col - 1] =~? '\s'
endfunction

inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>completion_check_bs() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
" inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>
nmap <silent> [c <Plug>(coc-diagnostic-prev)
nmap <silent> ]c <Plug>(coc-diagnostic-next)

nmap <silent> <C-]> <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> <C-t> <Plug>(coc-references)
"Autocmd CursorHold * silent call CocUpdagteAsync('highlight')
" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
vmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

" Using CocList
" Show all diagnostics
nnoremap <silent> <space>a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> <space>e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>

" not stop completion $ & /
setlocal iskeyword+=$
setlocal iskeyword+=-

" indent guides
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1

" vim-oscyank
autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '' | execute 'OSCYankReg "' | endif

" fzf
let g:fzf_command_prefix = 'Fzf'
let g:fzf_layout = { 'down': '~40%' }
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \   'rg --column --line-number --no-heading --color=always '.shellescape(<q-args>), 1,
  \   <bang>0 ? fzf#vim#with_preview({'options': '--exact --reverse'}, 'up:60%')
  \           : fzf#vim#with_preview({'options': '--exact --reverse'},'right:50%:hidden', '?'),
  \   <bang>0)

nnoremap <silent> <C-p> :FzfFiles<CR>
nnoremap <silent> <C-h> :FzfHistory<cr>
nnoremap <silent> <C-g> :FzfRg<cr>

autocmd CursorHold * silent call CocActionAsync('highlight')
let g:coc_disable_startup_warning = 1

" markdown
let g:vim_markdown_folding_disabled = 1

" lightline
let g:lightline = {
      \ 'separator': { 'left': "\ue0b8", 'right': "\ue0be" },
      \ 'subseparator': { 'left': "\ue0b9", 'right': "\ue0b9" },
      \ 'tabline_separator': { 'left': "\ue0bc", 'right': "\ue0ba" },
      \ 'tabline_subseparator': { 'left': "\ue0bb", 'right': "\ue0bb" },
      \ 'colorscheme': 'gruvbox',
      \ 'inactive': {'left': [[]] },
      \ 'active': {
      \   'left': [ [ 'mode', 'paste' ],
      \             [ 'gitbranch', 'readonly', 'filename', 'modified' ] ]
      \ },
      \ 'component_function': {
      \   'gitbranch': 'FugitiveHead',
      \   'filename': 'FilenameForLightline'
      \ }
      \ }

function! FilenameForLightline()
    return expand('%')
endfunction

let g:vim_tags_auto_generate = 1
let g:vim_tags_project_tags_command = "ctags --exclude=vendor -f .tags -R . 2>/dev/null"
let g:vim_tags_gems_tags_command = "ctags -R -f .Gemfile.lock.tags `bundle show --paths` 2>/dev/null"
let g:vim_tags_use_vim_dispatch = 1
autocmd filetype ruby nnoremap <C-]> g<C-]>

"-----------------
" general
"-----------------
if executable('asdf')
  if executable('python3')
    let g:python3_host_prog = expand('~/.asdf/shims/python3')
  endif
endif

syntax enable

set sh=zsh
set completeopt=menuone
set encoding=utf-8
set nobackup
set modeline
set fileencoding=utf-8
set fileencodings=ucs-boms,utf-8,euc-jp,cp932
set fileformats=unix,dos,mac
set expandtab " change tab to space
set tabstop=4
set softtabstop=4
set autoindent
set smartindent
set shiftwidth=4
set autowrite
filetype plugin indent on
set backspace=indent,eol,start
set whichwrap=b,s,h,l,<,>,[,],~
set showmatch
set wildmenu
set visualbell
set nocursorline
autocmd InsertEnter,InsertLeave * set cursorline! "  cursorline highlight only insert mode
set hlsearch
set ruler
set noswapfile
set hidden
set title
set wildmenu wildmode=list:full
set ignorecase
set incsearch
set splitright
set confirm
nnoremap n nzz
nnoremap N Nzz
nnoremap * *zz
nnoremap # #zz
nnoremap g* g*zz
nnoremap g# g#zz
noremap <Space>w :w<Space>!<Space>sudo<Space>tee<Space>><Space>/dev/null<Space>%
set number
set history=700
set showcmd
set clipboard=unnamed
set lazyredraw
set ttyfast
set wrapscan
set shortmess+=I
set tags+=.tags
set tags+=.Gemfile.lock.tags
vnoremap v $h " select endline by vv
" changelog
let g:changelog_timeformat="%Y-%m-%d"
let g:changelog_username="dais0n<t.omura8383@gmail.com>"

" turn terminal to normal mode with escape
set splitbelow
tnoremap <Esc> <C-\><C-n>
" open terminal on ctrl+x
function! OpenTerminal()
  split term://zsh
  resize 15
endfunction
nnoremap <c-x> :call OpenTerminal()<CR>

"-----------------
" color
"-----------------
try
    colorscheme gruvbox
catch
endtry
highlight clear SignColumn
set t_Co=256
highlight Normal ctermbg=none

"-----------------
" user cmd
"-----------------
command DelBrankLine v/./d
command DelMathcLine g//d
command ExecReplaceFiles argdo %s///g | update
aug QFClose
  au!
  au WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&buftype") == "quickfix"|q|endif
aug END

" open file in cursor position which I opened file before
autocmd BufReadPost *
            \ if line("'\"") > 0 && line ("'\"") <= line("$") |
            \   exe "normal! g'\"" |
            \ endif

" tmuxline.vim
let g:tmuxline_preset = {
      \'a'    : '#S',
      \'b'    : '%R',
      \'c'    : [ '#{sysstat_mem} #[fg=blue]#{sysstat_ntemp}' ],
      \'win'  : [ '#I', '#W' ],
      \'cwin' : [ '#I', '#W', '#F' ],
      \'x'    : [ "#[fg=blue]#{sysstat_itemp} #{sysstat_cpu}" ],
      \'y'    : [ '#(TZ=UTC-9 date "+%Y-%m-%d %H:%M:%S")' ],
      \'z'    : '#H #{prefix_highlight}'
      \}
let g:tmuxline_separators = {
      \ 'left' : "\ue0bc",
      \ 'left_alt': "\ue0bd",
      \ 'right' : "\ue0ba",
      \ 'right_alt' : "\ue0bd",
      \ 'space' : ' '}

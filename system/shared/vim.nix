{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    ((vim-full.override { }).customize {
      name = "myvim";
      vimrcConfig = {
        beforePlugins = # vim
          ''
            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""" 
            "               
            "               ██╗   ██╗██╗███╗   ███╗██████╗  ██████╗
            "               ██║   ██║██║████╗ ████║██╔══██╗██╔════╝
            "               ██║   ██║██║██╔████╔██║██████╔╝██║     
            "               ╚██╗ ██╔╝██║██║╚██╔╝██║██╔══██╗██║     
            "                ╚████╔╝ ██║██║ ╚═╝ ██║██║  ██║╚██████╗
            "                 ╚═══╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝
            "               
            """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""  

            set rtp+=/usr/local/opt/fzf

            " Force vim to use true color when run within tmux
            let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
            let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"

            " Enable true color outside tmux
            set termguicolors

            " In case this config file is loaded some other way 
            " (e.g. saved as `foo`, and then Vim started with `vim -u foo`).
            set nocompatible

            " Customise location of viminfo file
            if !has('nvim') | set viminfo+=n~/.vim/viminfo | endif

            " Disable the default Vim startup message.
            set shortmess+=I

            " Synchronise unnamed register with OS clipboard
            set clipboard+=unnamed

            " Show relative line numbers except for current line
            set number
            set relativenumber

            " Enable type file detection. Vim will be able to try to detect the type of file in use.
            filetype on

            " Enable plugins and load plugin for the detected file type.
            filetype plugin on

            " Load an indent file for the detected file type.
            filetype indent on

            " Turn syntax highlighting on.
            syntax on

            " Set dark mode
            set background=dark

            " Highlight cursor line underneath the cursor horizontally.
            set cursorline

            " Highlight cursor line underneath the cursor vertically.
            " set cursorcolumn

            " Set shift width to 4 spaces.
            set shiftwidth=4

            " Set tab width to 4 columns.
            set tabstop=4

            " Use space characters instead of tabs.
            set expandtab

            " Do not save backup files.
            set nobackup

            " Do not let cursor scroll below or above N number of lines when scrolling.
            set scrolloff=10

            " Do not wrap lines. Allow long lines to extend as far as the line goes.
            set nowrap

            " While searching though a file incrementally highlight matching characters as you type.
            set incsearch

            " Ignore capital letters during search.
            set ignorecase

            " Override the ignorecase option if searching for capital letters.
            " This will allow you to search specifically for capital letters.
            set smartcase

            " Show partial command you type in the last line of the screen.
            set showcmd

            " Show the mode you are on the last line.
            set showmode

            " Show matching words during a search.
            set showmatch

            " Use highlighting when doing a search.
            set hlsearch

            " Set the commands to save in history default number is 20.
            set history=1000

            " Enable auto completion menu after pressing TAB.
            set wildmenu

            " Make wildmenu behave like similar to Bash completion.
            set wildmode=list:longest

            " There are certain files that we would never want to edit with Vim.
            " Wildmenu will ignore files with these extensions.
            set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

            " The backspace key has slightly unintuitive behavior by default. For example,
            " by default, you can't backspace before the insertion point set with 'i'.
            " This configuration makes backspace behave more reasonably, in that you can
            " backspace over anything.
            set backspace=indent,eol,start

            " Disable audible bell because it's annoying.
            set noerrorbells visualbell t_vb=

            " Enable mouse support. You should avoid relying on this too much, but it can
            " sometimes be convenient.
            set mouse+=a

            " By default, Vim doesn't let you hide a buffer (i.e. have a buffer that isn't
            " shown in any window) that has unsaved changes. This is to prevent you from "
            " forgetting about unsaved changes and then quitting e.g. via `:qa!`. We find
            " hidden buffers helpful enough to disable this protection. See `:help hidden`
            " for more information on this.
            set hidden
          '';
        plug.plugins = with pkgs.vimPlugins; [
          # loaded on launch
          asyncomplete-vim
          asyncomplete-lsp-vim
          fzf
          fzfWrapper
          fzf-vim
          molokai
          nerdtree
          vim-airline
          vim-commentary
          vim-sensible
          vim-lsp
          vim-lsp-settings
          # this plugin does not work
          # vim-maximizer
        ];
        # To automatically load a plugin when opening a filetype, add vimrc lines like:
        # autocmd FileType php :packadd phpCompletion
        customRC = # vim
          ''
            "--------BUILTIN PLUGINS

            " manpage viewer: See :help Man
            runtime ftplugin/man.vim
            " Use <SHIFT>-K without <leader> to open keyword in man within vim
            set keywordprg=:Man

            " Mappings code goes here.

            " Unbind some useless/annoying default key bindings.
            nmap Q <Nop> " 'Q' in normal mode enters Ex mode. You almost never want this.

            " Try to prevent bad habits like using the arrow keys for movement. This is
            " not the only possible bad habit. For example, holding down the h/j/k/l keys
            " for movement, rather than using more efficient movement commands, is also a
            " bad habit. The former is enforceable through a .vimrc, while we don't know
            " how to prevent the latter.
            " Do this in normal mode...
            nnoremap <Left>  :echoe "Use h"<CR>
            nnoremap <Right> :echoe "Use l"<CR>
            nnoremap <Up>    :echoe "Use k"<CR>
            nnoremap <Down>  :echoe "Use j"<CR>
            " ...and in insert mode
            inoremap <Left>  <ESC>:echoe "Use h"<CR>
            inoremap <Right> <ESC>:echoe "Use l"<CR>
            inoremap <Up>    <ESC>:echoe "Use k"<CR>
            inoremap <Down>  <ESC>:echoe "Use j"<CR>

            " Set the backslash as the official leader key and map space to it 
            " (so space key will show up as \ in status bar).
            let mapleader = "\\"
            map <space> <leader>

            " Press <leader>\ to jump back to the last cursor position.
            nnoremap <leader>\ ``

            " Press <leader>p to print the current file to the default printer from a Linux/Mac operating system.
            " View available printers:   lpstat -v
            " Set default printer:       lpoptions -d <printer_name>
            " <silent> means do not display output.
            nnoremap <silent> <leader>p :%w !lp<CR>

            " Press return to type the : character in command mode.
            " nnoremap <CR> :
            " vnoremap <CR> :

            nnoremap ; :
            vnoremap ; :

            nnoremap <leader>; ;
            vnoremap <leader>; ;

            " Pressing the letter o will open a new line below the current one.
            " Exit insert mode after creating a new line above or below the current line.
            nnoremap o o<esc>
            nnoremap O O<esc>

            " Center the cursor vertically and automatically open folds
            " when moving to the next word during a search.
            nnoremap n nzzzv
            nnoremap N Nzzzv

            " Yank from cursor to the end of line.
            nnoremap Y y$

            " Map the F5 key to run a Python script inside Vim.
            " I map F5 to a chain of commands here.
            " :w saves the file.
            " <CR> (carriage return) is like pressing the enter key.
            " !clear runs the external clear screen command.
            " !python3 % executes the current file with Python.
            nnoremap <f5> :w <CR>:!clear <CR>:!python3 % <CR>

            " You can split the window in Vim by typing :split or :vsplit.
            " Navigate the split view easier by pressing CTRL+j, CTRL+k, CTRL+h, or CTRL+l.
            nnoremap <c-j> <c-w>j
            nnoremap <c-k> <c-w>k
            nnoremap <c-h> <c-w>h
            nnoremap <c-l> <c-w>l

            " Resize split windows using arrow keys by pressing:
            " CTRL+UP, CTRL+DOWN, CTRL+LEFT, or CTRL+RIGHT.
            noremap <c-up> <c-w>+
            noremap <c-down> <c-w>-
            noremap <c-left> <c-w>>
            noremap <c-right> <c-w><

            " Source Vim configuration file and install plugins
            nnoremap <silent><leader>1 :source ~/.vim/vimrc \| :PlugInstall<CR>

            " ------------------ Plugin Specific Mappings ------------------------

            " NERDTree specific mappings.
            " Map the <C-t> to toggle NERDTree open and close.
            nnoremap <C-t> :NERDTreeToggle<cr>

            " Have nerdtree ignore certain files and directories.
            let NERDTreeIgnore=['\.git$', '\.jpg$', '\.mp4$', '\.ogg$', '\.iso$', '\.pdf$', '\.pyc$', '\.odt$', '\.png$', '\.gif$', '\.db$']

            let NERDTreeShowHidden=1

            " Commentary Plugin specific mappings
            " Toggle comments with <leader> + /
            noremap <leader>/ :Commentary<cr>

            " More Vimscripts code goes here.

            " If the current file type is HTML, set indentation to 2 spaces.
            autocmd Filetype html setlocal tabstop=2 shiftwidth=2 expandtab

            " If Vim version is equal to or greater than 7.3 enable undofile.
            " This allows you to undo changes to a file even after saving it.
            if version >= 703
            set undodir=~/.vim/backup
            set undofile
            set undoreload=10000
            endif

            " You can split a window into sections by typing `:split` or `:vsplit`.
            " Display cursorline and cursorcolumn ONLY in active window.
            augroup cursor_off
            autocmd!
            autocmd WinLeave * set nocursorline nocursorcolumn
            autocmd WinEnter * set cursorline 
            augroup END

            " If GUI version of Vim is running set these options.
            if has('gui_running')

            " Set the background tone.
            set background=dark

            " Set the color scheme.
            colorscheme molokai

            " Set a custom font you have installed on your computer.
            " Syntax: set guifont=<font_name>\ <font_weight>\ <size>
            set guifont=Monospace\ Regular\ 12

                " Display more of the file by default.
            " Hide the toolbar.
            set guioptions-=T

            " Hide the the left-side scroll bar.
            set guioptions-=L

            " Hide the the right-side scroll bar.
            set guioptions-=r

            " Hide the the menu bar.
            set guioptions-=m

            " Hide the the bottom scroll bar.
            set guioptions-=b

            " Map the F4 key to toggle the menu, toolbar, and scroll bar.
            " <Bar> is the pipe character.
            " <CR> is the enter key.
            nnoremap <F4> :if &guioptions=~#'mTr'<Bar>
            \set guioptions-=mTr<Bar>
            \else<Bar>
            \set guioptions+=mTr<Bar>
            \endif<CR>

            endif

            "-------------- Enable vim-lsp functionality ----------------
            function! s:on_lsp_buffer_enabled() abort
            setlocal omnifunc=lsp#complete
            setlocal signcolumn=yes
            if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
            nmap <buffer> gd <plug>(lsp-definition)
            nmap <buffer> gs <plug>(lsp-document-symbol-search)
            nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
            nmap <buffer> gr <plug>(lsp-references)
            nmap <buffer> gi <plug>(lsp-implementation)
            nmap<buffer> gt <plug>(lsp-type-definition)
            nmap <buffer> <leader>rn <plug>(lsp-rename)
            nmap <buffer> [g <plug>(lsp-previous-diagnostic)
            nmap <buffer> ]g <plug>(lsp-next-diagnostic)
            nmap <buffer> K <plug>(lsp-hover)
            nmap <expr><buffer> <c-d> popup_list()->empty() ? '<c-d>' : lsp#scroll(+4)
            nmap <expr><buffer> <c-u> popup_list()->empty() ? '<c-u>' : lsp#scroll(-4)
            " Replaced by the two above which do not overwrite normal functionality
            " See https://github.com/prabirshrestha/vim-lsp/issues/1522 
            " nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
            " nnoremap <buffer> <expr><c-d> lsp#scroll(-4)

            let g:lsp_format_sync_timeout = 1000
            autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')

            " refer to doc to add more commands
            endfunction

            augroup lsp_install
            au!
            " call s:on_lsp_buffer_enabled only for languages that have the server registered.
            autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
            augroup END

            " open terminal in a split using 'T'
            command! -nargs=* T split | terminal <args> 

            " Status line block currently disabled to test airline plugin defaults 
            " STATUS LINE ------------------------------------------------------------ 

            " Status bar code goes here.
            " Clear status line when vimrc is reloaded.
            " set statusline=

            " Status line left side.
            " set statusline+=\ %F\ %M\ %Y\ %R

            " Use a divider to separate the left side from the right side.
            " set statusline+=%=

            " Status line right side.
            " set statusline+=\ ascii:\ %b\ hex:\ 0x%B\ row:\ %l\ col:\ %c\ percent:\ %p%%

            " Show the status on the second to last line.
            " set laststatus=2
          '';
      };
    })
  ];
}

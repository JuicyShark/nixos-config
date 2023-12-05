{ pkgs, config, ... }:

let
  vim-nix-rummik = with pkgs.vimUtils; buildVimPlugin {
    pname = "vim-nix";
    version = "0def8020f152a51c011a707680780dac61a8989a";

    src = pkgs.fetchFromGitHub {
      owner = "rummik";
      repo = "vim-nix";
      rev = "0def8020f152a51c011a707680780dac61a8989a";
      hash = "sha256-Q+Jx6/MgeE2hsd/a6FqfXpAOaRcNymZW6t75hYCcH4E=";
    };
  };
in
{
  programs.bat.enable = true;

  home.packages = with pkgs; [
    # c
    gcc
    clang-tools
    pkg-config
    gnumake
    cmake

    # go
    go
    gopls

    # nix
    nil
    alejandra
    nixpkgs-fmt
    nixfmt

    # crystal
    crystal
    shards

    # node/yarn/deno/bun
    nodejs
    nodePackages.npm
    yarn
    deno
    bun
    biome
    nodePackages.typescript-language-server
    nodePackages."@astrojs/language-server"
    nodePackages."@prisma/language-server"
    nodePackages.pnpm
    tailwindcss-language-server

    # rust
    rustc
    rustfmt
    cargo
    cargo-info
    cargo-audit
    cargo-license
    cargo-feature
    rust-analyzer
    bacon
    clippy

    # markdown
    marksman

    # lua
    lua-language-server

    # tex/typst
    texlive.combined.scheme-full
    texlab
    typst
    typstfmt
    typst-lsp
    typst-live

    # ctags
    universal-ctags

    # emmet
    emmet-language-server
  ];

  editorconfig = {
    enable = true;

    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        insert_final_newline = true;
        indent_size = 2;
        indent_style = "space";
        trim_trailing_whitespace = false;
      };

      "Makefile" = {
        indent_style = "tab";
        indent_size = 4;
      };

      "*.html" = {
        indent_style = "tab";
        indent_size = 4;
      };

      "*.go" = {
        indent_style = "tab";
        indent_size = 4;
      };

      "*.rs" = {
        indent_style = "space";
        indent_size = 4;
      };
    };
  };

  programs.neovim = {
    enable = true;
    extraConfig = /* vim */ ''
      filetype plugin indent on
      set undofile
      set spell
      set number
      set linebreak
      set clipboard=unnamedplus
      set fileencoding=utf-8         " Ensure that we always save files as utf-8
      set fileencodings=utf-8,sjis   " Automatically open shiftjis files with their proper encoding
      set spelllang=en_us,cjk        " Don't show errors for CJK characters
      set noshowmode                 " Disable the --MODE-- text (enable if not using the status line)
      set mouse=a
      set ignorecase                 " By default use case-insensitive search (combine with smartcase)
      set smartcase                  " Make search case-sensitive when using capital letters
      set scrolloff=1                " The minimal number of rows to show when scrolling up/down
      set sidescrolloff=5            " The minimal number of columns to show when scrolling left/right
      set tabstop=4                  " Show a tab character as 4 spaces
      set softtabstop=0              " Edit soft tabs as if they're regular spaces
      set shiftwidth=4               " Make autoindent appear as 4 spaces

      set foldmethod=indent
      set foldlevelstart=99

      map <MiddleMouse> <Nop>
      imap <MiddleMouse> <Nop>
      map <2-MiddleMouse> <Nop>
      imap <2-MiddleMouse> <Nop>
      map <3-MiddleMouse> <Nop>
      imap <3-MiddleMouse> <Nop>
      map <4-MiddleMouse> <Nop>
      imap <4-MiddleMouse> <Nop>

      highlight Search ctermbg=240 ctermfg=255
      highlight IncSearch ctermbg=255 ctermfg=240

      let mapleader = ' '
      nnoremap <silent> <leader>e :set nu!<CR>
      nnoremap <silent> <leader>t :OverCommandLine<CR>%s/
      nnoremap <silent> <leader>o :GitBlameToggle<CR>
      nnoremap <silent> <leader>a <C-w>w
      nnoremap <silent> <leader>s :Alpha<CR>
      nnoremap <silent> <leader>d :Bdelete<CR>
      nnoremap <silent> <leader>f :Files<CR>
      nnoremap <silent> <leader>g :set hlsearch!<CR>
      nnoremap <silent> <leader>j :Buffers<CR>
      nnoremap <silent> <leader>l :Rg<CR>
      nnoremap <silent> <leader>; :NvimTreeToggle<CR>
      nnoremap <silent> <leader>z :ZenMode<CR>
      nnoremap <silent> <leader>b :TagbarToggle<CR>
      vnoremap <C-s> y:silent !notify-send -t 4000 "成果" "$(tango '<C-r>0')"<CR>:<Esc>

      autocmd BufNewFile,BufRead *.ecr    setlocal syntax=html
      autocmd BufWritePre,FileWritePre * silent! call mkdir(expand('<afile>:p:h'), 'p')
      autocmd VimEnter * silent! :cd `git rev-parse --show-toplevel`

      tnoremap <C-space> <C-\><C-n>

      autocmd BufNewFile,BufRead *.mdx set filetype=markdown
    '';

    plugins = with pkgs.vimPlugins; [
      {
        plugin = nvim-tree-lua;
        type = "lua";
        config = /* lua */ ''
          require("nvim-tree").setup()

          vim.api.nvim_create_autocmd({"QuitPre"}, {
              callback = function() vim.cmd("NvimTreeClose") end
          })

          local function open_nvim_tree(data)
            local real_file = vim.fn.filereadable(data.file) == 1
            local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

            if not real_file and not no_name then
              return
            end

            require("nvim-tree.api").tree.toggle({ focus = false, find_file = true })
          end

          vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
        '';
      }
      {
        plugin = indent-blankline-nvim;
        type = "lua";
        config = /* lua */ ''
          require("ibl").setup()
        '';
      }
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = /* lua */ ''
          require('gitsigns').setup()
        '';
      }
      {
        plugin = nvim-web-devicons;
        type = "lua";
      }
      {
        plugin = nvim-scrollbar;
        type = "lua";
        config = /* lua */ ''require("scrollbar").setup()'';
      }
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = /* lua */ ''
          local lspconfig = require('lspconfig')
          local capabilities = require("cmp_nvim_lsp").default_capabilities()
          lspconfig.denols.setup {
            capabilities = capabilities,
            root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
          }
          lspconfig.tsserver.setup {
            capabilities = capabilities,
            root_dir = lspconfig.util.root_pattern("package.json"),
            single_file_support = false
          }
          lspconfig.typst_lsp.setup {
            capabilities = capabilities,
            settings = {
              exportPdf = "onSave"
            }
          }
          vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
          vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)
          vim.api.nvim_create_autocmd('LspAttach', {
            group = vim.api.nvim_create_augroup('UserLspConfig', {}),
            callback = function(ev)
              local opts = { buffer = ev.buf }
              vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
              vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
              vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
              vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
              vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
              vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
              vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
              vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
              vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            end,
          })
        '';
      }
      {
        plugin = nvim-cmp;
        type = "lua";
        config = /* lua */ ''
          -- Add additional capabilities supported by nvim-cmp
          local capabilities = require("cmp_nvim_lsp").default_capabilities()

          local lspconfig = require('lspconfig')

          -- Enable some language servers with the additional completion capabilities offered by nvim-cmp
          local servers = {
            'nil_ls',
            'rust_analyzer',
            'marksman',
            'gopls',
            'lua_ls',
            'clangd',
            'texlab',
            'crystalline',
            'prismals',
            'tailwindcss',
            'emmet_language_server',
            'astro',
          }

          for _, lsp in ipairs(servers) do
            lspconfig[lsp].setup {
              -- on_attach = my_custom_on_attach,
              capabilities = capabilities,
            }
          end

          -- luasnip setup
          local luasnip = require 'luasnip'

          -- nvim-cmp setup
          local cmp = require 'cmp'
          cmp.setup {
            snippet = {
              expand = function(args)
                luasnip.lsp_expand(args.body)
              end,
            },
            mapping = cmp.mapping.preset.insert({
              ['<C-u>'] = cmp.mapping.scroll_docs(-4), -- Up
              ['<C-d>'] = cmp.mapping.scroll_docs(4), -- Down
              -- C-b (back) C-f (forward) for snippet placeholder navigation.
              ['<C-Space>'] = cmp.mapping.complete(),
              ['<CR>'] = cmp.mapping.confirm {
                behavior = cmp.ConfirmBehavior.Replace,
                select = true,
              },
              ['<Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                else
                  fallback()
                end
              end, { 'i', 's' }),
              ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end, { 'i', 's' }),
            }),
            sources = {
              { name = 'nvim_lsp' },
              { name = 'luasnip' },
            },
          }
        '';
      }
      cmp-nvim-lsp
      cmp_luasnip
      {
        plugin = luasnip;
        type = "lua";
        config = /* lua */ ''
          require("luasnip.loaders.from_vscode").lazy_load()
        '';
      }
      friendly-snippets
      {
        plugin = nvim-base16;
        type = "lua";
        config = "vim.cmd('colorscheme base16-${config.lib.stylix.scheme.slug}')";
      }
      {
        plugin = lualine-nvim;
        type = "lua";
        config = /* lua */ ''
          local theme = require("lualine.themes.base16")
          theme.normal.b.bg = nil
          theme.normal.c.bg = nil
          theme.replace.b.bg = nil
          theme.insert.b.bg = nil
          theme.visual.b.bg = nil
          theme.inactive.a.bg = nil
          theme.inactive.b.bg = nil
          theme.inactive.c.bg = nil

          require('lualine').setup {
            options = {
              theme = theme,
              disabled_filetypes = {'NvimTree', 'tagbar'}
            },
            sections = { lualine_c = {'%f'} }
          }
        '';
      }
      {
        plugin = image-nvim;
        type = "lua";
        config = /* lua */ ''
          require("image").setup({
            backend = "kitty",
            integrations = {
              markdown = {
                enabled = true,
                sizing_strategy = "auto",
                download_remote_images = false,
                clear_in_insert_mode = true,
              },
              neorg = {
                enabled = false,
              },
            },
            max_width = 600,
            max_height = 400,
            max_width_window_percentage = 40,
            max_height_window_percentage = 50,
            kitty_method = "normal",
            kitty_tmux_write_delay = 10,
            window_overlap_clear_enabled = false,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
          })
        '';
      }
      {
        plugin = git-blame-nvim;
        type = "lua";
      }
      {
        plugin = comment-nvim;
        type = "lua";
        config = ''require('Comment').setup()'';
      }
      {
        plugin = zen-mode-nvim;
        type = "lua";
        config = /* lua */ ''
          require("zen-mode").setup({
            window = {
              backdrop = 1,
              width = 80,
              height = 0.9,
              options = {
                signcolumn = "no",
                number = false,
              },
            },
            on_open = function(win)
              vim.cmd("ScrollbarHide")
            end,
            on_close = function()
              vim.cmd("ScrollbarShow")
            end,
          })
        '';
      }
      {
        plugin = plenary-nvim;
        type = "lua";
      }
      {
        plugin = nvim-autopairs;
        type = "lua";
        config = ''require("nvim-autopairs").setup {}'';
      }
      {
        plugin = clipboard-image-nvim;
        type = "lua";
        config = /* lua */ ''
          require("clipboard-image").setup {
            default = {
              img_dir = {"%:p:h", "_"},
              img_dir_txt = "_",
            }
          }
        '';
      }
      {
        plugin = auto-save-nvim;
        type = "lua";
        config = ''require("auto-save").setup()'';
      }
      {
        plugin = toggleterm-nvim;
        type = "lua";
        config = /* lua */ ''
          require("toggleterm").setup {
            shade_terminals = false
          }
        '';
      }
      {
        plugin = vimtex;
        config = /* vim */ ''
          let g:vimtex_mappings_enabled = 0
          let g:vimtex_imaps_enabled = 0
          let g:vimtex_view_method = 'zathura'
          let g:vimtex_compiler_latexmk = {'build_dir': '.tex'}

          nnoremap <localleader>f <plug>(vimtex-view)
          nnoremap <localleader>g <plug>(vimtex-compile)
          nnoremap <localleader>d <plug>(vimtex-env-delete)
          nnoremap <localleader>c <plug>(vimtex-env-change)
        '';
      }
      {
        plugin = vim-markdown;
        config = /* vim */ ''
          let g:vim_markdown_folding_disabled = 1
          let g:vim_markdown_conceal = 0
          let g:vim_markdown_frontmatter = 1
          let g:vim_markdown_toml_frontmatter = 1
          let g:vim_markdown_json_frontmatter = 1
        '';
      }
      {
        plugin = alpha-nvim;
        type = "lua";
        config = /* lua */ ''
          local startify = require('alpha.themes.startify')

          startify.section.header.val = vim.fn.system("${pkgs.fish}/bin/fish -c 'cat (random choice (${pkgs.fd}/bin/fd . ${pkgs.ponysay}/share/ponysay/quotes --ignore-file ~/.config/fd/ponyignore)) | head -n 1'")

          startify.section.top_buttons.val = {
              startify.button("e", "新しいファイル", "<cmd>ene <CR>")
          }

          startify.section.mru.val = { { type = "padding", val = 0 } }
          startify.section.mru_cwd.val = {
            { type = "padding", val = 1 },
            { type = "text", val = "歴史", opts = { hl = "SpecialComment", shrink_margin = false } },
            { type = "padding", val = 1 },
            {
                type = "group",
                val = function()
                    return { startify.mru(0, vim.fn.getcwd()) }
                end,
                opts = { shrink_margin = false },
            }
          }

          require('alpha').setup(startify.config)
        '';
      }
      {
        plugin = nvim-ts-autotag;
        type = "lua";
        config = /* lua */ ''
          require('nvim-ts-autotag').setup()
        '';
      }
      fzf-vim
      vim-caddyfile
      vim-graphql
      vim-pug
      vim-prisma
      vim-javascript
      vim-jsx-pretty
      vim-vue
      vim-over
      vim-endwise
      csv-vim
      rust-vim
      yuck-vim
      neoformat
      bufdelete-nvim
      vim-crystal
      vim-nix-rummik
      fcitx-vim
      vim-astro
      vim-svelte
      typst-vim
      emmet-vim
      nvim-treesitter.withAllGrammars
      tagbar
    ];
  };

  xdg.configFile."fd/ponyignore".text = ''
    snowflake+horsepower+bulkbiceps.1
    snowflake+horsepower+bulkbiceps.2
  '';
}

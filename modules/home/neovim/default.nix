{
  lib,
  osConfig,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./options.nix
    ./plugins.nix
    ./keymaps.nix
    ./lua.nix
  ];

  home.file."documents/notes/pages/neovim-ide-cheatsheet.norg".text = ''
    @document.meta
    title: Neovim IDE Cheatsheet
    created: 2026-07-16
    categories: [neovim, ide, reference]
    @end

    * Neovim IDE Cheatsheet

    ** Code Intelligence
    - `k` / `K` :: Show hover docs for the symbol under the cursor.
    - `gd` :: Jump to definition.
    - `gD` :: List references.
    - `gt` :: Jump to type definition.
    - `gi` :: Jump to implementation.
    - `<F2>` :: Rename symbol across the project.
    - `<leader>ca` :: Code actions, quick fixes, imports, and refactors.
    - `<leader>cf` :: Format the current buffer.
    - `<leader>cr` :: Rename symbol across the project.
    - `<leader>ch` :: Show native LSP health and attached clients.
    - `<leader>co` :: Activate embedded Lua LSP for Lua inside Nix strings.
    - `<leader>cd` :: Pick definitions.
    - `<leader>ct` :: Pick type definitions.
    - `<leader>ci` :: Pick implementations.
    - `<leader>cD` :: Pick references.
    - `<leader>cs` :: Pick document symbols.
    - `<leader>cS` :: Pick workspace symbols.

    ** Rust
    - `<leader>mr` :: Pick Rust runnables.
    - `<leader>mR` :: Run the Rust target under the cursor.
    - `<leader>mt` :: Pick Rust tests.
    - `<leader>md` :: Pick Rust debuggables.
    - `<leader>mD` :: Debug the Rust target under the cursor.
    - `<leader>me` :: Explain the current Rust error.
    - `<leader>ml` :: Show the rendered Rust diagnostic.
    - `<leader>mm` :: Expand the Rust macro under the cursor.
    - `<leader>mc` :: Open the package Cargo.toml.
    - `<leader>mp` :: Open the parent module.
    - `<leader>ma` :: Rust grouped code action.
    - `<leader>mj` :: Rust join lines.

    ** Diagnostics
    - `<leader>xx` :: Workspace diagnostics.
    - `<leader>xX` :: Buffer diagnostics.
    - `<leader>xd` :: Diagnostics picker.
    - `<leader>xq` :: Quickfix list.
    - `<leader>xl` :: Location list.
    - `gl` :: Show diagnostics for the current line.
    - `[d` / `]d` :: Previous or next diagnostic.
    - `<leader>td` :: Toggle diagnostics.
    - Current-line diagnostics :: Render as native virtual lines without a popup autocmd.

    ** Search And Project Work
    - `<leader>ff` :: Find files.
    - `<leader>fg` :: Live grep.
    - `<leader>fb` :: Find buffers alias.
    - `<leader>fr` :: Recent files.
    - `<leader>fw` :: Search word under cursor.
    - `<leader>fR` :: Resume last picker.
    - `<leader>bb` :: Switch buffers.
    - `<leader>bd` :: Delete the current buffer.
    - `<leader>bo` :: Close other buffers.
    - `<leader>bn` / `<leader>bp` :: Next or previous buffer.
    - `<leader>pf` :: Project files.
    - `<leader>ps` :: Project search.
    - `<leader>pb` :: Project buffers.
    - `<leader>pt` :: Project tree.
    - `<leader>gd` :: Git diff view.

    ** Notes And Journal
    - Notes root :: `~/documents/notes`.
    - `<leader>nn` :: Find note.
    - `<leader>nc` :: Capture note.
    - `<leader>nI` :: Capture a task directly into the inbox.
    - `<leader>nd` / `<leader>nj` :: Open today's native Neorg journal.
    - `<leader>n[` / `<leader>n]` :: Open yesterday's or tomorrow's journal.
    - `<leader>ns` :: Search notes.
    - `<leader>nb` :: Backlinks.
    - `<leader>ni` :: Insert node.
    - `<leader>na` :: Scan task and date markers across notes.
    - `<leader>nt…` :: Change the task state in a `.norg` buffer.
    - `<leader>nJ` :: Open the journal table of contents.
    - `<leader>nX` :: Tangle the current `.norg` file.

    ** Run And Debug
    - `<leader>rr` / `<F6>` :: Pick and run an Overseer task.
    - `<leader>rl` :: Restart the most recent task.
    - `<leader>rt` :: Toggle the task list.
    - `<leader>ra` :: Act on a task.
    - `<leader>rs` :: Run a shell command as a tracked task.
    - `<F5>` :: Start or continue debugging.
    - `<F10>` / `<F11>` / `<S-F11>` :: Step over, into, or out.
    - The DAP UI opens and closes with the debug session.

    ** Neovim Concepts
    - buffer :: An opened file or scratch text object.
    - window :: A viewport onto a buffer.
    - tabpage :: A layout containing one or more windows.
    - quickfix list :: Project-wide list of locations from searches, builds, or diagnostics.
    - location list :: Window-local list of locations.
    - LSP client :: Neovim's connection to a language server for definitions, hover docs, diagnostics, and refactors.
    - treesitter :: Parser-backed syntax tree used for highlighting, text objects, folding, and structural selection.
    - filetype :: Buffer language mode that decides syntax, LSP attachment, indentation, and plugins.
    - normal mode :: Command mode for edits and actions.
    - insert mode :: Text entry mode.
    - visual mode :: Selection mode for operating on selected text.
    - command-line mode :: `:` commands, search prompts, and ex commands.
    - operator :: An action waiting for a text object or motion, such as delete, change, or format.
    - text object :: A semantic range such as a function, argument, string, paragraph, or block.
    - register :: Clipboard-like storage used by yank, delete, paste, and macros.
    - mark :: Named location inside a file or across files.
    - jumplist :: History of larger jumps such as definitions and searches.
    - undo tree :: Branching edit history for the buffer.

    ** Navigation Bias
    - Keep everyday file movement in buffers, recent files, project files, and project search.
    - Use tabpages only for temporary alternate window layouts; they are not shown as a clickable file list.

    ** When Hover Is Empty
    - Run `<leader>ch` and confirm an LSP client is attached.
    - Check that the language server is installed and the filetype is correct.
    - Some servers provide definitions and diagnostics but little hover text.
  '';

  programs.nixvim = {
    enable = true;
    nixpkgs.source = pkgs.path;
    defaultEditor =
      lib.mkIf (
        !(osConfig.modules.desktop.enable or false) && !(osConfig.modules.emacs.enable or false)
      )
      true;
    vimdiffAlias = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    # Inject the language named in a /* lang */ comment into the string that
    # immediately follows it. Lets `/* lua */ ''...''` highlight as Lua inside
    # .nix files (e.g. modules/home/hyprland/lua.nix).
    extraFiles."after/queries/nix/injections.scm".text = ''
      ;; extends

      ((comment) @injection.language
        .
        [
          (string_expression (string_fragment) @injection.content)
          (indented_string_expression (string_fragment) @injection.content)
        ]
        (#gsub! @injection.language "/%*%s*([%w%p]+)%s*%*/" "%1")
        (#set! injection.combined))
    '';
    globals.mapleader = " ";
    extraPackages = with pkgs; [
      shellcheck
      shfmt

      prettierd
      alejandra
      stylua

      # Toolchains and utilities not owned by an enabled NixVim server.
      go
      gotools

      # C / C++ — clangd + clang-format + build tools for Overseer tasks.
      cppcheck
      gcc
      gnumake
      cmake

      # Rust formatter; rustaceanvim drives rust-analyzer.
      rustfmt
      cargo-nextest

      # Godot/GDScript linting and formatting. The gdscript LSP itself is
      # provided by a running Godot editor instance.
      gdtoolkit_4

      # Nix linters matched to the repo's devShell
      statix
      deadnix

      # Binary / low-level exploration used by :Disasm / :Strings / :Hexdump / :NixDrv
      binutils
      file
      jq
      mercurial

      # DAP adapter for c/cpp/rust
      vscode-extensions.vadimcn.vscode-lldb
    ];
  };
}

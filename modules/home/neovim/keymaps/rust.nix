{
  lib,
  pkgs,
  ...
}: {
  programs.nixvim.files."after/ftplugin/rust.lua".keymaps = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (let
    rustMap = key: action: desc: {
      mode = "n";
      inherit key action;
      options = {
        buffer = true;
        silent = true;
        inherit desc;
      };
    };
  in [
    (rustMap "<leader>mr" "<cmd>RustLsp runnables<CR>" "Rust runnables")
    (rustMap "<leader>mR" "<cmd>RustLsp run<CR>" "Rust run target")
    (rustMap "<leader>mt" "<cmd>RustLsp testables<CR>" "Rust tests")
    (rustMap "<leader>md" "<cmd>RustLsp debuggables<CR>" "Rust debuggables")
    (rustMap "<leader>mD" "<cmd>RustLsp debug<CR>" "Rust debug target")
    (rustMap "<leader>me" "<cmd>RustLsp explainError current<CR>" "Rust explain error")
    (rustMap "<leader>ml" "<cmd>RustLsp renderDiagnostic current<CR>" "Rust rendered diagnostic")
    (rustMap "<leader>mm" "<cmd>RustLsp expandMacro<CR>" "Rust expand macro")
    (rustMap "<leader>mc" "<cmd>RustLsp openCargo<CR>" "Rust open Cargo.toml")
    (rustMap "<leader>mp" "<cmd>RustLsp parentModule<CR>" "Rust parent module")
    (rustMap "<leader>ma" "<cmd>RustLsp codeAction<CR>" "Rust code action")
    (rustMap "<leader>mj" "<cmd>RustLsp joinLines<CR>" "Rust join lines")
  ]);
}

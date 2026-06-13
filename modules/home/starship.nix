{lib, ...}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      scan_timeout = 10;
      command_timeout = 800;
      palette = lib.mkForce "nocturne";

      format = ''
        [╭─](fg:surface1 bold)$directory$git_branch$git_status$nix_shell$jobs$cmd_duration$status
        [╰─](fg:surface1 bold)$character
      '';

      right_format = "";

      palettes.nocturne = {
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        mauve = "#cba6f7";
        red = "#f38ba8";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
        text = "#cdd6f4";
        subtext1 = "#bac2de";
        subtext0 = "#a6adc8";
        surface2 = "#585b70";
        surface1 = "#45475a";
        surface0 = "#313244";
        base = "#1e1e2e";
        mantle = "#181825";
        crust = "#11111b";
      };

      fill = {
        symbol = " ";
        style = "surface0";
      };

      os = {
        disabled = true;
        symbols = {
          NixOS = "";
          Macos = "";
          Linux = "";
        };
      };

      username = {
        show_always = true;
        disabled = true;
      };

      hostname = {
        ssh_only = false;
        disabled = true;
      };

      directory = {
        format = "[ $path]($style) ";
        style = "fg:mauve bold";
        truncation_length = 4;
        truncation_symbol = "…/";
        read_only = " 󰌾";
        read_only_style = "fg:red bold";
        home_symbol = "~";
        substitutions = {
          Documents = "󰈙 ";
          Downloads = " ";
          Music = "󰝚 ";
          Pictures = " ";
          Videos = " ";
          Projects = "󰲋 ";
          nixos-config = " cfg";
        };
      };

      git_branch = {
        format = "[on $symbol$branch(:$remote_branch)]($style) ";
        style = "fg:green bold";
        symbol = " ";
      };

      git_status = {
        disabled = false;
        format = "[$all_status$ahead_behind]($style) ";
        style = "fg:peach bold";
        conflicted = "conflict:$count ";
        ahead = "ahead:$count ";
        behind = "behind:$count ";
        diverged = "diverged:$ahead_count/$behind_count ";
        up_to_date = "";
        untracked = "new:$count ";
        stashed = "stash:$count ";
        modified = "mod:$count ";
        staged = "stg:$count ";
        renamed = "ren:$count ";
        deleted = "del:$count ";
      };

      character = {
        format = "$symbol";
        success_symbol = "[❯](fg:green bold) ";
        error_symbol = "[❯](fg:red bold) ";
        vicmd_symbol = "[❮](fg:yellow bold) ";
        disabled = false;
      };

      nix_shell = {
        disabled = false;
        heuristic = false;
        format = "[via $symbol$state]($style) ";
        style = "fg:blue bold";
        symbol = " ";
        impure_msg = "";
        pure_msg = "";
        unknown_msg = "";
      };

      jobs = {
        format = "[jobs:$number]($style) ";
        style = "fg:yellow bold";
        symbol = "󰒋 ";
        number_threshold = 1;
      };

      status = {
        disabled = false;
        format = "[exit $status]($style) ";
        style = "fg:red bold";
        symbol = "󰅙 ";
      };

      time = {
        disabled = true;
        format = "[ $time ]($style)";
        style = "fg:subtext0 bold";
        time_format = "%H:%M";
      };

      aws.disabled = true;
      gcloud.disabled = true;
      nodejs.disabled = true;
      ruby.disabled = true;
      python.disabled = true;
      rust.disabled = true;
      golang.disabled = true;
      java.disabled = true;
      kotlin.disabled = true;
      lua.disabled = true;
      perl.disabled = true;
      php.disabled = true;
      swift.disabled = true;
      terraform.disabled = true;
      zig.disabled = true;
      package.disabled = true;
      conda.disabled = true;
      docker_context.disabled = true;
      kubernetes.disabled = true;
      helm.disabled = true;
      cmd_duration = {
        min_time = 500;
        style = "fg:peach bold";
        format = "[took $duration]($style) ";
      };
    };
  };
}

{
  lib,
  config,
  ...
}: {
  programs = {
    starship = {
      enable = true;
      # Starship can wedge while probing the Darwin host over SSH, leaving
      # zsh without a prompt. Initialise it only for local interactive zsh.
      enableZshIntegration = false;
      settings = {
        # Headless homes do not import Stylix. Its palette takes precedence
        # on desktops; elsewhere these names follow the terminal's colors.
        palette = lib.mkDefault "terminal";
        palettes.terminal = {
          base03 = "bright-black";
          base04 = "white";
          base05 = "white";
          base08 = "red";
          base09 = "yellow";
          base13 = "bright-yellow";
          base14 = "bright-green";
          base15 = "bright-cyan";
        };
        scan_timeout = 10;
        command_timeout = 300;

        format = ''
          $username$hostname$directory$git_branch$git_state$nix_shell$jobs$cmd_duration
          $character
        '';

        right_format = "$git_status$status";

        username = {
          show_always = false;
          format = "[ $user ]($style)";
          style_user = "fg:base05 bold";
          style_root = "fg:base08 bold";
        };

        hostname = {
          ssh_only = true;
          format = "[@$hostname ]($style)";
          style = "fg:base15 bold";
          trim_at = ".nixlab.au";
        };

        directory = {
          format = "[$path]($style)[$read_only]($read_only_style) ";
          style = "fg:base15 bold";
          truncation_length = 4;
          truncation_symbol = "…/";
          read_only = " 󰌾";
          read_only_style = "fg:base08 bold";
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
          format = "[ $symbol$branch(:$remote_branch) ]($style)";
          style = "fg:base14 bold";
          symbol = " ";
        };

        git_status = {
          format = "[$all_status$ahead_behind]($style)";
          style = "fg:base09 bold";
          conflicted = "!$count ";
          ahead = "⇡$count ";
          behind = "⇣$count ";
          diverged = "⇕$ahead_count/$behind_count ";
          up_to_date = "";
          untracked = "?$count ";
          stashed = "≡$count ";
          modified = "~$count ";
          staged = "+$count ";
          renamed = "»$count ";
          deleted = "-$count ";
        };

        git_state = {
          format = "[ $state( $progress_current/$progress_total) ]($style)";
          style = "fg:base13 bold";
        };

        character = {
          format = "$symbol";
          success_symbol = "[❯](fg:base14 bold) ";
          error_symbol = "[❯](fg:base08 bold) ";
          vicmd_symbol = "[❮](fg:base13 bold) ";
          vimcmd_visual_symbol = "[V](fg:base13 bold) ";
        };

        nix_shell = {
          format = "[ $symbol nix ]($style)";
          style = "fg:base15 bold";
          symbol = "";
          impure_msg = "";
          pure_msg = "";
          unknown_msg = "";
        };

        jobs = {
          format = "[ $symbol$number ]($style)";
          style = "fg:base13 bold";
          symbol = "󰒋 ";
          number_threshold = 1;
        };

        cmd_duration = {
          min_time = 2000;
          format = "[ $duration ](fg:base13)";
        };

        status = {
          disabled = false;
          format = "[ $symbol$status ]($style)";
          style = "fg:base08 bold";
          symbol = "󰅙 ";
        };
      };
    };

    zsh.initContent = lib.mkAfter ''
      if [[ $TERM == dumb ]]; then
        PROMPT='%n@%m:%~ %# '
      elif [[ -n ''${SSH_CONNECTION-} ]]; then
        PROMPT='%F{yellow}%n@%m%f %F{cyan}%~%f %(?..%F{red}exit %?%f )%# '
        RPROMPT=""
      else
        eval "$(${lib.getExe config.programs.starship.package} init zsh)"
      fi
    '';
  };
}

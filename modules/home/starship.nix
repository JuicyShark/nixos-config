_: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      scan_timeout = 10;
      command_timeout = 800;

      format = ''
        $hostname$directory$git_branch$fill$git_status$git_metrics$git_state$nodejs$python$rust$golang$lua$package$jobs
        $character
      '';

      right_format = "$cmd_duration$status";

      fill = {
        symbol = " ";
        style = "base03";
      };

      os = {
        disabled = false;
        format = "[ $symbol ]($style)";
        style = "fg:base04 bold";
        symbols = {
          NixOS = "";
          Macos = "";
          Linux = "";
        };
      };

      username = {
        show_always = true;
        disabled = false;
        format = "[ $user ]($style)";
        style_user = "fg:base05 bold";
        style_root = "fg:base08 bold";
      };

      hostname = {
        ssh_only = false;
        format = "[@$hostname ]($style)";
        style = "fg:base15 bold";
        trim_at = ".nixlab.au";
        disabled = false;
      };

      sudo = {
        format = "[ $symbol]($style)";
        symbol = "󰌋 ";
        style = "fg:base08 bold";
        allow_windows = false;
        disabled = false;
      };

      directory = {
        format = "[ 󰉋 $path ]($style)";
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
        format = "[  $branch(:$remote_branch) ]($style)";
        ignore_branches = ["master" "main"];
        style = "fg:base14 bold";
        symbol = " ";
      };

      git_status = {
        disabled = false;
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
        disabled = false;
        format = "[ $state( $progress_current/$progress_total) ]($style)";
        style = "fg:base13 bold";
      };

      git_metrics = {
        disabled = false;
        only_nonzero_diffs = true;
        format = "([ diff +$added ]($added_style))([-$deleted ]($deleted_style))";
        added_style = "fg:base14 bold";
        deleted_style = "fg:base08 bold";
      };

      character = {
        format = "$symbol";
        success_symbol = "[❯](fg:base14 bold) ";
        error_symbol = "[❯](fg:base08 bold) ";
        vicmd_symbol = "[❮](fg:base13 bold) ";
        vimcmd_visual_symbol = "[V](fg:base13 bold) ";
        disabled = false;
      };

      nix_shell = {
        disabled = false;
        heuristic = false;
        format = "[ $symbol$state ]($style)";
        style = "fg:base16 bold";
        symbol = " ";
        impure_msg = "";
        pure_msg = "";
        unknown_msg = "";
      };

      direnv = {
        disabled = false;
        format = "[ env $loaded/$allowed ]($style)";
        style = "fg:base17 bold";
        symbol = " ";
        allowed_msg = "ok";
        not_allowed_msg = "lock";
        loaded_msg = "env";
        unloaded_msg = "off";
        denied_msg = "deny";
      };

      jobs = {
        format = "[ $symbol$number ]($style)";
        style = "fg:base13 bold";
        symbol = "󰒋 ";
        number_threshold = 1;
      };

      status = {
        disabled = false;
        format = "[ $symbol$status ]($style)";
        style = "fg:base08 bold";
        symbol = "󰅙 ";
      };

      time = {
        disabled = false;
        format = "[ $time ]($style)";
        style = "fg:base04 bold";
        time_format = "%H:%M";
      };

      aws.disabled = true;
      gcloud.disabled = true;
      nodejs = {
        disabled = false;
        format = "[ $symbol$version ]($style)";
        style = "fg:base13 bold";
        symbol = " ";
      };
      ruby.disabled = true;
      python = {
        disabled = false;
        format = "[ $symbol$version( $virtualenv) ]($style)";
        style = "fg:base16 bold";
        symbol = " ";
      };
      rust = {
        disabled = false;
        format = "[ $symbol$version ]($style)";
        style = "fg:base09 bold";
        symbol = " ";
      };
      golang = {
        disabled = false;
        format = "[ $symbol$version ]($style)";
        style = "fg:base15 bold";
        symbol = " ";
      };
      java.disabled = true;
      kotlin.disabled = true;
      lua = {
        disabled = false;
        format = "[ $symbol$version ]($style)";
        style = "fg:base17 bold";
        symbol = " ";
      };
      perl.disabled = true;
      php.disabled = true;
      swift.disabled = true;
      terraform.disabled = true;
      zig.disabled = true;
      package = {
        disabled = false;
        format = "[ $symbol$version ]($style)";
        style = "fg:base04 bold";
        symbol = "󰏗 ";
      };
      conda.disabled = true;
      docker_context.disabled = true;
      kubernetes.disabled = true;
      helm.disabled = true;
      cmd_duration = {
        min_time = 500;
        style = "fg:base09 bold";
        format = "[ 󰔟 $duration ]($style)";
      };
    };
  };
}

{ config, ... }:
{
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.fish = {
    enable = true;

    shellAliases = {
      tree = "eza --all --long --tree";
      mv = "mv -i";
      cp = "cp -ia";
      #    cd = "zoxide";
      z = "zoxide";
    };

    shellAbbrs = {
      g = "git";
      ga = "git add";
      gaa = "git add --all";
      gap = "git add --patch";
      gapp = "git apply";
      gb = "git branch --verbose";
      gbr = "git branch --verbose --remotes";
      gbd = "git branch --delete";
      gbD = "git branch --delete --force";
      gc = "git commit -m";
      gca = "git commit --amend";
      gcl = "git clone";
      gco = "git checkout";
      gcot = "git checkout --theirs";
      gcp = "git cherry-pick --strategy-option theirs";
      gcpx = "git cherry-pick --strategy-option theirs -x";
      gd = "git diff";
      gds = "git diff --staged";
      gf = "git fetch";
      gi = "git init";
      gl = "git log --oneline --decorate --graph -n 10";
      gm = "git merge";
      gp = "git push";
      gpu = "git pull";
      gr = "git reset HEAD~";
      gR = "git restore";
      gRs = "git restore --staged";
      gra = "git remote add";
      gre = "git remote --verbose";
      grh = "git reset HEAD";
      grr = "git reset --hard HEAD~";
      grb = "git rebase --interactive";
      grbc = "git rebase --continue";
      gs = "git status";
      gsma = "git submodule add";
      gsmu = "git submodule update --init --remote --recursive";
      gst = "git stash";
      gstp = "git stash pop";
      gsw = "git switch";
      gt = "git tag";
      gts = "git tag -s";

      nf = "nix flake";
      nfc = "nix flake check";
      nfu = "nix flake update";
      npr = "nixpkgs-review pr --run fish --print-result";
      nd = "nix develop --command fish";
      nb = "nix build";
      ns = "nix shell";
      nr = "nix run";
      ncg = "sudo nix-collect-garbage -d && nix-collect-garbage -d";
      nvd = "nvd --color always diff /run/current-system result | rg -v 0.0.0 | less -R";

      ca = "cargo add";
      cab = "cargo add --build";
      cad = "cargo add --dev";
      cb = "cargo build";
      cr = "cargo run";
      ct = "cargo test";
      crm = "cargo remove";
      crmb = "cargo remove --build";
      crmd = "cargo remove --dev";
      cc = "cargo clippy";
      cf = "cargo fmt";

      dl = "yt-dlp";
      vol = "wpctl set-volume '@DEFAULT_AUDIO_SINK@'";
      vm = "nixos-rebuild build-vm --flake . && ./result/bin/run-nixos-vm && trash put result nixos.qcow2";
      sw = "sudo nixos-rebuild switch --flake .";

      c = "clear";
      unzip = "7z -x";
      edit = "$VISUAL:-$EDITOR:-vi";

    };

    functions = {
      wav2flac =
        # fish
        ''
          set ORIGINAL_SIZE (du -hs | cut -f1)

          fd -e wav -x ffmpeg -i "{}" -loglevel quiet -stats "{.}.flac"
          fd -e wav -X trash

          set NEW_SIZE (du -hs | cut -f1)

          echo "Done. Reduced file size from $ORIGINAL_SIZE to $NEW_SIZE"
        '';

      opus =
        # fish
        ''
          set ORIGINAL_SIZE (du -hs | cut -f1)

          fd -e wav -e flac -x ffmpeg -i "{}" -c:a libopus -b:a 128K -loglevel quiet -stats "{.}.opus"
          fd -e wav -e flac -X rm -I

          set NEW_SIZE (du -hs | cut -f1)

          echo "Done. Reduced file size from $ORIGINAL_SIZE to $NEW_SIZE"
        '';

    };
  };
}

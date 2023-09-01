{ pkgs, ... }:

{
  home.packages = with pkgs; [ mpc-cli ];

  services.mpd = {
    enable = true;
    musicDirectory = "/home/user/音楽";
  };

  xdg.configFile = {
    "mpd/mpd.conf".text = ''
      auto_update "yes"
    '';

    "ncmpcpp/on-song-change.sh" = {
      executable = true;
      text = /* bash */ ''
        #!/usr/bin/env bash

        music_dir="$HOME/音楽"
        fallback_image="$HOME/a.jpg"

        main () {
            find_cover 2>/dev/null
            send       2>/dev/null
        }

        find_cover () {
            ext="$(mpc --format %file% current | sed 's/^.*\.//')"
            if [ "$ext" != "flac" ]; then
                ffmpeg -y -i "$(mpc --format "$music_dir"/%file% | head -n 1)" \
                /tmp/cover.jpg && cover_path="/tmp/cover.jpg" && return
            else
                # ffmpeg doesn't work for flacs
                metaflac --export-picture-to=/tmp/cover.jpg \
                "$(mpc --format "$music_dir"/%file% current)" && cover_path="/tmp/cover.jpg" && return
            fi
            #without embedded images this is used as a fallback
            file="$music_dir/$(mpc --format %file% current)"
            album="''${file%/*}"
            #search for cover image
            cover_path=$(find "$album"  -maxdepth 1 | grep -m 1 ".*\.\(jpg\|png\|gif\|bmp\)")
        }

        send () {
            notify-send -i "''${cover_path:-$fallback_image}" "Now Playing" "$(mpc current)"
        }

        main
      '';
    };
  };

  programs.ncmpcpp = {
    enable = true;

    bindings = [
      { key = "mouse"; command = "dummy"; }
      { key = "h"; command = [ "previous_column" "jump_to_parent_directory" ]; }
      { key = "j"; command = "scroll_down"; }
      { key = "k"; command = "scroll_up"; }
      { key = "l"; command = [ "next_column" "enter_directory" "play_item" ]; }
      { key = "H"; command = [ "select_item" "scroll_down" ]; }
      { key = "J"; command = [ "move_sort_order_down" "move_selected_items_down" ]; }
      { key = "K"; command = [ "move_sort_order_up" "move_selected_items_up" ]; }
      { key = "L"; command = [ "select_item" "scroll_up" ]; }
      { key = "'"; command = "remove_selection"; }
      { key = "ctrl-u"; command = "page_up"; }
      { key = "ctrl-d"; command = "page_down"; }
      { key = "u"; command = "page_up"; }
      { key = "d"; command = "page_down"; }
      { key = "n"; command = "next_found_item"; }
      { key = "N"; command = "previous_found_item"; }
      { key = "t"; command = "next_screen"; }
      { key = "g"; command = "move_home"; }
      { key = "G"; command = "move_end"; }
      { key = "w"; command = "next"; }
      { key = "b"; command = "previous"; }
      { key = ";"; command = "seek_forward"; }
      { key = ","; command = "seek_backward"; }
      { key = "f"; command = "apply_filter"; }
      { key = "i"; command = "select_item"; }
      { key = "x"; command = [ "delete_playlist_items" "delete_browser_items" "delete_stored_playlist" ]; }
      { key = "U"; command = "update_database"; }
      { key = "m"; command = "add_random_items"; }
    ];

    settings = {
      ncmpcpp_directory = "~/.config/ncmpcpp";
      user_interface = "alternative";
      autocenter_mode = "yes";
      allow_for_physical_item_deletion = "no";
      mouse_support = "no";
      execute_on_song_change = "~/.config/ncmpcpp/on-song-change.sh";
      mpd_crossfade_time = 3;
    };
  };
}

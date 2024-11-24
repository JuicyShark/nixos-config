{config, pkgs, ...}
:{
  xdg.configFile."yazi/plugins/smart-enter.yazi/init.lua".text = ''
    return {
	    entry = function()
		  local h = cx.active.current.hovered
		  ya.manager_emit(h and h.cha.is_dir and "enter" or "open", { hovered = true })
	  end,
    }
  '';
  xdg.configFile."yazi/init.lua".text = ''
    Header:children_add(function()
	    if ya.target_family() ~= "unix" then
		    return ui.Line {}
	    end
	    return ui.Span(ya.user_name() .. "@" .. ya.host_name() .. ":"):fg("blue")
    end, 500, Header.LEFT)
  '';

  programs.yazi = {
    enable = true;

    settings = {
      manager = {
        sort_dir_first = true;
        linemode = "mtime";

        ratio = [
          1
          2
          4
        ];
      };

      preview = {
        tab_size = 4;
        image_filter = "lanczos3";
        max_width = 1920;
        max_height = 1080;
        image_quality = 90;
      };

      opener = {

        pdf = [
	        { run = "zathura '$@'"; desc = "zathura"; block = false; }
];
image = [
    { run = "timg '$0'"; desc = "timg"; block = false; }
    { run = "gimp '$@'"; desc = "gimp"; block = false; }
];
text = [
    { run = "less '$0'"; desc = "less"; block = true; }
    { run = "bat '$0'"; desc = "bat"; block = true; }

];
edit = [
    { run = "nvim '$@'"; desc = "nvim"; block = true; }
];
video = [
    { run = "${config.programs.mpv.package}/bin/umpv $1'"; desc = "mpv"; block = false; }
];
audio = [
    { run = "${config.programs.mpv.package}/bin/umpv --force-window '$1'"; desc = "mpv"; block = false; }
];
      };

      open = {
        rules = [
  # Mime types
  { mime = "application/pdf"; use = "pdf"; }
  { mime = "image/*"; use = "image"; }
  { mime = "video/*"; use = "video"; }
  { mime = "audio/*"; use = "audio"; }
  { mime = "text/*"; use = ["edit" "text"]; }

  # File extensions
  { name = "*.pdf"; use = "pdf"; }
  { name = "*.json"; use = "edit"; }
  { name = "*.md"; use = "edit"; }
  { name = "*.html"; use = ["edit" "text"]; }
  { name = "*.sh"; use = "edit"; }
  { name = "*.txt"; use = ["edit" "text"]; }
  { name = "*.csv"; use = "edit"; }
  { name = "*.dat"; use = "edit"; }
  { name = "*.toml"; use = "edit"; }
  { name = "*.yaml"; use = "edit"; }
  { name = "*.yml"; use = "edit"; }
  { name = "*.lua"; use = ["edit" "text"]; }
  { name = "*.log"; use = "text"; }
  { name = "*.rs"; use = ["edit" "text"]; }
  { name = "*.js"; use = ["edit" "text"]; }
  { name = "*.ts"; use = ["edit" "text"]; }
  { name = "*.mp3"; use = "audio"; }
  { name = "*.wav"; use = "audio"; }
  { name = "*.ogg"; use = "audio"; }
];

      };

    };

    keymap = {
      manager.prepend_keymap = [
        {
          run = "remove --force";
          on = [ "d" ];
        }
      ];
    };
  };
}

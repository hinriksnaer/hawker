# Yazi -- terminal file manager with preview support.
# Fully managed by Home Manager's programs.yazi module.
# theme.toml is NOT managed here -- hawker-theme-set writes it at runtime.
{ pkgs, ... }:

{
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y";

    # Plugins from nixpkgs (pkgs.yaziPlugins)
    plugins = {
      inherit (pkgs.yaziPlugins) smart-enter smart-filter;
    };

    settings = {
      mgr = {
        ratio = [1 5 4];
        sort_by = "alphabetical";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
        show_hidden = true;
        show_symlink = true;
        scrolloff = 5;
        linemode = "size";
      };
      preview = {
        tab_size = 2;
        max_width = 600;
        max_height = 900;
        cache_dir = "";
        wrap = "no";
        image_adapter = "auto";
        ueberzug_scale = 1;
        ueberzug_offset = [0 0 0 0];
      };
      opener = {
        edit = [{ run = ''nvim "$@"''; block = true; "for" = "linux"; }];
        open = [{ run = ''xdg-open "$@"''; desc = "Open"; orphan = true; }];
        reveal = [{ run = ''yazi "$@"''; desc = "Reveal in Yazi"; "for" = "linux"; }];
        play = [{ run = ''mpv "$@"''; orphan = true; "for" = "linux"; desc = "Play with mpv"; }];
        archive = [
          { run = ''ouch decompress "$@"''; desc = "Extract here"; }
          { run = ''ouch decompress "$@" --yes''; desc = "Extract (overwrite)"; }
        ];
        image = [
          { run = ''imv "$@"''; orphan = true; desc = "View in imv"; }
          { run = ''xdg-open "$@"''; orphan = true; desc = "Open with default"; }
        ];
        pdf = [
          { run = ''zathura "$@"''; orphan = true; desc = "Open in Zathura"; }
          { run = ''xdg-open "$@"''; orphan = true; desc = "Open with default"; }
        ];
      };
      open.rules = [
        { mime = "text/*"; use = "edit"; }
        { mime = "application/json"; use = "edit"; }
        { mime = "application/x-yaml"; use = "edit"; }
        { mime = "application/toml"; use = "edit"; }
        { mime = "*/javascript"; use = "edit"; }
        { mime = "image/*"; use = "image"; }
        { mime = "video/*"; use = "play"; }
        { mime = "audio/*"; use = "play"; }
        { mime = "application/x-tar"; use = "archive"; }
        { mime = "application/zip"; use = "archive"; }
        { mime = "application/gzip"; use = "archive"; }
        { mime = "application/x-7z-compressed"; use = "archive"; }
        { mime = "application/x-rar"; use = "archive"; }
        { mime = "application/pdf"; use = "pdf"; }
        { mime = "inode/directory"; use = "open"; }
      ];
      tasks = {
        micro_workers = 10;
        macro_workers = 25;
        bizarre_retry = 5;
        image_alloc = 536870912;
        image_bound = [0 0];
        suppress_preload = false;
      };
      log.enabled = false;
    };

    keymap = {
      mgr.prepend_keymap = [
        { on = ["h"]; run = "leave"; desc = "Go to parent directory"; }
        { on = ["j"]; run = "arrow 1"; desc = "Move cursor down"; }
        { on = ["k"]; run = "arrow -1"; desc = "Move cursor up"; }
        { on = ["l"]; run = "enter"; desc = "Enter directory or open file"; }
        { on = ["<C-u>"]; run = "arrow -50%"; desc = "Move cursor up 50%"; }
        { on = ["<C-d>"]; run = "arrow 50%"; desc = "Move cursor down 50%"; }
        { on = ["g" "g"]; run = "arrow -99999999"; desc = "Move cursor to top"; }
        { on = ["G"]; run = "arrow 99999999"; desc = "Move cursor to bottom"; }
        { on = ["<Enter>"]; run = "plugin --sync smart-enter"; desc = "Enter directory or open file"; }
        { on = ["y"]; run = "yank"; desc = "Copy selected files"; }
        { on = ["x"]; run = "yank --cut"; desc = "Cut selected files"; }
        { on = ["p"]; run = "paste"; desc = "Paste files"; }
        { on = ["P"]; run = "paste --force"; desc = "Paste files (overwrite)"; }
        { on = ["d"]; run = "remove"; desc = "Move to trash"; }
        { on = ["D"]; run = "remove --permanently"; desc = "Permanently delete"; }
        { on = ["a"]; run = "create"; desc = "Create a file or directory"; }
        { on = ["r"]; run = "rename"; desc = "Rename a file or directory"; }
        { on = ["<Space>"]; run = "select --state=none"; desc = "Toggle selection"; }
        { on = ["v"]; run = "visual_mode"; desc = "Enter visual mode"; }
        { on = ["V"]; run = "visual_mode --unset"; desc = "Exit visual mode"; }
        { on = ["<C-a>"]; run = "select_all --state=true"; desc = "Select all files"; }
        { on = ["<C-r>"]; run = "select_all --state=none"; desc = "Inverse selection"; }
        { on = ["/"]; run = "find"; desc = "Find files"; }
        { on = ["n"]; run = "find_arrow"; desc = "Go to next found file"; }
        { on = ["N"]; run = "find_arrow --previous"; desc = "Go to previous found file"; }
        { on = ["f"]; run = "plugin smart-filter"; desc = "Smart filter files"; }
        { on = ["s" "m"]; run = "sort modified --reverse=no"; desc = "Sort by modified time"; }
        { on = ["s" "M"]; run = "sort modified --reverse"; desc = "Sort by modified time (reverse)"; }
        { on = ["s" "c"]; run = "sort created --reverse=no"; desc = "Sort by created time"; }
        { on = ["s" "C"]; run = "sort created --reverse"; desc = "Sort by created time (reverse)"; }
        { on = ["s" "s"]; run = "sort size --reverse=no"; desc = "Sort by size"; }
        { on = ["s" "S"]; run = "sort size --reverse"; desc = "Sort by size (reverse)"; }
        { on = ["s" "a"]; run = "sort alphabetical --reverse=no"; desc = "Sort alphabetically"; }
        { on = ["s" "A"]; run = "sort alphabetical --reverse"; desc = "Sort alphabetically (reverse)"; }
        { on = ["t"]; run = "tab_create --current"; desc = "Create a new tab"; }
        { on = ["1"]; run = "tab_switch 0"; desc = "Switch to tab 1"; }
        { on = ["2"]; run = "tab_switch 1"; desc = "Switch to tab 2"; }
        { on = ["3"]; run = "tab_switch 2"; desc = "Switch to tab 3"; }
        { on = ["4"]; run = "tab_switch 3"; desc = "Switch to tab 4"; }
        { on = ["5"]; run = "tab_switch 4"; desc = "Switch to tab 5"; }
        { on = ["["]; run = "tab_switch -1 --relative"; desc = "Switch to previous tab"; }
        { on = ["]"]; run = "tab_switch 1 --relative"; desc = "Switch to next tab"; }
        { on = ["{"]; run = "tab_swap -1"; desc = "Swap current tab with previous"; }
        { on = ["}"]; run = "tab_swap 1"; desc = "Swap current tab with next"; }
        { on = ["z" "h"]; run = "hidden toggle"; desc = "Toggle hidden files"; }
        { on = ["z" "p"]; run = "preview"; desc = "Toggle preview pane"; }
        { on = ["~"]; run = "shell"; desc = "Run shell command"; }
        { on = ["?"]; run = "help"; desc = "Show help"; }
        { on = [":"]; run = "shell --block --interactive"; desc = "Run shell command (blocking)"; }
        { on = ["q"]; run = "quit"; desc = "Quit yazi"; }
        { on = ["Q"]; run = "quit --no-cwd-file"; desc = "Quit without saving cwd"; }
      ];
      tasks.prepend_keymap = [
        { on = ["<Esc>"]; run = "close"; desc = "Close task manager"; }
        { on = ["<C-c>"]; run = "close"; desc = "Close task manager"; }
        { on = ["w"]; run = "close"; desc = "Close task manager"; }
      ];
      select.prepend_keymap = [
        { on = ["<Esc>"]; run = "close"; desc = "Cancel selection"; }
        { on = ["<C-c>"]; run = "close"; desc = "Cancel selection"; }
        { on = ["<Enter>"]; run = "close --submit"; desc = "Submit selection"; }
        { on = ["k"]; run = "arrow -1"; desc = "Move cursor up"; }
        { on = ["j"]; run = "arrow 1"; desc = "Move cursor down"; }
      ];
      input.prepend_keymap = [
        { on = ["<Esc>"]; run = "close"; desc = "Cancel input"; }
        { on = ["<C-c>"]; run = "close"; desc = "Cancel input"; }
        { on = ["<Enter>"]; run = "close --submit"; desc = "Submit input"; }
        { on = ["<C-u>"]; run = "kill bol"; desc = "Kill to beginning of line"; }
      ];
      completion.prepend_keymap = [
        { on = ["<Tab>"]; run = "close --submit"; desc = "Submit completion"; }
        { on = ["<S-Tab>"]; run = "arrow -1"; desc = "Previous completion"; }
        { on = ["<C-n>"]; run = "arrow 1"; desc = "Next completion"; }
        { on = ["<C-p>"]; run = "arrow -1"; desc = "Previous completion"; }
      ];
      help.prepend_keymap = [
        { on = ["<Esc>"]; run = "close"; desc = "Close help"; }
        { on = ["q"]; run = "close"; desc = "Close help"; }
        { on = ["k"]; run = "arrow -1"; desc = "Move cursor up"; }
        { on = ["j"]; run = "arrow 1"; desc = "Move cursor down"; }
      ];
    };

    initLua = ''
      -- Minimal custom linemode showing only size
      function Linemode:size_only()
        local size = self._file:size()
        return ui.Line(size and ya.readable_size(size) or "-")
      end
    '';
  };

  # Preview support packages
  home.packages = with pkgs; [
    file              # MIME detection
    ffmpegthumbnailer # video thumbnails
    poppler-utils     # PDF preview
    imagemagick       # image preview
  ];

  # Hawker theme-map.conf (not standard yazi config, used by hawker-theme-set)
  xdg.configFile."yazi/theme-map.conf".source = ../../../dotfiles/yazi/.config/yazi/theme-map.conf;
}

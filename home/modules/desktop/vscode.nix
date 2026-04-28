# Visual Studio Code with extensions and settings.
# Extensions are managed declaratively -- install/update via hawker-switch.
{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;

      extensions = with pkgs.vscode-extensions; [
        # AI
        saoudrizwan.claude-dev

        # Python
        ms-python.python
        ms-python.vscode-pylance

        # Theme
        teabyii.ayu
      ];

      userSettings = {
        # Theme
        "workbench.colorTheme" = "Ayu Dark";

        # Editor
        "editor.fontFamily" = "'CaskaydiaMono Nerd Font', 'monospace'";
        "editor.fontSize" = 13;
        "editor.fontLigatures" = true;
        "editor.minimap.enabled" = false;
        "editor.renderWhitespace" = "boundary";
        "editor.bracketPairColorization.enabled" = true;
        "editor.guides.bracketPairs" = "active";
        "editor.smoothScrolling" = true;
        "editor.cursorBlinking" = "smooth";
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.formatOnSave" = true;

        # Terminal
        "terminal.integrated.fontFamily" = "'CaskaydiaMono Nerd Font'";
        "terminal.integrated.fontSize" = 12;

        # Workbench
        "workbench.startupEditor" = "none";
        "workbench.sideBar.location" = "right";
        "workbench.tree.indent" = 16;
        "workbench.iconTheme" = "ayu";

        # Window
        "window.titleBarStyle" = "custom";
        "window.menuBarVisibility" = "toggle";

        # Files
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        "files.trimFinalNewlines" = true;

        # Python
        "python.analysis.typeCheckingMode" = "basic";
        "python.analysis.autoImportCompletions" = true;

        # Telemetry
        "telemetry.telemetryLevel" = "off";
      };
    };
  };
}

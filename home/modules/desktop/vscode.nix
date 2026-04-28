# Visual Studio Code with extensions and theme.
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

        # Vim
        vscodevim.vim

        # Theme
        teabyii.ayu
        pkief.material-icon-theme
      ];

      userSettings = {
        "workbench.colorTheme" = "Ayu Dark";
        "workbench.iconTheme" = "material-icon-theme";
      };
    };
  };
}

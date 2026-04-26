{ ... }:

{
  # Default cursor theme (makes Adwaita available system-wide)
  environment.etc."icons/default/index.theme".text = ''
    [Icon Theme]
    Inherits=Adwaita
  '';
}

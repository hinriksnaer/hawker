# Power menu -- rofi-based shutdown/reboot/logout dialog.
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "power-menu";
      runtimeInputs = with pkgs; [ rofi systemd ];
      text = builtins.readFile ./power-menu.sh;
      excludeShellChecks = [ "SC2029" "SC2016" ];
    })
  ];
}

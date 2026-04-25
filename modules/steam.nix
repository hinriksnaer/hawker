{ pkgs, ... }:

{
  # Steam
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };

  # Gamescope compositor (for per-game resolution/refresh control)
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # Gamemode (CPU governor + GPU optimizations while gaming)
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud     # FPS overlay
    protonup-qt  # Proton version manager
  ];
}

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    starship
  ];

  programs.fish.enable = true;
}

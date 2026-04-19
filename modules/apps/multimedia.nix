{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ffmpeg
    libva
    libva-utils
  ];

  # Hardware video acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva
    ];
  };
}

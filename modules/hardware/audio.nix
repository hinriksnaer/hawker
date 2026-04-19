{ pkgs, ... }:

{
  # PipeWire audio stack
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Disable PulseAudio (replaced by PipeWire)
  services.pulseaudio.enable = false;

  # RealtimeKit for PipeWire scheduling priority
  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    pavucontrol
    pamixer      # CLI mixer (used by waybar right-click mute)
    playerctl
    alsa-utils
  ];
}

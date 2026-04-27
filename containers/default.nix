# OCI container image via streamLayeredImage.
# Packages and env vars come from the NixOS module system (hosts/container/),
# extracted by flake.nix and passed here. No systemd, no NixOS inside —
# just the declared packages + dotfiles + a fish shell.
# Config changes = rebuild image on host (fast with Nix caching).
{ pkgs, packages, username, sessionVariables ? {}, name ? "hawker-dev" }:

let
  sessionEnv = pkgs.lib.mapAttrsToList (k: v: "${k}=${v}") sessionVariables;

  repoSrc = builtins.path {
    path = ../.;
    name = "hawker-src";
  };

  homeDir = pkgs.runCommand "hawker-home" {
    nativeBuildInputs = [ pkgs.stow ];
  } ''
    mkdir -p $out/tmp
    chmod 1777 $out/tmp
    mkdir -p $out/home/${username}
    mkdir -p $out/home/${username}/.cache
    mkdir -p $out/home/${username}/.local/share/fish

    cp -r ${repoSrc} $out/home/${username}/hawker
    chmod -R u+w $out/home/${username}/hawker

    HOME=$out/home/${username} \
      bash $out/home/${username}/hawker/bootstrap.sh
  '';

  # FHS compatibility helpers from dockerTools
  inherit (pkgs.dockerTools) usrBinEnv binSh;

  # Pre-generate ld.so.cache at the exact Nix store path that glibc's
  # ldconfig has hardcoded.  This derivation's $out is mapped to / in
  # the image, so $out${pkgs.glibc}/etc/ld.so.cache becomes
  # ${pkgs.glibc}/etc/ld.so.cache — the path ldconfig already looks for.
  # No wrappers needed; the real ldconfig just finds its cache.
  ldsoCache = pkgs.runCommand "ldconfig-cache" {} ''
    mkdir -p "$out${pkgs.glibc}/etc"
    echo "${pkgs.stdenv.cc.cc.lib}/lib" > /tmp/ld.so.conf
    echo "${pkgs.glibc}/lib"           >> /tmp/ld.so.conf
    ${pkgs.glibc.bin}/sbin/ldconfig \
      -f /tmp/ld.so.conf \
      -C "$out${pkgs.glibc}/etc/ld.so.cache"
  '';

  etcDir = pkgs.runCommand "hawker-etc" {} ''
    mkdir -p $out/etc/ssh
    echo "root:x:0:0:root:/root:/bin/bash" > $out/etc/passwd
    echo "${username}:x:1000:1000::/home/${username}:${pkgs.fish}/bin/fish" >> $out/etc/passwd
    echo "root:x:0:" > $out/etc/group
    echo "users:x:1000:${username}" >> $out/etc/group
    echo "hosts: files dns" > $out/etc/nsswitch.conf

    cat > $out/etc/ssh/ssh_known_hosts << 'HOSTS'
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
HOSTS
  '';

in
pkgs.dockerTools.streamLayeredImage {
  inherit name;
  tag = "latest";

  contents = packages ++ [ homeDir etcDir ldsoCache usrBinEnv binSh ];

  fakeRootCommands = ''
    chown -R 1000:1000 /home/${username}
    chmod 1777 /tmp

    # Symlink the dynamic linker to the standard FHS path so unpatched
    # binaries (e.g. VSCode server's node) can find it.
    mkdir -p /lib64
    ln -sf ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
  '';
  enableFakechroot = true;

  config = {
    User = "${username}";
    Env = [
      "LANG=en_US.UTF-8"
      "TERM=xterm-256color"
      "EDITOR=nvim"
      "VISUAL=nvim"
      "SHELL=${pkgs.fish}/bin/fish"
      "HOME=/home/${username}"
      "USER=${username}"
      "XDG_DATA_HOME=/home/${username}/.local/share"
      "XDG_CONFIG_HOME=/home/${username}/.config"
      "XDG_CACHE_HOME=/home/${username}/.cache"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ] ++ sessionEnv;
    Cmd = [ "${pkgs.fish}/bin/fish" ];
    WorkingDir = "/home/${username}";
  };
}

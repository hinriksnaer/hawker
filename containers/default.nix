{ pkgs, packages, username, projects ? [], gpus ? "all", sessionVariables ? {}, hmActivation ? null, name ? "hawker-dev" }:

let
  projectsStr = builtins.concatStringsSep "," projects;
  sessionEnv = pkgs.lib.mapAttrsToList (k: v: "${k}=${v}") sessionVariables;

  entryScript = pkgs.writeShellScript "container-entry" (builtins.readFile ../scripts/container-entry.sh);

  # All packages that go into the container's Nix profile
  profile = pkgs.buildEnv {
    name = "hawker-profile";
    paths = packages ++ [ pkgs.nix pkgs.git pkgs.cacert pkgs.bashInteractive ];
    ignoreCollisions = true;
  };

in
pkgs.dockerTools.buildImage {
  inherit name;
  tag = "latest";

  extraCommands = ''
    # Initialize Nix store DB and profile
    export NIX_REMOTE=local?root=$PWD
    export USER=nobody
    ${pkgs.nix}/bin/nix-store --load-db < ${pkgs.closureInfo { rootPaths = [ profile entryScript ]; }}/registration
    ${profile}/bin/nix-env --profile nix/var/nix/profiles/default --set ${profile}

    # FHS compatibility
    mkdir -p bin usr/bin sbin
    ln -s /nix/var/nix/profiles/default/bin/bash bin/bash
    ln -s /nix/var/nix/profiles/default/bin/sh bin/sh
    ln -s /nix/var/nix/profiles/default/bin/env usr/bin/env

    # Home directory
    mkdir -p home/${username}

    # /etc
    mkdir -p etc/ssh etc/nix
    echo "root:x:0:0:root:/root:/bin/bash" > etc/passwd
    echo "${username}:x:1000:1000::/home/${username}:${pkgs.fish}/bin/fish" >> etc/passwd
    echo "root:x:0:" > etc/group
    echo "users:x:1000:${username}" >> etc/group
    echo "hosts: files dns" > etc/nsswitch.conf

    cat > etc/nix/nix.conf << 'NIXCONF'
experimental-features = nix-command flakes
NIXCONF

    cat > etc/ssh/ssh_known_hosts << 'HOSTS'
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
HOSTS

    # Entry script
    mkdir -p usr/local/bin
    cp ${entryScript} usr/local/bin/container-entry

    # Writable tmp
    mkdir -m 1777 tmp
  '';

  config = {
    User = "root";
    Env = [
      "LANG=en_US.UTF-8"
      "TERM=xterm-256color"
      "EDITOR=nvim"
      "VISUAL=nvim"
      "SHELL=${pkgs.fish}/bin/fish"
      "HOME=/home/${username}"
      "USER=${username}"
      "PATH=/nix/var/nix/profiles/default/bin:/usr/local/bin"
      "SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt"
      "NIX_SSL_CERT_FILE=/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt"
      "HAWKER_PATH=/home/${username}/.local/share/hawker"
      "HAWKER_USER=${username}"
      "HAWKER_PROJECTS=${projectsStr}"
      "HAWKER_GPUS=${gpus}"
      "LD_LIBRARY_PATH=/usr/lib64:${pkgs.stdenv.cc.cc.lib}/lib"
      "TRITON_LIBCUDA_PATH=/usr/lib64"
    ] ++ sessionEnv;
    Cmd = [ "/usr/local/bin/container-entry" ];
    WorkingDir = "/home/${username}";
  };
}

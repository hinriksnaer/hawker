# OCI container image via streamLayeredImage.
# Packages and env vars come from the NixOS module system (hosts/container/),
# extracted by flake.nix and passed here. No systemd, no NixOS inside —
# just the declared packages + dotfiles + a fish shell.
# Config changes = rebuild image on host (fast with Nix caching).
{ pkgs, packages, username, sessionVariables ? {}, name ? "hawker-dev", hmCli ? null }:

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

  # VSCode Remote attach compatibility
  vscode = import ./vscode.nix { inherit pkgs username; };

  # Container init: fix ownership (root), clone repo + bootstrap + HM (dev), exec shell.
  entrypoint = pkgs.writeShellScript "container-init" ''
    SETPRIV="${pkgs.util-linux}/bin/setpriv --reuid=1000 --regid=1000 --init-groups --"
    HAWKER="/home/${username}/hawker"

    # Phase 1: root -- fix /nix ownership (once)
    if [ "$(id -u)" = "0" ]; then
      if [ ! -f /nix/.ownership-fixed ]; then
        mkdir -p /home/${username}/.local/state/nix/profiles
        chown -R 1000:1000 /nix /home/${username}
        touch /nix/.ownership-fixed
      fi

      # Phase 2: dev -- clone repo + bootstrap + HM (first start only)
      if [ ! -d "$HAWKER/.git" ] && [ -d /mnt/hawker/.git ]; then
        echo "==> Cloning hawker repo from host..."
        $SETPRIV ${pkgs.git}/bin/git clone /mnt/hawker "$HAWKER.tmp"
        rm -rf "$HAWKER"
        mv "$HAWKER.tmp" "$HAWKER"
        # Set SSH remote for push
        if [ -n "''${HAWKER_REPO:-}" ]; then
          $SETPRIV ${pkgs.git}/bin/git -C "$HAWKER" remote set-url origin "$HAWKER_REPO"
        fi
        # Bootstrap dotfiles (stow)
        $SETPRIV ${pkgs.bash}/bin/bash "$HAWKER/bootstrap.sh" || true
        # Apply Home Manager config
        $SETPRIV ${pkgs.nix}/bin/nix run "$HAWKER#homeConfigurations.${username}.activationPackage" 2>/dev/null || true
      fi

      # Phase 3: drop to dev, exec shell
      exec $SETPRIV "$@"
    else
      exec "$@"
    fi
  '';

  etcDir = pkgs.runCommand "hawker-etc" {} ''
    mkdir -p $out/etc/ssh
    echo "root:x:0:0:root:/root:/bin/bash" > $out/etc/passwd
    echo "${username}:x:1000:1000::/home/${username}:${pkgs.fish}/bin/fish" >> $out/etc/passwd
    echo "root:x:0:" > $out/etc/group
    echo "users:x:1000:${username}" >> $out/etc/group
    echo "hosts: files dns" > $out/etc/nsswitch.conf
    ${vscode.etcSetup}

    mkdir -p $out/etc/nix
    echo 'experimental-features = nix-command flakes' > $out/etc/nix/nix.conf

    cat > $out/etc/ssh/ssh_known_hosts << 'HOSTS'
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
HOSTS
  '';

  # Wrap entrypoint in a directory so streamLayeredImage can include it
  # (writeShellScript produces a single file, contents expects directories)
  entrypointDir = pkgs.runCommand "entrypoint-dir" {} ''
    mkdir -p $out/usr/local/bin
    cp ${entrypoint} $out/usr/local/bin/container-init
    chmod +x $out/usr/local/bin/container-init
  '';

  # All content items for the image (shared with nixDb closure)
  allContents = packages
    ++ [ homeDir etcDir vscode.localExtensions entrypointDir usrBinEnv binSh ]
    ++ pkgs.lib.optional (hmCli != null) hmCli;

  # Generate Nix database without gcroots symlinks.
  # includeNixDB = true fails under proot when packages share basenames
  # (ln -s follows the first symlink into the read-only store).
  # We generate just the DB -- gcroots are only for GC prevention
  # which doesn't apply in a container.
  nixDb = pkgs.runCommand "nix-db" {
    nativeBuildInputs = [ pkgs.nix ];
    closureInfo = pkgs.closureInfo { rootPaths = allContents; };
  } ''
    mkdir -p $out/nix/var/nix/db
    export NIX_REMOTE=local?root=$out
    export USER=nobody
    nix-store --load-db < $closureInfo/registration
    ${pkgs.sqlite}/bin/sqlite3 $out/nix/var/nix/db/db.sqlite \
      "UPDATE ValidPaths SET registrationTime = 1"
  '';

in
pkgs.dockerTools.streamLayeredImage {
  inherit name;
  tag = "latest";

  contents = allContents ++ [ nixDb ];

  fakeRootCommands = ''
    chown -R 1000:1000 /home/${username}
    chmod 1777 /tmp

    # Dereference Nix DB symlinks -- contents creates symlinks into
    # the read-only store, but Nix needs writable db files.
    for f in nix/var/nix/db/*; do
      if [ -L "$f" ]; then
        cp -L "$f" "$f.real"
        rm "$f"
        mv "$f.real" "$f"
      fi
    done
    chmod -R u+w nix/var/nix/

    ${vscode.fakeRootSetup}
  '';
  enableFakechroot = true;

  config = {
    Labels = vscode.labels;
    Entrypoint = [ "${entrypoint}" ];
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

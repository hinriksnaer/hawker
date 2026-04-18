{ pkgs, packages, name ? "hyprpunk-dev" }:

let
  repoSrc = builtins.path {
    path = ../.;
    name = "hyprpunk-nix";
  };

  homeDir = pkgs.runCommand "hyprpunk-home" {
    nativeBuildInputs = [ pkgs.stow ];
  } ''
    mkdir -p $out/tmp
    chmod 1777 $out/tmp
    mkdir -p $out/home/softmax

    # Include the repo and run bootstrap
    cp -r ${repoSrc} $out/home/softmax/hyprpunk-nix
    chmod -R u+w $out/home/softmax/hyprpunk-nix

    HOME=$out/home/softmax \
      bash $out/home/softmax/hyprpunk-nix/bootstrap.sh

    # SSH directory with known hosts baked in
    mkdir -p $out/home/softmax/.ssh
    chmod 700 $out/home/softmax/.ssh
    cat > $out/home/softmax/.ssh/known_hosts << 'HOSTS'
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
HOSTS
    chmod 644 $out/home/softmax/.ssh/known_hosts
  '';

  etcDir = pkgs.runCommand "hyprpunk-etc" {} ''
    mkdir -p $out/etc/ssh
    echo "root:x:0:0:root:/root:/bin/bash" > $out/etc/passwd
    echo "softmax:x:1000:1000::/home/softmax:${pkgs.fish}/bin/fish" >> $out/etc/passwd
    echo "root:x:0:" > $out/etc/group
    echo "users:x:1000:softmax" >> $out/etc/group
    echo "hosts: files dns" > $out/etc/nsswitch.conf

    # System-wide known hosts (works regardless of which user runs the container)
    cat > $out/etc/ssh/ssh_known_hosts << 'HOSTS'
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
HOSTS
  '';

in
pkgs.dockerTools.buildLayeredImage {
  inherit name;
  tag = "latest";

  contents = packages ++ [ homeDir etcDir ];

  config = {
    Env = [
      "LANG=en_US.UTF-8"
      "TERM=xterm-256color"
      "EDITOR=nvim"
      "VISUAL=nvim"
      "SHELL=${pkgs.fish}/bin/fish"
      "HOME=/home/softmax"
      "USER=softmax"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "HYPRPUNK_PATH=/home/softmax/.local/share/hyprpunk"
    ];
    Cmd = [ "${pkgs.fish}/bin/fish" ];
    WorkingDir = "/home/softmax";
  };
}

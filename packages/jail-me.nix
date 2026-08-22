{
  pkgs,
  jail,
  ...
}:
let
  commonPkgs = with pkgs; [
    bashInteractive
    curl
    wget
    jq
    git
    which
    ripgrep
    gnugrep
    gawkInteractive
    ps
    findutils
    gzip
    unzip
    gnutar
    diffutils
    coreutils
    tree
    file
    wget
    vim
    gnused
  ];
  jailedCombinators =
    {
      name,
      hostNetwork ? true,
      extraPkgs,
    }:
    with jail.combinators;
    (
      [
        time-zone
        no-new-session
        # keep a persistent home dir at:
        # `~/.local/share/jail.nix/${name}`
        (persist-home name)
        # mount-cwd AFTER persist-home or it will conflict
        mount-cwd
        # add these pkgs bin/ directories to $path
        (add-pkg-deps commonPkgs)
        (add-pkg-deps extraPkgs)
        (set-env "EDITOR" "vim")
      ]
      ++ (
        if hostNetwork then
          [
            network
            (set-hostname name)
          ]
        else
          [ ]
      )
    );
in
{
  name ? "dave-shield",
  hostNetwork ? true,
  exec,
  extraPkgs ? [ ],
  extraCombinators ? [ ],
}:
jail name exec (
  jailedCombinators {
    inherit name hostNetwork extraPkgs;
  }
  ++ extraCombinators
)

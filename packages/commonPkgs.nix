{
  pkgs,
}:
with pkgs;
[
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

  # add more common dependencies here.
  # or export a lib function and take a list of extraPkgs as an argument.
  python3
  uv
  pyright
  nodejs
  typescript-language-server
]

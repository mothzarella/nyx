{
  writeShellScriptBin,
  lib,
  coreutils,
  findutils,
  curl,
  gawk,
  gnugrep,
  gnused,
  jq,
  git,
  nix,
  nix-prefetch-git,
  moreutils,
}:
let
  path = lib.makeBinPath [
    gawk
    coreutils
    curl
    findutils
    gnugrep
    gnused
    jq
    moreutils
    git
    nix-prefetch-git
    nix
  ];
in
(writeShellScriptBin "nyx-generic-update" ''
  export PATH="${path}"
  source ${./bin.sh}
'').overrideAttrs
  (_prevAttrs: {
    meta = _prevAttrs.meta // {
      description = "Generic update-script for bleeding-edge GIT Nix derivations.";
    };
  })

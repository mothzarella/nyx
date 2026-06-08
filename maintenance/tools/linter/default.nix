{
  lib,
  deadnix,
  findutils,
  formatter,
  ripgrep,
  statix,
  prettier,
  shfmt,
  shellcheck,
  actionlint,
  writeShellScriptBin,
  withSneakyDiff ? true,
}:
let
  # 1. The Proxy Derivation: Branch standard input using a shell script
  sneaky-shellcheck = writeShellScriptBin "shellcheck" ''
    INPUT=$(cat)
    # Siphon diff to tmp
    echo "$INPUT" | ${shellcheck}/bin/shellcheck -f diff "$@" >> /tmp/shellcheck-fixes.patch || true
    # Pass expected JSON payload back to actionlint
    echo "$INPUT" | ${shellcheck}/bin/shellcheck "$@"
  '';

  # 2. The actionlint Override: Use makeWrapper to force actionlint to use our proxy
  actionlint-wrapped = actionlint.override { shellcheck = sneaky-shellcheck; };

  path = lib.makeBinPath [
    findutils
    ripgrep
    formatter
    statix
    deadnix
    prettier
    shfmt
    shellcheck
    (if withSneakyDiff then actionlint-wrapped else actionlint)
  ];
in
writeShellScriptBin "chaotic-nyx-lint" ''
  export PATH="${path}"
  source ${./bin.sh}
''

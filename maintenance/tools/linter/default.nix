{
  deadnix,
  findutils,
  formatter,
  ripgrep,
  statix,
  shellcheck,
  actionlint,
  writeShellScriptBin,
  withSneakyDiff ? true,
}:
let
  Find = "${findutils}/bin/find";
  Rg = "${ripgrep}/bin/rg";
  Fmt = "${formatter}/bin/treefmt";
  Statix = "${statix}/bin/statix";
  Deadnix = "${deadnix}/bin/deadnix";
  ShellCheck = "${shellcheck}/bin/shellcheck";

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

  ActionLint = "${if withSneakyDiff then actionlint-wrapped else actionlint}/bin/actionlint";
in
writeShellScriptBin "chaotic-nyx-lint" ''
  set -euo pipefail

  ${Fmt} --ci
  ${Statix} check .
  ${Deadnix} --fail .

  _SHORT_FILES=$(${Find} . -type f -name '*.nix' | (xargs ${Rg} -P '[^\w"-\/\{](?!_?xs|_?id|_?[kvx]:)(_?[a-zA-Z_][a-zA-Z_-]?:)(?!\w)' || true))
  if [[ -n "$_SHORT_FILES" ]]; then
    echo "Lambda parameters can't have two letters or less (except: x, xs, id, k, v):"
    echo "$_SHORT_FILES"
    exit 1
  fi

  ${Find} . -type f -name '*.sh' | xargs -r ${ShellCheck} -a
  ${ActionLint}
''

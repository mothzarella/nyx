{
  lib,
  writeShellScriptBin,
  nixfmt-tree,
  prettier,
  shellcheck,
  shfmt,
  ...
}:
let
  nixFormatter = nixfmt-tree.override {
    settings = {
      tree-root-file = ".git/index";
      excludes = [
        "maintenance/failures.aarch64-darwin.nix"
        "maintenance/failures.aarch64-linux.nix"
        "maintenance/failures.x86_64-linux.nix"
      ];
      formatter.nixfmt = {
        command = "nixfmt";
        includes = [ "*.nix" ];
      };
    };
  };

  script = ''
    set -euo pipefail

    ${lib.getExe nixFormatter} "$@"

    filtered_args=()
    for arg in "$@"; do
        if [[ ! "$arg" == -* ]]; then
            filtered_args+=("$arg")
        else
          echo 'Unable to run other formatters with these arguments.' >&2
          exit 0
        fi
    done

    ${lib.getExe shfmt} -w "''${filtered_args[@]}"
    ${lib.getExe prettier} -lw "''${filtered_args[@]}"

    filtered_scripts=()
    for arg in "$@"; do
        if [[ ! "$arg" == -* ]] && [[ "$arg" == *.sh ]]; then
            filtered_scripts+=("$arg")
        fi
    done

    if [ "''${#filtered_scripts[@]}" -gt 0 ]; then
      _SHELLCHECK_OUT=$(${lib.getExe shellcheck} -af diff "''${filtered_scripts[@]}")
      [ -n "$_SHELLCHECK_OUT" ] && echo "$_SHELLCHECK_OUT" | git apply
    fi
  '';
in
(writeShellScriptBin "chaotic-nyx-formatter" script).overrideAttrs (prevAttrs: {
  passthru = prevAttrs.passthru // {
    inherit nixFormatter;
  };
})

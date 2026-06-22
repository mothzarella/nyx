{
  writeShellScript,
  lib,
  coreutils,
  curl,
  git,
  jq,
  moreutils,
  nix,
  git-cinnabar,
}:

let
  path = lib.makeBinPath [
    coreutils
    curl
    git
    jq
    moreutils # sponge
    nix # nix store prefetch-file
    git-cinnabar
  ];
in
writeShellScript "firefox-nightly-update" ''
  set -euo pipefail

  export PATH=${path}

  version_json="''${VERSION_JSON:-pkgs/firefox-nightly/version.json}"
  mozilla_versions_url="https://product-details.mozilla.org/1.0/firefox_versions.json"
  github_repo="https://github.com/mozilla-firefox/firefox"
  hg_repo="https://hg-edge.mozilla.org/mozilla-central"

  fetch_json() {
    curl -fsSL "$1"
  }

  json_field() {
    jq -er "$1"
  }

  git_short() {
    printf '%s' "$1" | cut -c1-9
  }

  latest_version=$(
    fetch_json "$mozilla_versions_url" |
      json_field '.FIREFOX_NIGHTLY'
  )

  local_version=$(jq -er '.version' "$version_json")
  local_rev=$(jq -er '.rev' "$version_json")

  nightly_metadata_url="https://archive.mozilla.org/pub/firefox/nightly/latest-mozilla-central/firefox-$latest_version.en-US.linux-x86_64.json"

  latest_hg_rev=$(
    fetch_json "$nightly_metadata_url" |
      json_field '.moz_source_stamp'
  )

  tmpdir=$(mktemp -d)
  trap 'rm -rf "$tmpdir"' EXIT

  map_dir="$tmpdir/ff-map"

  git init --quiet "$map_dir"

  git -C "$map_dir" \
    -c cinnabar.graft="$github_repo" \
    cinnabar fetch \
    "hg::$hg_repo" \
    "$latest_hg_rev"

  latest_rev=$(
    git -C "$map_dir" cinnabar hg2git "$latest_hg_rev"
  )

  if [ "$local_rev" = "$latest_rev" ]; then
    echo "firefox-nightly is already up to date: $local_version-$(git_short "$local_rev")"
    exit 0
  fi

  latest_url="https://codeload.github.com/mozilla-firefox/firefox/tar.gz/$latest_rev"

  latest_hash=$(
    nix --extra-experimental-features nix-command \
      store prefetch-file \
      --json \
      --hash-type sha256 \
      --name "firefox.tar.gz" \
      "$latest_url" |
      jq -er '.hash'
  )

  jq \
    --arg version "$latest_version" \
    --arg rev "$latest_rev" \
    --arg hash "$latest_hash" \
    '
      .rev = $rev
      | .version = $version
      | .hash = $hash
    ' \
    "$version_json" |
    sponge "$version_json"

  git add "$version_json"

  git commit -m "firefox-nightly: $local_version-$(git_short "$local_rev") -> $latest_version-$(git_short "$latest_rev")"
''

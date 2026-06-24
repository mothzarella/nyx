{
  lib,
  current ? importJSON ./version.json,
  importJSON ? lib.trivial.importJSON,
  buildMozillaMach,
  callPackage,
  fetchurl,
  nss_git,
  nyxUtils,
  stdenv,
  # Temporary fixes:
  rust-cbindgen,
  fetchFromGitHub,
  rustPlatform,
  apple-sdk_26,
}:

let
  rust-cbindgen_latest =
    if rust-cbindgen.version == "0.29.2" then
      rust-cbindgen.overrideAttrs (prevAttrs: rec {
        version = "0.29.4";

        src = fetchFromGitHub {
          owner = "mozilla";
          repo = "cbindgen";
          tag = "v${version}";
          hash = "sha256-leeHOwpzXuzg2cTjXehBnCsS+dvU4eIIFtWKeCee20U=";
        };

        cargoDeps = rustPlatform.fetchCargoVendor {
          inherit src;
          inherit (prevAttrs.cargoDeps) name;
          hash = "sha256-f6YoDoiVoh0BVPYHFO1FsdI4OCsF+LY72QaD57StdIQ=";
        };
      })
    else
      rust-cbindgen;

  binaryName = "firefox-nightly";

  mach = buildMozillaMach {
    pname = "firefox-nightly";
    inherit binaryName;
    version = with current; "${version}-${buildId}-${builtins.substring 0 7 rev}";
    applicationName = "Firefox Nightly";
    requireSigning = false;
    branding = "browser/branding/nightly";
    src = fetchurl {
      inherit (current) hash;
      url = "https://codeload.github.com/mozilla-firefox/firefox/tar.gz/${current.rev}";
      name = "firefox.tar.gz";
    };

    meta = {
      description = "Web browser built from Firefox Nightly source tree";
      homepage = "https://www.firefox.com/";
      maintainers = with lib.maintainers; [ pedrohlc ];
      platforms = lib.platforms.unix;
      broken = stdenv.buildPlatform.is32bit;
      maxSilent = 14400;
      license = lib.licenses.mpl20;
      mainProgram = binaryName;
    };

    updateScript = callPackage ./update.nix { };
  };

  postOverride = prevAttrs: {
    patches =
      nyxUtils.removeByBaseNames [
        "133-env-var-for-system-dir.patch"
        "136-no-buildconfig.patch"
        "139-wayland-drag-animation.patch"
        "140-bindgen-string-view.patch"
      ] (prevAttrs.patches or [ ])
      ++ [
        ./env_var_for_system_dir-ff-unstable.patch
        ./no-buildconfig-ffx-unstable.patch
        ./relax-apple-sdk.patch
      ];

    env = (prevAttrs.env or { }) // {
      MOZ_SOURCE_REPO = "https://github.com/mozilla-firefox/firefox";
      MOZ_SOURCE_CHANGESET = current.rev;
      MOZ_INCLUDE_SOURCE_INFO = "1";
    };

    nativeBuildInputs = map (
      pkg: if pkg.pname or "" == "rust-cbindgen" then rust-cbindgen_latest else pkg
    ) (prevAttrs.nativeBuildInputs or [ ]);

    buildInputs =
      (prevAttrs.buildInputs or [ ])
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        apple-sdk_26
      ];

    passthru = (prevAttrs.passthru or { }) // {
      rust-cbindgen = rust-cbindgen_latest;
    };
  };

  newInputs = {
    nss_latest = nss_git;
  };
in
nyxUtils.multiOverride mach newInputs postOverride

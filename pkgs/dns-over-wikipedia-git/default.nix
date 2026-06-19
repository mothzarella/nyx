{
  lib,
  fetchFromGitHub,
  callPackage,
  rustPlatform,
  pkg-config,
  openssl,
}:

let
  current = lib.trivial.importJSON ./version.json;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "dns-over-wikipedia";
  inherit (current) version cargoHash;

  src = fetchFromGitHub {
    owner = "aaronjanse";
    repo = "dns-over-wikipedia";
    inherit (current) rev hash;
  };

  sourceRoot = "${finalAttrs.src.name}/hosts-file";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  postUnpack = ''
    test -s ${finalAttrs.sourceRoot}/Cargo.lock
    cp ${./Cargo.lock} ${finalAttrs.sourceRoot}/Cargo.lock
  '';

  postPatch = ''
    substituteInPlace src/main.rs \
      --replace-fail \
        'server.listen("127.0.0.1:80").unwrap();' \
        'server.listen(std::env::var("IDK_DNS_BIND_ADDR").unwrap_or_else(|_| "127.0.0.1:80".to_string())).unwrap();'
  '';

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit (finalAttrs) pname;
    nyxKey = "dns-over-wikipedia_git";
    versionPath = "pkgs/dns-over-wikipedia-git/version.json";
    fetchLatestRev = callPackage ../../shared/github-rev-fetcher.nix { } "master" finalAttrs.src;
    gitUrl = finalAttrs.src.gitRepoUrl;
    hasCargo = true;
  };

  meta = {
    description = "Redirect `.idk` domains using Wikipedia";
    homepage = "https://github.com/aaronjanse/dns-over-wikipedia/tree/master/hosts-file";
    license = with lib.licenses; [ publicDomain ];
    maintainers = with lib.maintainers; [ pedrohlc ];
  };
})

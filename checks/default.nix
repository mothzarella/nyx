flakes: pkgs: {
  all-in-one = import ./all-in-one.nix {
    inherit (flakes) nixpkgs;
    chaotic = flakes.self;
  } pkgs;
}

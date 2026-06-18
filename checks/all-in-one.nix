# Run with:
# nix run .#checks.x86_64-linux.all-in-one.driverInteractive
{
  nixpkgs,
  chaotic,
}:

import "${nixpkgs}/nixos/tests/make-test-python.nix" (
  { lib, ... }:
  {
    name = "chaotic-nyx-one";
    meta.maintainers = with lib.maintainers; [ pedrohlc ];

    nodes.machine = _inputs: {
      imports = [
        chaotic.nixosModules.default
        "${nixpkgs}/nixos/tests/common/user-account.nix"
        ./modules/autologin.nix
        ./modules/cachyos.nix
        ./modules/mesa-git.nix
        ./modules/plymouth.nix
        ./modules/virgl-venus.nix
      ];

      virtualisation.memorySize = 16 * 1024;
    };

    # TODO: TODO
    testScript = ''
      start_all()

      machine.wait_for_unit("graphics.target")


    '';
  }
)

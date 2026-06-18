{ pkgs, ... }:
{
  # Stuff to test mesa-git
  chaotic.mesa-git.enable = true;

  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    alacritty
  ];
}

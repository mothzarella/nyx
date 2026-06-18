_inputs:
let
  testingDM = "sddm"; # "sddm" | "gdm"
  testingDE = "plasma6"; # "plasma6" | "gnome"
  testingSession = "plasma"; # "gnome" | "plasma"
  testingWithAutoLogin = true;
in
{
  services = {
    xserver.enable = true;
    displayManager = {
      "${testingDM}".enable = true;
      autoLogin = {
        enable = testingWithAutoLogin;
        user = "alice";
      };
      defaultSession = testingSession;
    };
    desktopManager.${testingDE}.enable = true;
  };
}

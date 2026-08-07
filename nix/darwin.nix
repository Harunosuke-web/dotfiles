{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-darwin";
  system.primaryUser = "papicom";

  nix.settings.experimental-features = [
      "nix-command"
      "flakes"
  ];

  # sudoでTouch IDを使用。pam_reattachでtmux内からの認証にも対応する。
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
    };

    # finder = {
    #   AppleShowAllExtensions = true;
    #   ShowPathbar = true;
    # };
    #
    # NSGlobalDomain = {
    #   KeyRepeat = 2;
    #   InitialKeyRepeat = 15;
    # };
    #
    # trackpad = {
    #   Clicking = true;
    # };
  };

  # nix-darwinの互換性基準。
  # macOSのバージョンではないので、導入後にむやみに変更しない。
  system.stateVersion = 6;
}

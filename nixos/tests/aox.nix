import ./make-test-python.nix {
  name = "aox";

  machine = { pkgs, lib, ... }: {
    services.aox.enable = true;
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql; #_9_6;
      ensureDatabases = ["aox"];
      ensureUsers = [{
        name = "aox";
        ensurePermissions = {
          "DATABASE aox" = "ALL PRIVILEGES";
        };
      }];
      #enableTCPIP = true;
    };
  };

  testScript = ''
    machine.wait_for_unit("aox.service")
    machine.wait_for_open_port(143)
  '';
}

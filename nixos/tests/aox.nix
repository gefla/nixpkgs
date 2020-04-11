import ./make-test-python.nix {
  name = "aox";

  machine = { pkgs, lib, ... }: {
    services.aox.enable = true;
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
    };
  };

  testScript = ''
    machine.wait_for_unit("aox.service")
    machine.wait_for_open_port(143)
  '';
}

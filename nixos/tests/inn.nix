import ./make-test-python.nix ({ pkgs, ... } : let

in {

  name = "inn";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ gefla ];
  };

  nodes = {
    server = args: {
      services.postfix.enable = true;
      services.inn = {
        enable = true;
        domain = "test.invalid";
      };
    };
  };

  testScript = ''
    start_all()
    server.wait_for_unit("inn.service")
    server.succeed("[ -e /var/run/news/control ]")
  '';

})

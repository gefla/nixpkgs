import ./make-test-python.nix ({ pkgs, ... } : let
  name = "aox";

  runWithOpenSSL = file: cmd: pkgs.runCommand file {
    buildInputs = [ pkgs.openssl ];
  } cmd;

  keys_pem = runWithOpenSSL "key.pem" ''
    openssl req -x509 -nodes -newkey rsa:4096 -keyout $TMP/key.pem -out $TMP/cert.pem -days 365 -subj "/CN=aox" -config ${openssl_cnf}
    cat $TMP/key.pem $TMP/cert.pem >$out
  '';
  openssl_cnf = pkgs.writeText "openssl.cnf" ''
      ions = v3_req
      distinguished_name = req_distinguished_name
      [req_distinguished_name]
      [ v3_req ]
      basicConstraints = CA:FALSE
      keyUsage = digitalSignature, keyEncipherment
      extendedKeyUsage = serverAuth
      subjectAltName = @alt_names
      [alt_names]
      DNS.1 = node1
      DNS.2 = node2
      DNS.3 = node3
      IP.1 = 127.0.0.1
    '';
in {
  machine = { pkgs, lib, ... }: {
    services.aox = {
      enable = true;
      cert = "${keys_pem}";
    };
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
    };
    environment.systemPackages = let
      testImap = pkgs.writeScriptBin "test-imap" ''
        #!${pkgs.python3.interpreter}
        import imaplib
        with imaplib.IMAP4('localhost') as imap:
          imap.login('alice', 'foobar')
          imap.select()
          status, refs = imap.search(None, 'ALL')
          assert status == 'OK'
          assert len(refs) == 1
      '';
      in [ testImap pkgs.archiveopteryx ];
  };

  testScript = ''
    machine.wait_for_unit("aox.service")
    machine.wait_for_open_port(143)
    machine.succeed("aox add user alice foobar testuser@test.invalid")
    machine.succeed("test-imap")
  '';
})

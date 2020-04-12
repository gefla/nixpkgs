{ config, lib, pkgs, ... }:

with lib;

let

  name = "aox";

  cfg = config.services.aox;

  aoxConf = ''
    db-address = ${cfg.dbAddress}
    db-name = ${cfg.dbName}
    db-user = ${cfg.dbUser}
    db-password = ${cfg.dbPassword}
    logfile = syslog/mail
    ${lib.optionalString (cfg.usePop) ''
      use-pop = true
    ''}
    ${lib.optionalString (cfg.lmtpAddress != null) ''
      lmtp-address = ${cfg.lmtpAddress}
      lmtp-port = ${cfg.lmtpPort}
    ''}
    log-level = info
    # Uncomment the following ONLY if necessary for debugging.
    #security = off
    #use-tls = false
    #use-imaps = true
    tls-certificate = ${cfg.cert}
    use-smtp-submit = false
    #use-http = true
    use-sieve = true
    memory-limit = 256
    ${cfg.extraConfig}
  '';

in

  {
    options.services.aox = {
      enable = mkEnableOption "Archiveopteryx, an IMAP server.";
      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra directives added to to the end of aox's configuration file,
          archiveopteryx.conf. Basic configuration like file location and uid/gid
          is added automatically to the beginning of the file. For available
          options see <literal>man 5 archiveopteryx.conf</literal>'.
        '';
      };
      usePop = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the POP3 server.
        '';
      };
      dbFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
         Change the following to tell smtpd(8) to accept connections on
         an address other than the default localhost.
        '';
      };
      dbUser = mkOption {
        type = types.str;
        default = name;
        description = "PostgreSQL database user";
      };
      dbPassword = mkOption {
        type = types.str;
        default = name;
        description = "PostgreSQL database password";
      };
      dbName = mkOption {
        type = types.str;
        default = "archiveopteryx";
        description = "PostgreSQL database name";
      };
      dbAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "PostgreSQL database address";
      };
      lmtpAddress = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "LMTP address to listen on. Disabled if null.";
      };
      cert = mkOption {
        type = types.str;
        default = null;
        description = "File containing combined key and certificate for TLS";
      };

    };

    config = mkIf cfg.enable {

      environment.etc."aox/archiveopteryx.conf".text = aoxConf;

      users.users.aox = {
        isSystemUser = true;
        group = "aox";
      };
      users.groups.aox = {};

      systemd.services.aox-init = {
        wantedBy = [ "multi-user.target" ];
        requires = [ "postgresql.service" ];
        after = [ "postgresql.service" ];
        path = [ pkgs.postgresql ];
        preStart = ''
          mkdir -p /var/lib/aox/jail
          chmod 001 /var/lib/aox/jail
          systemctl status postgresql.service
          PSQL="${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql"
          #$PSQL -c "ALTER USER aox PASSWORD 'aox'" aox
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = ''
            ${pkgs.archiveopteryx}/lib/installer -s /var/run/postgresql/.s.PGSQL.5432
          '';
        };
      };
      systemd.services.aox = {
        description = "Aox IMAP server";
        after = [ "aox-init.service" ];
        requires = [ "aox-init.service" ];
        wantedBy = [ "multi-user.target" ];

        path = [ pkgs.openssl ];
        preStart = ''
            PSQL="${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql"
            $PSQL <<__EOF
            \l
            \c archiveopteryx
            \d
            __EOF
          '';
        serviceConfig = {
          Type = "forking";
          PIDFile = "/run/aox/archiveopteryx.pid";
          ExecStart = "${pkgs.archiveopteryx}/bin/aox -v -v start";
          Restart = "on-failure";
          LogsDirectory = "aox";
          RuntimeDirectory = "aox";
          RuntimeDirectoryPreserve = "yes";
          StateDirectory = "aox";
          #StateDirectoryMode = "001";
        };
      };

      environment.systemPackages = [ pkgs.archiveopteryx ];
    };
  }

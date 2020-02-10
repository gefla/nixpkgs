{ stdenv, fetchurl, perlPackages
, sendmailPath ? "/run/wrappers/bin/sendmail"
}:

stdenv.mkDerivation rec {
  name = "inn-${version}";

  version = "2.6.3";

  src = fetchurl {
    url = "https://ftp.isc.org/isc/inn/${name}.tar.gz";
    sha256 = "bd914ac421f8e71a36dc95cef0655a05dd162eb68f5893cc4028642209015256";
  };

  patches = [
    ./disable-site-install.patch
  ];

  buildInputs = with perlPackages; [
    perl GD MIMETools
  ];

  configureFlags = [
    "--with-sendmail=${sendmailPath}"
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--disable-rpath"
  ];
  #makeFlags = [ "DESTDIR=$(out) " ];
  installFlags = "CHOWNPROG=set CHGRPPROG=set";

  meta = {
    homepage = https://www.eyrie.org/~eagle/software/inn/;
    description = "An extremely flexible and configurable Usenet / Netnews news server";
    # Mostly BSD, but some parts are GPL v2 or later
    license = stdenv.lib.licenses.gpl2Plus;
    platforms = stdenv.lib.platforms.unix;
    maintainers = with stdenv.lib.maintainers; [ gefla ];
  };
}

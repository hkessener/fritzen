# fritzen

  Process FRITZ!Box configuration data using the TR-064 protocol

# Installation

  1. Extract archive to your preferred location/folder.
  2. Set appropriate file ownership and permissions of fritzen.cfg to avoid unauthorized access.

# Usage

  ./fritzen.pl --help

  or

  perldoc fritzen.pl

# Required perl modules

  AppConfig
  Config::Std
  Cwd
  FindBin::libs
  Git::Repository
  HTTP::Daemon
  HTTP::Daemon:SSL
  HTTP::Status
  Log::Log4perl
  LWP::UserAgent
  Net::Address::IP::Local
  Net::Fritz
  Pod::Usage
  URI

# Installation of required perl modules with apt-get

  sudo apt-get install libappconfig-perl libconfig-std-perl libfindbin-libs-perl libgit-repository-perl libhttp-daemon-perl libhttp-daemon-ssl-perl libhttp-message-perl liblog-log4perl-perl libwww-perl libnet-address-ip-local-perl

# Installation of other perl modules with apt-get (in preparation for CPAN installation of Net::Fritz)

  sudo apt-get install libxml-simple-perl libxml-parser-perl libsoap-lite-perl

# Installation of Net::Fritz from CPAN

  sudo cpan

  cpan[1]> install Net::Fritz

# Troubleshooting installation failure of HTTP::Daemon::SSL when using CPAN

  (see bug info: https://rt.cpan.org/Public/Bug/Display.html?id=88998)

  1. Change to your CPAN distroprefs directory

    cd ~/.cpan/prefs/

  2. Get YAML file with patch information

    sudo curl -o HTTP-Daemon-SSL.yml https://raw.githubusercontent.com/eserte/srezic-cpan-distroprefs/master/HTTP-Daemon-SSL.yml

    or

    sudo wget -O HTTP-Daemon-SSL.yml https://raw.githubusercontent.com/eserte/srezic-cpan-distroprefs/master/HTTP-Daemon-SSL.yml

  3. Change to home directory & start CPAN

    sudo cpan

  4. Install YAML (unless installed)

    cpan[1]> install YAML

  5. Install HTTP::Daemon::SSL with patch

    cpan[2]> install HTTP::Daemon::SSL


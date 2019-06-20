#!/usr/bin/perl

use lib '.';

use strict; 
use warnings;

use FindBin::libs;
use AppConfig;
use Git::Repository;
use Net::Fritz::Box;
use Log::Log4perl;
use Pod::Usage;

use Fritzen::Config;
use Fritzen::Common;
use Fritzen::DeviceConfig;
use Fritzen::DeviceInfo;
use Fritzen::OnTel;
use Fritzen::WANDSLInterfaceConfig;

#####################################################################
# fritzen.pl
#####################################################################

# start with initial config
my $Config = GetInitialConfig();

# get command line arguments
$Config->args();

# show help if requested
if(defined $Config->help) {
  pod2usage(1);
}

# read config file
if($Config->cfgfile eq Fritzen::Config::DEFAULT_CFGFILE) {
  # read from default location if file exists
  $Config->file($Config->cfgfile) if(-f $Config->cfgfile);
} else {
  # read from given location
  $Config->file($Config->cfgfile) or
  die 'cannot read config file '.$Config->cfgfile;
}

# check config
unless(CheckConfig($Config)) {
  pod2usage(2);
}
 
# initialize logging
InitLogger($Config) or die;
my $Log = Log::Log4perl->get_logger();

# change to working directory
if($Config->workdir ne Fritzen::Config::DEFAULT_WORKDIR) {
  unless(chdir($Config->workdir)) {
    $Log->logexit('cannot change to working directory '.$Config->workdir);
  }
}

# do the git init
if(defined $Config->git) {
  unless(Git::Repository->run(init => '.')) {
    $Log->logexit('failed to initialize git repository');
  }
}

#####################################################################
# connect to fritzbox

my $Fritz = Net::Fritz::Box->new(
  username => $Config->username,
  password => $Config->password,
  upnp_url => $Config->deviceurl,
);
if($Fritz->error) {
  $Log->logexit($Fritz->error);
}

# run discovery  
my $Device = $Fritz->discover();
if($Device->error) {
  $Log->logexit($Device->error);
}

#####################################################################
# check service

my $Wrapper; # service wrapper

if($Config->service eq 'deviceconfig') {
  $Wrapper = Fritzen::DeviceConfig->new(
    Device => $Device,
    Config => $Config,
  );
} elsif($Config->service eq 'deviceinfo') {
  $Wrapper = Fritzen::DeviceInfo->new(
    Device => $Device
  );
} elsif($Config->service eq 'ontel') {
  $Wrapper = Fritzen::OnTel->new(
    Device => $Device,
    Config => $Config,
  );
} elsif($Config->service eq 'wandslinterfaceconfig') {
  $Wrapper = Fritzen::WANDSLInterfaceConfig->new(
    Device => $Device
  );
} else {
  $Log->logexit('service unknown');
}

defined($Wrapper) or $Log->logexit('service unavailable');

#####################################################################
# run action and/or task

if(defined $Config->action) {
  $Log->debug('running action '.$Config->action.' of service '.$Config->service);
  unless($Wrapper->RunAction($Config->action)) {
    $Log->warn('error');
  }
}

if(defined $Config->task) {
  $Log->debug('running task '.$Config->task.' for service '.$Config->service);
  if($Wrapper->RunTask($Config->task)) {
    if(defined $Config->git) {
      Git::Repository->run(add => '*');
      Git::Repository->run(commit => '-m',qq|$0|);
    }
  } else {
    $Log->warn('error');
  }
}

#####################################################################
__END__

=head1 NAME

fritzen.pl

=head1 DESCRIPTION

Process FRITZ!Box configuration data using the TR-064 protocol.

=head1 SYNOPSIS

fritzen.pl --service <value> --action <value> [other options...]

fritzen.pl --service <value> --task   <value> [other options...]

 Options:
   -s,--service		deviceconfig | deviceinfo | ...
   -a,--action		getinfo | getsecurityport | ...
   -t,--task		backup | restore | ...

   -u,--username	SOAP username
   -p,--password	SOAP password
   -d,--deviceurl	UPnP URL of fritzbox

   -c,--cfgfile		config filename
   -l,--logfile		log filename
   -v,--loglevel	debug | info | warn

   -w,--workdir		working directory
   -g,--git		git init/commit

   -q,--quiet		suppress screen messages
   -h,--help		show help screen

   --configpw		password for config file protection

   --serverproto	internal webserver protocol
   --serveraddr		internal webserver ip address
   --serverport		internal webserver tcp port
   --sslcertfile	internal webserver ssl certificate file
   --sslkeyfile		internal webserver ssl private key file

=head1 OPTIONS

=over 4

=item B<-s, --service>

TR-064 service (mandatory): B<deviceconfig>, B<deviceinfo> or B<ontel>

=item B<-a, --action>

TR-064 action to perform. Either an action or a task must be given.

List of actions for service B<deviceconfig>:

- B<factory-reset>: Reset fritzbox to factory settings. Use with care!

- B<reboot>: Reboot fritzbox. Note: The fritzbox will reboot itself automatically approx. 30 seconds after restore from file.

List of actions for service B<deviceinfo>:

- B<getinfo>: Get miscellaneous information about fritzbox hardware and software.

- B<getsecurityport>: Get HTTPS port of fritzbox for secure information.

List of actions for service B<ontel>:

B<none>

List of actions for service B<wlandslinterfaceconfig>:

- B<getinfo>: Get status information about current DSL connection

- B<getstatisticstotal>: Get statistics on current DSL connection

- B<getdsldiagnoseinfo>: Returns the state of a DSL diagnose

=item B<-t, --task>

Task to perform. Either an action or a task must be given.

List of tasks for service B<deviceconfig>:

- B<backup>: Backup fritzbox configuration to file.

- B<restore>: Restore fritzbox configuration from file.

List of tasks for service B<deviceinfo>:

B<none>

List of actions for service B<ontel>:

- B<backup> : Backup all phonebooks to files.

- B<backup:id> : Backup phonebook from file by ID. For example "--action backup:1" will back up the phonebook with ID #1.

- B<delete>: Delete all phonebooks on the FRITZ!Box. The phonebooks will be deleted top-down, starting with the highest ID first.

- B<delete:id> : Delete phonebook identified by ID on the FRITZ!Box. Note that phonebooks with IDs above ID will "slide down" and the FRITZ!Box will reassign them new IDs. As a result, phonebook IDs on the FRITZ!Box and the respective backup file numbering will be out of sync and require manual rework.

- B<list>: List available phonebooks on the FRITZ!Box.

- B<restore> : Restore all phonebooks from files.

- B<restore:id> : Restore phonebook by ID from file.

=item B<-u, --username>

SOAP username (better use config file)

=item B<-p, --password>

SOAP password (better use config file)

=item B<-d, --deviceurl>

UPnP URL of fritzbox (default: B<http://fritz.box:49000>)

=item B<-c, --cfgfile>

Config filename (default: B<fritzen.cfg>)

=item B<-l, --logfile>

Log filename (default: B<fritzen.log>)

=item B<-v, --loglevel>

Log level: B<debug>, B<info> or B<warn> (default: B<info>).

=item B<-w, --workdir>

Working directory (default: current directory). Must be writeable. This is where all backed up files will be stored and a git repository will be initialized (if option B<--git> is set). It is recommended to use distinct and different working directories for different devices and/or sets of configuration data.

=item B<-g, --git>

Commit files to git repository (switch, default: B<false>). Init git repository in working directory if not already done.

=item B<-q, --quiet>

Suppress screen messages i. e. when running in cronjob (switch, default: B<false>).

=item B<--configpw>

Password for config file protection. If unset the SOAP passsord will be used.

=item B<--serverproto>

Serve files for fritzbox either with B<HTTP> or B<HTTPS> protocol (default: B<http>). The module HTTP::Daemon::SSL is required for HTTPS. Use B<http> if the installation of HTTP::Daemon::SSL fails on your system and edit Fritzen/Common.pm to set "SSL_AVAILABLE => 0".

=item B<--serveraddr>

Serve files for fritzbox with this IP address (default: auto-discovered IPv4 address of your system)

=item B<--serverport>

Serve files for fritzbox with this TCP port (default: B<8888>)

=item B<--sslcertfile>

SSL certificate file for HTTPS server (default: B<ssl/ssl-cert-snakeoil.pem>)

=item B<--sslkeyfile>

SSL key file for HTTPS server (default: B<ssl/ssl-cert-snakeoil.key>)

=item B<-h, --help>

Print this help screen and exit.

=back

=cut

#####################################################################
1;

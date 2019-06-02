package Fritzen::Config;

use strict;
use warnings;

use AppConfig;
use Cwd;
use Net::Address::IP::Local;
  
use base 'Exporter';
  
our @EXPORT = qw(GetInitialConfig CheckConfig);

=head1 NAME
  
Fritzen::Config - fritzen config related functions

=cut

use constant {
  DEFAULT_USERNAME    => 'soap_user',
  DEFAULT_PASSWORD    => 'soap_pass',
  DEFAULT_DEVICEURL   => 'http://fritz.box:49000',
  DEFAULT_WORKDIR     => cwd(),
  DEFAULT_CFGFILE     => cwd().'/'.'fritzen.cfg',
  DEFAULT_LOGFILE     => cwd().'/'.'fritzen.log',
  DEFAULT_LOGLEVEL    => 'INFO',
  DEFAULT_SERVERPROTO => 'http',
  DEFAULT_SERVERADDR  => Net::Address::IP::Local->public_ipv4,
  DEFAULT_SERVERPORT  => '8888',
  DEFAULT_SSLCERTFILE => cwd().'/ssl/ssl-cert-snakeoil.pem',
  DEFAULT_SSLKEYFILE  => cwd().'/ssl/ssl-cert-snakeoil.key',
};

######################################################################
sub GetInitialConfig() {

  my $Config = AppConfig->new(
    # SOAP credentials
    'username|u=s' , { DEFAULT => DEFAULT_USERNAME },
    'password|p=s' , { DEFAULT => DEFAULT_PASSWORD },
    # UPNP URL of fritzbox
    'deviceurl|d=s', { DEFAULT => DEFAULT_DEVICEURL },
    # working directory
    'workdir|w=s'  , { DEFAULT => DEFAULT_WORKDIR },
    # configuration file
    'cfgfile|c=s'  , { DEFAULT => DEFAULT_CFGFILE },
    # log file
    'logfile|l=s'  , { DEFAULT => DEFAULT_LOGFILE },
    # log level
    'loglevel|v=s' , { DEFAULT => DEFAULT_LOGLEVEL },
    # mandatory parameters without defaults
    'action|a=s', 'task|t=s', 'service|s=s',
    # flags without defaults
    'git|g', 'quiet|q', 'help|h|?',
    # parameters without defaults
    'configpw=s',
    # server and ssl settings
    'serverproto=s', { DEFAULT => DEFAULT_SERVERPROTO },
    'serveraddr=s' , { DEFAULT => DEFAULT_SERVERADDR },
    'serverport=s' , { DEFAULT => DEFAULT_SERVERPORT },
    'sslcertfile=s', { DEFAULT => DEFAULT_SSLCERTFILE },
    'sslkeyfile=s' , { DEFAULT => DEFAULT_SSLKEYFILE },
  );

  return $Config;
}
######################################################################
sub CheckConfig($) {
  my($Config) = @_ or die;

  # mandatory parameters set?
  return undef unless(defined $Config->service);
  $Config->service(lc($Config->service));

  unless(defined $Config->action) {
     return undef unless(defined $Config->task);
     $Config->task(lc($Config->task));
  }
  unless(defined $Config->task) {
     return undef unless(defined $Config->action);
     $Config->action(lc($Config->action));
  }

  # credentials given?
  return undef unless(defined $Config->username);
  return undef unless(defined $Config->password);
  unless(defined $Config->configpw) {
     $Config->configpw($Config->password);
  }
  
  # optional parameters valid?
  my $LogLevel = uc($Config->loglevel);
  unless($LogLevel =~ /^DEBUG$|^INFO$|^WARN$/) {
    $LogLevel = DEFAULT_LOGLEVEL;
    warn(qq|loglevel invalid, using $LogLevel|);
  }
  $Config->loglevel($LogLevel);

  my $ServerProto = lc($Config->serverproto);
  unless($ServerProto =~ /^http$|^https$/) {
    $ServerProto = DEFAULT_SERVERPROTO;
    warn(qq|serverproto invalid, using $ServerProto|);
  }
  $Config->serverproto($ServerProto);

  my $ServerPort  = abs(int($Config->serverport));
  unless($ServerPort >= 1024) {
    $ServerPort = DEFAULT_SERVERPORT;
    warn(qq|serverport invalid, using $ServerPort|);
  }
  $Config->serverport($ServerPort);

  return 1;

}
######################################################################
1;

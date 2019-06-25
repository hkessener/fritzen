package Fritzen::Common;

use strict;
use warnings;

use AppConfig;
use HTTP::Daemon;
use HTTP::Status;
use Log::Log4perl;
use LWP::UserAgent;
use URI;
  
use base 'Exporter';
  
our @EXPORT = qw(InitLogger DownloadFile ServeFile);

=head1 NAME
  
Fritzen::Common

Common functions

=cut

# set this to 1 if HTTP::Daemon::SSL is available
use constant SSL_AVAILABLE => 0;
# realms used by Fritzbox; new with FritzOS 6.8
use constant HTTP_REALM  => 'HTTP Access';
use constant HTTPS_REALM => 'HTTPS Access';
######################################################################
sub InitLogger($) {
  my($Config) = @_;

  my $LogFile  = $Config->logfile;
  my $LogLevel = $Config->loglevel;
  my $Quiet    = $Config->quiet;

  my $LogConf;

  unless(defined $Quiet) {
    # log to screen and file
    $LogConf = qq|
    log4perl.rootLogger              = $LogLevel, Screen, File
    log4perl.appender.File           = Log::Log4perl::Appender::File
    log4perl.appender.File.filename  = $LogFile
    log4perl.appender.File.mode      = append
    log4perl.appender.File.layout    = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.File.layout.ConversionPattern = %d %p %m %n
    log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr  = 0
    log4perl.appender.Screen.layout  = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = %m %n
    |;
  } else {
    # log to file only
    $LogConf = qq|
    log4perl.rootLogger              = $LogLevel, File
    log4perl.appender.File           = Log::Log4perl::Appender::File
    log4perl.appender.File.filename  = $LogFile
    log4perl.appender.File.mode      = append
    log4perl.appender.File.layout    = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.File.layout.ConversionPattern = %d %p %m %n
    |;
  }

  Log::Log4perl::init(\$LogConf) or return undef;

  return 1;
}
######################################################################
sub DownloadFile($$$) {
  my($Config,$URL,$FileName) = @_;

  my $Log = Log::Log4perl->get_logger();

  my $UserAgent = LWP::UserAgent->new();
     $UserAgent->ssl_opts(verify_hostname => 0,
                          SSL_verify_mode => 0);

  my $URI = URI->new($URL);
  my $Host = $URI->host();
  my $Port = $URI->port();

  # do embrace if $Host is an ipv6 address
  $Host = "[$Host]" if($Host =~ /:/);

  $UserAgent->credentials("$Host:$Port",HTTP_REALM ,$Config->username,$Config->password);
  $UserAgent->credentials("$Host:$Port",HTTPS_REALM,$Config->username,$Config->password);

  my $Response = $UserAgent->get($URL);
    
  unless($Response->is_success) {
    my $status_line = $Response->status_line;
    $Log->warn(qq|cannot download from URL "$URL" -- $status_line|);
    return undef;
  }
            
  unless(open(FILE,">$FileName")) {
    $Log->warn(qq|cannot open file "$FileName"|);
    return undef;
  }
    
  binmode(FILE,":utf8");
  print FILE $Response->decoded_content;
  close(FILE);

  $Log->debug(qq|wrote file "$FileName"|);

  return length($Response->decoded_content);    
}
######################################################################
sub ServeFile($$) {
  my($Config,$FileName) = @_;

  my $Log = Log::Log4perl->get_logger();

  my $ServerProto = $Config->serverproto;
  my $ServerAddr  = $Config->serveraddr;
  my $ServerPort  = $Config->serverport;
  my $SSLCertFile = $Config->sslcertfile;
  my $SSLKeyFile  = $Config->sslkeyfile;

  my $Daemon;
  if($ServerProto eq 'http') {
    $Daemon = HTTP::Daemon->new(
      LocalAddr => $ServerAddr,
      LocalPort => $ServerPort,
      Reuse   => 1, # avoid warning "address already in use"
      Timeout => 4, # should be appropriate for all fb variants
    ) or $Log->logexit('cannot start HTTP::Daemon');
  } elsif($ServerProto eq 'https') {
    use if SSL_AVAILABLE, 'HTTP::Daemon::SSL';
    $Daemon = HTTP::Daemon::SSL->new(
      LocalAddr => $ServerAddr,
      LocalPort => $ServerPort,
      Reuse   => 1, # avoid warning "address already in use"
      Timeout => 4, # should be appropriate for all fb variants
      SSL_cert_file => $SSLCertFile,
      SSL_key_file  => $SSLKeyFile,
    ) or $Log->logexit('cannot start HTTPS::Daemon');
  } else {
    $Log->logexit(qq|invalid protocol: $ServerProto|);
    return undef;
  }

  my $Success = 0;

  unless(my $ClientConn = $Daemon->accept()) {
    # got no get-request within timeout period
    $Log->warn('timeout reached before receiving get-request');
  } else {
    my $Request = $ClientConn->get_request();

    if($Request->method eq 'GET' and $Request->url->path eq "/$FileName") {
      # got a get-request asking for filename
      $ClientConn->send_file_response($FileName);
      $Success = 1;
      $Log->debug(qq|sent file "$FileName"|);
    } else {
      # got any other kind of request
      $ClientConn->send_error(RC_FORBIDDEN);
      $Log->debug(qq|got invalid GET request: |.$Request->url->path);
    }

    $ClientConn->close();
    undef($ClientConn);
  }

  return $Success;
}
######################################################################
1;

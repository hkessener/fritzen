package Fritzen::DeviceConfig;

use strict;
use warnings;

use AppConfig;
use Log::Log4perl;
use Net::Fritz::Box;
use Net::Address::IP::Local;

use Fritzen::Common;
  
=head1 NAME
  
Fritzen::DeviceConfig

Device Config related functions

=cut

use constant {
  DEFAULT_FILENAME => 'device_config.xml',
};

######################################################################
sub new {
  my($class,%args) = @_;

  my $self = bless({}, $class);

  # mandatory parameter: Net::Fritz::Device
  my $Device = $args{Device} or return undef;

  # check if device related service is available
  my $Service = $Device->find_service('DeviceConfig:1');

  if($Service->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Service->error);
    return undef;
  }

  $self->{Device}  = $Device;
  $self->{Service} = $Service;

  # mandatory parameter: AppConfig-object
  $self->{Config} = $args{Config} or return undef;

  return $self;
}
######################################################################
sub FactoryReset() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'FactoryReset',
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return 1;
}
######################################################################
sub Reboot() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'Reboot',
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return 1;
}
######################################################################
sub GetConfigFile() {
  my($self) = @_;

  my $Service = $self->{Service};
  my $Config  = $self->{Config};

  my $ConfigPW = $Config->configpw;
  my $FileName = DEFAULT_FILENAME;

  my $Response = $Service->call(
    'X_AVM-DE_GetConfigFile',
    'NewX_AVM-DE_Password' => $ConfigPW
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  my $ConfigFileUrl = $Response->data->{'NewX_AVM-DE_ConfigFileUrl'};

  return DownloadFile($Config,$ConfigFileUrl,$FileName);
}
######################################################################
sub SetConfigFile() {
  my($self) = @_;

  my $Service = $self->{Service};
  my $Config  = $self->{Config};

  my $ConfigPW = $Config->configpw;
  my $FileName = DEFAULT_FILENAME;

  my $ServerProto = $Config->serverproto;
  my $ServerAddr  = $Config->serveraddr;
  my $ServerPort  = $Config->serverport;

  # compose download url for FRITZ!Box
  my $ConfigFileUrl = qq|$ServerProto://$ServerAddr:$ServerPort/$FileName|;

  # spawn a "server"-child
  my $Pid = fork();

  if($Pid == 0) {
    # the child serves the file
    exit ServeFile($Config,$FileName);
  }

  # the parent issues the command
  my $Response = $Service->call(
    'X_AVM-DE_SetConfigFile',
    'NewX_AVM-DE_Password' => $ConfigPW,
    'NewX_AVM-DE_ConfigFileUrl' => $ConfigFileUrl,
  );

  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
  }

  # wait for the child
  wait();

  # and return the download result
  return $?;
}
######################################################################
sub RunAction($) {
  my($self,$Action) = @_;

  my $Log = Log::Log4perl->get_logger();

  if($Action eq 'factory-reset') {
    $Log->info(qq|A factory reset? Are you sure?|); 
    $Log->info(qq|Run again with "factory-reset-now".|); 
    return undef;
  }
  if($Action eq 'factory-reset-now') {
    return $self->FactoryReset();
  }
  if($Action eq 'reboot') {
    return $self->Reboot();
  }

  $Log->warn('unknown action: '.$Action);
  return undef;
}
######################################################################
sub RunTask($$) {
  my($self,$Task) = @_;

  my $Log = Log::Log4perl->get_logger();

  if($Task eq 'backup') {
    return $self->GetConfigFile();
  }
  if($Task eq 'restore') {
    return $self->SetConfigFile();
  }

  $Log->warn('unknown task: '.$Task);
  return undef;
}
######################################################################
1;

package Fritzen::WANDSLInterfaceConfig;

use strict;
use warnings;

use Log::Log4perl;
use Net::Fritz::Box;

use Fritzen::Common;
  
=head1 NAME
  
Fritzen::WANDSLInterfaceConfig

WAN/DSL Interface Config related functions

=cut

######################################################################
sub new {
  my($class,%args) = @_;

  my $self = bless({}, $class);

  # mandatory parameter: Net::Fritz::Device
  my $Device = $args{Device} or return undef;

  # check if device related service is available
  my $Service = $Device->find_service('WANDSLInterfaceConfig:1');

  if($Service->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Service->error);
    return undef;
  }

  $self->{Device}  = $Device;
  $self->{Service} = $Service;

  return $self;
}
######################################################################
sub GetInfo() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'GetInfo',
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return $Response->data;
}
######################################################################
sub GetStatisticsTotal() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'GetStatisticsTotal',
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return $Response->data;
}
######################################################################
sub GetDSLDiagnoseInfo() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'X_AVM-DE_GetDSLDiagnoseInfo',
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return $Response->data;
}
######################################################################
sub RunAction($) {
  my($self,$Action) = @_;

  my $Log = Log::Log4perl->get_logger();

  if($Action eq 'getinfo') {
    my $R = $self->GetInfo() or return undef;
    while(my($Key,$Value) = each %$R) {
      $Log->info(qq|$Key: $Value|);
    }
    return 1; 
  }
  if($Action eq 'getstatisticstotal') {
    my $R = $self->GetStatisticsTotal() or return undef;
    while(my($Key,$Value) = each %$R) {
      $Log->info(qq|$Key: $Value|);
    }
    return 1; 
  }
  if($Action eq 'getdsldiagnoseinfo') {
    my $R = $self->GetDSLDiagnoseInfo() or return undef;
    while(my($Key,$Value) = each %$R) {
      $Log->info(qq|$Key: $Value|);
    }
    return 1; 
  }

  $Log->warn('unknown action: '.$Action);
  return undef;
}
######################################################################
sub RunTask($) {
  my($self,$Task) = @_;

  my $Log = Log::Log4perl->get_logger();

  $Log->warn('unknown task: '.$Task);
  return undef;
}
######################################################################
1;

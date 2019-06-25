package Fritzen::WANCommonInterfaceConfig;

use strict;
use warnings;

use Log::Log4perl;
use Net::Fritz::Box;

use Fritzen::Common;
  
=head1 NAME
  
Fritzen::WANCommonInterfaceConfig

WAN Common Interface Configuration related functions

=cut

######################################################################
sub new {
  my($class,%args) = @_;

  my $self = bless({}, $class);

  # mandatory parameter: Net::Fritz::Device
  my $Device = $args{Device} or return undef;

  # check if device related service is available
  my $Service = $Device->find_service('WANCommonInterfaceConfig:1');

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
sub GetCommonLinkProperties() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'GetCommonLinkProperties',
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return $Response->data;
}
######################################################################
sub GetTotalBytesSent() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'GetTotalBytesSent',
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return $Response->data->{'NewTotalBytesSent'};
}
######################################################################
sub GetTotalBytesReceived() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'GetTotalBytesReceived',
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return $Response->data->{'NewTotalBytesReceived'};
}
######################################################################
sub GetTotalPacketsSent() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'GetTotalPacketsSent',
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return $Response->data->{'NewTotalPacketsSent'};
}
######################################################################
sub GetTotalPacketsReceived() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'GetTotalPacketsReceived',
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return $Response->data->{'NewTotalPacketsReceived'};
}
######################################################################
sub SetWANAccessType($) {
  my($self,$NewAccessType) = @_;

  my $Service = $self->{Service};

  my $Log = Log::Log4perl->get_logger();

  my %map = (
    'dsl'		=> 'DSL',
    'ethernet'		=> 'Ethernet',
    'fiber'		=> 'X_AVM-DE_Fiber',
    'x_avm-de_fiber'	=> 'X_AVM-DE_Fiber',
    'umts'		=> 'X_AVM-DE_UMTS',
    'x_avm-de_umts'	=> 'X_AVM-DE_UMTS',
    'cable'		=> 'X_AVM-DE_Cable',
    'x_avm-de_cable'	=> 'X_AVM-DE_Cable',
    'lte'		=> 'X_AVM-DE_LTE',
    'x_avm-de_lte'	=> 'X_AVM-DE_LTE',
  );

  unless(defined($NewAccessType)) {
    $Log->debug(qq|AccessType not set|);
    return undef;
  }

  unless(exists($map{$NewAccessType})) {
    $Log->debug(qq|AccessType unknown: $NewAccessType|);
    return undef;
  }

  $NewAccessType = $map{$NewAccessType};

  my $Response = $Service->call(
    'X_AVM-DE_SetWANAccessType',
    'NewAccessType' => $NewAccessType
  );
  if($Response->error) {
    $Log->debug($Response->error);
    return undef;
  }

  return $Response->data;
}
######################################################################
sub RunAction($) {
  my($self,$Action) = @_;

  my $Log = Log::Log4perl->get_logger();

  if($Action eq 'getcommonlinkproperties') {
    my $R = $self->GetCommonLinkProperties() or return undef;
    while(my($Key,$Value) = each %$R) {
      $Log->info(qq|$Key: $Value|);
    }
    return 1; 
  }
  if($Action eq 'gettotalbytessent') {
    my $R = $self->GetTotalBytesSent() or return undef;
    $Log->info(qq|$R|);
    return 1; 
  }
  if($Action eq 'gettotalbytesreceived') {
    my $R = $self->GetTotalBytesReceived() or return undef;
    $Log->info(qq|$R|);
    return 1; 
  }
  if($Action eq 'gettotalpacketssent') {
    my $R = $self->GetTotalPacketsSent() or return undef;
    $Log->info(qq|$R|);
    return 1; 
  }
  if($Action eq 'gettotalpacketsreceived') {
    my $R = $self->GetTotalPacketsReceived() or return undef;
    $Log->info(qq|$R|);
    return 1; 
  }
  if($Action =~ /^setwanaccesstype\:/) {
    my $NewAccessType = (split(/:/,$Action))[1];
    my $R = $self->SetWANAccessType($NewAccessType) or return undef;
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

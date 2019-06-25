package Fritzen::OnTel;

use strict;
use warnings;

use Config::Std;
use Log::Log4perl;
use Net::Fritz::Box;

use Fritzen::Common;
  
=head1 NAME
  
Fritzen::OnTel

Contact related functions

=cut

use constant {
  # printf format strings
  FMT_XML_FILENAME => 'phonebook.%u.xml', # %u --> phonebook ID
  FMT_BAK_FILENAME => 'phonebook.%u.bak', # %u --> phonebook ID
};

######################################################################
sub new {
  my($class,%args) = @_;
 
  my $self = bless({}, $class);

  # mandatory parameter: Net::Fritz::Device
  my $Device = $args{Device} or return undef;

  # check if phonebook related service is available
  my $Service = $Device->find_service('X_AVM-DE_OnTel:1');

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
sub GetPhonebookList() {
  my($self) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'GetPhonebookList'
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  my $Scalar = $Response->data->{'NewPhonebookList'};
  # comma separated list of indexes, i. e. "0,1,2"
  my @List = split(/,/,$Scalar);

  return @List;
}
######################################################################
sub GetPhonebookEntry($$) {
  my($self,$ID,$EntryID) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'GetPhonebookEntry',
    'NewPhonebookID' => $ID,
    'NewPhonebookEntryID' => $EntryID
  );
  if($Response->error) {
    # When blindly iterating over entries, the index may run
    # out of bounds. It's okay and we do not have be warned.
    unless($Response->error =~ /SpecifiedArrayIndexInvalid/) {
      my $Log = Log::Log4perl->get_logger();
         $Log->debug($Response->error);
    }
    return undef;
  }

  return $Response->data->{'NewPhonebookEntryData'};
}
######################################################################
sub SetPhonebookEntry($$$) {
  my($self,$ID,$EntryID,$EntryData) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'SetPhonebookEntry',
    'NewPhonebookID' => $ID,
    'NewPhonebookEntryID' => $EntryID,
    'NewPhonebookEntryData' => $EntryData
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return 1;
}
######################################################################
sub DeletePhonebookEntry($$) {
  my($self,$ID,$EntryID) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'DeletePhonebookEntry',
    'NewPhonebookID' => $ID,
    'NewPhonebookEntryID' => $EntryID
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return 1;
}
######################################################################
sub DeletePhonebook($$) {
  my($self,$ID,$ExtraID) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'DeletePhonebook',
    'NewPhonebookID' => $ID,
    'NewPhonebookExtraID' => $ExtraID
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return 1;
}
######################################################################
sub AddPhonebook($$) {
  my($self,$Name,$ExtraID) = @_;

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'AddPhonebook',
    'NewPhonebookName' => $Name,
    'NewPhonebookExtraID' => $ExtraID,
  );
  if($Response->error) {
    my $Log = Log::Log4perl->get_logger();
       $Log->debug($Response->error);
    return undef;
  }

  return 1;
}
######################################################################
sub GetPhonebook($) {
  my($self,$ID) = @_;

  my $Log = Log::Log4perl->get_logger();

  my $Service = $self->{Service};

  my $Response = $Service->call(
    'GetPhonebook',
    'NewPhonebookID' => $ID
  );
  if($Response->error) {
    $Log->debug($Response->error);
    return undef;
  }

  # get phonebook name & download url
  my $URL     = $Response->data->{'NewPhonebookURL'};
  my $Name    = $Response->data->{'NewPhonebookName'};
  my $ExtraID = $Response->data->{'NewPhonebookExtraID'};

  return($URL,$Name,$ExtraID);
}
######################################################################
sub SetPhonebook($) {
  my($self,$ID) = @_;

  # Empty function, just for the sake of completeness;
  # there is no "SetPhonebook" function available via
  # TR-064. "BackupPhonebook" & "RestorePhonebook" do
  # the backup and restore job instead.
  return undef;
}
######################################################################
sub BackupPhonebook($) {
  my($self,$ID) = @_;

  my $Log = Log::Log4perl->get_logger();

  my $Config  = $self->{Config};

  # Step 1: Get phonebook as a whole via download
  my($URL,$Name,$ExtraID) = $self->GetPhonebook($ID);
  return undef unless defined($URL);

  # compose filename for local storage
  my $FileName = sprintf(FMT_XML_FILENAME,$ID);

  unless(DownloadFile($Config,$URL,$FileName)) {
    $Log->debug(qq|cannot download phonebook "$Name" from URL "$URL"|);
    return undef;
  }

  # Step 2: Get phonebook as single entries (needed for restore,
  # no respective upload feature via TR-064 available)

  # compose filename from given ID
  $FileName = sprintf(FMT_BAK_FILENAME,$ID);

  # put all the stuff into a hash
  my %Hash;

  # start with the metadata
  $Hash{'meta'}{'name'} = $Name;
  $Hash{'meta'}{'extra_id'} = $ExtraID;

  # continue with phonebook entries
  for(my $EntryID = 0;; $EntryID++) {
    my $Data = $self->GetPhonebookEntry($ID,$EntryID) or last;
    my $Key  = sprintf("item_%u",$EntryID);
    $Hash{'items'}{$Key} = $Data;
  }

  unless(write_config(%Hash,$FileName)) {
    $Log->debug(qq|cannot open file "$FileName" for writing|);
    return undef;
  }

  $Log->debug(qq|wrote file "$FileName"|);

  return 1;
}
######################################################################
sub RestorePhonebook($) {
  my($self,$ID) = @_;

  my $Log = Log::Log4perl->get_logger();

  # compose filename from given ID
  my $FileName = sprintf(FMT_BAK_FILENAME,$ID);

  # get all the stuff into a hash
  my %Hash;

  unless(read_config($FileName,%Hash)) {
    $Log->debug(qq|cannot open file "$FileName" for reading|);
    return undef;
  }

  # get the meta data
  my $Name    = $Hash{'meta'}{'name'};
  my $ExtraID = $Hash{'meta'}{'extra_id'};

  # just a bit of error checking (did *you* edit the file?)
  if($Name eq '') {
    $Log->debug(qq|name of phonebook must not be an empty string|);
    return undef;
  }

  # add phonebook
  if($self->AddPhonebook($Name,$ExtraID)) {
    # expected result, even if phonebook exists
    $Log->debug(qq|add phonebook "$Name"|);
  } else {
    # unexpected result, should not happen...
    $Log->debug(qq|cannot add phonebook "$Name"|);
  }

  # set the entries
  for(my $EntryID = 0;; $EntryID++) {
    my $Key  = sprintf("item_%u",$EntryID);
    my $Data = $Hash{'items'}{$Key};
    last unless($Data);

    if($self->SetPhonebookEntry($ID,$EntryID,$Data)) {
      $Log->debug(qq|set phonebook entry #$ID:$EntryID|);
    } else {
      $Log->debug(qq|cannot set phonebook entry #$ID:$EntryID|);
    }
  }

  return 1;
}
######################################################################
sub RunAction($) {
  my($self,$Action) = @_;

  my $Log = Log::Log4perl->get_logger();

  $Log->warn('unknown action: '.$Action);
  return undef;
}
######################################################################
sub RunTask($) {
  my($self,$Task) = @_;

  my $Log = Log::Log4perl->get_logger();

  # backup all phonebooks
  if($Task eq 'backup') {
    my @List = $self->GetPhonebookList();
    my $Done = 0;
    my $ToDo = @List;
    # is there anything to do?
    unless($ToDo > 0) {
      $Log->info(qq|no phonebooks present|);
      return undef;
    }
    # do the backups
    foreach my $ID (@List) {
      $Done++ if($self->BackupPhonebook($ID));
    }
    # everything worked fine?
    if($Done != $ToDo) {
      $Log->info(qq|backed up $Done of $ToDo phonebooks|);
      return undef;
    }
    return 1;
  }

  # backup just one phonebook
  if($Task =~ /^backup\:\d$/) {
    my $ID = int((split(/:/,$Task))[1]);
    my @List = $self->GetPhonebookList();
    unless($ID < @List) {
      $Log->info(qq|no phonebook #$ID present|);
      return undef;
    }
    return $self->BackupPhonebook($ID);
  }

  # restore all phonebooks
  if($Task eq 'restore') {
    my $Done = 0;
    my $ToDo = 0;
    # we expect IDs in ascending order
    for(my $ID = 0;; $ID++) {
      my $FileName = sprintf(FMT_BAK_FILENAME,$ID);
      last unless(-f $FileName);
      $ToDo++;
      $Done++ if($self->RestorePhonebook($ID));
    }
    # everything worked fine?
    if($Done != $ToDo) {
      $Log->info(qq|restored $Done of $ToDo phonebooks|);
      return undef;
    }
    return 1;
  }

  # restore just one phonebook
  if($Task =~ /^restore\:\d$/) {
    my $ID = int((split(/:/,$Task))[1]);
    my $FileName = sprintf(FMT_BAK_FILENAME,$ID);
    unless(-f $FileName) {
      $Log->info(qq|no backup file for phonebook #$ID available|);
      return undef;
    }
    return $self->RestorePhonebook($ID);
  }

  # delete all phonebooks
  if($Task eq 'delete') {
    my @List = $self->GetPhonebookList();
    my $Done = 0;
    my $ToDo = @List;
    # is there anything to do?
    unless($ToDo > 0) {
      $Log->info(qq|no phonebooks present|);
      return undef;
    }
    # do delete top-down
    foreach my $ID (sort {$b cmp $a} (@List)) {
      $Done++ if($self->DeletePhonebook($ID));
    }
    # everything worked fine?
    if($Done != $ToDo) {
      $Log->info(qq|deleted $Done of $ToDo phonebooks|);
      return undef;
    }
    return 1;
  }

  # delete just one phonebook
  if($Task =~ /^delete\:\d$/) {
    my $ID = int((split(/:/,$Task))[1]);
    my @List = $self->GetPhonebookList();
    unless($ID < @List) {
      $Log->info(qq|no phonebook #$ID present|);
      return undef;
    }
    return $self->DeletePhonebook($ID);
  }

  # list available phonebooks on FRITZ!Box
  if($Task eq 'list') {
    $Log->info(qq|ID\tName|);
    my @List = $self->GetPhonebookList();
    foreach my $ID (@List) {
      my($URL,$Name,$ExtraID) = $self->GetPhonebook($ID) or return undef;
      my $Line = sprintf(qq|%2u\t%s|,$ID,$Name);
      $Log->info($Line);
    }
    return 1;
  }

  $Log->warn('unknown task: '.$Task);
  return undef;
}
######################################################################
1;

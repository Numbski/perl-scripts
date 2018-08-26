<SCRIPT LANGUAGE="PerlScript" RUNAT="SERVER">

use Win32::OLE;
Win32::OLE->Initialize(Win32::OLE::COINIT_OLEINITIALIZE);

sub ISMTPOnArrival_OnArrival {
  #expecting a $message object
  my $message = $_[0];
  my $status = 0;
  #...and so on
}

</SCRIPT>

<SCRIPT LANGUAGE="PerlScript">
use Win32::OLE;
Win32::OLE->Initialize(Win32::OLE::COINIT_OLEINITIALIZE);
use Win32::OLE::Const ('Microsoft CDO For Exchange 2000 Library');
use Win32::OLE::Variant;
#I'm not sure if the Win32::OLE::Variant is required in this particular
#scenario, but it shouldn't hurt.

sub ISMTPOnArrival_OnArrival {
  my $message = $_[0];
  my $straddr = '[EMAIL PROTECTED]'
  if ($message->EnvelopeFields->Item(cdoClientIPAddress)->{Value} eq "")
{
    #OUTGOING
  } else {
    #INCOMING
  }
  $message->{EnvelopeFields}->Item(cdoRecipientList)->{Value} =
$message->{EnvelopeFields}->Item(cdoRecipientList)->{Value}.";".$straddr
;
  $message->{EnvelopeFields}->Update();
  $message->DataSource->Save();
  $_[0] = $message;
  $_[1] = 0;
}
</SCRIPT>

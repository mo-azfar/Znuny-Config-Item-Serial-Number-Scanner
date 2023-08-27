# --
# Copyright (C) 2023 mo-azfar, https://github.com/mo-azfar
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::CustomerAssetScan;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
		   
	# check needed CustomerID
    if ( !$Self->{UserCustomerID} ) {
        my $Output = $LayoutObject->CustomerHeader(
            Title => Translatable('Error'),
        );
        $Output .= $LayoutObject->CustomerError(
            Message => Translatable('Need CustomerID!'),
        );
        $Output .= $LayoutObject->CustomerFooter();
        return $Output;
    }
	
	my $Title = $Self->{Subaction};
	
	my $Output = $LayoutObject->CustomerHeader(
        Title   => $Title,
    );
	
	#since we didnt need template file to show html, throw an error instead of sending parameter to template file
	if ( !$Self->{Subaction} )
	{
		#$LayoutObject->Block(
		#	Name => 'SubmitFooter',
		#);
		#
		## start html page
        #$Output .= $LayoutObject->Output(
        #    TemplateFile => 'CustomerAssetScan',
        #    Data         => \%Param,
        #);
		#
        #$Output .= $LayoutObject->CustomerFooter();
        #return $Output;
		
		my $Output = $LayoutObject->CustomerHeader(
            Title => Translatable('Warning'),
        );
		
		$Output .= $LayoutObject->Warning(
			Message => Translatable('Opps.Cant Access This Directly!.'),
			Comment => Translatable('!'),
		);
        
		$Output .= $LayoutObject->CustomerFooter();
        
		return $Output;
		
	}
	
	elsif ( $Self->{Subaction} eq "AddAsset" )
	{	
		my $SerialNumber = $ParamObject->GetParam( Param => 'SerialNumber' ) || '';
		
		if ( !$SerialNumber )
		{
			$Output .= $LayoutObject->Warning(
				Message => Translatable('Opps.You Need To Scan The Asset Serial Number!.'),
				Comment => Translatable('!'),
			);
			
			$Output .= $LayoutObject->CustomerFooter();
			
			return $Output;
		}
		
		my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
		
		#search asset in cmdb
		my $ConfigItemIDs = $ConfigItemObject->ConfigItemSearchExtended(
			What => [                                               
				# each array element is a and condition
				{
					# or condition in hash
					"[%]{'SerialNumber'}[%]{'Content'}" => $SerialNumber,
				},
			], 
			UsingWildcards => 0,
		);
		
		if (!@{$ConfigItemIDs})
		{
			my $MessageEncoded = $LayoutObject->LinkEncode("*SerialNumber#$SerialNumber not found in the system");
			
			return $LayoutObject->Redirect( OP => "Action=CustomerTicketMessage&Message=$MessageEncoded" );
		}
		
		my @Data;
		for my $ConfigItemID ( @{$ConfigItemIDs})
		{
			#get scanned serial number data
			my $LastVersion = $ConfigItemObject->VersionGet(
				ConfigItemID => $ConfigItemID,
				XMLDataGet   => 1,
			);
			
			my $Tree = $LastVersion->{XMLData}->[1]->{Version}->[1];
			
			my $Number = $LastVersion->{Number};
			my $Name = $LastVersion->{Name};
			my $Class = $LastVersion->{Class};
			my $MatchedSerialNumber  = $Tree->{SerialNumber}->[1]->{Content};
			my $Vendor = $Tree->{Vendor}->[1]->{Content};
			
			my $Text = "ConfigItem#: $Number<br/>Name: $Name<br/>Class: $Class<br/>S/N: $MatchedSerialNumber<br/>Vendor: $Vendor";
			push @Data, $Text;	
		}
		
		#just in case serialnumber connected to multiple asset since no unique identifier in CMDB.
		my $Body = join('<br/><br/>', @Data);
		my $BodyEncoded = $LayoutObject->LinkEncode($Body);
		my $MessageEncoded = $LayoutObject->LinkEncode("*SerialNumber#$SerialNumber has been added to the ticket body");
		
		return $LayoutObject->Redirect( OP => "Action=CustomerTicketMessage;Body=$BodyEncoded&Message=$MessageEncoded" );
	}
	
	else 
	{
		
        return $LayoutObject->CustomerErrorScreen(
            Message => Translatable('No Subaction!'),
            Comment => Translatable('Please contact the administrator.'),
        );
		
    }
	  
}

1;
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

    my $Error = {
        Status => 'Error',
        ErrorMessage => 0,
    };

    my $OK = {
        Status => 'OK',
        ConfigItem    => 0,
    };

	# check needed CustomerID
    if ( !$Self->{UserCustomerID} ) {
        $Error->{ErrorMessage} = "Need CustomerID!";
        
        my $JSON = $LayoutObject->JSONEncode(
            Data        => $Error,
            NoQuotes    => 1, # optional: no double quotes at the start and the end of JSON string
        );
        
        return $LayoutObject->Attachment(
                Type        => 'inline',        # optional, default: attachment, possible: inline|attachment
                ContentType => 'application/json',
                Charset     => 'utf-8',         # optional
                Content     => $JSON,
                NoCache     => 1,               # optional
        );	
    }
	
	#since we didnt need template file to show html, throw an error instead of sending parameter to template file
	if ( !$Self->{Subaction} )
	{
        $Error->{ErrorMessage} = "Opps.Cant Access This Directly!";

        my $JSON = $LayoutObject->JSONEncode(
            Data        => $Error,
            NoQuotes    => 1, # optional: no double quotes at the start and the end of JSON string
        );

        return $LayoutObject->Attachment(
                Type        => 'inline',        # optional, default: attachment, possible: inline|attachment
                ContentType => 'application/json',
                Charset     => 'utf-8',         # optional
                Content     => $JSON,
                NoCache     => 1,               # optional
        );	
		
	}
	
	elsif ( $Self->{Subaction} eq "AddAsset" )
	{	  
        my $SerialNumber = $ParamObject->GetParam( Param => 'SerialNumber' ) || '';
		
		if ( !$SerialNumber )
		{
			$Error->{ErrorMessage} = "Need SerialNumber!";

            my $JSON = $LayoutObject->JSONEncode(
                Data        => $Error,
                NoQuotes    => 1, # optional: no double quotes at the start and the end of JSON string
            );
            
            return $LayoutObject->Attachment(
                Type        => 'inline',        # optional, default: attachment, possible: inline|attachment
                ContentType => 'application/json',
                Charset     => 'utf-8',         # optional
                Content     => $JSON,
                NoCache     => 1,               # optional
            );	
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
			$OK->{Status} = 0;
            
            my $JSON = $LayoutObject->JSONEncode(
                Data        => $OK,
                NoQuotes    => 1, # optional: no double quotes at the start and the end of JSON string
            );
            
            return $LayoutObject->Attachment(
                Type        => 'inline',        # optional, default: attachment, possible: inline|attachment
                ContentType => 'application/json',
                Charset     => 'utf-8',         # optional
                Content     => $JSON,
                NoCache     => 1,               # optional
            );	
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
		
        $OK->{ConfigItem} = \@Data;

        my $JSON = $LayoutObject->JSONEncode(
                Data        => $OK,
                NoQuotes    => 1, # optional: no double quotes at the start and the end of JSON string
            );
            
            return $LayoutObject->Attachment(
                Type        => 'inline',        # optional, default: attachment, possible: inline|attachment
                ContentType => 'application/json',
                Charset     => 'utf-8',         # optional
                Content     => $JSON,
                NoCache     => 1,               # optional
            );	

	}
	
	else 
	{
		$Error->{ErrorMessage} = "Wrong Subaction!";

        my $JSON = $LayoutObject->JSONEncode(
            Data        => $Error,
            NoQuotes    => 1, # optional: no double quotes at the start and the end of JSON string
        );

        return $LayoutObject->Attachment(
            Type        => 'inline',        # optional, default: attachment, possible: inline|attachment
            ContentType => 'application/json',
            Charset     => 'utf-8',         # optional
            Content     => $JSON,
            NoCache     => 1,               # optional
        );	
		
    }
	  
}

1;
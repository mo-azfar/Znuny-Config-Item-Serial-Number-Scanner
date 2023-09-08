# --
# Copyright (C) 2023 mo-azfar,https://github.com/mo-azfar
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::ShowQRScanner;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Group',
    'Kernel::System::Web::Request',
);

use Kernel::System::VariableCheck qw(:all);

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ConfigObject                    = $Kernel::OM->Get('Kernel::Config');
    my $GroupObject                     = $Kernel::OM->Get('Kernel::System::Group');
    my $LayoutObject                    = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject                     = $Kernel::OM->Get('Kernel::System::Web::Request');
   
	my $Action = $ParamObject->GetParam( Param => 'Action' );
	
	return 1 if !$Action;
    return 1 if !$Param{Templates}->{$Action};
	
	#qrscanner button and field
	my $Field = qq~
	<script src="https://unpkg.com/html5-qrcode" type="text/javascript"></script>
	<div class="card-item col-wide-33 col-desktop-100 col-tablet-100">
        <h2 class="card-title">Scan Asset Serial Number</h2>
		<div class="active-inner-cols">
			<div class="Field">
                <button id="btnShow" title="Scan Asset QR" type="button" value="Scan Asset QR" class="btn-primary btn-main btn-width-md" onclick="myFunction()">Scan Asset QR</button>
								
				<div id="qr-reader" style="width: 300px"></div>
			</div>		
		</div>
    </div>
	~;		

	#qrscanner function call
	my $JS2 = qq~<script type="text/javascript">
	function myFunction() {	
	const html5QrCode = new Html5Qrcode("qr-reader");
	const qrCodeSuccessCallback = (decodedText, decodedResult) => {
		html5QrCode.stop().then((ignore) => {});
		alert("Detected Serial Number: "+decodedText);
        async function attachBody() {
        let obj;

        const res = await    
        fetch(Core.Config.Get('CGIHandle')+"?Action=CustomerAssetScan;Subaction=AddAsset;SerialNumber="+decodedText, 
        {
            method: "POST",
            headers: {
                "Content-type": "application/json; charset=UTF-8"
            }
        })

        obj = await res.json();
        //obj.Status will retun OK (with data) / 0 (empty not found) / ErrorCode
        //obj.ConfigItem will return array
        //console.log(obj.ConfigItem);

        if (obj.Status == 'OK') 
        {
            const text = obj.ConfigItem;
            //append back message to qr reader to show message result
	        document.getElementById('qr-reader').innerHTML = obj.Status;
            CKEDITOR.instances['RichText'].insertHtml(text.join('<br/><br/>'));
        } 
        else if (obj.Status == '0')
        {
            document.getElementById('qr-reader').innerHTML = decodedText+" Not Found";
        }
        else
        {
            document.getElementById('qr-reader').innerHTML = "Error. Check Console Log";
            console.log(obj);
        }
        
    }

    attachBody();

	};
	
	const config = { fps: 10, qrbox: { width: 200, height: 200 } };
	// If you want to prefer back camera
	html5QrCode.start({ facingMode: "environment" }, config, qrCodeSuccessCallback);				
	}
	
	</script>
	~;	
	
	my $SearchField = quotemeta "<fieldset class=\"TableLike card-item-wrapper\">";
	my $ReturnField = qq~<fieldset class="TableLike card-item-wrapper">
	~;
	
	#search and replace	 
	${ $Param{Data} } =~ s{$SearchField}{$ReturnField $Field $JS2};
	
    return 1;
}

1;

package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
	
  public class WarningMessage {

		public function WarningMessage() {
		}
        
		public static function send(message:String):void {
			ExternalInterface.call('s3_swf.onWarning',message);
		}

	}
}

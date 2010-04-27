package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
	
  public class ErrorMessage {


		public function ErrorMessage() {
		}
        
		public static function send(message:String):void {
			ExternalInterface.call('s3_swf.onError',message);
		}

	}
}

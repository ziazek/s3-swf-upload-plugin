package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
	
  public class ErrorNotifier {

		private var _notifyCall:String;

		public function ErrorNotifier(notifyCall:String) {
			_notifyCall = notifyCall;
		}
        
		public function send(message:String):void {
			ExternalInterface.call(_notifyCall,message);
		}

	}
}

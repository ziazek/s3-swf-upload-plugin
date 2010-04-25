package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
	
  public class CompletionNotifier {

		private var _notifyCall:String;

		public function CompletionNotifier(notifyCall:String) {
			_notifyCall = notifyCall;
		}
        
		public function send():void {
			ExternalInterface.call(_notifyCall);
		}

	}
}

package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
	
  public class StatusNotifier {

		private var _notifyCall:String;

		public function StatusNotifier(notifyCall:String) {
			_notifyCall = notifyCall;
		}
        
		public function send(message:String):void {
			ExternalInterface.call(_notifyCall,message);
		}

	}
}

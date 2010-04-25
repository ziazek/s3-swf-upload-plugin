package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
	import flash.events.ProgressEvent;
	
  public class ProgressNotifier {

		private var _notifyCall:String;

		public function ProgressNotifier(notifyCall:String) {
			_notifyCall = notifyCall;
		}
        
		public function send(event:ProgressEvent, filesRemaining:Number):void {
			event.bytesLoaded, event.bytesTotal
			ExternalInterface.call(_notifyCall,event.bytesLoaded, event.bytesTotal,filesRemaining);
		}

	}
}

package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
	
  public class ProgressNotifier {

		private var _notifyCall:String;

		public function ProgressNotifier(notifyCall:String) {
			_notifyCall = notifyCall;
		}
        
		public function send(currentSent:Number,
													currentSize:Number,
													overallSent:Number,
													overallSize:Number):void {
			ExternalInterface.call(_notifyCall,currentSent,currentSize,overallSent,overallSize);
		}

	}
}

package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
  import flash.net.FileReference;
	
  public class FileSelectionNotifier {

		private var _notifyCall:String;

		public function FileSelectionNotifier(notifyCall:String) {
			_notifyCall = notifyCall;
		}
        
		public function send(file:FileReference, contentType:String):void {
			ExternalInterface.call(_notifyCall,file.name,file.size,contentType);
		}

	}
}

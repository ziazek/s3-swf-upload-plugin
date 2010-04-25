package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
	import com.elctech.S3UploadOptions;
	
  public class SuccessNotifier {

		private var _notifyCall:String;

		public function SuccessNotifier(notifyCall:String) {
			_notifyCall = notifyCall;
		}
        
		public function send(options:S3UploadOptions):void {
			ExternalInterface.call(_notifyCall, options.FileName, options.FileSize, options.ContentType);
		}

	}
}



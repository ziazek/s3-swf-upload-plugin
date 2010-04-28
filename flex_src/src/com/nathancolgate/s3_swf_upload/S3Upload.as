package com.nathancolgate.s3_swf_upload {
	
	import com.elctech.S3UploadOptions;
	import com.elctech.S3UploadRequest;
  import flash.external.ExternalInterface;
	import com.nathancolgate.s3_swf_upload.*;
	import flash.net.*;
	import flash.events.*;
	
  public class S3Upload extends S3UploadRequest {
		
		private var _upload_options:S3UploadOptions;
	
		public function S3Upload(s3_upload_options:S3UploadOptions) {
			super(s3_upload_options);
			
			_upload_options = s3_upload_options;
			
			addEventListener(Event.OPEN, openHandler);
	    addEventListener(ProgressEvent.PROGRESS, progressHandler);
	    addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
	    addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
	    addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, completeHandler);
	
		  try {
				var next_file:FileReference = FileReference(Globals.queue.getItemAt(0));
				this.upload(next_file);
			} catch(error:Error) {
				ExternalInterface.call('s3_swf.onUploadError',_upload_options,error);
	    }
		}
		
		// called after the file is opened before _upload_options    
		private function openHandler(event:Event):void{
			// This should only happen once per file
			// But sometimes, after stopping and restarting the queeue
			// It gets called multiple times
			// BUG BUG BUG!
			ExternalInterface.call('s3_swf.onUploadOpen',_upload_options,event);
		}

		// called during the file _upload_options of each file being _upload_optionsed
		// we use this to feed the progress bar its data
		private function progressHandler(progress_event:ProgressEvent):void {
			ExternalInterface.call('s3_swf.onUploadProgress',_upload_options,progress_event);
		}

		// only called if there is an  error detected by flash player browsing or _upload_optionsing a file   
		private function ioErrorHandler(io_error_event:IOErrorEvent):void{
			ExternalInterface.call('s3_swf.onUploadIOError',_upload_options,io_error_event);
		}    

		private function httpStatusHandler(http_status_event:HTTPStatusEvent):void {
			ExternalInterface.call('s3_swf.onUploadHttpStatus',_upload_options,http_status_event);
		}
		
		// only called if a security error detected by flash player such as a sandbox violation
		private function securityErrorHandler(security_error_event:SecurityErrorEvent):void{
			ExternalInterface.call('s3_swf.onUploadSecurityError',_upload_options,security_error_event);
		}
        
		private function completeHandler(event:Event):void{
			ExternalInterface.call('s3_swf.onUploadComplete',_upload_options,event);
			Globals.queue.removeItemAt(0);
			if (Globals.queue.length > 0){
				Globals.queue.uploadNextFile();
			} else {
				ExternalInterface.call('s3_swf.onUploadingFinish');
			}
		}
		
	}
}
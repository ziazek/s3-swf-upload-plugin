package com.nathancolgate.s3_swf_upload {
	
	import com.elctech.S3UploadOptions;
	import com.elctech.S3UploadRequest;
  import flash.external.ExternalInterface;
	import com.nathancolgate.s3_swf_upload.*;
	import flash.net.*
	import flash.events.*
	
  public class S3Upload extends S3UploadRequest {
		
		private var options:S3UploadOptions;
	
		public function S3Upload(options:S3UploadOptions) {
			super(options);
			
			this.options = options;
			
			this.addEventListener(Event.OPEN, openHandler);
	    this.addEventListener(ProgressEvent.PROGRESS, progressHandler);
	    this.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
	    this.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			this.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
	    this.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, completeHandler);
	
		  try {
				this.upload(Globals.file);
			} catch(e:Error) {
				ErrorMessage.send("Upload General Error: "+e);
	    }
		}
		
		// called after the file is opened before upload    
		private function openHandler(event:Event):void{
			// This should only happen once per file
			// But sometimes, after stopping and restarting the queeue
			// It gets called multiple times
			// BUG BUG BUG!
			ExternalInterface.call('s3_swf.onUploadOpen',event);
		}

		// called during the file upload of each file being uploaded
		// we use this to feed the progress bar its data
		private function progressHandler(event:ProgressEvent):void {
			ExternalInterface.call('s3_swf.onUploadProgress',event);
		}

		// only called if there is an  error detected by flash player browsing or uploading a file   
		private function ioErrorHandler(event:IOErrorEvent):void{
			ErrorMessage.send("Upload IO Error: "+event);
		}    

		private function httpStatusHandler(event:HTTPStatusEvent):void {
			ExternalInterface.call('s3_swf.onUploadHttpStatus',event);
		}
		
		// only called if a security error detected by flash player such as a sandbox violation
		private function securityErrorHandler(event:SecurityErrorEvent):void{
			ErrorMessage.send("Upload Security Error: "+event);
		}
        
		private function completeHandler(event:Event):void{
			ExternalInterface.call('s3_swf.onUploadComplete',this.options);
			Globals.queue.removeItemAt(0);
			if (Globals.queue.length > 0){
				Globals.queue.uploadNextFile();
			} else {
				ExternalInterface.call('s3_swf.onQueueFinish',Globals.queue);
			}
		}
		
	}
}
package com.nathancolgate.s3_swf_upload {
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
  import flash.external.ExternalInterface;
	import flash.net.FileReference;
	import com.nathancolgate.s3_swf_upload.*;
	
  public class S3Queue extends ArrayCollection {
	
		// S3 Interaction Vars
		private var _signatureUrl:String;
		private var _prefixPath:String;

		public function S3Queue(signatureUrl:String,
														prefixPath:String,
														source:Array = null) {
															
			_signatureUrl = signatureUrl;
			_prefixPath	  = prefixPath;
			super(source);

			// Outgoing calls
			this.addEventListener(CollectionEvent.COLLECTION_CHANGE, changeHandler);
			// Incoming calls
			ExternalInterface.addCallback("startUploading", startUploadingHandler);
			ExternalInterface.addCallback("clearQueue", clearHandler);
			ExternalInterface.addCallback("stopUploading", stopUploadingHandler);
		}
		
		public function uploadNextFile():void{
			var next_file:FileReference = FileReference(this.getItemAt(0));
			var signature:S3Signature = new S3Signature(next_file,_signatureUrl,_prefixPath);
		}
		
		// whenever the queue changes this function is called 
		private function changeHandler(event:CollectionEvent):void{
			ExternalInterface.call('s3_swf.onQueueChange',this);
		}
		
		// Remove all files from the upload queue;
		private function clearHandler():void{
			this.removeAll();
			ExternalInterface.call('s3_swf.onQueueClear',this);
		}

		// Start uploading the files from the queue
		private function startUploadingHandler():void{
			if (this.length > 0){
				ExternalInterface.call('s3_swf.onUploadingStart');
				uploadNextFile();
			} else {
				ExternalInterface.call('s3_swf.onQueueEmpty',this);
			}
		}
		
		// Cancel Current File Upload
		// Which stops all future uploads as well
		private function stopUploadingHandler():void{
			if (this.length > 0){
				var current_file:FileReference = FileReference(this.getItemAt(0));
				current_file.cancel();
				ExternalInterface.call('s3_swf.onUploadingStop');
			} else {
				ExternalInterface.call('s3_swf.onQueueEmpty',this);
			}
		}

	}
}

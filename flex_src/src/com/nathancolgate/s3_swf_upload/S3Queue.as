package com.nathancolgate.s3_swf_upload {
	
	import mx.collections.ArrayCollection;
	import mx.events.CollectionEvent;
  import flash.external.ExternalInterface;
	import flash.net.FileReference;
	import com.nathancolgate.s3_swf_upload.*;
	
  public class S3Queue extends ArrayCollection {
	
		// S3 Interaction Vars
		private var _signature:S3Signature;

		public function S3Queue(source:Array = null) {
			super(source);

			// Outgoing calls
			this.addEventListener(CollectionEvent.COLLECTION_CHANGE, changeHandler);
			// Incoming calls
			ExternalInterface.addCallback("startQueue", startHandler);
			ExternalInterface.addCallback("clearQueue", clearHandler);
			ExternalInterface.addCallback("stopQueue", stopHandler);
		}
		
		public function uploadNextFile():void{
			Globals.file = FileReference(this.getItemAt(0));
			_signature = new S3Signature;
		}
		
		// whenever the queue changes this function is called 
		private function changeHandler(event:CollectionEvent):void{
			ExternalInterface.call('s3_swf.onQueueChange',this);
		}
		
		// Start uploading the files from the queue
		private function startHandler():void{
			if (this.length > 0){
				ExternalInterface.call('s3_swf.onQueueStart',this);
				Globals.queue.uploadNextFile();
			} else {
				WarningMessage.send('You must select at least one file to upload');
			}
		}
		
		// Remove all files from the upload queue;
		private function clearHandler():void{
			this.removeAll();
			ExternalInterface.call('s3_swf.onQueueClear',this);
		}
		
		// Cancel Current File Upload
		private function stopHandler():void{
			Globals.file.cancel();
			ExternalInterface.call('s3_swf.onQueueStop',this);
		}

	}
}

package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
	import mx.collections.ArrayCollection;
	import flash.net.FileReference;
	
  public class CollectionChangeNotifier {

		private var _notifyCall:String;

		public function CollectionChangeNotifier(notifyCall:String) {
			_notifyCall = notifyCall;
		}
        
		public function send(files:ArrayCollection):void {
			ExternalInterface.call(_notifyCall,files);
		}

	}
}

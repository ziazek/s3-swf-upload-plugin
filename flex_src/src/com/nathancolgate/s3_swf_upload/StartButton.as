package com.nathancolgate.s3_swf_upload {

  import flash.external.ExternalInterface;
	
  public class StartButton {

		private var _enabled:Boolean;
		private var _enableCall:String;

		public function StartButton(enableCall:String) {
			_enableCall = enableCall;
			init();
		}
        
		private function init():void {
			// Disable on startup
			enabled = false;
		}
		
		// Not sure if anyone will ever use this, but including it anyway
		public function get enabled():Boolean {
			return _enabled;
		}

		public function set enabled( value:Boolean ):void {
			_enabled = value;
			ExternalInterface.call(_enableCall,value);
		}

	}
}

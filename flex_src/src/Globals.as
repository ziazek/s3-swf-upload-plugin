package  {
	
	import flash.net.FileReference;
	import com.nathancolgate.s3_swf_upload.S3Queue;
	
	public dynamic class Globals extends Object{
		
		public static var queue:S3Queue;
		public static var file:FileReference;
		public static var signatureUrl:String;
		public static var prefixPath:String;
		
		public function Globals(){
			super();
			return;
		}

	}
}

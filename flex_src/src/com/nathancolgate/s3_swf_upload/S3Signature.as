package com.nathancolgate.s3_swf_upload {
	
	import com.elctech.S3UploadOptions;
	import com.nathancolgate.s3_swf_upload.*;
  import flash.external.ExternalInterface;
	import com.adobe.net.MimeTypeMap;

	import flash.net.*
	import flash.events.*
	
  public class S3Signature {

		private var _options:S3UploadOptions;
		private var _upload:S3Upload;
		private var _mimeMap:MimeTypeMap;

		public function S3Signature() {		
			_upload											= null;
			_mimeMap 										= new MimeTypeMap;
			
			// Create options list for file s3 upload metadata 
			_options										= new S3UploadOptions;
			_options.FileSize          	= Globals.file.size.toString();
			_options.FileName          	= getFileName(Globals.file);
			_options.ContentType       	= getContentType(_options.FileName);
			_options.key               	= Globals.prefixPath + _options.FileName;
			
			var variables:URLVariables 	= new URLVariables();
			variables.key              	= _options.key
			variables.content_type     	= _options.ContentType;
		
			var request:URLRequest     	= new URLRequest(Globals.signatureUrl);
			request.method             	= URLRequestMethod.GET;
			request.data               	= variables;
			
			var loader:URLLoader       	= new URLLoader();
			loader.dataFormat          	= URLLoaderDataFormat.TEXT;
			loader.addEventListener(Event.OPEN, openHandler);
			loader.addEventListener(ProgressEvent.PROGRESS, progressHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			loader.addEventListener(Event.COMPLETE, completeHandler);
			loader.load(request);
  	}

		private function openHandler(event:Event):void {
			ExternalInterface.call('s3_swf.onSignatureOpen',event);
		}

		private function progressHandler(event:ProgressEvent):void {
			ExternalInterface.call('s3_swf.onSignatureProgress',event);
		}

		private function securityErrorHandler(event:SecurityErrorEvent):void {
			ErrorMessage.send("Signature Security Error: "+event);
		}

		private function httpStatusHandler(event:HTTPStatusEvent):void {
			ExternalInterface.call('s3_swf.onSignatureHttpStatus',event);
		}

		private function ioErrorHandler(event:IOErrorEvent):void {
			ErrorMessage.send("Signature IO Error: "+event);
		}

  	private function completeHandler(event:Event):void {
			ExternalInterface.call('s3_swf.onSignatureComplete',event);
      var loader:URLLoader = URLLoader(event.target);
      var xml:XML  = new XML(loader.data);
      
      // create the s3 options object
      _options.policy         = xml.policy;
      _options.signature      = xml.signature;
      _options.bucket         = xml.bucket;
      _options.AWSAccessKeyId = xml.accesskeyid;
      _options.acl            = xml.acl;
      _options.Expires        = xml.expirationdate;
      _options.Secure         = xml.https;

      if (xml.errorMessage != "") {
				ErrorMessage.send("Signature XML Error");
				return;
      }
			
      _upload = new S3Upload(_options);
		}
		
		/* MISC */
		
		private function getContentType(fileName:String):String {
			var fileNameArray:Array    = fileName.split(/\./);
			var fileExtension:String   = fileNameArray[fileNameArray.length - 1];
			var contentType:String     = _mimeMap.getMimeType(fileExtension);
			return contentType;
		}
		private function getFileName(file:FileReference):String {
			var fileName:String = file.name.replace(/^.*(\\|\/)/gi, '').replace(/[^A-Za-z0-9\.\-]/gi, '_');
			return fileName;
		}
	}
}
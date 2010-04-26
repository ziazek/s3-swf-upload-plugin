package com.nathancolgate.s3_swf_upload {

	// S3 Connectivity
	import com.elctech.S3UploadOptions;
	import com.elctech.S3UploadRequest;
	
	//Events
	import flash.events.ProgressEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.DataEvent;

	// Misc
	import com.adobe.net.MimeTypeMap;
	import mx.collections.ArrayCollection;
	import mx.controls.Button;
	import mx.events.CollectionEvent;
	import flash.external.ExternalInterface;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoaderDataFormat;

	// S3 SWF Upload Classes
	import com.nathancolgate.s3_swf_upload.ErrorNotifier;
	import com.nathancolgate.s3_swf_upload.StatusNotifier;
	import com.nathancolgate.s3_swf_upload.FileSelectionNotifier;
	import com.nathancolgate.s3_swf_upload.ProgressNotifier;
	import com.nathancolgate.s3_swf_upload.SuccessNotifier;
	import com.nathancolgate.s3_swf_upload.CompletionNotifier;
	import com.nathancolgate.s3_swf_upload.CollectionChangeNotifier;
	import com.nathancolgate.s3_swf_upload.ResetButton;
	import com.nathancolgate.s3_swf_upload.StopButton;
	import com.nathancolgate.s3_swf_upload.StartButton;

	public class MultipleFileS3Uploader {
		
		//File Reference Vars
		private var _files:ArrayCollection;
		private var _file:FileReference;
		private var _multiFileDialogBox:FileReferenceList;
		private var _singleFileDialogBox:FileReference;
		private var _multipleFiles:Boolean;

		//config vars
		private var _options:S3UploadOptions;
		private var _maxFileCount:Number;
		private var _maxFileSize:Number; //bytes
		private var _signatureUrl:String;
		private var _prefixPath:String;
		private var _browseButton:Button;
		private var _mimeMap:MimeTypeMap;
		private var _fileFilter:FileFilter;
		private var _initialStatus:String;
		private var _queueFileSize:Number; //bytes
		private var _queueSentSize:Number; //bytes

		// External Notifiers
		private var _statusNotifier:StatusNotifier;
		private var _errorNotifier:ErrorNotifier;
		private var _fileSelectionNotifier:FileSelectionNotifier;
		private var _progressNotifier:ProgressNotifier;
		private var _successNotifier:SuccessNotifier;
		private var _completionNotifier:CompletionNotifier;
		private var _collectionChangeNotifier:CollectionChangeNotifier;

		// External Buttons
		private var _resetButton:ResetButton;
		private var _stopButton:StopButton;
		private var _startButton:StartButton;

		public function MultipleFileS3Uploader(signatureUrl:String,
																						prefixPath:String,
																						maxFileSize:Number,
																						fileTypes:String,
																						fileTypeDescs:String,
																						browseButton:Button,
																						maxFileCount:Number,
																						initialStatus:String,
																						multipleFiles:Boolean) {
			
			// set up from args
			_signatureUrl 	= signatureUrl;
			_prefixPath 		= prefixPath;
			_maxFileSize 		= maxFileSize;
			_fileFilter 		= new FileFilter(fileTypeDescs, fileTypes);
			_browseButton 	= browseButton;
			_maxFileCount 	= maxFileCount;
			_initialStatus 	= initialStatus;
			_multipleFiles 	= multipleFiles;

			init();
		}
        
		private function init():void {
			// Create options list for file s3 upload metadata 
			_options = new S3UploadOptions();
			
			// other defaults
			_mimeMap = new MimeTypeMap();

			// Setup File Array Collection and FileReference
			_files = new ArrayCollection();
			_file = new FileReference;
			_multiFileDialogBox = new FileReferenceList;
			_singleFileDialogBox = new FileReference;
			
			// Build the External Buttons
			_resetButton 	= new ResetButton("s3_swf.enableResetButton");
			_stopButton 	= new StopButton("s3_swf.enableStopButton");
			_startButton 	= new StartButton("s3_swf.enableStartButton");
			
			// Build the Notifiers
			_errorNotifier						= new ErrorNotifier("s3_swf.onError");
			_statusNotifier						= new StatusNotifier("s3_swf.onStatus");
			_fileSelectionNotifier		= new FileSelectionNotifier("s3_swf.onFileSelection");
			_progressNotifier					= new ProgressNotifier("s3_swf.onProgress");
			_successNotifier					= new SuccessNotifier("s3_swf.onSuccess");
			_completionNotifier				= new CompletionNotifier("s3_swf.onCompletion");
			_collectionChangeNotifier = new CollectionChangeNotifier("s3_swf.onCollectionChange");
			
			// Send the initial Status, if applicable
			if(_initialStatus != ''){
				_statusNotifier.send(_initialStatus);
			}

			// Add Event Listeners/Callbacks to UI buttons...
			_browseButton.addEventListener(MouseEvent.CLICK, browseHandler);
			ExternalInterface.addCallback("start", startHandler);
			ExternalInterface.addCallback("reset", resetHandler);
			ExternalInterface.addCallback("stop", stopHandler);
			ExternalInterface.addCallback("delete", deleteHandler);
			
			// ... and disable UI Buttons;
			_resetButton.enabled = false;
			_stopButton.enabled = false;
			_startButton.enabled = false;

			// Add Listeners to the file management
			_multiFileDialogBox.addEventListener(Event.SELECT, selectHandler);
			_singleFileDialogBox.addEventListener(Event.SELECT, selectHandler);
			_files.addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler);

		}

		// called when the browse button is clicked
		// Browse for files
		private function browseHandler(event:Event):void{
			if(_multipleFiles == true){
				_multiFileDialogBox.browse([_fileFilter]);
			} else {
				_singleFileDialogBox.browse([_fileFilter]);
			}
		}

		// Called when the upload button is clicked
		// These are the things we only want to do one time
		private function startHandler():void{
			if (_files.length > 0){
				// Update the Overall File Size Queue
				var i:int;
				_queueFileSize = 0;
				_queueSentSize = 0;
				for(i=0;i < _files.length;i++){
					_queueFileSize +=  _files[i].size;
				}
				// Manage the buttons
				_browseButton.enabled = false;
				_resetButton.enabled = false;
				_startButton.enabled = false;
				_stopButton.enabled = true;
				// Now start kicking off the files
				uploadFiles();
			} else {
				_errorNotifier.send('You must select at least one file to upload');
			}
		}
		
		// Called when th clear button is clicked
		// Remove all files from the upload cue;
		private function resetHandler():void{
			_files.removeAll();
		}
		
		// Called when the cancel button is clicked
		// Cancel Current File Upload
		private function stopHandler():void{
			_file.cancel();
			// Manage the buttons
			_browseButton.enabled = true;
			_resetButton.enabled = true;
			_startButton.enabled = true;
			_stopButton.enabled = false;
		}
		
		//Remove Selected File From Queue
		private function deleteHandler(file_index:Number):void{
			try {
				_files.removeItemAt(file_index);
			} catch(e:Error) {
				_errorNotifier.send('The specified file could not be found in the queue');
			}
		}

		// whenever the _files arraycollection changes this function is called 
		private function collectionChangeHandler(event:CollectionEvent):void{
			// handles UPLOAD and CLEAR states based on number of files in the cue;
			if (_files.length > 0){  
				_startButton.enabled = true;
				_resetButton.enabled = true;
			} else {
				_startButton.enabled = false;
				_resetButton.enabled = false;
			}
			_collectionChangeNotifier.send(_files);
		}
		      

		//  called after user selected files form the browse dialouge box.
		private function selectHandler(event:Event):void {
			var remainingSpots:int = _maxFileCount - _files.length;
			var tooMany:Boolean = false;
			
			if(_multipleFiles == true){
				// Add multiple files to the _files array
				if(event.currentTarget.fileList.length > remainingSpots) { tooMany = true; }
				var i:int;
				for (i=0;i < remainingSpots; i ++){
			    addFileToQueue(event.currentTarget.fileList[i]);
				}
			} else {
				// Add one single files to the _files array
				if(remainingSpots > 0) {
					addFileToQueue(FileReference(event.target));
				} else {
					tooMany = true;
				}
			}
			
			if(tooMany == true) {
				_errorNotifier.send("You can only upload "+_maxFileCount+" files at a time");
			}
			
			if(_files.length > 0) {
				_statusNotifier.send("Click 'Upload' to start loading files, or 'Browse...' to select more.");
			}
		}
		
		
		private function addFileToQueue(file:FileReference):void{
			if (checkFileSize(file.size)){
				_files.addItem(file);
				_fileSelectionNotifier.send(file,getContentType(file.name));
			}  else {
				_errorNotifier.send(file.name + " too large, max is " + Math.round(_maxFileSize / 1024) + " kb");
			}
		}
		
		// Called when the upload button is clicked
		private function uploadFiles():void{
			_file = FileReference(_files.getItemAt(0));
			_statusNotifier.send("Initiating "+_file.name+"...");
			// And away it goes!
			getSignature();
		}

		/* SIGNATURE */
		
    private function getSignature():void {
			var request:URLRequest     = new URLRequest(_signatureUrl);
			var loader:URLLoader       = new URLLoader();
			var variables:URLVariables = new URLVariables();

			_options.FileSize          = _file.size.toString();
			_options.FileName          = getFileName(_file);
			_options.ContentType       = getContentType(_options.FileName);
			_options.key               = _prefixPath + _options.FileName;

			variables.key              = _options.key
			variables.content_type     = _options.ContentType;

			request.method             = URLRequestMethod.GET;
			request.data               = variables;
			loader.dataFormat          = URLLoaderDataFormat.TEXT;

			loader.addEventListener(Event.COMPLETE, sigCompleteHandler);
			loader.addEventListener(Event.OPEN, sigOpenHandler);
			loader.addEventListener(ProgressEvent.PROGRESS, sigProgressHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, sigSecurityErrorHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, sigHttpStatusHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, sigIoErrorHandler);

			loader.load(request);
    }

		private function sigOpenHandler(event:Event):void {
			_statusNotifier.send("Preparing "+_file.name+"...");
		}

		private function sigProgressHandler(event:ProgressEvent):void {
		}

		private function sigSecurityErrorHandler(event:SecurityErrorEvent):void {
			_errorNotifier.send("Signature Security Error");
		}

		private function sigHttpStatusHandler(event:HTTPStatusEvent):void {
		}

		private function sigIoErrorHandler(event:IOErrorEvent):void {
			_errorNotifier.send("Signature Network Error");
		}

    private function sigCompleteHandler(event:Event):void {
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
					_startButton.enabled = true;
					_errorNotifier.send("Error! Please try again, or contact us for help.");
					return;
        }

        var request:S3UploadRequest = new S3UploadRequest(_options);
        request.addEventListener(Event.OPEN, s3OpenHandler);
        request.addEventListener(ProgressEvent.PROGRESS, s3ProgressHandler);
        request.addEventListener(IOErrorEvent.IO_ERROR, s3IoErrorHandler);
        request.addEventListener(SecurityErrorEvent.SECURITY_ERROR, s3SecurityErrorHandler);
        request.addEventListener(DataEvent.UPLOAD_COMPLETE_DATA, s3CompleteHandler);

        try {
					_statusNotifier.send("Uploading "+_file.name+"...");
					request.upload(_file);
				} catch(e:Error) {
					_errorNotifier.send("Upload error!");
        }
    }

		/* S3 S3 S3 */
		
		// called after the file is opened before upload    
		private function s3OpenHandler(event:Event):void{
			_statusNotifier.send("Opening "+_file.name+"... (This should only be called once per file)");
		}

		// called during the file upload of each file being uploaded
		// we use this to feed the progress bar its data
		private function s3ProgressHandler(event:ProgressEvent):void {
			_progressNotifier.send(event.bytesLoaded, event.bytesTotal, _queueSentSize+event.bytesLoaded, _queueFileSize)
		}

		// only called if there is an  error detected by flash player browsing or uploading a file   
		private function s3IoErrorHandler(event:IOErrorEvent):void{
			_errorNotifier.send("S3 Network Error");
		}    

		// only called if a security error detected by flash player such as a sandbox violation
		private function s3SecurityErrorHandler(event:SecurityErrorEvent):void{
			_errorNotifier.send("S3 Security Error");
		}
        
		private function s3CompleteHandler(event:Event):void{
			_successNotifier.send(_options);
			_queueSentSize += parseInt(_options.FileSize);
			_files.removeItemAt(0);
			if (_files.length > 0){
				// _totalbytes = 0;
				uploadFiles();
			} else {
				_browseButton.enabled = true;
				_stopButton.enabled = false;
				_completionNotifier.send();
				_statusNotifier.send("All uploads complete");
			}
		}    
		

		/* MISC MISC MISC */
		
		private function getFileName(file:FileReference):String {
			var fileName:String = file.name.replace(/^.*(\\|\/)/gi, '').replace(/[^A-Za-z0-9\.\-]/gi, '_');
			return fileName;
		}

		private function getContentType(fileName:String):String {
			var fileNameArray:Array    = fileName.split(/\./);
			var fileExtension:String   = fileNameArray[fileNameArray.length - 1];
			var contentType:String     = _mimeMap.getMimeType(fileExtension);
			return contentType;
		}

		// Checks the files do not exceed maxFileSize | if _maxFileSize == 0 No File Limit Set
		private function checkFileSize(filesize:Number):Boolean{
			var r:Boolean = false;
			//if  filesize greater then _maxFileSize
			if (filesize > _maxFileSize){
				r = false;
			} else if (filesize <= _maxFileSize){
				r = true;
			}
			if (_maxFileSize == 0){
				r = true;
			}
			return r;
		}

	}
}

package com.nathancolgate.s3_swf_upload {

	import com.adobe.net.MimeTypeMap;

	import com.elctech.S3UploadOptions;
	import com.elctech.S3UploadRequest;

	import mx.collections.ArrayCollection;
	import mx.controls.Button;
	// import mx.controls.DataGrid;
	// import mx.controls.dataGridClasses.*;
	import mx.events.CollectionEvent;
	
	//Events
	import flash.events.ProgressEvent;
	import flash.events.MouseEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.HTTPStatusEvent;
	import flash.events.DataEvent;
	
	import flash.external.ExternalInterface;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoaderDataFormat;

	import com.nathancolgate.s3_swf_upload.ErrorNotifier;
	import com.nathancolgate.s3_swf_upload.StatusNotifier;
	import com.nathancolgate.s3_swf_upload.FileSelectionNotifier;
	import com.nathancolgate.s3_swf_upload.ProgressNotifier;
	import com.nathancolgate.s3_swf_upload.SuccessNotifier;
	import com.nathancolgate.s3_swf_upload.CompletionNotifier;

	import com.nathancolgate.s3_swf_upload.ClearingManager;
	import com.nathancolgate.s3_swf_upload.CancelingManager;
	import com.nathancolgate.s3_swf_upload.UploadingManager;

	public class MultipleFileS3Uploader {

		//UI Vars
		private var _signatureUrl:String;
		private var _prefixPath:String;
		private var _browseButton:Button;
		
		/*
		private var _filesDataGrid:DataGrid;

	
		//DataGrid Columns
		private var _nameColumn:DataGridColumn;
		private var _sizeColumn:DataGridColumn;
		private var _columns:Array;
		*/
		
		//File Reference Vars
		[Bindable]
		private var _files:ArrayCollection;
		private var _fileref:FileReferenceList
		private var _file:FileReference;
		private var _totalbytes:Number;

		//config vars
		private var _options:S3UploadOptions;
		private var _maxFileCount:Number;
		private var _maxFileSize:Number; //bytes

		private var _mimeMap:MimeTypeMap;
		private var _fileFilter:FileFilter;

		// External Notifiers
		private var _statusNotifier:StatusNotifier;
		private var _errorNotifier:ErrorNotifier;
		private var _fileSelectionNotifier:FileSelectionNotifier;
		private var _progressNotifier:ProgressNotifier;
		private var _successNotifier:SuccessNotifier;
		private var _completionNotifier:CompletionNotifier;

		// External Managers
		private var _clearButton:ClearingManager;
		private var _cancelButton:CancelingManager;
		private var _uploadButton:UploadingManager;

		public function MultipleFileS3Uploader(signatureUrl:String,
																						prefixPath:String,
																						maxFileSize:Number,
																						fileTypes:String,
																						fileTypeDescs:String,
																						browseButton:Button,
																						maxFileCount:Number) {
			
			// set up from args
			_signatureUrl = signatureUrl;
			_prefixPath = prefixPath;
			_maxFileSize = maxFileSize;
			_fileFilter = new FileFilter(fileTypeDescs, fileTypes);
			_browseButton = browseButton;
			_maxFileCount = maxFileCount;
			// _filesDataGrid = filesDataGrid;

			init();
		}
        
		private function init():void {
			// Create options list for file s3 upload metadata 
			_options = new S3UploadOptions();
			
			// other defaults
			_mimeMap = new MimeTypeMap();
			_totalbytes = 0;

			// Setup File Array Collection and FileReference
			_files = new ArrayCollection();
			_fileref = new FileReferenceList;
			_file = new FileReference;
			
			// Build the Managers
			_clearButton 		= new ClearingManager("s3_swf.manageClearing");
			_cancelButton 	= new CancelingManager("s3_swf.manageCanceling");
			_uploadButton 	= new UploadingManager("s3_swf.manageUploading");
			
			// Build the Notifiers
			_errorNotifier					= new ErrorNotifier("s3_swf.onError");
			_statusNotifier					= new StatusNotifier("s3_swf.onStatus");
			_fileSelectionNotifier	= new FileSelectionNotifier("s3_swf.onFileSelection");
			_progressNotifier				= new ProgressNotifier("s3_swf.onProgress");
			_successNotifier				= new SuccessNotifier("s3_swf.onSuccess");
			_completionNotifier			= new CompletionNotifier("s3_swf.onCompletion");

			// Add Event Listeners/Callbacks to UI buttons...
			_browseButton.addEventListener(MouseEvent.CLICK, browseFiles);
			ExternalInterface.addCallback("upload", uploadFiles);
			ExternalInterface.addCallback("clear", clearFileQueue);
			ExternalInterface.addCallback("cancel", cancelFileIO);
			
			// ... and disable UI Buttons;
			_clearButton.enabled = false;
			_cancelButton.enabled = false;
			_uploadButton.enabled = false;

			// Add Listeners to the file management
			_fileref.addEventListener(Event.SELECT, selectHandler);
			_files.addEventListener(CollectionEvent.COLLECTION_CHANGE, popDataGrid);

			/*
			// Set Up DataGrid UI
			_nameColumn = new DataGridColumn;
			_sizeColumn = new DataGridColumn;
			// _updatedColumn = new DataGridColumn;

			_nameColumn.dataField = "name";
			_nameColumn.headerText= "File";

			_sizeColumn.dataField = "size";
			_sizeColumn.headerText = "Size";
			_sizeColumn.labelFunction = bytesColumnToString as Function;
			_sizeColumn.width = 52;

			// _updatedColumn.dataField = "modificationDate";
			// _updatedColumn.headerText = "Modified";
			// _updatedColumn.labelFunction = dateTimeColumnToString as Function;
			// _updatedColumn.width = 64;

			// _columns = new Array(_nameColumn, _sizeColumn, _updatedColumn);
			_columns = new Array(_nameColumn, _sizeColumn);
			_filesDataGrid.columns = _columns
			_filesDataGrid.sortableColumns = false;
			_filesDataGrid.dataProvider = _files;
			_filesDataGrid.dragEnabled = false;
			_filesDataGrid.dragMoveEnabled = false;
			_filesDataGrid.dropEnabled = false;
			*/
		}

		// called when the browse button is clicked
		// Browse for files
		private function browseFiles(event:Event):void{        
			_fileref.browse([_fileFilter]);
		}
		
		// Called when the upload button is clicked
		private function uploadFiles():void{
			if (_files.length > 0){
				_statusNotifier.send('Initiating...');
				_file = FileReference(_files.getItemAt(0));
				getSignature();
				// Manage the controls
				_browseButton.enabled = false;
				_clearButton.enabled = false;
				_uploadButton.enabled = false;
				_cancelButton.enabled = true;
			} else {
				_errorNotifier.send('You must select at least one file to upload');
			}
		}
		
		// Called when th clear button is clicked
		// Remove all files from the upload cue;
		private function clearFileQueue():void{
			_files.removeAll();
		}
		
		// Called when the cancel button is clicked
		// Cancel Current File Upload
		private function cancelFileIO():void{
			_file.cancel();
			// Manage the buttons
			_browseButton.enabled = true;
			_clearButton.enabled = true;
			_uploadButton.enabled = true;
			_cancelButton.enabled = false;
		}

		// whenever the _files arraycollection changes this function is called 
		// to make sure the datagrid data jives
		private function popDataGrid(event:CollectionEvent):void{                
			// Updates the total bytes var
			var i:int;
			_totalbytes = 0;
			for(i=0;i < _files.length;i++){
				_totalbytes +=  _files[i].size;
			}
			
			// handles UPLOAD and CLEAR states based on number of files in the cue;
			if (_files.length > 0){  
				_uploadButton.enabled = true;
				_clearButton.enabled = true;
			} else {
				_uploadButton.enabled = false;
				_clearButton.enabled = false;
			}
		}
		      

		//  called after user selected files form the browse dialouge box.
		private function selectHandler(event:Event):void {
			var i:int;
			var msg:String ="";
			var dl:Array = [];
			for (i=0;i < event.currentTarget.fileList.length; i ++){
				if (checkFileSize(event.currentTarget.fileList[i].size)){
					_files.addItem(event.currentTarget.fileList[i]);
					_fileSelectionNotifier.send(event.currentTarget.fileList[i],getContentType(event.currentTarget.fileList[i].name));
					// trace("under size " + event.currentTarget.fileList[i].size);
				}  else {
					dl.push(event.currentTarget.fileList[i]);
					_errorNotifier.send(event.currentTarget.fileList[i].name + " too large, max is " + Math.round(_maxFileSize / 1024) + " kb");
				}
			}	            

			/* Don't do this here, just make the external interface call above. */
			/*if (dl.length > 0) {
			for (i=0;i<dl.length;i++) {
			msg += String(dl[i].name + " is too large. \n");
			}
			mx.controls.Alert.show(msg + "Max File Size is: " + Math.round(_maxFileSize / 1024) + " kb","File Too Large",4,null).clipContent;
			}*/

			if(_files.length > 0) {
				_statusNotifier.send("Click 'Upload' to start loading files, or 'Browse...' to select more.");
			}
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
		_statusNotifier.send("Preparing...");
		// trace("openHandler: " + event);
		}

		private function sigProgressHandler(event:ProgressEvent):void {
		// trace("progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal);
		}

		private function sigSecurityErrorHandler(event:SecurityErrorEvent):void {
		// trace("securityErrorHandler: " + event);
		_errorNotifier.send("Security error!");
		// mx.controls.Alert.show(String(event),"securityError",0);
		}

		private function sigHttpStatusHandler(event:HTTPStatusEvent):void {
		// trace("httpStatusHandler: " + event);
		}

		private function sigIoErrorHandler(event:IOErrorEvent):void {
		// trace("ioErrorHandler: " + event);
		// trace(s3onFailedCall);
		_errorNotifier.send("Network error!");
		// mx.controls.Alert.show(String(event),"networkError",0);
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
						_uploadButton.enabled = true;
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
	        _statusNotifier.send("Upload started...");
            request.upload(_file);
        } catch(e:Error) {
            _errorNotifier.send("Upload error!");
            // trace("An error occurred: " + e);
        }
    }

		/* S3 S3 S3 */
		
		// called after the file is opened before upload    
		private function s3OpenHandler(event:Event):void{
			_statusNotifier.send("File (1 of "+_files.length+") is opened and about to be uploaded");
			// What's up with this?
			_files;
		}

		// called during the file upload of each file being uploaded
		// we use this to feed the progress bar its data
		private function s3ProgressHandler(event:ProgressEvent):void {
			_progressNotifier.send(event, _files.length-1)
		}

		// only called if there is an  error detected by flash player browsing or uploading a file   
		private function s3IoErrorHandler(event:IOErrorEvent):void{
			_errorNotifier.send("Error! Please retry, or contact us for help: " + String(event));
		}    

		// only called if a security error detected by flash player such as a sandbox violation
		private function s3SecurityErrorHandler(event:SecurityErrorEvent):void{
			_errorNotifier.send("Error, access denied: " + String(event));
		}
        
		private function s3CompleteHandler(event:Event):void{
			_successNotifier.send(_options);
			_files.removeItemAt(0);
			if (_files.length > 0){
				_totalbytes = 0;
				uploadFiles();
			} else {
				_browseButton.enabled = true;
				_cancelButton.enabled = false;
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

		/*
		//Remove Selected File From Queue
		private function removeSelectedFileFromQueue(event:Event):void{
			if (_filesDataGrid.selectedIndex >= 0){
				_files.removeItemAt( _filesDataGrid.selectedIndex);
			}
		}
		*/

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
		
		/* DESTROY DESTROY DESTROY */
		/* DESTROY DESTROY DESTROY */
		/* DESTROY DESTROY DESTROY */
		/* DESTROY DESTROY DESTROY */
		/* DESTROY DESTROY DESTROY */

		/*
		//label function for the datagird File Size Column
		private function bytesColumnToString(data:Object,blank:Object):String {
			return bytesToString(data.size);
		}

		//label function for the datagird File Size Column
		private function bytesToString(bytes:Number):String {
			var byteString:String;
			var kiloBytes:Number;
			kiloBytes = bytes / 1024;
			if (kiloBytes > 1024) {
				byteString = String(Math.round(kiloBytes / 1024)) + ' mb';
			} else {
				byteString = String(Math.round(kiloBytes)) + ' kb';
			}
			return byteString;
		}
		*/
        
		/*private function dateTimeColumnToString(data:Object, column:DataGridColumn):String {
		var dateString:String;
		dateString = _dateTimeFormatter.format(data.modificationDate);
		return dateString;
		}*/


	}
}

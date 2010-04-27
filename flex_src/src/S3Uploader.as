package  {
	//Events
	import flash.events.*;

	// Misc
	import flash.external.ExternalInterface;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.FileReferenceList;
	import flash.display.Sprite;
	import flash.system.Security;

	// S3 SWF Upload
	import com.nathancolgate.s3_swf_upload.*;
	
	public class S3Uploader extends Sprite {
		
		//File Reference Vars
		public var queue:S3Queue;
		public var file:FileReference;
		
		private var _multipleFileDialogBox:FileReferenceList;
		private var _singleFileDialogBox:FileReference;
		private var _fileFilter:FileFilter;
		
		//config vars
		private var _maxFileSize:Number; //bytes
		private var _maxFileCount:Number;
		private var _multipleFiles:Boolean;
		
		public function S3Uploader() {
			super();
			registerCallbacks();
		}

		private function registerCallbacks():void {
			if (ExternalInterface.available) {
				ExternalInterface.addCallback("init", init);
				ExternalInterface.call('s3_swf.init');
			}
		}

		private function init(signatureUrl:String,  
		                      prefixPath:String, 
		                      maxFileSize:Number,
													maxFileCount:Number,
		                      fileTypes:String,
		                      fileTypeDescs:String,
													multipleFiles:Boolean):void {
			
			
			flash.system.Security.allowDomain("*");

			var browseButton:BrowseButton = new BrowseButton;
      addChild(browseButton);
										
			// signature configs to be passed along to the S3 Signature objects
			Globals.signatureUrl = signatureUrl;
			Globals.prefixPath 	 = prefixPath;

			// file dialog boxes
			// We do two, so that we have the option to pick one or many
			_maxFileSize 					= maxFileSize;
			_fileFilter 					= new FileFilter(fileTypeDescs, fileTypes);
			_maxFileCount 				= maxFileCount;
			_multipleFiles 				= multipleFiles;
			_multipleFileDialogBox= new FileReferenceList;
			_singleFileDialogBox 	= new FileReference;
			_multipleFileDialogBox.addEventListener(Event.SELECT, selectFileHandler);
			_singleFileDialogBox.addEventListener(Event.SELECT, selectFileHandler);

			// The button!
			// _browseButton 				= new Button;
			addEventListener(MouseEvent.CLICK, clickHandler);

			// Setup Queue, File
			this.queue 						= new S3Queue;
			Globals.queue					= this.queue;
			this.file 						= null;
			Globals.file					= this.file;

			ExternalInterface.addCallback("removeFile", removeFileHandler);
			
			/*
				<mx:Application xmlns:mx="http://www.adobe.com/2006/mxml"
				               backgroundAlpha="0"
				               backgroundColor="#FFFFFF"
				               creationComplete="registerCallbacks();"
				               layout="absolute">
					<mx:Script source="S3Uploader.as"/>
					<mx:Button label="Browse..." id="browseButton"/>
				</mx:Application>
			*/
			
		}
		
		// called when the browse button is clicked
		// Browse for files
		private function clickHandler(event:Event):void{
			if(_multipleFiles == true){
				_multipleFileDialogBox.browse([_fileFilter]);
			} else {
				_singleFileDialogBox.browse([_fileFilter]);
			}
		}

		//  called after user selected files form the browse dialouge box.
		private function selectFileHandler(event:Event):void {
			var remainingSpots:int = _maxFileCount - this.queue.length;
			var tooMany:Boolean = false;
			
			if(_multipleFiles == true){
				// Add multiple files to the queue array
				if(event.currentTarget.fileList.length > remainingSpots) { tooMany = true; }
				var i:int;
				for (i=0;i < remainingSpots; i ++){
			    addFile(event.currentTarget.fileList[i]);
				}
			} else {
				// Add one single files to the queue array
				if(remainingSpots > 0) {
					addFile(FileReference(event.target));
				} else {
					tooMany = true;
				}
			}
			
			if(tooMany == true) {
				WarningMessage.send("You can only upload "+_maxFileCount+" files at a time");
			}

		}
		
		// Add Selected File to Queue from file browser dialog box
		private function addFile(file:FileReference):void{
			if (checkFileSize(file.size)){
				this.queue.addItem(file);
				ExternalInterface.call('s3_swf.onFileAdd',file);
			}  else {
				WarningMessage.send(this.file.name + " too large, max is " + Math.round(_maxFileSize / 1024) + " kb");
			}
		}
		
		
		// Remove File From Queue by index number
		private function removeFileHandler(index:Number):void{
			try {
				var del_file:FileReference = FileReference(this.queue.getItemAt(index));
				this.queue.removeItemAt(index);
				ExternalInterface.call('s3_swf.onFileRemove',del_file);
			} catch(e:Error) {
				WarningMessage.send('The specified file could not be found in the queue');
			}
		}


		/* MISC */

		// Checks the files do not exceed maxFileSize | if maxFileSize == 0 No File Limit Set
		private function checkFileSize(filesize:Number):Boolean{
			var r:Boolean = false;
			//if  filesize greater then maxFileSize
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
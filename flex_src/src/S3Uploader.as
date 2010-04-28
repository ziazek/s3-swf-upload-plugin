package  {

	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.*;
	import flash.display.Sprite;
	import flash.system.Security;
	import com.nathancolgate.s3_swf_upload.*;
	
	public class S3Uploader extends Sprite {
		
		//File Reference Vars
		public var queue:S3Queue;
		public var file:FileReference;
		
		private var _multipleFileDialogBox:FileReferenceList;
		private var _singleFileDialogBox:FileReference;
		private var _fileFilter:FileFilter;
		
		//config vars
		private var _fileSizeLimit:Number; //bytes
		private var _queueSizeLimit:Number;
		private var _selectMultipleFiles:Boolean;
		
		private var cssLoader:URLLoader;
		
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
		                      fileSizeLimit:Number,
													queueSizeLimit:Number,
		                      fileTypes:String,
		                      fileTypeDescs:String,
													selectMultipleFiles:Boolean,
													buttonWidth:Number,
													buttonHeight:Number,
													buttonUpUrl:String,
													buttonDownUrl:String,
													buttonOverUrl:String
													):void {
			
			flash.system.Security.allowDomain("*");
			
			// UI
			var browseButton:BrowseButton = new BrowseButton(buttonWidth,buttonHeight,buttonUpUrl,buttonDownUrl,buttonOverUrl);
		  addChild(browseButton);


      stage.showDefaultContextMenu = false;
      stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
      stage.align = flash.display.StageAlign.TOP_LEFT;

			this.addEventListener(MouseEvent.CLICK, clickHandler);

			// file dialog boxes
			// We do two, so that we have the option to pick one or many
			_fileSizeLimit 					= fileSizeLimit;
			_fileFilter 						= new FileFilter(fileTypeDescs, fileTypes);
			_queueSizeLimit 				= queueSizeLimit;
			_selectMultipleFiles		= selectMultipleFiles;
			_multipleFileDialogBox	= new FileReferenceList;
			_singleFileDialogBox 		= new FileReference;
			_multipleFileDialogBox.addEventListener(Event.SELECT, selectFileHandler);
			_singleFileDialogBox.addEventListener(Event.SELECT, selectFileHandler);

			

			// Setup Queue, File
			this.queue 						= new S3Queue(signatureUrl,prefixPath);
			Globals.queue					= this.queue;
			
			ExternalInterface.addCallback("removeFileFromQueue", removeFileHandler);
			
		}
		
		// called when the browse button is clicked
		// Browse for files
		private function clickHandler(event:Event):void{
			if(_selectMultipleFiles == true){
				_multipleFileDialogBox.browse([_fileFilter]);
			} else {
				_singleFileDialogBox.browse([_fileFilter]);
			}
		}

		//  called after user selected files form the browse dialouge box.
		private function selectFileHandler(event:Event):void {
			var remainingSpots:int = _queueSizeLimit - this.queue.length;
			var tooMany:Boolean = false;
			
			if(_selectMultipleFiles == true){
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
				ExternalInterface.call('s3_swf.onQueueSizeLimitReached',this.queue);
			}

		}
		
		// Add Selected File to Queue from file browser dialog box
		private function addFile(file:FileReference):void{
			if (checkFileSize(file.size)){
				this.queue.addItem(file);
				ExternalInterface.call('s3_swf.onFileAdd',file);
			}  else {
				ExternalInterface.call('s3_swf.onFileSizeLimitReached',file);
			}
		}
		
		
		// Remove File From Queue by index number
		private function removeFileHandler(index:Number):void{
			try {
				var del_file:FileReference = FileReference(this.queue.getItemAt(index));
				this.queue.removeItemAt(index);
				ExternalInterface.call('s3_swf.onFileRemove',del_file);
			} catch(e:Error) {
				ExternalInterface.call('s3_swf.onFileNotInQueue');
			}
		}


		/* MISC */

		// Checks the files do not exceed maxFileSize | if maxFileSize == 0 No File Limit Set
		private function checkFileSize(filesize:Number):Boolean{
			var r:Boolean = false;
			//if  filesize greater then maxFileSize
			if (filesize > _fileSizeLimit){
				r = false;
			} else if (filesize <= _fileSizeLimit){
				r = true;
			}
			if (_fileSizeLimit == 0){
				r = true;
			}
			return r;
		}
	}
}
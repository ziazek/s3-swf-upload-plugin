import com.elctech.S3UploadOptions;

import flash.external.ExternalInterface;

import mx.controls.DataGrid;
import mx.controls.ProgressBar;
import mx.controls.Button;
import mx.controls.Label;

import com.nathancolgate.s3_swf_upload.MultipleFileS3Uploader;

private var _multipleFileUploader:MultipleFileS3Uploader;

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
                      fileTypeDescs:String
                      ):void {
    _multipleFileUploader = new MultipleFileS3Uploader(signatureUrl,   
                                                       prefixPath,
                                                       maxFileSize,
                                                       fileTypes,
                                                       fileTypeDescs,
                                                       browseButton,
																											maxFileCount);
}

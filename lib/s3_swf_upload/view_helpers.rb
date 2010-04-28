module S3SwfUpload
  module ViewHelpers
    def s3_swf_upload_tag(options = {})
      width                   = options[:width]  || false
      height                  = options[:height] || false
    	flashVersion            = options [:height] || false
    	queueSizeLimit          = options [:queueSizeLimit] || false
    	fileSizeLimit           = options [:fileSizeLimit] || false
      fileTypes               = options [:fileTypes] || false
      fileTypeDescs           = options [:fileTypeDescs] || false
    	selectMultipleFiles     = options [:selectMultipleFiles] ||  true
      keyPrefix               = options [:keyPrefix] || false
    	signaturePath           = options [:signaturePath] || '/s3_uploads.xml'
    	buttonUpPath            = options [:buttonUpPath] || false
    	buttonOverPath          = options [:buttonOverPath] || false
    	buttonDownPath          = options [:buttonDownPath] || false
    	
    	onFileAdd							  = options [:buttonDownPath] || false		
    	onFileRemove						= options [:buttonDownPath] || false
    	onFileSizeLimitReached 	= options [:buttonDownPath] || false	
    	onFileNotInQueue				= options [:buttonDownPath] || false	
    	                        
    	onQueueChange						= options [:buttonDownPath] || false
    	onQueueClear						= options [:buttonDownPath] || false
    	onQueueSizeLimitReached	= options [:buttonDownPath] || false
    	onQueueEmpty						= options [:buttonDownPath] || false
    	                        
    	onUploadingStop					= options [:buttonDownPath] || false
    	onUploadingStart				= options [:buttonDownPath] || false
    	onUploadingFinish				= options [:buttonDownPath] || false
    	                        
    	onSignatureOpen					= options [:buttonDownPath] || false
    	onSignatureProgress			= options [:buttonDownPath] || false
    	onSignatureHttpStatus		= options [:buttonDownPath] || false
    	onSignatureComplete			= options [:buttonDownPath] || false
    	onSignatureSecurityError= options [:buttonDownPath] || false
    	onSignatureIOError			= options [:buttonDownPath] || false
    	onSignatureXMLError			= options [:buttonDownPath] || false
    	                        
    	onUploadOpen						= options [:buttonDownPath] || false
    	onUploadProgress				= options [:buttonDownPath] || false
    	onUploadHttpStatus			= options [:buttonDownPath] || false
    	onUploadComplete				= options [:buttonDownPath] || false
    	onUploadIOError					= options [:buttonDownPath] || false
    	onUploadSecurityError		= options [:buttonDownPath] || false
    	onUploadError						= options [:buttonDownPath] || false
    	
      @include_s3_upload ||= false 
      @count ||= 1
      
      out = ''

      if !@include_s3_upload
        out << javascript_include_tag('s3_upload')
        @include_s3_upload = true
      end

      out << '<script type="text/javascript">'
      out << "var s3_swf_#{@count}_object = s3_swf_init('s3_swf_#{@count}', {"
      out << "width: #{width}," if width
      out << "height: #{height}," if height
      out << "flashVersion: '#{flashVersion}'," if flashVersion
      out << "queueSizeLimit: #{queueSizeLimit}," if queueSizeLimit
      out << "fileSizeLimit: #{fileSizeLimit}," if fileSizeLimit
      out << "fileTypes: '#{fileTypes}'," if fileTypes
      out << "fileTypeDescs: '#{fileTypeDescs}'," if fileTypeDescs
      out << "selectMultipleFiles: '#{selectMultipleFiles}'," if selectMultipleFiles
      out << "keyPrefix: '#{keyPrefix}'," if keyPrefix
      out << "signaturePath: '#{signaturePath}'," if signaturePath
      out << "buttonUpPath: '#{buttonUpPath}'," if buttonUpPath
      out << "buttonOverPath: '#{buttonOverPath}'," if buttonOverPath
      out << "buttonDownPath: '#{buttonDownPath}'," if buttonDownPath
      out << "});"
      out << "</script>"
      out << '<div id="s3_swf_#{@count}">'
      out << 'Please <a href="http://www.adobe.com/go/getflashplayer">Update</a> your Flash Player to Flash v9.0.1 or higher...'
      out << "</div>"
      
      @count += 1
      out
    end

  end
end

ActionView::Base.send(:include, S3SwfUpload::ViewHelpers)

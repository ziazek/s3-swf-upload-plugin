package com.nathancolgate.s3_swf_upload {
	
	import flash.display.SimpleButton;
	import flash.display.Shape;
	import flash.events.MouseEvent;
	import flash.display.Sprite;

	public dynamic class BrowseButton extends Sprite {

		private var _playButton:flash.display.SimpleButton;
		
		public function BrowseButton()
		{
			super();
			build();
			draw();
			return;
		}
		


          public function draw():void
         {

            var play_rect:Shape = new flash.display.Shape();
            play_rect.graphics.beginFill(0xFFCC00);
            play_rect.graphics.lineStyle(1, 0x666666);
            play_rect.graphics.drawRect(0, 0, 80, 80);
            play_rect.graphics.endFill();

						var play_circle:Shape = new Shape();
            play_circle.graphics.beginFill(0xFFCC00);
            play_circle.graphics.lineStyle(1, 0x666666);
            play_circle.graphics.drawCircle(40, 40, 40);
            play_circle.graphics.endFill();

						var play_bigcircle:Shape = new Shape();
            play_bigcircle.graphics.beginFill(0xFFCC00);
            play_bigcircle.graphics.lineStyle(1, 0x666666);
            play_bigcircle.graphics.drawCircle(80, 80, 80);
            play_bigcircle.graphics.endFill();
    
						var loc8:*={
							"playOver":play_circle, 
							"playDown":play_bigcircle, 
							"playUp":play_rect
						};

						
             _playButton.upState = loc8.playUp;
             _playButton.overState = loc8.playOver;
             _playButton.downState = loc8.playDown;
             _playButton.useHandCursor = true;
             _playButton.hitTestState = loc8.playOver;

             return;
         }

		private function build():void
		{
			_playButton = new flash.display.SimpleButton();
			addChild(_playButton);
			return;
		}

	}
}

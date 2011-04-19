package screenshooter.events
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	/**
	 * ScreenshotEvent
	 *
	 * This class is used with the Screenshooter to take screenshots of displayobjects
	 *
	 * @author Jeremy Herrman
	 **/
	public class ScreenshotEvent extends Event
	{
		//--------------------------------------------------------------------------
		//
		//  Variables
		//
		//--------------------------------------------------------------------------

		public var imgBytes:ByteArray;
		public var rect:Rectangle;

		//--------------------------------------------------------------------------
		//
		//  Static Variables
		//
		//--------------------------------------------------------------------------

		public static const SCREENSHOT_START:String = "screenshotStart";
		public static const SCREENSHOT_FINISH:String = "screenshotFinish";
//		public static const ENCODING_START:String = "encodingStart";
//		public static const ENCODING_FINISH:String = "encodingFinish";

		//--------------------------------------------------------------------------
		//
		//  Properties
		//
		//--------------------------------------------------------------------------

		public function ScreenshotEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false, imageBytes:ByteArray = null, rectangle:Rectangle = null)
		{
			super(type, bubbles, cancelable);
			imgBytes = imageBytes;
			rect = rectangle;
		}

		//--------------------------------------------------------------------------
		//
		//  Methods
		//
		//--------------------------------------------------------------------------

		override public function clone():Event
		{
			return new ScreenshotEvent(this.type, this.bubbles, this.cancelable, this.imgBytes, this.rect);
		}

	}
}

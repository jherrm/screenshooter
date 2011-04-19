package screenshooter
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import mx.core.UIComponent;
	import mx.graphics.codec.JPEGEncoder;
	
	import screenshooter.events.ScreenshotEvent;

	public class ScreenshotManager extends UIComponent
	{
//		[Embed("crosshair.png")]
//		private var cursorSymbol:Class;
//		private var cursorID:Number = 0;

		private var _mouseDownLoc:Point;

		private var _encodingQuality:Number = 90;

		public function get encodingQuality():Number
		{
			return _encodingQuality;
		}
		public function set encodingQuality(value:Number):void
		{
			if(value > 100)
				_encodingQuality = 100;
			else if(value < 1)
				_encodingQuality = 1;
			else
				_encodingQuality = value;
		}

		private var _targetDisplayObject:DisplayObject;

		/**
		 * Restrict the bounds of the screenshooter to a specific container.
		 **/
		public function get targetDisplayObject():DisplayObject
		{
			return _targetDisplayObject;
		}
		public function set targetDisplayObject(value:DisplayObject):void
		{
			_targetDisplayObject = value;
		}

		private var _capturingBox:DisplayObject;

		/**
		 * Restrict the bounds of the screenshooter to a specific container.
		 **/
		public function get capturingBox():DisplayObject
		{
			return _capturingBox;
		}
		public function set capturingBox(value:DisplayObject):void
		{
			_capturingBox = value;
		}

		[Bindable]
		public var capturing:Boolean = false;

		//--------------------------------------------------------------------------
		//
		//  Constructor
		//
		//--------------------------------------------------------------------------

		public function ScreenshotManager()
		{
		}

		public function captureFullScreen():void
		{
			// When capturing the full screen we want to ignore the capturing box.
			captureSpecifiedDisplayObject(this.stage, false);
		}

		public function captureDisplayObject(limitToCapturingBox:Boolean=true, includeOverlap:Boolean=true):void
		{
			captureSpecifiedDisplayObject(targetDisplayObject, limitToCapturingBox, includeOverlap);
		}

		private function captureSpecifiedDisplayObject(object:DisplayObject, limitToCapturingBox:Boolean=true, includeOverlap:Boolean=true):void
		{
			if(object != null)
			{
				if(this.stage != null)
				{
					var coordinateSpace:DisplayObject = includeOverlap ? this.stage : object;
					capturePartialScreen(object.getBounds(coordinateSpace), coordinateSpace, limitToCapturingBox);
				}
				else
				{
					//Alert.show("The ScreenshotManager must be added to the stage.");
				}
			}
			else
			{
				//Alert.show("You must specify a targetDisplayObject");
			}
		}

		public function captureScreenArea(area:Rectangle, limitToCapturingBox:Boolean=true):void
		{
			capturePartialScreen(area, targetDisplayObject, limitToCapturingBox);
		}

		private function capturePartialScreen(bounds:Rectangle, coordinateSpace:DisplayObject, limitToCapturingBox:Boolean=true):void
		{
			var areaToCapture:Rectangle = bounds;

			// Get the intersection of the capture area and the capturing box bounds.
			if(capturingBox != null && limitToCapturingBox)
				areaToCapture = bounds.intersection(capturingBox.getBounds(coordinateSpace));

			if(areaToCapture.width <= 0 || areaToCapture.height <= 0)
				return;

			var bmpd:BitmapData = new BitmapData(areaToCapture.width, areaToCapture.height);

			var m:Matrix = new Matrix();
			m.tx = -areaToCapture.x;
			m.ty = -areaToCapture.y;
			bmpd.draw(coordinateSpace, m);

			dispatchEvent(new ScreenshotEvent(ScreenshotEvent.SCREENSHOT_START));

			var encoder:JPEGEncoder = new JPEGEncoder(encodingQuality);
			var imgBytes:ByteArray = encoder.encode(bmpd);

			dispatchEvent(new ScreenshotEvent(ScreenshotEvent.SCREENSHOT_FINISH, false, false, imgBytes));
		}

		public function startInteractiveCapture():void
		{
			this.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		}

		public function endInteractiveCapture():void
		{
			this.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		}

		//--------------------------------------------------------------------------
		//
		//  Event Handling
		//
		//--------------------------------------------------------------------------

		private function mouseDownHandler(event:MouseEvent):void
		{
			// set the mouse up handler on the stage that way the user doesn't
			// have to release the mouse button while hovering over the target
			if(this.stage != null)
			{
				this.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				this.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			}
			else
			{
				return;
			}

			capturing = true;

			// Save the initial global coordinates
			_mouseDownLoc = new Point(event.stageX, event.stageY);

			// Move the preview rectangle to the location of the mouse down.
//			var p:Point = new Point(event.localX, event.localY);
//			var p:Point = this.globalToLocal(new Point(event.stageX, event.stageY));
//			this.x = p.x;
//			this.y = p.y;
			this.x = event.stageX;
			this.y = event.stageY;
		}

		private function mouseMoveHandler(event:MouseEvent):void
		{
			this.graphics.clear();
			// anytime you clear you have to reset the linestyle
			this.graphics.lineStyle(1, 0x666666);
			this.graphics.drawRect(0, 0, event.stageX - _mouseDownLoc.x, event.stageY - _mouseDownLoc.y);
		}

		private function mouseUpHandler(event:MouseEvent):void
		{
			capturing = false;

			this.graphics.clear();
			if(this.stage != null)
			{
				this.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
				this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				this.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			}

			var rect:Rectangle = new Rectangle();

			// fix the rectangle if the mouse up was to the top left of the mouse down
			rect.x = (_mouseDownLoc.x < event.stageX) ? _mouseDownLoc.x : event.stageX;
			rect.y = (_mouseDownLoc.y < event.stageY) ? _mouseDownLoc.y : event.stageY;
			rect.width  = Math.abs(event.stageX - _mouseDownLoc.x);
			rect.height = Math.abs(event.stageY - _mouseDownLoc.y);

			// fix the rectangle if the mouse up was outside of the stage
			if(rect.x < 0)
			{
				rect.width += rect.x;
				rect.x = 0;
			}
			else if(rect.x + rect.width > this.stage.stageWidth)
			{
				rect.width = this.stage.stageWidth - rect.x;
			}

			if(rect.y < 0)
			{
				rect.height += rect.y;
				rect.y = 0;
			}
			else if(rect.y + rect.height > this.stage.stageHeight)
			{
				rect.height = this.stage.stageHeight - rect.y;
			}

			var bounds:Rectangle;
			var displayObject:DisplayObject;

			if(targetDisplayObject != null)
			{
				bounds = new Rectangle();
				bounds.topLeft = targetDisplayObject.globalToLocal(rect.topLeft);
				bounds.bottomRight = targetDisplayObject.globalToLocal(rect.bottomRight);

				displayObject = targetDisplayObject;
			}
			else
			{
				bounds = rect;
				displayObject = this.stage;
			}

			capturePartialScreen(bounds, displayObject);
		}

	}
}

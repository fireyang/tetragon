/*
 *      _________  __      __
 *    _/        / / /____ / /________ ____ ____  ___
 *   _/        / / __/ -_) __/ __/ _ `/ _ `/ _ \/ _ \
 *  _/________/  \__/\__/\__/_/  \_,_/\_, /\___/_//_/
 *                                   /___/
 * 
 * Tetragon : Game Engine for multi-platform ActionScript projects.
 * http://www.tetragonengine.com/ - Copyright (C) 2012 Sascha Balkau
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
package tetragon.core
{
	import tetragon.Main;
	import tetragon.data.Settings;

	import com.hexagonstar.signals.Signal;

	import flash.events.Event;
	import flash.utils.getTimer;
	
	
	/**
	 * A system that executes the main game loop by dispatching a tick and a render signal.
	 */
	public final class GameLoop
	{
		//-----------------------------------------------------------------------------------------
		// Properties
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Total number of milliseconds elapsed since game start.
		 * @private
		 */
		private var _total:uint;
		
		/**
		 * Total number of milliseconds elapsed since last update loop.
		 * Counts down as we step through the game loop.
		 * @private
		 */
		private var _accumulator:int;
		
		/**
		 * Milliseconds of time per step of the game loop.  FlashEvent.g. 60 fps = 16ms.
		 * @private
		 */
		private var _step:Number;
		
		/**
		 * Framerate of the Flash player (NOT the game loop). Default = 30.
		 * @private
		 */
		private var _stageFrameRate:uint;
		
		/**
		 * Max allowable accumulation (see _accumulator).
		 * Should always (and automatically) be set to roughly 2x the flash player framerate.
		 * @private
		 */
		private var _maxAccumulation:uint;
		
		/**
		 * Reference to Main.
		 * @private
		 */
		private var _main:Main;
		
		
		//-----------------------------------------------------------------------------------------
		// Signals
		//-----------------------------------------------------------------------------------------
		
		/** @private */
		private var _tickSignal:TickSignal;
		/** @private */
		private var _renderSignal:RenderSignal;
		/** @private */
		private var _frameRateChangedSignal:Signal;
		
		
		//-----------------------------------------------------------------------------------------
		// Constructor
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Creates a new instance of the class.
		 */
		public function GameLoop()
		{
			_main = Main.instance;
			_tickSignal = new TickSignal();
			_renderSignal = new RenderSignal();
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Public Methods
		//-----------------------------------------------------------------------------------------
		
		public function init():void
		{
			var f:Number = _main.registry.settings.getNumber(Settings.FRAME_RATE);
			if (isNaN(f)) f = 60;
			
			frameRate = f;
			stageFrameRate = _main.contextView.stage.frameRate;
			_accumulator = _step;
			_total = 0;
		}
		
		
		public function start():void
		{
			_main.contextView.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		
		public function stop():void
		{
			_main.contextView.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Getters & Setters
		//-----------------------------------------------------------------------------------------
		
		/**
		 * How many times you want the game to update each second. More updates usually
		 * means better collisions and smoother motion. NOTE: This is NOT the same thing
		 * as the Flash Player framerate!
		 */
		public function get frameRate():Number
		{
			return 1000 / _step;
		}
		public function set frameRate(v:Number):void
		{
			v = v < 5 ? 5 : v > 200 ? 200 : v;
			_step = 1000 / v;
			if (_maxAccumulation < _step) _maxAccumulation = _step;
			if (_frameRateChangedSignal) _frameRateChangedSignal.dispatch(frameRate);
		}
		
		
		public function get stageFrameRate():Number
		{
			return _main.contextView.stage.frameRate;
		}
		public function set stageFrameRate(v:Number):void
		{
			_stageFrameRate = v;
			_main.contextView.stage.frameRate = _stageFrameRate;
			_maxAccumulation = 2000 / _stageFrameRate - 1;
			if (_maxAccumulation < _step) _maxAccumulation = _step;
		}
		
		
		public function get tickSignal():TickSignal
		{
			return _tickSignal;
		}
		
		
		public function get renderSignal():RenderSignal
		{
			return _renderSignal;
		}
		
		
		public function get frameRateChangedSignal():Signal
		{
			if (!_frameRateChangedSignal) _frameRateChangedSignal = new Signal();
			return _frameRateChangedSignal;
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Callback Handlers
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		private function onEnterFrame(e:Event):void
		{
			var time:uint = getTimer();
			var ms:uint = time - _total;
			var ticks:uint = 0;
			_total = time;
			
			_accumulator += ms;
			if (_accumulator > _maxAccumulation)
			{
				_accumulator = _maxAccumulation;
			}
			while (_accumulator >= _step)
			{
				++ticks;
				_tickSignal.dispatch();
				_accumulator -= _step;
			}
			_renderSignal.dispatch(ticks, ms);
		}
	}
}

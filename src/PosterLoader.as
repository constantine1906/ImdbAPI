package
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	
	import mx.utils.URLUtil;
	
	[Event(name="complete",type="flash.events.Event")]
	[Event(name="error",type="flash.events.ErrorEvent")]
	
	public class PosterLoader extends EventDispatcher
	{
		public static const POSTERJPG:String = "poster.jpg";
		
		private var file:File;
		private var poster:FileStream;
		
		[Bindable] public var movie:Movie;
		
		public function PosterLoader(folder:File, movie:Movie)
		{
			super();
			this.file = folder.resolvePath(POSTERJPG);
			this.movie = movie;
		}
		
		public function fetchPoster():void
		{
			if(file.exists == false || file.size == 0)
			{
				if(URLUtil.isHttpURL(movie.parsed.posterUrl) || URLUtil.isHttpsURL(movie.parsed.posterUrl))
				{
					poster = new FileStream;
					poster.open(file, FileMode.WRITE);
					var u:URLStream = new URLStream;
					u.addEventListener(ProgressEvent.PROGRESS, onPosterProgress);
					u.addEventListener(Event.COMPLETE, onPosterComplete);
					u.addEventListener(IOErrorEvent.IO_ERROR, onPosterError);
					u.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onPosterError);
					var q:URLRequest = new URLRequest(movie.parsed.posterUrl);
					q.requestHeaders = [new URLRequestHeader('Referer', 'http://www.google.com')];
					u.load(q);
				}
				else
					dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, "Invalid poster url: " + movie.parsed.posterUrl));
			}
			else
				dispatchEvent(new Event(Event.COMPLETE));
		}
		
		protected function onPosterProgress(event:ProgressEvent):void
		{
			var u:URLStream = URLStream(event.target);
			var b:ByteArray = new ByteArray;
			u.readBytes(b);
			poster.writeBytes(b);
		}
		
		protected function onPosterComplete(event:Event):void
		{
			poster.close();
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		protected function onPosterError(event:Event):void
		{
			poster.close();
			file.deleteFile();
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, event.toString()));
		}
	}
}
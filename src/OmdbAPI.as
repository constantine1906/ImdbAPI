package
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class OmdbAPI
	{
		public var success:Function;
		public var failure:Function;
		
		public var id:String;
		public var title:String;
		public var year:String;
		
		public function OmdbAPI(success:Function, failure:Function)
		{
			this.success = success;
			this.failure = failure;
		}
		
		public function search(title:String, year:String):void
		{
			this.title = title;
			this.year = year;
			
			var url:String = "http://www.omdbapi.com/?s=" + encodeURIComponent(this.title) + "&r=XML";
			var l:URLLoader = new URLLoader;
			l.addEventListener(Event.COMPLETE, onSearchComplete);
			l.addEventListener(IOErrorEvent.IO_ERROR, onError);
			l.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			l.load(new URLRequest(url));
		}
		
		protected function onSearchComplete(event:Event):void
		{
			try
			{
				parseSearch(URLLoader(event.target).data);
			}
			catch(e:Error)
			{
				failure(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message, e.errorID));
			}
		}
		
		protected function parseSearch(response:String):void
		{
			var data:XML = XML(response);
			if(String(data.@response) == "True")
			{
				var find:XMLList = data.Movie.(@Year == this.year);
				find = find.(@Type == "movie");
				
				try
				{
					if(find.length() > 1)
						find = find.(@Title.split(/[\/\\:\*\?"<>\|%]/).join(" ").split("  ").join(" ") == this.title)
					
					if(find.length() >= 1)
						this.id = find[0].@imdbID.toString();
				}
				catch(e:Error){}
			}
			
			this.fetch();
		}
		
		public function fetch():void
		{
			var url:String;
			if(this.id && this.id.length > 0)
				url = "http://www.omdbapi.com/?i=" + encodeURIComponent(this.id) + "&r=XML";
			else
				url = "http://www.omdbapi.com/?t=" + encodeURIComponent(this.title) + "&y=" + this.year + "&r=XML";
			
			var l:URLLoader = new URLLoader;
			l.addEventListener(Event.COMPLETE, onFetchComplete);
			l.addEventListener(IOErrorEvent.IO_ERROR, onError);
			l.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			l.load(new URLRequest(url));
		}
		
		protected function onFetchComplete(event:Event):void
		{
			try
			{
				success(URLLoader(event.target).data);
			}
			catch(e:Error)
			{
				failure(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message, e.errorID));
			}
		}
		
		protected function onError(event:ErrorEvent):void
		{
			failure(event);
		}
	}
}
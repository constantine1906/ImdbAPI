package
{
	import flash.events.DataEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	[Event(name="complete",type="flash.events.Event")]
	[Event(name="error",type="flash.events.ErrorEvent")]
	[Event(name="data",type="flash.events.DataEvent")]
	
	public class MovieLoader extends EventDispatcher
	{
		public static const IMDBXML:String = "imdb.xml";
		public static const IMDBURL:String = "imdb.url";
		public static const FOLDERICON:String = "desktop.ini";
			
		public static const BYYEAR:String = "By Year";
		public static const BYRATING:String = "By Rating";
		public static const BYGENRE:String = "By Genre";
		public static const BYACTORS:String = "By Actors";
		public static const BYDIRECTORS:String = "By Directors";
		public static const BYCONTENT:String = "By Content Rating";
		public static const _ERROR:String = "_Errors";
		
		private static var renameAtDiff:uint;
		private static var actorsIndex:File;
		private static var genreIndex:File;
		private static var yearIndex:File;
		private static var ratingIndex:File;
		private static var directorIndex:File;
		private static var contentRatingIndex:File;
		private static var errorIndex:File;
		
		private static var cacheXML:Boolean = false;
		private static var urlShortcut:Boolean = false;
		private static var folderIcon:Boolean = false;
		private static var recreateAll:Boolean = false;
		
		private var response:String;
		[Bindable] public var folder:File;
		[Bindable] public var movie:Movie;
		
		public static function init(index:File, renameAtDiff:uint, linkTypes:uint, files:String):void
		{
			MovieLoader.renameAtDiff = renameAtDiff;
			
			if((linkTypes & Movie.YEAR) != 0)
			{
				yearIndex = index.resolvePath(BYYEAR);
				yearIndex.createDirectory();
			}
			if((linkTypes & Movie.RATING) != 0)
			{
				ratingIndex = index.resolvePath(BYRATING);
				ratingIndex.createDirectory();
			}
			if((linkTypes & Movie.GENRE) != 0)
			{
				genreIndex = index.resolvePath(BYGENRE);
				genreIndex.createDirectory();
			}
			if((linkTypes & Movie.ACTORS) != 0)
			{
				actorsIndex = index.resolvePath(BYACTORS);
				actorsIndex.createDirectory();
			}
			if((linkTypes & Movie.DIRECTORS) != 0)
			{
				directorIndex = index.resolvePath(BYDIRECTORS);
				directorIndex.createDirectory();
			}
			if((linkTypes & Movie.CONTENTRATING) != 0)
			{
				contentRatingIndex = index.resolvePath(BYCONTENT);
				contentRatingIndex.createDirectory();
			}
			
			errorIndex = index.resolvePath(_ERROR);
			errorIndex.createDirectory();
			
			cacheXML = files.indexOf(IMDBXML) != -1;
			urlShortcut = files.indexOf(IMDBURL) != -1;
			folderIcon = files.indexOf(FOLDERICON) != -1;
		}
		
		public static function deleteIndices():void
		{
			if(genreIndex && genreIndex.exists)
				genreIndex.deleteDirectory(true);
			
			if(ratingIndex && ratingIndex.exists)
				ratingIndex.deleteDirectory(true);
			
			if(yearIndex && yearIndex.exists)
				yearIndex.deleteDirectory(true);
			
			if(actorsIndex && actorsIndex.exists)
				actorsIndex.deleteDirectory(true);
			
			if(directorIndex && directorIndex.exists)
				directorIndex.deleteDirectory(true);
			
			if(contentRatingIndex && contentRatingIndex.exists)
				contentRatingIndex.deleteDirectory(true);
			
			if(errorIndex && errorIndex.exists)
				errorIndex.deleteDirectory(true);
		}
		
		public function MovieLoader(folder:File)
		{
			super();
			this.folder = folder;
			this.movie = new Movie(folder.parent.getRelativePath(folder, false));
		}
		
		public function fetchInfo():void
		{
			var record:File = folder.resolvePath(IMDBXML);
			if(record.exists == false || record.size == 0)
				new OmdbAPI(onResponse, onError).search(movie.detected.title, movie.detected.year);
			else
			{
				try
				{
					var f:FileStream = new FileStream;
					f.open(record, FileMode.READ);
					response = f.readUTFBytes(record.size);
					f.close();
					onResponse(response);
				}
				catch(e:Error)
				{
					onError(new ErrorEvent(ErrorEvent.ERROR, false, false, e.message, e.errorID));
				}
			}
		}
		
		protected function onResponse(response:String):void
		{
			var data:XML = XML(response);
			if(String(data.@response).toLowerCase() != "true")
				throw new Error("Error response: " + response.split("\n").join(" "));
			
			movie.parseData(data);
			createFiles(response);
			processResponse();
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		protected function processResponse():void
		{
			if((movie.diff & renameAtDiff) > 0)
				moveFolder();
			
			if(yearIndex != null)
				processYear();
			
			if(ratingIndex != null)
				processRating();
			
			if(genreIndex != null)
				processGenreList();
			
			if(actorsIndex != null)
				processActorList();
			
			if(directorIndex != null)
				processDirectorsList();
			
			if(contentRatingIndex != null)
				processContentRating();
		}
		
		protected function moveFolder():void
		{
			var info:String = "Old: " + folder.nativePath;
			var tempFolder:File = folder.parent.resolvePath(new Date().time.toString());
			folder.moveTo(tempFolder, false);
			folder = folder.parent.resolvePath(movie.parsed.name);
			tempFolder.moveTo(folder, false);
			info += " New: " + folder.nativePath;
			movie = new Movie(folder.parent.getRelativePath(folder, false));
			movie.parseData(XML(response));
			dispatchEvent(new DataEvent(DataEvent.DATA, false, false, info));
		}
		
		protected function processYear():void
		{
			var name:String = Movie.createName(this.movie.parsed, Movie.TITLE + Movie.RATING + Movie.GENRE);
			var y:File = yearIndex.resolvePath(movie.parsed.year);
			if(!y.exists)
				y.createDirectory();
			createSymLink(y, name);
		}
		
		protected function processRating():void
		{
			var name:String = Movie.createName(this.movie.parsed, Movie.TITLE + Movie.YEAR + Movie.RATING + Movie.GENRE);
			var _rating:Number = Number(movie.parsed.rating);
			var _l:Number = Math.floor(2*_rating)/2;
			var _h:Number = Math.floor(2*_rating + 1)/2 - 0.1;
			var rating:String = _l.toFixed(1) + " - " + (_h).toFixed(1);
			var r:File = ratingIndex.resolvePath(rating);
			if(!r.exists)
				r.createDirectory();
			createSymLink(r, name);
		}
		
		protected function processGenreList():void
		{
			var name:String = Movie.createName(this.movie.parsed, Movie.TITLE + Movie.YEAR + Movie.RATING + Movie.GENRE);
			for(var i:uint = 0; i<movie.parsed.genre.length; ++i)
			{
				var g:File = genreIndex.resolvePath(movie.parsed.genre[i]);
				if(!g.exists)
					g.createDirectory();
				createSymLink(g, name);
			}
		}
		
		protected function processActorList():void
		{
			var name:String = Movie.createName(this.movie.parsed, Movie.TITLE + Movie.YEAR + Movie.RATING + Movie.GENRE);
			for(var i:uint = 0; i<movie.parsed.actors.length; ++i)
			{
				var a:File = actorsIndex.resolvePath(movie.parsed.actors[i]);
				if(!a.exists)
					a.createDirectory();
				createSymLink(a, name);
			}
		}
		
		protected function processDirectorsList():void
		{
			var name:String = Movie.createName(this.movie.parsed, Movie.TITLE + Movie.YEAR + Movie.RATING + Movie.GENRE);
			for(var i:uint = 0; i<movie.parsed.directors.length; ++i)
			{
				var d:File = directorIndex.resolvePath(movie.parsed.directors[i]);
				if(!d.exists)
					d.createDirectory();
				createSymLink(d, name);
			}
		}
		
		protected function processContentRating():void
		{
			var name:String = Movie.createName(this.movie.parsed, Movie.TITLE + Movie.YEAR + Movie.RATING + Movie.GENRE);
			var c:File = contentRatingIndex.resolvePath(movie.parsed.contentRating);
			if(!c.exists)
				c.createDirectory();
			createSymLink(c, name);
		}
		
		protected function createFiles(data:String):void
		{
			if(cacheXML)
				FSUtils.createFileIfNotFound(folder.resolvePath(IMDBXML).nativePath, data);
			
			if(urlShortcut)
				FSUtils.createFileIfNotFound(folder.resolvePath(IMDBURL).nativePath,
					"[InternetShortcut]\r\nURL=http://www.imdb.com/title/" + movie.parsed.id + "/\r\nIconFile=C:\\Windows\\system32\\SHELL32.dll\r\nIconIndex=220");
			
			if(folderIcon)
			{
				FSUtils.createFileIfNotFound(folder.resolvePath(FOLDERICON).nativePath,
					"[ViewState]\r\nFolderType=Videos\r\nLogo=" + folder.resolvePath(PosterLoader.POSTERJPG).nativePath + "\r\n");
				FSUtils.changeAttribute(folder.resolvePath(FOLDERICON).nativePath, ['+s']);
			}
		}
		
		protected function createSymLink(f:File, name:String):void
		{
			FSUtils.createSymbolicLink(folder.nativePath.split(":")[1], f.resolvePath(name).nativePath);
		}
		
		protected function onError(event:ErrorEvent):void
		{
			var name:String = Movie.createName(this.movie.detected, Movie.TITLE + Movie.YEAR);
			createSymLink(errorIndex, name);
			dispatchEvent(event.clone());
		}
	}
}
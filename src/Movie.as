package
{
	[Bindable]
	public class Movie extends Object
	{
		public static const TITLE_CASE:uint = 0x1;
		public static const TITLE:uint = 0x2;
		public static const YEAR:uint = 0x4;
		public static const RATING:uint = 0x8;
		public static const GENRE:uint = 0x10;
		public static const ACTORS:uint = 0x20;
		public static const DIRECTORS:uint = 0x40;
		public static const CONTENTRATING:uint = 0x80;
		
		private static const UNKNOWN:String = "_Unknown";
		private static const CERROR:String = '<font color="#00FF00">';
		private static const TERROR:String = '<font color="#0000FF">';
		private static const YERROR:String = '<font color="#FF0000">';
		private static const _END:String = '</font>';
		
		public var imdbID:String;
		public var detected:MovieData = new MovieData;
		public var parsed:MovieData = new MovieData;
		
		public var diff:uint = 0;
		public var diffDetail:String = "";
		
		public function Movie(detectedName:String)
		{
			super();
			
			this.detected.name = detectedName;
			var c:Array = detectedName.split(" ");
			this.detected.year = String(c.pop()).substr(1, 4);
			this.detected.title = c.join(" ");
		}
		
		public function parseData(data:XML):void
		{
			this.parsed.id = parseString(data.movie.@imdbID, "");
			this.parsed.title = parseString(data.movie.@title, this.detected.title).split(/[\/\\:\*\?"<>\|]/).join(" ").split("  ").join(" ");
			this.parsed.year = parseString(data.movie.@year, this.detected.year);
			this.parsed.rating = parseString(data.movie.@imdbRating, UNKNOWN);
			this.parsed.genre = parseArray(String(data.movie.@genre), [UNKNOWN]);
			this.parsed.actors = parseArray(String(data.movie.@actors), [UNKNOWN]);
			this.parsed.directors = parseArray(String(data.movie.@director), [UNKNOWN]);
			this.parsed.contentRating = parseString(data.movie.@rated, UNKNOWN);
			this.parsed.posterUrl = parseString(data.movie.@poster, "");
			
			this.parsed.name = Movie.createName(this.parsed, Movie.TITLE + Movie.YEAR);
			
			var _c:Boolean = false;
			var _t:Boolean = false;
			var _y:Boolean = false;
			
			if(this.detected.title != this.parsed.title)
				if(this.detected.title.toLowerCase() == this.parsed.title.toLowerCase())
				{
					diff += TITLE_CASE;
					_c = true;
				}
				else
				{
					diff += TITLE;
					_t = true;
				}
			
			if(this.parsed.year != this.detected.year)
			{
				diff += YEAR;
				_y = true;
			}
			
			if(diff != 0)
			{
				diffDetail =
					(_c ? CERROR : (_t ? TERROR : '')) + this.detected.title + (_c || _t ? _END : '') +
					(_y ? YERROR : '') + ' (' + this.detected.year + ') ' + (_y ? _END : '') +'\t\t\t\t' +
					(_c ? CERROR : (_t ? TERROR : '')) + this.parsed.title + (_c || _t ? _END : '') +
					(_y ? YERROR : '') + ' (' + this.parsed.year + ')' + (_y ? _END : '');
			}
		}
		
		protected static function parseString(str:String, def:String):String
		{
			if(str == null || str == "" || str.toLowerCase() == "n/a")
				return def;
			else
				return str;
		}
		
		protected static function parseArray(str:String, def:Array):Array
		{
			var array:Array = new Array;
			var a:Array = str.split(", ");
			for each(var item:String in a)
			if(item.length >= 0 && item.toLowerCase() != "n/a")
				array.push(item);
			
			if(array.length == 0)
				return def;
			else
				return array.sort();
		}
		
		public static function createName(movie:MovieData, incl:uint):String
		{
			var name:String = "";
			if((incl & Movie.TITLE) > 0)
				name += movie.title;
			
			if((incl & Movie.YEAR) > 0)
				name += (name.length > 0 ? " " : "") + "(" + movie.year + ")";
			
			if((incl & Movie.RATING) > 0)
				name += (name.length > 0 ? " " : "") + movie.rating;
			
			if((incl & Movie.GENRE) > 0)
				name += (name.length > 0 ? " " : "") + "[" + movie.genre.join(", ") + "]";
			
			if((incl & Movie.ACTORS) > 0)
				name += (name.length > 0 ? " " : "") + "[" + movie.actors.join(", ") + "]";
			
			if((incl & Movie.DIRECTORS) > 0)
				name += (name.length > 0 ? " " : "") + "[" + movie.directors.join(", ") + "]";
			
			if((incl & Movie.CONTENTRATING) > 0)
				name += (name.length > 0 ? " " : "") + movie.contentRating;
			
			return name;
		}
	}
}
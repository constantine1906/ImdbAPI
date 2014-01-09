package
{
	[Bindable]
	public class MovieData extends Object
	{
		public var id:String = "";
		public var name:String = "";
		public var title:String = "";
		public var year:String = "";
		public var rating:String = "";
		public var genre:Array = new Array;
		public var actors:Array = new Array;
		public var directors:Array = new Array;
		public var contentRating:String = "";
		public var posterUrl:String = "";
	}
}
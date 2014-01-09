package
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	
	import mx.utils.StringUtil;

	public class FSUtils
	{
		public static const COMMAND_INTERPRETER:String = "C:\\Windows\\system32\\cmd.exe";
		
		public static function deleteFile(file:String, dir:String, recursive:Boolean = true, attrib:String = null):void
		{
			var args:Vector.<String> = new Vector.<String>;
			args.push("/c");
			args.push("del");
			args.push("/q");
			if(recursive == true)
				args.push("/s");
			if(attrib != null && attrib.length > 0)
				args.push("/a:" + attrib);
			args.push(file);
			startProcess(COMMAND_INTERPRETER, args, dir);
		}
		
		public static function createFileIfNotFound(path:String, data:String):void
		{
			var f:FileStream = new FileStream;
			var file:File = new File(path);
			if(!file.exists || file.size == 0)
			{
				f.open(file, FileMode.WRITE);
				f.writeUTFBytes(data);
				f.close();
			}
		}
		
		public static function createSymbolicLink(target:String, name:String):void
		{
			var args:Vector.<String>  = new Vector.<String>;
			args.push("/c");
			args.push("mklink");
			args.push("/d");
			args.push(name);
			args.push(target);
			startProcess(COMMAND_INTERPRETER, args);
		}
		
		public static function changeAttribute(file:String, attributes:Array):void
		{
			var args:Vector.<String> = new Vector.<String>;
			args.push("/c");
			args.push("attrib");
			for each(var attrib:String in attributes)
				args.push(String(attrib));
			args.push(file);
			startProcess(COMMAND_INTERPRETER, args);
		}
		
		public static function startProcess(exec:String, args:Vector.<String>, dir:String = null):void
		{
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo;
			info.executable = new File(exec);
			info.arguments = args;
			if(dir && dir.length > 0)
				info.workingDirectory = new File(dir);
			
			var proc:NativeProcess = new NativeProcess;
			proc.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, processIOErrorHandler);
			proc.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, processOutputHandler);
			proc.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, processErrorHandler);
			proc.addEventListener(NativeProcessExitEvent.EXIT, processExitHandler);
			proc.start(info);
		}
		
		private static function processIOErrorHandler(event:IOErrorEvent):void
		{
			trace(event.toString() + " " + event.text);
		}
		
		private static function processOutputHandler(event:ProgressEvent):void
		{
			var data:IDataInput = NativeProcess(event.target).standardOutput;
			var str:String = StringUtil.trim(data.readUTFBytes(data.bytesAvailable));
			trace(str);
		}
		
		private static function processErrorHandler(event:ProgressEvent):void
		{
			var data:IDataInput = NativeProcess(event.target).standardError;
			var str:String = StringUtil.trim(data.readUTFBytes(data.bytesAvailable));
			trace(str);
		}
		
		private static function processExitHandler(event:NativeProcessExitEvent):void
		{
			var proc:NativeProcess = NativeProcess(event.target);
			proc.removeEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, processIOErrorHandler);
			proc.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, processOutputHandler);
			proc.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, processErrorHandler);
			proc.removeEventListener(NativeProcessExitEvent.EXIT, processExitHandler);
			if(event.exitCode != 0)
				trace(event.toString());
		}
	}
}

package core;

import sys.Web;

typedef Route = {
	var regex:EReg;
	var path:String;
};

class Router
{

	public function new()
	{
		_routes = new Array();
	}

	public function add(regex:EReg, path:String)
	{
		_routes.push({regex: regex, path: path});
	}

	public function route()
	{
		var params = Web.getParams();
		var controllerName:String = Tracks.settings.defaultController;
		var method:String = Tracks.settings.defaultMethod;

		var args:Array<String> = [];
		if (params.exists('uri'))
		{
			var uri = params.get('uri');

			// search for user defined routes
			for (r in _routes)
			{
				if (r.regex.match(uri))
				{
					uri = r.regex.replace(uri, r.path);
				}
			}

			var route:Array<String> = uri.split('/'), val:String;

			// Controller
			if (route.length > 0)
			{
				val = route.shift();
				if (val != "") controllerName = val;
			}

			// Method
			if (route.length > 0)
			{
				val = route.shift();
				if (val != "") method = val;
			}

			args = route;
		}

		controllerName = controllerName.toLowerCase();

		// convert to haxe name (poSts = Posts)
		var controllerClass = Tracks.settings.controllerPackage + "." + controllerName.charAt(0).toUpperCase() + controllerName.substr(1);

		// Find the controller and run the appropriate method
		var proto = Type.resolveClass(controllerClass);
		if (proto == null)
		{
			throw "Could not find '" + controllerClass + "'. Make sure it is compiled.";
		}
		else
		{
			var inst = Type.createInstance(proto, []);
			if (inst == null || !Std.is(inst, core.Controller))
			{
				throw "Could not create an instance of " + controllerClass;
			}
			else
			{
				inst.name = controllerName;
				var func = Reflect.field(inst, method);
				if (func == null)
				{
					throw "Method does not exist " + method;
				}
				else
				{
					Reflect.callMethod(inst, func, args);
				}
			}
		}
	}

	private var _routes:Array<Route>;

}
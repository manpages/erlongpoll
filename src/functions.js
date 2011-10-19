function Poll (argURL, argHandler) {
	$.get(AbsURL(argURL), function(data) {
		var varTuple = eval(data);
		if(!varTuple[0]) {
			argHandler (varTuple[1]);
			Poll (argURL, argHandler);
		} 	
	})
}

function AbsURL(argRelativeURL) {
	return document.location.protocol + "//" + document.location.host + argRelativeURL;
}

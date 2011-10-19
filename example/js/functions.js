function RegisterFileUploader(argNode) { //argNode -- jQuery node
	var varFormNode = argNode.closest("form");
	varFormNode.ajaxForm({
		beforeSubmit: 
			function(argFormData, argJqForm, argOptions) {
				argNode.attr('data-progress', 0.0);
				PollID = argNode.attr('name');
				console.log("tut");
				Poll ('/longpoll/' +  PollID, function (data) {
					argNode.attr('data-progress', parseFloat(data));
					argNode.trigger('newChunk');
				});
				return true;
			},
		success: 
			function (argResponse, argStatus) {
				argNode.attr('data-progress', 100.00);
				console.log ('INVOKING ' + 100.00);
				argNode.trigger('newChunk');
			},
		error:
			function() {
				console.log("pizdets");
			}
	});
	argNode.change(function () {
		varFormNode.submit();
	});
}

function Poll (argURL, argHandler) {
	var varURL = document.location.protocol + "//" + document.location.host + argURL;
	console.log("tam " + argURL);
	$.get(varURL, function(data) {
		var varTuple = eval(data);
		if(!varTuple[0]) {
			argHandler (varTuple[1]);
			Poll (argURL, argHandler);
		} 	
	})
}

function Request(module, method, params, callback) {

	var SuccessFunc = function(params) {
			if (params.refresh)
				document.location.reload();
						
			if (params.alert)
				alert(params.alert);
				
			if (params.error)
				alert(params.error);
			else
				callback(params);
	};

	if (typeof(Ajax) != "undefined") { //We have prototype
		new Ajax.Request('/!/'+module+'/'+method, {
			method:'post',
			postBody:'json='+encodeURIComponent(Object.toJSON(params)),
			onSuccess: function(transport) {			
				try {
					var json = transport.responseText.evalJSON();
					SuccessFunc(json);
				}
				catch (e) {
					if (transport.responseText && transport.responseText.length)
						return alert("Error occured while talking to server.\n"+transport.responseText + "\n" + e.message);
				}
			}
		});
	}
	else if (typeof(jQuery) != "undefined") { //We have jQuery
		jQuery.post('/!/'+module+'/'+method, 
			$.toJSON(params),
			function(response) {
				try {
					var json = $.parseJSON(response);
					SuccessFunc(json);
				}
				catch (e) {
					if (response && response.length)
						return alert("Error occured while talking to server.\n" + response + "\n" + e.message);
				}
			}
		);
	}
	else {
		alert('Please install prototype.js or jQuery + http://jollytoad.googlepages.com/json.js (or rewrite Request() yourself)');
	}
}

function RegisterFileUploader(argNode) { //argNode -- jQuery node
	var varFormNode = argNode.closest("form");
	varFormNode.ajaxForm({
		beforeSubmit: 
			function(argFormData, argJqForm, argOptions) {
				argNode.attr('data-progress', 0.0);
				PollID = argNode.attr('name');
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
	console.log("Poll xD");
	$.get(argURL, function(data) {
		var varTuple = eval(data);
		if(!varTuple[0]) {
			argHandler (varTuple[1]);
			Poll (argURL, argHandler);
		} 	
	})
}

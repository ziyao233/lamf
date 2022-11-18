local dequery = require("http.url").parse_query;
return {
	decode = function(path,arg,header,body)
		return dequery(arg) or {};
	end,
       };

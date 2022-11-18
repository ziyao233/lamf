local skynet	= require("skynet");

skynet.start(function()
	skynet.dispatch("lua",function(src,session,cmd)
		skynet.ret(skynet.pack("Hello lamf (dummy service)\n"));
	end);
end);

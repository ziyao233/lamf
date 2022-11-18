--[[
--	lamf
--	File:/service/HTTP_Gateway.lua
--	Date:2022.11.19
--	By MIT License.
--	Copyright (c) 2022 Ziyao.
--]]

local table		= require "table";
local string		= require "string";
local math		= require "math";

local skynet		= require "skynet";
local socket		= require "skynet.socket";
local httpd		= require "http.httpd";
local socketHelper	= require "http.sockethelper";

local mode = ...;

--[[
--	Main Service
--]]
if not mode
then
local workerList,balance = {},1;
local workerNum = math.tointeger(skynet.getenv "thread");

local cmdList = {};
cmdList.publish = function(...)
	for i = 1,workerNum
	do
		skynet.send(workerList[i],"lua","publish",...);
	end
end;

skynet.start(function()
	for i = 1,workerNum
	do
		table.insert(workerList,
			     skynet.newservice("HTTP_Gateway","worker"));
	end

	local sock = socket.start(socket.listen(skynet.getenv "listenAddress",
						skynet.getenv "listenPort"),
				  function(conn)
		skynet.send(workerList[balance],"lua","connection",conn);
		balance = balance == workerNum and 1 or balance + 1;
	end);

	skynet.dispatch("lua",function(src,session,cmd,...)
		cmdList[cmd](...);
	end);
end);
else
--[[
--	Worker Service
--]]
local writeFunction = socketHelper.writefunc;
local readFunction = socketHelper.readfunc;
local readRequest = httpd.read_request;
local writeResponse = httpd.write_response;
local contentSizeLimit = skynet.getenv "maxRequestSize";
local respond = function(helper,...)
	local ok,err = writeResponse(helper,...);
	if not ok
	then
		skynet.error(string.format("HTTP_Gateway: write response, %s",
					   err));
	end
end
local socketError = socketHelper.socket_error;
local cmdList,serviceList = {},{};
local encoders,decoders = require "lamf.encoders",require "lamf.decoders";
local dequery = require("http.url").parse;
cmdList.connection = function(conn)
	socket.start(conn);

	local reader = readFunction(conn);

	local code,url,method,header,body =
		readRequest(reader,contentSizeLimit);
	if code
	then
		if code ~= 200
		then
			respond(writeFunction(conn),500);
		else
			local path,query = dequery(url);
			local service = serviceList[path];
			if not service
			then
				respond(writeFunction(conn),404,"\n");
			else
				local ret = skynet.call(service.id,"lua",
					service.decode(path,query,header,body));
				respond(writeFunction(conn),200,
					service.encode(ret));
			end
		end
	else
		if url == socketError
		then
			skynet.error("Connection closed");
		else
			skynet.error(url);
		end
	end
	socket.close(conn);	-- XXX:Keepalive
end;

cmdList.publish = function(id,path,input,output)
	serviceList[path] = {
				id	= id,
				encode	= encoders[output],
				decode	= decoders[input],
			    };
end;

skynet.start(function()
	skynet.dispatch("lua",function(src,session,cmd,...)
		cmdList[cmd](...);
	end);
end);
end

--[[
--	lamf
--	File:/service/HTTP_Gateway.lua
--	Date:2022.11.11
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
local urllib		= require "http.url";


local mode = ...;

if not mode
then
skynet.start(function()
	local workerList,balance = {},1;
	local workerNum = math.tointeger(skynet.getenv "thread");
	for i = 1,workerNum
	do
		table.insert(workerList,
			     skynet.newservice("HTTP_Gateway","worker"));
	end

	local sock = socket.start(socket.listen(skynet.getenv "listenAddress",
						skynet.getenv "listenPort"),
				  function(conn)
		skynet.send(workerList[balance],"lua",conn);
		balance = balance == workerNum and 1 or balance + 1;
		print(balance);
	end);
end);
else

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
skynet.start(function()
	skynet.dispatch("lua",function(session,src,conn)
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
				local path,query = urllib.parse(url);
				print(path);
				if query
				then
					for k,v in pairs(urllib.parse_query(query))
					do
						print(k .. ": " .. v);
					end
				end
				respond(writeFunction(conn),200,"\n");
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
	end);
end);
end

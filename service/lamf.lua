--[[
--	lamf
--	Main Controller
--	File:/service/lamf.lua
--	Date:2022.11.10
--	By MIT License.
--	Copyright (c) 2022 Ziyao.
--]]

local skynet		= require "skynet";
local socket		= require "skynet.socket";

local consoleHandler = function(conn)
	socket.write(conn,"Welcome to lamf console\n");
	while true
	do
		local cmd = socket.readline(conn);
		if cmd == "bye"
		then
			break;
		else
			socket.write(conn,"Unknown Command\n");
		end
	end
	socket.close(conn);
	return;
end;
local startConsole = function()
	socket.start(socket.listen("::",skynet.getenv "consolePort"),
		     function(conn)
		socket.start(conn);
		skynet.fork(consoleHandler,conn);
		return;
	end);
end;

skynet.start(function()
	startConsole();
	skynet.newservice "HTTP_Gateway";
end);

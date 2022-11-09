--[[
--	lamf
--	lamf skynet configuration
--	File:/lamf.conf.lua
--	Date:2022.11.10
--	By MIT License.
--	Copyright (c) 2022 Ziyao.
--]]

include "lamf_path.conf.lua"

thread = 1
logger = nil
logpath = "."
harbor = 0
start = "lamf"	-- main script
bootstrap = "snlua bootstrap"	-- The service for bootstrap
-- daemon = "./skynet.pid"
include "config.lua"

local Mod = Isidoro
Mod.FUNCTIONS = {}
local FUNCTIONS = Mod.FUNCTIONS

-- function from epiphany https://steamcommunity.com/sharedfiles/filedetails/?id=3012430463
---@param player EntityPlayer
---@return string
---@function
function FUNCTIONS:GetPlayerString(player)
	return "PLAYER_" .. player:GetCollectibleRNG(1):GetSeed() .. "_" .. player:GetCollectibleRNG(2):GetSeed()
end
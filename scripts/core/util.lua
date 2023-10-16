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

--math.max but for vectors
---@param vec1 Vector
---@param vec2 Vector
---@return Vector
---@function
function FUNCTIONS:VectorMax(vec1, vec2)
    if vec1:Length() >= vec2:Length() then
        return vec1
    else
        return vec2
    end
end

--math.min but for vectors
---@param vec1 Vector
---@param vec2 Vector
---@return Vector
---@function
function FUNCTIONS:VectorMin(vec1, vec2)
    if vec1:Length() <= vec2:Length() then
        return vec1
    else
        return vec2
    end
end

---@param integer integer
---@function
function FUNCTIONS.Round(integer)
	return integer % 1 >= 0.5 and math.ceil(integer) or math.floor(integer)
end

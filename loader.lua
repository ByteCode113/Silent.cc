local repo = "https://raw.githubusercontent.com/ByteCode113/Silent.cc/main/"
local folder = "Silent"
local versionFile = "version_data.json"

local HttpService = game:GetService("HttpService")
local placeId = game.PlaceId

local gameScripts = {
    ["default"] = "Games/universal.lua"
}

if not isfolder(folder) then
    makefolder(folder)
end

if not isfolder(folder .. "/Games") then
    makefolder(folder .. "/Games")
end

local function fetchVersions()
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(repo .. "versions.json"))
    end)
    
    if success then
        return result
    else
        return {}
    end
end

local function readLocalVersions()
    local localVersions = {}
    local versionPath = folder .. "/" .. versionFile
    
    if isfile(versionPath) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(versionPath))
        end)
        if success then
            localVersions = data
        end
    end
    
    return localVersions, versionPath
end

local function updateScripts()
    local remoteVersions = fetchVersions()
    local localVersions, versionPath = readLocalVersions()
    
    local updated = false
    
    for file, version in pairs(remoteVersions) do
        if localVersions[file] ~= version then
            local success, content = pcall(function()
                return game:HttpGet(repo .. file)
            end)
            
            if success then
                writefile(folder .. "/" .. file, content)
                localVersions[file] = version
                updated = true
            end
        end
    end
    
    if updated then
        writefile(versionPath, HttpService:JSONEncode(localVersions))
    end
end

local function loadGameScript()
    local selectedScript = gameScripts[placeId] or gameScripts["default"]
    local scriptPath = folder .. "/" .. selectedScript
    
    if isfile(scriptPath) then
        pcall(function()
            loadstring(readfile(scriptPath))()
        end)
    end
end

local steps = {
    {name = "Loading UI Library", func = function()
        return pcall(function()
            _G._lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/weakhoes/Roblox-UI-Libs/refs/heads/main/Void%20Lib/Void%20Lib%20Source.lua"))()
        end)
    end},
    {name = "Checking LocalPlayer", func = function()
        local Players = game:GetService("Players")
        while not Players.LocalPlayer do wait() end
        _G._lp = Players.LocalPlayer
        return true
    end},
    {name = "Checking Camera", func = function()
        while not workspace.CurrentCamera do wait() end
        _G._cam = workspace.CurrentCamera
        return true
    end},
    {name = "Verifying Core Services", func = function()
        local required = {"RunService", "HttpService", "UserInputService"}
        for _, service in ipairs(required) do
            if not game:GetService(service) then
                return false
            end
        end
        return true
    end},
    {name = "Finalizing", func = function()
        wait(0.2)
        return true
    end}
}

local total = #steps
local clear = string.rep("\n", 500)

for i, step in ipairs(steps) do
    print(clear)
    local bar = string.rep("█", i) .. string.rep(" ", total - i)
    local status, result = pcall(step.func)
    local success = status and result
    print("[" .. bar .. "] " .. math.floor(i / total * 100) .. "% - " .. step.name .. (success and " [OK]" or " [FAILED]"))
    if not success then
        print("Error loading: " .. step.name)
        return
    end
    wait(0.15)
end

print(clear)
print("All systems ready. Running main script...")

updateScripts()
loadGameScript()

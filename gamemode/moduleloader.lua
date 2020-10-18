include("module.lua")
include("loaderconfig.lua")

-- Derive the gamemode from base
DeriveGamemode("base")

--[[
    Module loader to load modules located in the modules directory.
    All module files must start with the following options:
        - cl
            - client side only files
        - sh
        - pl (player_xxxx)
            - shared files
        - sv
            - server only files.
--]]

SCP = {}
SCP.Modules = {}
SCP.Modules.LoadedFiles = {}
SCP.Modules.LoadedDirectories = {}
SCP.Modules.Tabs = {}
SCP.Modules.SubTabs = {}

local loadedModules = {} 

local function ServerInclude(path, fileName, recSpace)
    if SERVER then
        print(recSpace .. " - [SV] Loaded " .. fileName)
        include(path .. fileName)
    end
end
 
local function SharedInclude(path, fileName, recSpace)
    print(recSpace .. " - [SH] Loaded " .. fileName)
    AddCSLuaFile(path .. fileName)
    include(path .. fileName)
end

local function ClientInclude(path, fileName, recSpace)
    if CLIENT then
        print(recSpace .. " - [CL] Loaded " .. fileName)
        include(path .. fileName)
    else
        print(recSpace .. " - [CL] Sending " .. fileName)
        AddCSLuaFile(path .. fileName)
    end
end  

local function RealmInclude(path, fileName, recSpace)
    if #fileName < 2 || !string.EndsWith(fileName, ".lua") then
        Error("Attempted to include invalid file \'" .. fileName .. "\'.")
    end

    -- Don't include files if they've already been included.
    if SCP.Modules.LoadedFiles[path .. fileName] then return end

    local realm = string.sub(fileName, 0, 2)
    realm = string.lower(realm)

    local action = 
    {
        ["sv"] = function() ServerInclude(path, fileName, recSpace) end,
        ["sh"] = function() SharedInclude(path, fileName, recSpace) end,
        ["cl"] = function() ClientInclude(path, fileName, recSpace) end,
        ["pl"] = function() SharedInclude(path, fileName, recSpace) end, -- player_xxx files are shared.
    }

    if action[realm] then 
        action[realm]()
        SCP.Modules.LoadedFiles[path .. fileName] = true
    else
        ErrorNoHalt("Invalid realm \'" .. realm .. "\' in file \'" .. fileN.. "\'.")
    end
end

local function LoadModule(moduleName, numRecursions)
    numRecursions = numRecursions or 0

    -- If not recursive, then check that the module name is unique.
    if numRecursions == 0 then
        if loadedModules[moduleName] then
            print("[" .. moduleName .. "]")
            print(" - A module with that name was already loaded. Skipping...")
            return
        else
            loadedModules[moduleName] = true
        end
    end

    -- Get the module's directory from its name.
    local searchPath = engine.ActiveGamemode() .. "/gamemode/scpcr-modules/" .. moduleName .. "/"
    local modulePath = "scpcr-modules/" .. moduleName .. "/"

    -- Return if already loaded.
    if SCP.Modules.LoadedDirectories[modulePath] then
        return
    else
        SCP.Modules.LoadedDirectories[modulePath] = true
    end

    local moduleFiles, moduleDirectory = file.Find(searchPath .. "*", "LUA")

    if moduleDirectory == nil then
        Error("Cannot find module \'" .. moduleName .. "\'! Your gamemode modules are broken, re-install them.\n")
        return 
    end 
 
    local recSpace = string.rep(" ", numRecursions)

    -- TODO: Check that we still have things to load here (i.e. haven't been loaded via loadOrder yet)
    print(recSpace .. "[" .. moduleName .. "]")

    -- If the module is empty, quit.
    if #moduleFiles == 0 && table.GetFirstValue(moduleDirectory) == nil then
        print(" - Module is empty.")
        return
    end 

    -- Get the module's lua configuration.
    local moduleConfig = nil
    local moduleConfigPath = modulePath .. "module_" .. moduleName .. ".lua"

    if (numRecursions == 0 && file.Exists(searchPath .. "module_" .. moduleName .. ".lua", "LUA")) then
        moduleConfig = include(moduleConfigPath)
        if !moduleConfig then
            ErrorNoHalt(string.format(" - Invalid module file, skipping module.\n", moduleName))
            return
        else
            -- Send the module config file to clients.
            AddCSLuaFile(moduleConfigPath)
            
            if moduleName:lower() != moduleConfig:GetName():lower() then
                print(" - " .. moduleConfig:GetName())
            end
            print(" - " .. moduleConfig:GetDescription())
            print(" - Load Order: ")

            for _, v in pairs(moduleConfig:GetLoadOrder()) do
                print("  - " .. v)
            end
            print()
        end
    end

    -- If there's no module config, or if it's invalid, return. Only for root module directories, not subdirectories.
    if numRecursions == 0 && !moduleConfig then
        Error(" - Module has no module configuration file or is invalid, ignoring module. \n")
        return
    end

    -- Load files in the load order they're setup in.
    if numRecursions == 0 then
        for _, path in pairs(moduleConfig:GetLoadOrder()) do
            local loadPath = searchPath .. path
            local fileModulePath = modulePath .. path
            fileModulePath = string.Replace(fileModulePath, "//", "/") -- Remove excess slashes
            fileModulePath = string.Trim(fileModulePath, "/")  -- Remove leading and trailing slashes

            loadPath = string.Replace(loadPath, "//", "/") -- Remove excess slashes
            loadPath = string.Replace(loadPath, "*", "") -- No wildcards
            loadPath = string.Trim(loadPath, "/") -- Remove leading and trailing slashes
            print(" - Searching for priority file/dir: " .. loadPath)
            -- Pattern for invalid paths.
            local invalid, _ = string.find(loadPath, "..", 1, true) -- Cannot go backwards in directories.
            if invalid then
                ErrorNoHalt(string.format(" - Found invalid path '%s' in module file. Ignoring.\n", path))
                continue
            end

            -- Check if the path exists.
            if !file.Exists(loadPath, "LUA") then
                ErrorNoHalt(string.format(" - Cannot find path '%s'. Ignoring.\n", loadPath))
                continue
            end

            print(" - Found priority file/dir: " .. loadPath)

            -- If it's a directory, get all root files and directories and load them.
            if file.IsDir(loadPath, "LUA") then
                local files, dirs = file.Find(loadPath .. "*", "LUA")

                -- If already loaded, hecc off.
                if SCP.Modules.LoadedDirectories[fileModulePath] then continue end

                -- Load all root files first.
                for _, f in pairs(files) do
                    local fi = string.lower(f)
                    if string.EndsWith(fi, ".lua") then
                        RealmInclude(fileModulePath, fi, recSpace)
                    end
                end

                -- Load subdirectories.
                for _, dir in pairs(dirs) do
                    LoadModule(moduleName .. "/" .. dir, numRecursions + 1)
                end
            else -- then we just load the file. 

                -- If already loaded, hecc off.
                if SCP.Modules.LoadedFiles[fileModulePath] then continue end
                -- Do some magic if the path also contains folders.
                local tbl = string.Split(fileModulePath, "/")
                local fi = tbl[#tbl]

                if #tbl != 1 then
                    fileModulePath = string.sub(fileModulePath, 1, #fileModulePath - #fi)
                end

                if string.EndsWith(fi, ".lua") then
                    RealmInclude(fileModulePath, fi, recSpace) 
                end
            end
        end
    end

    -- Load other files in current directory.
    for _, f in pairs(moduleFiles) do
        local fi = string.lower(f) 
        local moduleFile = "module_" .. moduleName .. ".lua"
        if string.EndsWith(fi, ".lua") && fi != moduleFile  then 
            RealmInclude(modulePath, fi, recSpace)
        end 
    end 

    -- Load any subdirectories.
    for _, dir in pairs(moduleDirectory) do
        LoadModule(moduleName .. "/" .. dir, numRecursions + 1)
    end
end

function SCP.Modules.LoadAllModules()
    
    print()
    print("=== Reproduction Test Gamemode ===")
    print()
    
    -- Splash screen baby
    for _, line in pairs(loaderConfig.splash) do
        print(line)
    end

    print()
    print("=== Loading Modules ===")
    print()
    
    -- Load modules in the order they are inside the loader config
    for _, mod in pairs(loaderConfig.loadOrder) do
        if loadedModules[mod] then continue end

        LoadModule(mod)
    end
end
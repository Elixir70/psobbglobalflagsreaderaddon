-- Global Flags Reader - Addon that can read fields out of global flags inside the 
--                       client's copy of the character data. Can be useful to check
--                       Lucky Coins, MA4 Tickets, and other quest pseudorewards quickly.

local addonName                   = "Global Flags Reader"
local addonHome                   = "addons/" .. addonName .. "/"
local optionsFileName             = addonHome .. "options.lua"

local lib_helpers                 = require("solylib.helpers")
local core_mainmenu               = require("core_mainmenu")
local cfg                         = require(addonName .. ".configuration")
local optionsLoaded, options      = pcall(require, addonName .. ".options")

-- Thank you based Soda
local _CharacterData              = 0xA95DF8
local _GlobalFlagsArrayOffset     = 0x296C

-- Holder for configuration.lua
local ConfigurationWindow

-- Defaults for some known flags that I included. 
-- Description, Flag Number, bitmask, and whether to display hex
local _FlagsReaderDefaultFlags = {
    { description="Lucky Coins",                      flagNum=0xB, flagMask=0x000001FC, enable=true,  hexdisplay=false }, 
    { description="MA4 Tickets",                      flagNum=0xF, flagMask=0x000000FF, enable=true,  hexdisplay=false },
    { description="MA4 Kills (Total)",                flagNum=0xE, flagMask=0x7FFFFFFF, enable=false, hexdisplay=false },
    { description="MA4 Kills (Central Dome)",         flagNum=0x3, flagMask=0x7FFFFFFF, enable=false, hexdisplay=false },
    { description="MA4 Kills (Gal Da Val)",           flagNum=0x4, flagMask=0x7FFFFFFF, enable=false, hexdisplay=false },
    { description="MA4 Kills (Crater)",               flagNum=0x8, flagMask=0x7FFFFFFF, enable=false, hexdisplay=false },
    { description="MA4 (SAMURAI ARMOR)",              flagNum=0xF, flagMask=0x00000800, enable=false, hexdisplay=false },
    { description="MA4 (GIRASOLE)",                   flagNum=0xF, flagMask=0x00000200, enable=false, hexdisplay=false },
    { description="MA4 (FRIEND RING)",                flagNum=0xF, flagMask=0x00000400, enable=false, hexdisplay=false },
    { description="MA4 (PHOTON CRYSTAL)",             flagNum=0xF, flagMask=0x00000100, enable=false, hexdisplay=false },
    { description="AOL CUP -Sunset Base- (Mag Cell)", flagNum=0x9, flagMask=0x10000000, enable=false, hexdisplay=false },
    { description="AOL CUP -Sunset Base- (Ruins)",    flagNum=0x9, flagMask=0x20000000, enable=false, hexdisplay=false },
    { description="MA1v2 Points",                     flagNum=0x9, flagMask=0x00003FFF, enable=false, hexdisplay=false },
    { description="MA1v2 Tickets",                    flagNum=0xA, flagMask=0x7FC00000, enable=false, hexdisplay=false },
    { description="MA2v2 Points",                     flagNum=0x9, flagMask=0x0FFFC000, enable=false, hexdisplay=false },
    { description="MA2v2 Tickets",                    flagNum=0xA, flagMask=0x7FC00000, enable=false, hexdisplay=false },
    { description="Heart of HUmar",                   flagNum=0xA, flagMask=0x00000001, enable=false, hexdisplay=false },
    { description="Heart of HUnewearl",               flagNum=0xA, flagMask=0x00000002, enable=false, hexdisplay=false },
    { description="Heart of HUcast",                  flagNum=0xA, flagMask=0x00000004, enable=false, hexdisplay=false },
    { description="Heart of HUcaseal",                flagNum=0xA, flagMask=0x00000008, enable=false, hexdisplay=false },
    { description="Heart of RAmar",                   flagNum=0xA, flagMask=0x00000010, enable=false, hexdisplay=false },
    { description="Heart of RAmarl",                  flagNum=0xA, flagMask=0x00000020, enable=false, hexdisplay=false },
    { description="Heart of RAcast",                  flagNum=0xA, flagMask=0x00000040, enable=false, hexdisplay=false },
    { description="Heart of RAcaseal",                flagNum=0xA, flagMask=0x00000080, enable=false, hexdisplay=false },
    { description="Heart of FOmar",                   flagNum=0xA, flagMask=0x00000100, enable=false, hexdisplay=false },
    { description="Heart of FOmarl",                  flagNum=0xA, flagMask=0x00000200, enable=false, hexdisplay=false },
    { description="Heart of FOnewm",                  flagNum=0xA, flagMask=0x00000400, enable=false, hexdisplay=false },
    { description="Heart of FOnewearl",               flagNum=0xA, flagMask=0x00000800, enable=false, hexdisplay=false },
    { description="Heart of Viridia",                 flagNum=0xA, flagMask=0x00001000, enable=false, hexdisplay=false },
    { description="Heart of Greenill",                flagNum=0xA, flagMask=0x00002000, enable=false, hexdisplay=false },
    { description="Heart of Skyly",                   flagNum=0xA, flagMask=0x00004000, enable=false, hexdisplay=false },
    { description="Heart of Bluefull",                flagNum=0xA, flagMask=0x00008000, enable=false, hexdisplay=false },
    { description="Heart of Purplenum",               flagNum=0xA, flagMask=0x00010000, enable=false, hexdisplay=false },
    { description="Heart of Pinkal",                  flagNum=0xA, flagMask=0x00020000, enable=false, hexdisplay=false },
    { description="Heart of Redria",                  flagNum=0xA, flagMask=0x00040000, enable=false, hexdisplay=false },
    { description="Heart of Oran",                    flagNum=0xA, flagMask=0x00080000, enable=false, hexdisplay=false },
    { description="Heart of Yellowboze",              flagNum=0xA, flagMask=0x00100000, enable=false, hexdisplay=false },
    { description="Heart of Whitill",                 flagNum=0xA, flagMask=0x00200000, enable=false, hexdisplay=false },
}

local _FlagsReaderDefaultOptions = {
    {"enable", true},                          -- Is this enabled?
    {"configurationWindowEnable", true},       -- Is the config window enabled?
    {"anchor", 3},                             -- Anchor to the screen--see configuration.lua
    {"X", 0},                                  -- X coord of window (relative to anchor)
    {"Y", 0},                                  -- Y coord of window (relative to anchor)
    {"W", 400},                                -- Width of window 
    {"H", 300},                                -- Height of window
    {"noTitleBar", ""},                        -- If set, do not show title bar of the window
    {"noResize", ""},                          -- If set, no resizing the window
    {"noMove", ""},                            -- If set, no moving the window
    {"transparentWindow", false},              -- If true, window's background style is invisible
    {"AlwaysAutoResize", ""},                  -- If set, resize the addon based on the items. Can be nice for adding flags temporarily
    {"descriptionWidth", 75},                  -- Width of the flag description field as a % of the window width.
    {"globalFlags", _FlagsReaderDefaultFlags}, -- The flags. Defaults to the ones above.
}

-- Inserts tabs/spaces for saving the options.lua
local function InsertTabs(level)
    for i=0,level do
        io.write("    ")
    end
end

-- Recursively save a table to a file. Has some awful hacks.
local function SaveTableToFile(tbl, level)
    if level == 0 then
        io.write("return\n")
    end
    
    InsertTabs(level-1)
    io.write("{\n")
    for key,val in pairs(tbl) do
        local skey
        local ktype = type(key)			
        local sval
        local vtype = type(val)
        
        -- Hack to avoid writing out the internal changed var
        if tostring(key) ~= "changed" then
        
            if     vtype == "string"  then 
                sval = string.format("%q", val)
                
                InsertTabs(level)
                io.write(string.format("%s = %s,\n", key, sval))
                
            elseif vtype == "number"  then 
                -- Hack for hex...
                if tostring(key) == "flagMask" or tostring(key) == "flagNum" then
                    sval = string.format("0x%-0.8X", val)
                else
                    sval = string.format("%s", val)
                end
                
                InsertTabs(level)
                io.write(string.format("%s = %s,\n", key, sval))
                
            elseif vtype == "boolean" then 
                sval = tostring(val) 
                
                InsertTabs(level)
                io.write(string.format("%s = %s,\n", key, sval))
                
            elseif vtype == "table"   then 
                -- Very hackish... Don't write the index for nested  tables
                -- Why? Because I'm assuming there aren't any nested tables with
                -- any real indexes..
                if level == 0 then
                    InsertTabs(level)
                    io.write(string.format("%s = \n", key))
                end
                
                -- And recurse to write the table in this place
                SaveTableToFile(val, level+1)
            end
        end
    end
    
    InsertTabs(level-1)
    if level ~= 0 then
        io.write("},\n")
    else
        io.write("}\n")
    end
end

-- Save options to the file. Does some cleanup for hacks and removing empty flags.
local function SaveOptions(tbl, fileName)
    -- First remove the empty flags
    for i,v in ipairs(options.globalFlags) do
        if v.descriptionSave ~= nil then
            v.description = v.descriptionSave
            v.descriptionSave = nil
        end
        if v.description == "" or string.len(v.description) == 0 then
            table.remove(options.globalFlags, i)
        end
    end
    
    local file = io.open(fileName, "w")
    if file ~= nil then
        io.output(file)
        SaveTableToFile(tbl, 0)
        io.close(file)
    end
end

-- Debugging
local function PrintOptions()
    for key, val in pairs(options) do
        print(tostring(key), tostring(val))
    end
end

local function GetWindowOptions()
    local opts = { options.noMove, options.noResize, options.noTitleBar, options.AlwaysAutoResize }
    return opts
end

-- Given a value derived from a bitmask, figure out how much to shift
-- this value. For example, lucky coins are stored in the bits 
-- 0x1FC. This bitmask is b000011111100, so we should shift the 
-- result right by 2 bits. 
local function ShiftValueAccordingToMask(value, mask)
    local shiftBy = 0
    local i = 0
    
    -- Flags are 32 bits
    while i < 32 and bit.band(mask, 2^i) == 0 do
        i = i + 1
    end	
    return bit.rshift(value, i)
end

local function ReadGlobalFlagsPointer()
    return pso.read_u32(_CharacterData)
end

local function ReadGlobalFlagWithPointer(globalFlagsPointer, flagNum)
    if globalFlagsPointer == 0 then
        -- Shouldn't get here but oh well
        return nil
    end
    
    local fourByteFlag = pso.read_u32(globalFlagsPointer + _GlobalFlagsArrayOffset + 4 * flagNum)
    return fourByteFlag
end

local function ReadGlobalFlag(flagNum)
    local globalFlagsPointer = pso.read_u32(_CharacterData)
    return ReadGlobalFlagWithPointer(globalFlagsPointer)
end

local function ReadGlobalFlagBitsWithPointer(globalFlagsPointer, flagNum, flagMask)
    local ret = 0
    if globalFlagsPointer ~= 0 then
        ret = ReadGlobalFlagWithPointer(globalFlagsPointer, flagNum)
        ret = bit.band(ret, flagMask)
        ret = ShiftValueAccordingToMask(ret, flagMask)
    end
    
    return ret
end

local function ReadGlobalFlagBits(flagNum, flagMask)
    local globalFlagsPointer = ReadGlobalFlagsPointer()
    return ReadGlobalFlagBitsWithPointer(globalFlagsPointer, flagNum, flagMask)
end

local function PresentTopLevel()
    local ptr = ReadGlobalFlagsPointer()
    if ptr ~= 0 then
        local columnCount = 2
        imgui.Columns(columnCount)
        
        if options.AlwaysAutoResize == "" then
            -- Set second column starting at descriptionWidth% * windowwidth
            imgui.SetColumnOffset(1, 0.01 * options.descriptionWidth * imgui.GetWindowWidth())
        end
        for k,v in pairs(options.globalFlags) do
            if v.enable then
                -- Description column first
                imgui.Text(v.description)            
                imgui.NextColumn()
            
                -- Value column next
                local flagValue = ReadGlobalFlagBitsWithPointer(ptr, v.flagNum, v.flagMask)
                local s 
                if v.hexdisplay then
                    s = string.format("0x%X", flagValue)
                else
                    s = string.format("%i", flagValue)
                end
                imgui.Text(s)
            
                -- Go back to first column
                imgui.NextColumn()
            end
        end
    end
end

local function present()

    if options.configurationWindowEnable then
        ConfigurationWindow.open = true
        options.configurationWindowEnable = false
    end
    
    local configWindowChanged = false
    ConfigurationWindow.Update()
    if ConfigurationWindow.changed then
        configWindowChanged = true
        ConfigurationWindow.changed = false
        SaveOptions(options, optionsFileName)
    end
    
    -- Global enable here to let the configuration window work
    if options.enable == false then
        return
    end
    
    if options.transparentWindow == true then
        imgui.PushStyleColor("WindowBg", 0.0, 0.0, 0.0, 0.0)
    end

    if options.AlwaysAutoResize == "AlwaysAutoResize" then
       imgui.SetNextWindowSizeConstraints(0, 0, options.W, options.H)
    end

    if imgui.Begin(addonName, nil, GetWindowOptions()) then
        PresentTopLevel()
        lib_helpers.WindowPositionAndSize(addonName, options.X, options.Y, options.W, options.H, options.anchor, options.AlwaysAutoResize, configWindowChanged)
        imgui.End()
        if options.transparentWindow == true then
            imgui.PopStyleColor()
        end
    end
end


if optionsLoaded then
    -- Make sure everything is okay
    for _, opt in pairs(_FlagsReaderDefaultOptions) do
        options[opt[1]] = lib_helpers.NotNilOrDefault(options[opt[1]], opt[2])
    end
else
    options = {}
    for _, opt in pairs(_FlagsReaderDefaultOptions) do
        options[opt[1]] = opt[2]
    end
    
    -- We just created the options, so we should save to have valid file
    SaveOptions(options, optionsFileName) 
end

local function init()
    ConfigurationWindow = cfg.ConfigurationWindow(options, addonName)

    local function mainMenuButtonHandler()
        ConfigurationWindow.open = not ConfigurationWindow.open
    end
    
    core_mainmenu.add_button(addonName, mainMenuButtonHandler)
    
    return
    {
        name = 'Global Flags Reader',
        version = '1.0.0',
        author = 'Ender',
        present = present,
        toggleable = true,
    }
end

return
{
    __addon = 
    {
        init                      = init,
    },
    
    -- In case someone wants to pcall/require this file
    ShiftValueAccordingToMask     = ShiftValueAccordingToMask,
    ReadGlobalFlagsPointer        = ReadGlobalFlagsPointer,
    ReadGlobalFlagWithPointer     = ReadGlobalFlagWithPointer,
    ReadGlobalFlag                = ReadGlobalFlag,
    ReadGlobalFlagBitsWithPointer = ReadGlobalFlagBitsWithPointer,
    ReadGlobalFlagBits            = ReadGlobalFlagBits,
}

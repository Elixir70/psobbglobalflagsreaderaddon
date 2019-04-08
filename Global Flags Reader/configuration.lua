-- Global Flags Reader - Addon that can read fields out of global flags inside the 
--                       client's copy of the character data. Can be useful to check
--                       Lucky Coins, MA4 Tickets, and other quest pseudorewards quickly.

local function ConfigurationWindow(configuration, addonName)
    local this = 
    {
        title = addonName .. " - Configuration",
        open = false,
        changed = false,
    }

    local _configuration = configuration

    local _showWindowSettings = function()
        local success
        local anchorList =
        {
            "Top Left (Disabled)", "Left", "Bottom Left",
            "Top", "Center", "Bottom",
            "Top Right", "Right", "Bottom Right",
        }

        if imgui.Checkbox("Enable", _configuration.enable) then
            _configuration.enable = not _configuration.enable
            this.changed = true
        end

        if imgui.Checkbox("No title bar", _configuration.noTitleBar == "NoTitleBar") then
            if _configuration.noTitleBar == "NoTitleBar" then
                _configuration.noTitleBar = ""
            else
                _configuration.noTitleBar = "NoTitleBar"
            end
            this.changed = true
        end
        if imgui.Checkbox("No resize", _configuration.noResize == "NoResize") then
            if _configuration.noResize == "NoResize" then
                _configuration.noResize = ""
            else
                _configuration.noResize = "NoResize"
            end
            this.changed = true
        end
        if imgui.Checkbox("No move", _configuration.noMove == "NoMove") then
            if _configuration.noMove == "NoMove" then
                _configuration.noMove = ""
            else
                _configuration.noMove = "NoMove"
            end
            this.changed = true
        end

        if imgui.Checkbox("Transparent window", _configuration.transparentWindow) then
            _configuration.transparentWindow = not _configuration.transparentWindow
            this.changed = true
        end
            
        local descWidth
        imgui.PushItemWidth(0.25 * imgui.GetWindowWidth())
        success, descWidth = imgui.InputInt("Description Width (% of Window)", _configuration.descriptionWidth)
        imgui.PopItemWidth()
        if success and 0 <= descWidth and descWidth <= 100 then
            _configuration.changed = true
            _configuration.descriptionWidth = descWidth
            this.changed = true
        end
            
        imgui.Text("Position and Size")
        imgui.PushItemWidth(0.50 * imgui.GetWindowWidth())
        success, _configuration.anchor = imgui.Combo("Anchor", _configuration.anchor, anchorList, table.getn(anchorList))
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end

        imgui.PushItemWidth(0.25 * imgui.GetWindowWidth())
        success, _configuration.X = imgui.InputInt("X", _configuration.X)
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end

        imgui.SameLine(0, 0)
        imgui.SetCursorPosX(0.50 * imgui.GetWindowWidth())
        imgui.PushItemWidth(0.25 * imgui.GetWindowWidth())
        success, _configuration.Y = imgui.InputInt("Y", _configuration.Y)
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end

        imgui.PushItemWidth(0.25 * imgui.GetWindowWidth())
        success, _configuration.W = imgui.InputInt("Width", _configuration.W)
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end

        imgui.SameLine(0, 0)
        imgui.SetCursorPosX(0.50 * imgui.GetWindowWidth())
        imgui.PushItemWidth(0.25 * imgui.GetWindowWidth())
        success, _configuration.H = imgui.InputInt("Height", _configuration.H)
        imgui.PopItemWidth()
        if success then
            _configuration.changed = true
            this.changed = true
        end

        if imgui.TreeNodeEx("Global Flags") then
            for i=1, table.getn(_configuration.globalFlags) do
                imgui.PushID(i)
                if imgui.TreeNodeEx(_configuration.globalFlags[i].description) then
                    
                    if imgui.Checkbox("Enable", _configuration.globalFlags[i].enable) then
                        _configuration.globalFlags[i].enable = not _configuration.globalFlags[i].enable
                    end

                    local descBuf
                    imgui.PushItemWidth(0.40 * imgui.GetWindowWidth())
                    success, descBuf = imgui.InputText("Description", _configuration.globalFlags[i].description, 80)
                    imgui.PopItemWidth()
                    if success then
                        -- Save it in scratch field so that we don't generate a new ID for the TreeNode (causing it to 
                        -- automatically collapse every input
                        _configuration.globalFlags[i].descriptionSave = descBuf
                        --_configuration.globalFlags[i].description = descBuf
                    end
                    
                    local flagNum
                    imgui.PushItemWidth(0.20 * imgui.GetWindowWidth())
                    success, flagNum = imgui.InputInt("Flag Number (Decimal)", _configuration.globalFlags[i].flagNum)
                    imgui.PopItemWidth()
                    if success then
                        if flagNum ~= nil and 0 <= flagNum and flagNum <= 32 and flagNum ~= _configuration.globalFlags[i].flagNum then
                            _configuration.globalFlags[i].flagNum = flagNum
                        end
                    end
                    
                    local flagMask
                    local flagMaskCheck
                    imgui.PushItemWidth(0.20 * imgui.GetWindowWidth())
                    success, flagMask = imgui.InputInt("Flag Bitmask (Decimal)", _configuration.globalFlags[i].flagMask)
                    imgui.PopItemWidth()
                    if success then
                        if flagMask ~= nil and 0x0 <= flagMask and flagMask <= 0xFFFFFFFF then
                            _configuration.globalFlags[i].flagMask = flagMask
                        end
                    end
                    
                    if imgui.Checkbox("Display as Hex?", _configuration.globalFlags[i].hexdisplay) then
                        _configuration.globalFlags[i].hexdisplay = not _configuration.globalFlags[i].hexdisplay
                    end
            
                    imgui.TreePop()
                end
                imgui.PopID()
            end
            
            if imgui.Button("New Global Flag") then
                local newFlag = {description="(Empty)", flagNum=0x0, flagMask=0x0, hexdisplay=false}
                _configuration.globalFlags[#_configuration.globalFlags+1] = newFlag
                _configuration.changed = true
                this.changed = true
            end
            
            if imgui.Button("Save") then
                _configuration.changed = true
                this.changed = true
            end
            imgui.TreePop()
        end
    end

    this.Update = function()
        if this.open == false then
            return
        end

        local success

        imgui.SetNextWindowSize(500, 400, 'FirstUseEver')
        success, this.open = imgui.Begin(this.title, this.open)

        _showWindowSettings()

        imgui.End()
    end

    return this
end

return 
{
    ConfigurationWindow = ConfigurationWindow,
}

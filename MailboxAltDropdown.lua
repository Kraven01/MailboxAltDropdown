-- Function to migrate the database to the new format
local function MigrateDatabase()
    for fullName, value in pairs(MailboxAltDropdownDB) do
        if type(value) ~= "table" then
            -- Old format: value is just the class string
            MailboxAltDropdownDB[fullName] = {class = value, note = ""}
        end
    end
end

local function MigrateCharacterName()
    local name = UnitName("player")
    local realm = GetRealmName()
    local fullName = name .. "-" .. realm

    -- Check if the old name exists in the database
    if MailboxAltDropdownDB[name] and type(MailboxAltDropdownDB[name]) ~= "table" then
        -- Migrate the old name to the new format
        local class = MailboxAltDropdownDB[name]
        MailboxAltDropdownDB[fullName] = {class = class, note = ""}
        MailboxAltDropdownDB[name] = nil
    elseif MailboxAltDropdownDB[name] and type(MailboxAltDropdownDB[name]) == "table" then
        -- Old format with table but missing realm
        MailboxAltDropdownDB[fullName] = MailboxAltDropdownDB[name]
        MailboxAltDropdownDB[name] = nil
    end

    -- Add the current character if it does not already exist
    if not MailboxAltDropdownDB[fullName] then
        local class = select(2, UnitClass("player"))
        MailboxAltDropdownDB[fullName] = {class = class, note = ""}
    end
end

-- Function to add the current character to the database
local function AddCurrentCharacter()
    local name = UnitName("player")
    local realm = GetRealmName()
    local fullName = name .. "-" .. realm
    local class = select(2, UnitClass("player"))
    if not MailboxAltDropdownDB[fullName] then
        MailboxAltDropdownDB[fullName] = {class = class, note = ""}
    end
end

-- Function to remove a character from the database
local function RemoveCharacter(fullName)
    MailboxAltDropdownDB[fullName] = nil
end

-- Function to create the dropdown menu
local function CreateAltDropdown()
    local dropdown = CreateFrame("Frame", "AltDropdown", SendMailFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", SendMailNameEditBox, "TOPRIGHT", -17, 2)
    UIDropDownMenu_SetWidth(dropdown, 10)

    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        local sortedNames = {}

        -- Extract names from the database and sort them
        for fullName in pairs(MailboxAltDropdownDB) do
            if fullName ~= "config" then
                table.insert(sortedNames, fullName)
            end
        end
        table.sort(sortedNames)

        -- Add sorted names to the dropdown menu
        for _, fullName in ipairs(sortedNames) do
            local data = MailboxAltDropdownDB[fullName]
            local class = data.class
            local color = RAID_CLASS_COLORS[class].colorStr
            info.text = "|c" .. color .. fullName .. "|r"
            info.notCheckable = true

            -- Adding tooltip
            local config = MailboxAltDropdownDB.config
            if config and config.showActionTooltip then
                info.tooltipTitle = "Actions"
                info.tooltipText = "Left-click -> Add name as recipient\nShift + Left-click -> Remove name from list\n"
                if data.note and data.note ~= "" then
                    info.tooltipText = "Left-click -> Add name as recipient\nShift + Left-click -> Remove name from list\n" .. data.note
                end
        
                info.tooltipOnButton = true
            elseif data.note and data.note ~= "" then
                info.tooltipTitle = "Note"
                info.tooltipText = data.note
                info.tooltipOnButton = true
            elseif data.note and data.note == "" then
                info.tooltipOnButton = false
            end

            -- Set the full name as arguments
            info.arg1 = fullName

            -- Function to handle left click
            info.func = function(self, arg1)
                if IsShiftKeyDown() then
                    RemoveCharacter(arg1)
                else
                    SendMailNameEditBox:SetText(arg1)
                end
            end
            if(data.blacklisted) then
            else 
                UIDropDownMenu_AddButton(info)
            end
        end
    end)
end

local function CreateConfigWindow()
    local configFrame = CreateFrame("Frame", "MADConfigFrame", UIParent, "BasicFrameTemplateWithInset")
    configFrame:SetSize(400, 300)
    configFrame:SetPoint("CENTER")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:Hide()

    configFrame.title = configFrame:CreateFontString(nil, "OVERLAY")
    configFrame.title:SetFontObject("GameFontHighlight")
    configFrame.title:SetPoint("CENTER", configFrame.TitleBg, "CENTER", 0, 0)
    configFrame.title:SetText("Mailbox Alt Dropdown Configuration")
    

    -- Header legend
    local header = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", configFrame, "TOPLEFT", 15, -40)
    header:SetText("Character")
    header:SetJustifyH("LEFT")

    local blacklistHeader = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    blacklistHeader:SetPoint("TOPRIGHT", configFrame, "TOPRIGHT", -40, -40)
    blacklistHeader:SetText("Blacklist")
    blacklistHeader:SetJustifyH("RIGHT")

    -- Scrollable list for characters
    local scrollFrame = CreateFrame("ScrollFrame", nil, configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetSize(360, 200)
    scrollFrame:SetPoint("TOP", configFrame, "TOP", 0, -60)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(360, 200)
    scrollFrame:SetScrollChild(content)

    local characterButtons = {}

    local function RefreshCharacterList()
        for _, button in ipairs(characterButtons) do
            button:Hide()
        end
        wipe(characterButtons)

        local sortedNames = {}
        for fullName in pairs(MailboxAltDropdownDB) do
            if (fullName ~= "config") then
                table.insert(sortedNames, fullName)
            end
        end
        table.sort(sortedNames)

        local yOffset = -10
        for _, fullName in ipairs(sortedNames) do
            local data = MailboxAltDropdownDB[fullName]

            local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            button:SetSize(280, 30)
            button:SetPoint("TOPLEFT", 10, yOffset)
            button:SetText(fullName)

            -- Tooltip for the note
            button:SetScript("OnEnter", function()
                GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                GameTooltip:SetText("Note: " .. (data.note or ""))
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", GameTooltip_Hide)

            -- OnClick for blacklist and note editing
            button:SetScript("OnClick", function()
                StaticPopupDialogs["MAD_EDIT_NOTE"] = {
                    text = "Edit Note for " .. fullName,
                    button1 = "Save",
                    button2 = "Cancel",
                    hasEditBox = true,
                    maxLetters = 100,
                    OnShow = function(self)
                        self.editBox:SetText(data.note or "")
                    end,
                    OnAccept = function(self)
                        local note = self.editBox:GetText()
                        MailboxAltDropdownDB[fullName].note = note
                        RefreshCharacterList()
                    end,
                    OnCancel = function() end,
                    EditBoxOnEnterPressed = function(self)
                        local note = self:GetText()
                        MailboxAltDropdownDB[fullName].note = note
                        RefreshCharacterList()
                        self:GetParent():Hide()
                    end,
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                }
                StaticPopup_Show("MAD_EDIT_NOTE")
            end)

            -- Blacklist checkbox
            local blacklistCheckbox = CreateFrame("CheckButton", nil, button, "UICheckButtonTemplate")
            blacklistCheckbox:SetPoint("LEFT", button, "RIGHT", 10, 0)
            blacklistCheckbox:SetChecked(data.blacklisted)

            -- Tooltip for the blacklist checkbox
            blacklistCheckbox:SetScript("OnEnter", function()
                GameTooltip:SetOwner(blacklistCheckbox, "ANCHOR_RIGHT")
                GameTooltip:SetText("Mark this box to hide this character from the dropdown menu")
                GameTooltip:Show()
            end)
            blacklistCheckbox:SetScript("OnLeave", GameTooltip_Hide)

            blacklistCheckbox:SetScript("OnClick", function(self)
                MailboxAltDropdownDB[fullName].blacklisted = self:GetChecked()
            end)

            table.insert(characterButtons, button)
            yOffset = yOffset - 35
        end
    end

    RefreshCharacterList()

    configFrame.refreshButton = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    configFrame.refreshButton:SetSize(80, 22)
    configFrame.refreshButton:SetPoint("BOTTOMRIGHT", configFrame, "BOTTOMRIGHT", -10, 10)
    configFrame.refreshButton:SetText("Refresh")
    configFrame.refreshButton:SetScript("OnClick", RefreshCharacterList)

    local tooltipCheckbox = CreateFrame("CheckButton", nil, configFrame, "UICheckButtonTemplate")
    tooltipCheckbox:SetPoint("BOTTOMLEFT", configFrame, "BOTTOMLEFT", 10, 10)
    tooltipCheckbox.text = tooltipCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tooltipCheckbox.text:SetPoint("LEFT", tooltipCheckbox, "RIGHT", 5, 0)
    tooltipCheckbox.text:SetText("Show action tooltip in dropdown menu")

    tooltipCheckbox:SetChecked(MailboxAltDropdownDB.config.showActionTooltip)
    tooltipCheckbox:SetScript("OnClick", function(self)
        MailboxAltDropdownDB.config.showActionTooltip = self:GetChecked()
    end)
    return configFrame
end

-- Ensure the database exists and is backward-compatible
local function InitializeDatabase()
    MailboxAltDropdownDB = MailboxAltDropdownDB or {}
    -- Add default configuration if missing
    if not MailboxAltDropdownDB.config then
        MailboxAltDropdownDB.config = {
            showActionTooltip = true, -- Default: Show action tooltip
        }
    end
    -- Ensure all existing entries have the proper format
    for fullName, data in pairs(MailboxAltDropdownDB) do
        if fullName ~= "config" then
            if type(data) ~= "table" then
                MailboxAltDropdownDB[fullName] = {
                    class = data,
                    note = "",
                    blacklisted = false,
                }
            end
        end
    end
end

-- Create the configuration window instance

-- Slash command to open the configuration window


-- Frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("MAIL_SHOW")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        InitializeDatabase()
        MigrateCharacterName() -- Migrate the current character's name dynamically
        AddCurrentCharacter()
        local configWindow = CreateConfigWindow()
        SLASH_MAILBOXALTDROPDOWN1 = "/mad"
        SlashCmdList["MAILBOXALTDROPDOWN"] = function()
        if configWindow:IsShown() then
            configWindow:Hide()
        else
            configWindow:Show()
        end
end
    elseif event == "MAIL_SHOW" then
        CreateAltDropdown()
    end
end)


-- Initialize the database
MailboxAltDropdownDB = MailboxAltDropdownDB or {}

-- Function to add the current character to the database
local function AddCurrentCharacter()
    local name = UnitName("player")
    local class = select(2, UnitClass("player"))
    if not MailboxAltDropdownDB[name] then
        MailboxAltDropdownDB[name] = class
    end
end

-- Function to remove a character from the database
local function RemoveCharacter(name)
    MailboxAltDropdownDB[name] = nil
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
        for name in pairs(MailboxAltDropdownDB) do
            table.insert(sortedNames, name)
        end
        table.sort(sortedNames)

        -- Add sorted names to the dropdown menu
        for _, name in ipairs(sortedNames) do
            local class = MailboxAltDropdownDB[name]
            local color = RAID_CLASS_COLORS[class].colorStr
            info.text = "|c" .. color .. name .. "|r"
            info.notCheckable = true

            -- Adding tooltip
            info.tooltipTitle = "Actions"
            info.tooltipText = "Leftclick -> Add name as recipient\nShift + Leftclick -> Remove name from list"
            info.tooltipOnButton = true

            -- Set the name and class as arguments
            info.arg1 = name
            info.arg2 = class

            -- Function to handle left click
            info.func = function(self, arg1, arg2)
                if IsShiftKeyDown() then
                    RemoveCharacter(arg1)
                else
                    SendMailNameEditBox:SetText(arg1)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
end

-- Frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("MAIL_SHOW")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        AddCurrentCharacter()
    elseif event == "MAIL_SHOW" then
        CreateAltDropdown()
    end
end)

-- Frame to handle events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("MAIL_SHOW")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        AddCurrentCharacter()
    elseif event == "MAIL_SHOW" then
        CreateAltDropdown()
    end
end)

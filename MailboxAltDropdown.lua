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

-- Function to create the dropdown menu
local function CreateAltDropdown()
    local dropdown = CreateFrame("Frame", "AltDropdown", SendMailFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", SendMailNameEditBox, "TOPRIGHT", -17, 2)
    UIDropDownMenu_SetWidth(dropdown, 10)

    UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        for name, class in pairs(MailboxAltDropdownDB) do
            local color = RAID_CLASS_COLORS[class].colorStr
            info.text = "|c" .. color .. name .. "|r"
            info.func = function()
                SendMailNameEditBox:SetText(name)
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

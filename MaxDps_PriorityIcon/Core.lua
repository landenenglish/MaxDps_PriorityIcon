local addonName, MaxDpsPriorityIcon = ...

-- Create the addon
MaxDpsPriorityIcon = LibStub('AceAddon-3.0'):NewAddon(MaxDpsPriorityIcon, addonName, 'AceEvent-3.0', 'AceConsole-3.0')

-- Default settings
local defaults = {
    global = {
        enabled = true,
        combatOnly = false,
        
        -- Priority icon settings
        priority = {
            position = { x = 0, y = -100 },
            scale = 1.0,
            enabled = true
        },
        
        -- Cooldown icon settings  
        cooldown = {
            position = { x = 100, y = -100 },
            scale = 1.0,
            enabled = true,
            maxShown = 3
        },
        
        locked = false
    }
}

function MaxDpsPriorityIcon:OnInitialize()
    -- Initialize database
    self.db = LibStub('AceDB-3.0'):New('MaxDpsPriorityIconDB', defaults)
    
    -- Register chat command
    self:RegisterChatCommand('maxdpspriority', 'ShowConfig')
    self:RegisterChatCommand('mdpspri', 'ShowConfig')
    
    -- Add to Blizzard Interface Options
    self:SetupBlizzardOptions()
end

function MaxDpsPriorityIcon:OnEnable()
    if not _G.MaxDps then
        self:Print("|cFFFF0000MaxDps Priority Icon requires MaxDps to be installed and enabled!")
        return
    end
    
    self:RegisterEvent('PLAYER_LOGOUT')
    self:RegisterEvent('PLAYER_ENTERING_WORLD')
    self:RegisterEvent('PLAYER_REGEN_DISABLED') -- Entering combat
    self:RegisterEvent('PLAYER_REGEN_ENABLED')  -- Leaving combat
    self.Icons = self:GetModule('Icons')
    self:HookMaxDpsEvents()
end

function MaxDpsPriorityIcon:PLAYER_LOGOUT()
    if self.Icons then
        self.Icons:SavePositions()
    end
end

function MaxDpsPriorityIcon:PLAYER_REGEN_DISABLED()
    -- Entering combat
    if self.Icons then
        self.Icons:UpdateAllVisibility()
    end
end

function MaxDpsPriorityIcon:PLAYER_REGEN_ENABLED()
    -- Leaving combat
    if self.Icons then
        self.Icons:UpdateAllVisibility()
    end
end

function MaxDpsPriorityIcon:OnDisable()
    if self.Icons then
        self.Icons:HideAll()
    end
end

function MaxDpsPriorityIcon:HookMaxDpsEvents()
    local MaxDps = _G.MaxDps
    if not MaxDps then return end
    
    -- Safer hooks that don't replace original functions
    local lastPrioritySpell = nil

    if type(MaxDps.InvokeNextSpell) == 'function' then
        hooksecurefunc(MaxDps, 'InvokeNextSpell', function(maxdps)
            if lastPrioritySpell ~= maxdps.Spell then
                lastPrioritySpell = maxdps.Spell
                MaxDpsPriorityIcon:UpdatePriorityIcon(maxdps.Spell)
            end
        end)
    end

    if type(MaxDps.GlowNextSpell) == 'function' then
        hooksecurefunc(MaxDps, 'GlowNextSpell', function(maxdps, spellId)
            if lastPrioritySpell ~= spellId then
                lastPrioritySpell = spellId
                MaxDpsPriorityIcon:UpdatePriorityIcon(spellId)
            end
        end)
    end

    if type(MaxDps.GlowClear) == 'function' then
        hooksecurefunc(MaxDps, 'GlowClear', function()
            if lastPrioritySpell ~= nil then
                lastPrioritySpell = nil
                MaxDpsPriorityIcon:UpdatePriorityIcon(nil)
            end
        end)
    end

    -- Hook cooldown updates with throttling
    if type(MaxDps.GlowCooldown) == 'function' then
        MaxDpsPriorityIcon._cooldownActive = MaxDpsPriorityIcon._cooldownActive or {}
        hooksecurefunc(MaxDps, 'GlowCooldown', function(maxdps, spellId, condition)
            if condition then
                -- Add/refresh this cooldown
                MaxDpsPriorityIcon._cooldownActive[spellId] = true
                MaxDpsPriorityIcon:UpdateCooldownIcon(spellId)
            else
                -- Remove this cooldown from active list
                MaxDpsPriorityIcon._cooldownActive[spellId] = nil
                if MaxDpsPriorityIcon.Icons and MaxDpsPriorityIcon.Icons.RemoveCooldown then
                    MaxDpsPriorityIcon.Icons:RemoveCooldown(spellId)
                else
                    MaxDpsPriorityIcon:UpdateCooldownIcon(nil)
                end
            end
        end)
    end
end

function MaxDpsPriorityIcon:UpdatePriorityIcon(spellId)
    if self.Icons then
        -- Don't update priority icon if it's currently being dragged
        if self.Icons.priorityFrame and self.Icons.priorityFrame.isDragging then
            return
        end
        
        if spellId and spellId ~= "" then
            self.Icons:UpdatePriority(spellId)
        else
            self.Icons:ClearPriority()
        end
    end
end

function MaxDpsPriorityIcon:UpdateCooldownIcon(spellId)
    if self.Icons then
        if spellId and spellId ~= "" then
            self.Icons:UpdateCooldown(spellId)
        else
            self.Icons:ClearCooldown()
        end
    end
end

function MaxDpsPriorityIcon:ShowConfig()
    if not self.Config then
        self.Config = self:GetModule('Config')
    end
    self.Config:ShowWindow()
end

function MaxDpsPriorityIcon:PLAYER_ENTERING_WORLD()
    if self.Icons then
        self.Icons:UpdateAllVisibility()
    end
end

function MaxDpsPriorityIcon:SetupBlizzardOptions()
    local panel = CreateFrame("Frame")
    panel.name = "MaxDps Priority Icon"
    panel.parent = "MaxDps"
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("MaxDps Priority Icon")
    
    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Centralized priority ability icon for MaxDps")
    
    local configButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    configButton:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
    configButton:SetSize(120, 22)
    configButton:SetText("Open Config")
    configButton:SetScript("OnClick", function()
        self:ShowConfig()
    end)
    
    -- Register panel
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        category.ID = panel.name
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end 
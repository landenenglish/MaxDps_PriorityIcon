local addonName, MaxDpsPriorityIcon = ...

-- Create the addon
MaxDpsPriorityIcon = LibStub('AceAddon-3.0'):NewAddon(MaxDpsPriorityIcon, addonName, 'AceEvent-3.0', 'AceConsole-3.0')

-- Default settings
-- Default positions (single source of truth)
local DEFAULT_PRIORITY_POSITION = { x = 0, y = -120 }  -- further below center by default
local DEFAULT_COOLDOWN_POSITION = { x = 60, y = -60 } -- a tad right and down from center

local defaults = {
    global = {
        enabled = true,
        combatOnly = false,
        
        -- Priority icon settings
        priority = {
            position = DEFAULT_PRIORITY_POSITION,
            scale = 0.35,
            enabled = true
        },
        
        -- Cooldown icon settings  
        cooldown = {
            position = DEFAULT_COOLDOWN_POSITION,
            scale = 0.30,
            enabled = true,
            maxShown = 3
        },
        
        locked = false
    }
}

-- Expose defaults for maintenance (read-only usage)
function MaxDpsPriorityIcon_GetDefaults()
    return defaults
end

function MaxDpsPriorityIcon:OnInitialize()
    -- Initialize database
    self.db = LibStub('AceDB-3.0'):New('MaxDpsPriorityIconDB', defaults)
    
    -- One-time, non-destructive migration for users upgrading from <= 1.0.x
    -- Applies only once by bumping a schema marker; future versions won't rerun it
    do
        local SCHEMA_110 = 110
        local db = self.db
        local prev = db.global.__schemaVersion or 0
        if prev < SCHEMA_110 then
            local changed = false
            local function isOffscreen(pos)
                if not pos or pos.x == nil or pos.y == nil then return true end
                local W = UIParent:GetWidth() or 0
                local H = UIParent:GetHeight() or 0
                return pos.x < -W or pos.x > W or pos.y < -H or pos.y > H
            end

            -- Priority position: adopt new default if missing, off-screen, or exactly old default (0,-100)
            db.global.priority = db.global.priority or {}
            db.global.priority.position = db.global.priority.position or {}
            local pri = db.global.priority.position
            if isOffscreen(pri) or (pri.x == 0 and pri.y == -100) then
                db.global.priority.position = { x = DEFAULT_PRIORITY_POSITION.x, y = DEFAULT_PRIORITY_POSITION.y }
                changed = true
            end

            -- Cooldown position: adopt new default if missing, off-screen, or exactly old default (100,-100)
            db.global.cooldown = db.global.cooldown or {}
            db.global.cooldown.position = db.global.cooldown.position or {}
            local cd = db.global.cooldown.position
            if isOffscreen(cd) or (cd.x == 100 and cd.y == -100) then
                db.global.cooldown.position = { x = DEFAULT_COOLDOWN_POSITION.x, y = DEFAULT_COOLDOWN_POSITION.y }
                changed = true
            end

            -- Prune any obsolete keys from earlier builds
            if db.global.cooldown.autoPosition ~= nil then
                db.global.cooldown.autoPosition = nil
                changed = true
            end

            db.global.__schemaVersion = SCHEMA_110
            if changed then
                self:Print('Settings updated to new defaults. Adjust in /maxdpspriority if desired.')
            end
        end
    end
    
    -- Register chat command
    self:RegisterChatCommand('maxdpspriority', 'ShowConfig')
    self:RegisterChatCommand('mdpspri', 'ShowConfig')
    
    -- Add to Blizzard Interface Options
    self:SetupBlizzardOptions()
    
    -- Setup reset confirmation dialog
    self:SetupResetDialog()
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
    -- Apply current DB settings to all runtime frames/state
    if self.Icons and self.Icons.ApplyAllSettingsFromDB then
        self.Icons:ApplyAllSettingsFromDB()
    end
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
        -- Force a quick refresh of the last known priority to remove any perceived lag
        if self.lastPrioritySpell ~= nil then
            self.Icons:UpdatePriority(self.lastPrioritySpell)
        end
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
    self.lastPrioritySpell = nil

    if type(MaxDps.InvokeNextSpell) == 'function' then
        hooksecurefunc(MaxDps, 'InvokeNextSpell', function(maxdps)
            if MaxDpsPriorityIcon.lastPrioritySpell ~= maxdps.Spell then
                MaxDpsPriorityIcon.lastPrioritySpell = maxdps.Spell
                MaxDpsPriorityIcon:UpdatePriorityIcon(maxdps.Spell)
            end
        end)
    end

    if type(MaxDps.GlowNextSpell) == 'function' then
        hooksecurefunc(MaxDps, 'GlowNextSpell', function(maxdps, spellId)
            if MaxDpsPriorityIcon.lastPrioritySpell ~= spellId then
                MaxDpsPriorityIcon.lastPrioritySpell = spellId
                MaxDpsPriorityIcon:UpdatePriorityIcon(spellId)
            end
        end)
    end

    if type(MaxDps.GlowClear) == 'function' then
        hooksecurefunc(MaxDps, 'GlowClear', function()
            if MaxDpsPriorityIcon.lastPrioritySpell ~= nil then
                MaxDpsPriorityIcon.lastPrioritySpell = nil
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

function MaxDpsPriorityIcon:IsConfigOpen()
    return self.Config and self.Config.frame and self.Config.frame:IsShown() or false
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

function MaxDpsPriorityIcon:SetupResetDialog()
    StaticPopupDialogs['MAXDPS_PRIORITY_ICON_RESET_CONFIRM'] = {
        text = 'Are you sure you want to reset all MaxDps Priority Icon settings to defaults?\n\nThis will reset positions, scales, and all configuration options.',
        button1 = 'Reset All',
        button2 = 'Cancel',
        OnAccept = function()
            MaxDpsPriorityIcon:ResetAllSettings()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

function MaxDpsPriorityIcon:ResetAllSettings()
    -- Stop any runtime-only state (tests, tickers, drag) before resetting
    if self.Icons and self.Icons.ResetRuntime then
        self.Icons:ResetRuntime()
    end

    -- Reset SavedVariables to defaults
    self.db:ResetDB()

    -- Re-apply settings from DB into runtime objects
    if self.Icons and self.Icons.ApplyAllSettingsFromDB then
        self.Icons:ApplyAllSettingsFromDB()
    end

    -- Refresh the config UI if it's open
    local config = self:GetModule('Config', true)
    if config and config.frame and config.frame:IsShown() then
        config.frame:Hide()
        config.frame = nil
        config:ShowWindow()
    end

    self:Print('All settings have been reset to defaults.')
end 
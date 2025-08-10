local addonName, MaxDpsPriorityIcon = ...

--- @class Config
local Config = MaxDpsPriorityIcon:NewModule('Config')

function Config:ShowWindow()
    if self.frame then
        self.frame:Show()
        return
    end

    self:CreateConfigFrame()
    self.frame:Show()
end

function Config:CreateConfigFrame()
    -- Main frame
    local frame = CreateFrame('Frame', 'MaxDpsPriorityIconConfigFrame', UIParent, 'BasicFrameTemplateWithInset')
    frame:SetSize(520, 580)
    frame:ClearAllPoints()
    frame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 180, -120)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', frame.StartMoving)
    frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
    frame:SetFrameStrata('DIALOG')

    -- Title (use template defaults for TitleBg)
    frame.title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    if frame.TitleBg then
        frame.title:SetPoint('CENTER', frame.TitleBg, 'CENTER', 0, 0)
    else
        frame.title:SetPoint('TOP', frame, 'TOP', 0, -12)
    end
    frame.title:SetText('MaxDps Priority Icon — Settings')

    -- Content area (no scroll)
    local content = CreateFrame('Frame', nil, frame)
    content:SetPoint('TOPLEFT', frame, 'TOPLEFT', 16, -40)
    content:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -16, 54)

    local yOffset = -8
    local xPad = 10

    -- Helper: section container with header
    local function CreateSection(title)
        local section = CreateFrame('Frame', nil, content, 'InsetFrameTemplate3')
        section:SetPoint('TOPLEFT', content, 'TOPLEFT', xPad, yOffset)
        section:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -xPad, yOffset)
        section:SetHeight(1) -- will grow as children are positioned

        local header = section:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
        header:SetPoint('TOPLEFT', section, 'TOPLEFT', 10, -10)
        header:SetText(title)

        return section, header
    end

    local function FinishSection(section, bottomWidget)
        local top, bottom = section:GetTop(), bottomWidget:GetBottom()
        local height = (top and bottom) and (top - bottom + 14) or 80
        section:SetHeight(height)
        yOffset = yOffset - height - 10
    end

    -- General section
    local general, genHeader = CreateSection('General')
    local genY = -34

    local enabledCheck = CreateFrame('CheckButton', nil, general, 'ChatConfigCheckButtonTemplate')
    enabledCheck:SetPoint('TOPLEFT', general, 'TOPLEFT', 10, genY)
    enabledCheck.Text:SetText('Enable Icons')
    enabledCheck:SetChecked(MaxDpsPriorityIcon.db.global.enabled)
    enabledCheck:SetScript('OnClick', function(self)
        MaxDpsPriorityIcon.db.global.enabled = self:GetChecked()
        Config:UpdateIcons()
    end)
    genY = genY - 28

    local lockCheck = CreateFrame('CheckButton', nil, general, 'ChatConfigCheckButtonTemplate')
    lockCheck:SetPoint('TOPLEFT', general, 'TOPLEFT', 10, genY)
    lockCheck.Text:SetText('Lock Positions')
    lockCheck:SetChecked(MaxDpsPriorityIcon.db.global.locked)
    lockCheck:SetScript('OnClick', function(self)
        MaxDpsPriorityIcon.db.global.locked = self:GetChecked()
    end)
    genY = genY - 28

    local combatCheck = CreateFrame('CheckButton', nil, general, 'ChatConfigCheckButtonTemplate')
    combatCheck:SetPoint('TOPLEFT', general, 'TOPLEFT', 10, genY)
    combatCheck.Text:SetText('Show Only in Combat (icons always show while this menu is open)')
    combatCheck:SetChecked(MaxDpsPriorityIcon.db.global.combatOnly)
    combatCheck:SetScript('OnClick', function(self)
        MaxDpsPriorityIcon.db.global.combatOnly = self:GetChecked()
        Config:UpdateIcons()
    end)
    genY = genY - 36

    -- Small tip line
    local tip = general:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    tip:SetPoint('TOPLEFT', general, 'TOPLEFT', 14, genY)
    tip:SetText('Tip: Drag icons to move • Right-click icons for quick config')
    genY = genY - 18
    FinishSection(general, tip)

    -- Priority section
    local pri, priHeader = CreateSection('Priority Icon')
    local priY = -34

    local priEnable = CreateFrame('CheckButton', nil, pri, 'ChatConfigCheckButtonTemplate')
    priEnable:SetPoint('TOPLEFT', pri, 'TOPLEFT', 10, priY)
    priEnable.Text:SetText('Enable')
    priEnable:SetChecked(MaxDpsPriorityIcon.db.global.priority.enabled)
    priEnable:SetScript('OnClick', function(self)
        MaxDpsPriorityIcon.db.global.priority.enabled = self:GetChecked()
        Config:UpdateIcons()
    end)
    priY = priY - 28

    local priScaleLabel = pri:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    priScaleLabel:SetPoint('TOPLEFT', pri, 'TOPLEFT', 10, priY)
    priScaleLabel:SetText('Scale')
    local priValue = pri:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    priValue:SetPoint('LEFT', priScaleLabel, 'RIGHT', 6, 0)
    priValue:SetText(string.format('%.2f', MaxDpsPriorityIcon.db.global.priority.scale))
    priY = priY - 18

    local priSlider = CreateFrame('Slider', nil, pri, 'OptionsSliderTemplate')
    priSlider:SetPoint('TOPLEFT', pri, 'TOPLEFT', 10, priY)
    priSlider:SetMinMaxValues(0.2, 1.2)
    priSlider:SetValue(MaxDpsPriorityIcon.db.global.priority.scale)
    priSlider:SetValueStep(0.05)
    priSlider:SetObeyStepOnDrag(true)
    priSlider:SetWidth(180)
    priSlider:SetScript('OnValueChanged', function(self, value)
        value = math.floor(value * 20 + 0.5) / 20
        MaxDpsPriorityIcon.db.global.priority.scale = value
        priValue:SetText(string.format('%.2f', value))
        Config:UpdateIcons()
    end)
    priY = priY - 36
    local priBottom = priSlider
    FinishSection(pri, priBottom)

    -- Cooldowns section
    local cd, cdHeader = CreateSection('Cooldown Icons')
    local cdY = -34

    local cdEnable = CreateFrame('CheckButton', nil, cd, 'ChatConfigCheckButtonTemplate')
    cdEnable:SetPoint('TOPLEFT', cd, 'TOPLEFT', 10, cdY)
    cdEnable.Text:SetText('Enable')
    cdEnable:SetChecked(MaxDpsPriorityIcon.db.global.cooldown.enabled)
    cdEnable:SetScript('OnClick', function(self)
        MaxDpsPriorityIcon.db.global.cooldown.enabled = self:GetChecked()
        Config:UpdateIcons()
    end)
    cdY = cdY - 28

    local cdScaleLabel = cd:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    cdScaleLabel:SetPoint('TOPLEFT', cd, 'TOPLEFT', 10, cdY)
    cdScaleLabel:SetText('Scale')
    local cdValue = cd:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    cdValue:SetPoint('LEFT', cdScaleLabel, 'RIGHT', 6, 0)
    cdValue:SetText(string.format('%.2f', MaxDpsPriorityIcon.db.global.cooldown.scale))
    cdY = cdY - 18

    local cdSlider = CreateFrame('Slider', nil, cd, 'OptionsSliderTemplate')
    cdSlider:SetPoint('TOPLEFT', cd, 'TOPLEFT', 10, cdY)
    cdSlider:SetMinMaxValues(0.15, 1.2)
    cdSlider:SetValue(MaxDpsPriorityIcon.db.global.cooldown.scale)
    cdSlider:SetValueStep(0.05)
    cdSlider:SetObeyStepOnDrag(true)
    cdSlider:SetWidth(180)
    cdSlider:SetScript('OnValueChanged', function(self, value)
        value = math.floor(value * 20 + 0.5) / 20
        MaxDpsPriorityIcon.db.global.cooldown.scale = value
        cdValue:SetText(string.format('%.2f', value))
        Config:UpdateIcons()
    end)
    cdY = cdY - 36

    local maxLabel = cd:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    maxLabel:SetPoint('TOPLEFT', cd, 'TOPLEFT', 10, cdY)
    maxLabel:SetText('Max cooldown icons shown')
    local maxValue = cd:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
    maxValue:SetPoint('LEFT', maxLabel, 'RIGHT', 6, 0)
    maxValue:SetText(tostring(MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3))
    cdY = cdY - 18

    local maxSlider = CreateFrame('Slider', nil, cd, 'OptionsSliderTemplate')
    maxSlider:SetPoint('TOPLEFT', cd, 'TOPLEFT', 10, cdY)
    maxSlider:SetMinMaxValues(1, 6)
    maxSlider:SetValue(MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3)
    maxSlider:SetValueStep(1)
    maxSlider:SetObeyStepOnDrag(true)
    maxSlider:SetWidth(180)
    maxSlider:SetScript('OnValueChanged', function(self, value)
        value = math.floor(value + 0.5)
        MaxDpsPriorityIcon.db.global.cooldown.maxShown = value
        maxValue:SetText(tostring(value))
        Config:UpdateIcons()
    end)
    cdY = cdY - 36

    local cdBottom = maxSlider
    FinishSection(cd, cdBottom)

    -- Reset All (footer)
    local resetAllBtn = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
    resetAllBtn:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 10, 10)
    resetAllBtn:SetSize(140, 24)
    resetAllBtn:SetText('Reset All Settings')
    resetAllBtn:SetScript('OnClick', function()
        StaticPopup_Show('MAXDPS_PRIORITY_ICON_RESET_CONFIRM')
    end)

    -- Live apply when opening
    frame:HookScript('OnShow', function()
        if MaxDpsPriorityIcon and MaxDpsPriorityIcon.Icons and MaxDpsPriorityIcon.Icons.ApplyAllSettingsFromDB then
            MaxDpsPriorityIcon.Icons:ApplyAllSettingsFromDB()
        end
    end)

    local closeBtn = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
    closeBtn:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -10, 10)
    closeBtn:SetSize(80, 24)
    closeBtn:SetText('Close')
    closeBtn:SetScript('OnClick', function() frame:Hide() end)

    self.frame = frame
end

function Config:CreateIconSection() end -- deprecated

function Config:UpdateIcons()
    local icons = MaxDpsPriorityIcon.Icons
    if icons then
        -- Update priority icon
        icons:UpdatePriorityPosition()
        icons:UpdatePriorityScale()
        icons:UpdatePriorityVisibility()
        if icons.priorityFrame and icons.priorityFrame.spellId then
            icons:UpdatePriority(icons.priorityFrame.spellId)
        end
        
        -- Update cooldown icon
        icons:UpdateCooldownPosition()
        icons:UpdateCooldownScale()
        icons:UpdateCooldownVisibility()
        if icons.cooldownFrame and icons.cooldownFrame.spellId then
            icons:UpdateCooldown(icons.cooldownFrame.spellId)
        end
    end
end 
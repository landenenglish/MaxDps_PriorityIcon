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
    frame:SetSize(420, 500)
    frame:SetPoint('CENTER')
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')
    frame:SetScript('OnDragStart', frame.StartMoving)
    frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
    frame:SetFrameStrata('DIALOG')

    -- Title
    frame.title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
    frame.title:SetPoint('LEFT', frame.TitleBg, 'LEFT', 5, 0)
    frame.title:SetText('MaxDps Icons Configuration')

    -- Content area
    local content = CreateFrame('Frame', nil, frame)
    content:SetPoint('TOPLEFT', frame, 'TOPLEFT', 20, -40)
    content:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -20, 20)

    local yOffset = -10

    -- Global Enable checkbox
    local enabledCheck = CreateFrame('CheckButton', nil, content, 'ChatConfigCheckButtonTemplate')
    enabledCheck:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, yOffset)
    enabledCheck.Text:SetText('Enable Icons')
    enabledCheck:SetChecked(MaxDpsPriorityIcon.db.global.enabled)
    enabledCheck:SetScript('OnClick', function(self)
        MaxDpsPriorityIcon.db.global.enabled = self:GetChecked()
        Config:UpdateIcons()
    end)
    yOffset = yOffset - 35

    -- Lock position checkbox
    local lockCheck = CreateFrame('CheckButton', nil, content, 'ChatConfigCheckButtonTemplate')
    lockCheck:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, yOffset)
    lockCheck.Text:SetText('Lock Positions')
    lockCheck:SetChecked(MaxDpsPriorityIcon.db.global.locked)
    lockCheck:SetScript('OnClick', function(self)
        MaxDpsPriorityIcon.db.global.locked = self:GetChecked()
    end)
    yOffset = yOffset - 35

    -- Combat only checkbox
    local combatCheck = CreateFrame('CheckButton', nil, content, 'ChatConfigCheckButtonTemplate')
    combatCheck:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, yOffset)
    combatCheck.Text:SetText('Show Only in Combat')
    combatCheck:SetChecked(MaxDpsPriorityIcon.db.global.combatOnly)
    combatCheck:SetScript('OnClick', function(self)
        MaxDpsPriorityIcon.db.global.combatOnly = self:GetChecked()
        Config:UpdateIcons()
    end)
    yOffset = yOffset - 50

    -- Priority Icon Section
    local priorityHeader = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    priorityHeader:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, yOffset)
    priorityHeader:SetText('Priority Icon (Rotation)')
    yOffset = yOffset - 25

    self:CreateIconSection(content, yOffset, 'priority')
    yOffset = yOffset - 120

    -- Cooldown Icon Section  
    local cooldownHeader = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')
    cooldownHeader:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, yOffset)
    cooldownHeader:SetText('Cooldown Icon')
    yOffset = yOffset - 25

    self:CreateIconSection(content, yOffset, 'cooldown')
    yOffset = yOffset - 100

    -- Max cooldowns shown
    local maxLabel = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    maxLabel:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, yOffset)
    maxLabel:SetText('Max cooldown icons shown: ' .. tostring(MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3))
    
    local maxSlider = CreateFrame('Slider', nil, content, 'OptionsSliderTemplate')
    maxSlider:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, yOffset - 20)
    maxSlider:SetMinMaxValues(1, 6)
    maxSlider:SetValue(MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3)
    maxSlider:SetValueStep(1)
    maxSlider:SetObeyStepOnDrag(true)
    maxSlider:SetWidth(150)
    maxSlider:SetScript('OnValueChanged', function(self, value)
        value = math.floor(value + 0.5)
        MaxDpsPriorityIcon.db.global.cooldown.maxShown = value
        maxLabel:SetText('Max cooldown icons shown: ' .. tostring(value))
        Config:UpdateIcons()
    end)
    yOffset = yOffset - 60

    -- Instructions
    local instructionText = content:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    instructionText:SetPoint('TOPLEFT', content, 'TOPLEFT', 0, yOffset)
    instructionText:SetPoint('TOPRIGHT', content, 'TOPRIGHT', 0, yOffset)
    instructionText:SetJustifyH('LEFT')
    instructionText:SetText('• Drag icons to move • Right-click to configure\n• Commands: /maxdpspriority or /mdpspri')

    self.frame = frame
end

function Config:CreateIconSection(parent, yOffset, iconType)
    -- Enable checkbox
    local enabledCheck = CreateFrame('CheckButton', nil, parent, 'ChatConfigCheckButtonTemplate')
    enabledCheck:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, yOffset)
    enabledCheck.Text:SetText('Enable')
    enabledCheck:SetChecked(MaxDpsPriorityIcon.db.global[iconType].enabled)
    enabledCheck:SetScript('OnClick', function(self)
        MaxDpsPriorityIcon.db.global[iconType].enabled = self:GetChecked()
        Config:UpdateIcons()
    end)
    
    -- Scale slider
    local scaleLabel = parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    scaleLabel:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, yOffset - 25)
    scaleLabel:SetText('Scale: ' .. string.format('%.2f', MaxDpsPriorityIcon.db.global[iconType].scale))

    local scaleSlider = CreateFrame('Slider', nil, parent, 'OptionsSliderTemplate')
    scaleSlider:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, yOffset - 45)
    -- Center smaller with a broader small-side range
    scaleSlider:SetMinMaxValues(0.2, 1.4)
    scaleSlider:SetValue(MaxDpsPriorityIcon.db.global[iconType].scale)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetWidth(150)
    scaleSlider:SetScript('OnValueChanged', function(self, value)
        value = math.floor(value * 20 + 0.5) / 20
        MaxDpsPriorityIcon.db.global[iconType].scale = value
        scaleLabel:SetText('Scale: ' .. string.format('%.2f', value))
        Config:UpdateIcons()
    end)

    -- Test button
    local testBtn = CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate')
    testBtn:SetPoint('TOPLEFT', parent, 'TOPLEFT', 0, yOffset - 70)
    testBtn:SetSize(80, 20)
    testBtn:SetText('Test')
    testBtn:SetScript('OnClick', function()
        local icons = MaxDpsPriorityIcon.Icons
        if icons then
            if iconType == 'priority' then
                icons:TogglePriorityTest()
            else
                icons:ToggleCooldownTest()
            end
        end
    end)

    -- Reset position button
    local resetBtn = CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate')
    resetBtn:SetPoint('LEFT', testBtn, 'RIGHT', 5, 0)
    resetBtn:SetSize(80, 20)
    resetBtn:SetText('Reset')
    resetBtn:SetScript('OnClick', function()
        local defaults = iconType == 'priority' and {x = 0, y = -100} or {x = 100, y = -100}
        MaxDpsPriorityIcon.db.global[iconType].position.x = defaults.x
        MaxDpsPriorityIcon.db.global[iconType].position.y = defaults.y
        Config:UpdateIcons()
    end)
end

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
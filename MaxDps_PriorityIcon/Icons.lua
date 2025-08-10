local addonName, MaxDpsPriorityIcon = ...

--- @class Icons
local Icons = MaxDpsPriorityIcon:NewModule('Icons', 'AceEvent-3.0')

local GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
local C_Timer = C_Timer

-- Multiple cooldown frame support
Icons.cooldownFrames = Icons.cooldownFrames or {}
-- Soft-corner helpers (simulate slight border radius without circular mask)
-- (rounded-corner attempts reverted; use standard texcoords)
Icons.draggingCooldownGroup = false

-- A pool of common spellIds for random test display
-- test mode removed

function Icons:OnEnable()
    self:CreateFrames()
    return self
end

function Icons:CreateFrames()
    self:CreatePriorityFrame()
    self:EnsureCooldownContainer()
    local maxShown = MaxDpsPriorityIcon.db and MaxDpsPriorityIcon.db.global and MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    for i = 1, maxShown do
        self:CreateCooldownFrame(i)
    end
end

function Icons:EnsureCooldownContainer()
    if self.cooldownContainer then return end
    local container = CreateFrame('Frame', 'MaxDpsPriorityIconCooldownContainer', UIParent)
    container:SetSize(1, 1)
    container:SetFrameStrata('MEDIUM')
    container:SetFrameLevel(48)
    container:SetMovable(true)
    container:SetClampedToScreen(true)
    local pos = MaxDpsPriorityIcon.db.global.cooldown.position
    local x, y = pos.x or 140, pos.y or -140
    container:SetPoint('CENTER', UIParent, 'CENTER', x, y)
    self.cooldownContainer = container
end

function Icons:UpdateAllVisibility()
    self:UpdatePriorityVisibility()
    self:UpdateCooldownVisibility()
end

function Icons:CreatePriorityFrame()
    if self.priorityFrame then return end

    local frame = CreateFrame('Frame', 'MaxDpsPriorityIconPriorityFrame', UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
    frame:SetSize(80, 80)
    frame:SetFrameStrata('MEDIUM')
    frame:SetFrameLevel(50)

    local icon = frame:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    frame.icon = icon

    self:MakeDraggable(frame, 'priority')

    self.priorityFrame = frame
    self:UpdatePriorityPosition()
    self:UpdatePriorityScale()
    self:UpdatePriorityVisibility()
end

function Icons:CreateCooldownFrame(index)
    if self.cooldownFrames[index] then return end

    local name = 'MaxDpsPriorityIconCooldownFrame' .. index
    local parent = self.cooldownContainer or UIParent
    local frame = CreateFrame('Frame', name, parent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
    frame:SetSize(64, 64)
    frame:SetFrameStrata('MEDIUM')
    frame:SetFrameLevel(50)

    local icon = frame:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    frame.icon = icon

    self:MakeDraggable(frame, 'cooldown')

    self.cooldownFrames[index] = frame
end

function Icons:EnsureCooldownCapacity()
    local maxShown = MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    for i = 1, maxShown do
        if not self.cooldownFrames[i] then
            self:CreateCooldownFrame(i)
        end
    end
    -- Hide and clear any extra frames beyond maxShown
    for i = maxShown + 1, #self.cooldownFrames do
        local frame = self.cooldownFrames[i]
        if frame then
            frame:Hide()
            frame.spellId = nil
        end
    end
end

function Icons:MakeDraggable(frame, iconType)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame.isDragging = false
    
    frame:SetScript('OnMouseDown', function(f, button)
        if button == 'LeftButton' and not MaxDpsPriorityIcon.db.global.locked then
            f.isDragging = true
            if iconType == 'cooldown' then
                -- For cooldown icons, move the group by dragging the first frame only
                self:StartCooldownGroupDrag(self.cooldownFrames[1] or f)
            else
                f:StartMoving()
            end
        end
    end)
    
    frame:SetScript('OnMouseUp', function(f, button)
        if button == 'LeftButton' and f.isDragging then
            f.isDragging = false
            if iconType == 'cooldown' then
                self:StopCooldownGroupDrag(f)
            else
                f:StopMovingOrSizing()
                -- Persist priority icon position
                local _, _, _, xOfs, yOfs = f:GetPoint()
                if xOfs and yOfs then
                    MaxDpsPriorityIcon.db.global.priority.position.x = xOfs
                    MaxDpsPriorityIcon.db.global.priority.position.y = yOfs
                end
            end
        elseif button == 'RightButton' then
            MaxDpsPriorityIcon:ShowConfig()
        end
    end)
end
-- Centralized apply-from-DB routine for all frames/state
function Icons:ApplyAllSettingsFromDB()
    -- Priority icon
    if not self.priorityFrame then self:CreatePriorityFrame() end
    self:RefreshPriority()

    -- Cooldown container and frames
    self:EnsureCooldownContainer()
    self:ReanchorCooldownContainerToDB()
    self:EnsureCooldownCapacity()
    self:RefreshCooldowns()
end
-- High-level refresh helpers (DRY)
function Icons:RefreshPriority()
    self:UpdatePriorityScale()
    self:UpdatePriorityPosition()
    self:UpdatePriorityVisibility()
end

function Icons:RefreshCooldowns()
    self:UpdateCooldownScale()
    self:UpdateCooldownPosition()
    self:UpdateCooldownVisibility()
end

-- Clear all runtime-only state (no SavedVariables changes)
function Icons:ResetRuntime()
    -- No test mode state

    -- Clear frames content/visibility
    self:ClearPriority()
    self:ClearCooldown()

    -- Clear dragging and timers
    self.draggingCooldownGroup = false
    if self._dragUpdater then
        self._dragUpdater:SetScript('OnUpdate', nil)
    end
end

-- Force the cooldown container to match DB-saved position
function Icons:ReanchorCooldownContainerToDB()
    if not self.cooldownContainer then return end
    local pos = MaxDpsPriorityIcon.db and MaxDpsPriorityIcon.db.global and MaxDpsPriorityIcon.db.global.cooldown and MaxDpsPriorityIcon.db.global.cooldown.position or nil
    local x = (pos and pos.x) or 60
    local y = (pos and pos.y) or -60
    self.cooldownContainer:ClearAllPoints()
    self.cooldownContainer:SetPoint('CENTER', UIParent, 'CENTER', x, y)
end

function Icons:StartCooldownGroupDrag(draggedFrame)
    self.draggingCooldownGroup = true
    local maxShown = MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    local spacing = 6
    local frameWidth = (self.cooldownFrames[1] and self.cooldownFrames[1]:GetWidth()) or 64

    -- Mark frames as dragging to suppress external repositioning
    for i = 1, maxShown do
        local frame = self.cooldownFrames[i]
        if frame then
            frame.isDragging = true
            if frame.icon and frame.icon:GetTexture() then frame:Show() end
        end
    end

    -- Record starting cursor offset and container offset (center-relative)
    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    cursorX, cursorY = cursorX / uiScale, cursorY / uiScale
    local parentCenterX, parentCenterY = UIParent:GetCenter()
    local contX, contY = self.cooldownContainer:GetCenter()
    self._dragStartCursorOffX = cursorX - parentCenterX
    self._dragStartCursorOffY = cursorY - parentCenterY
    self._dragStartContOffX = contX - parentCenterX
    self._dragStartContOffY = contY - parentCenterY

    -- Ensure we have an updater frame
    if not self._dragUpdater then
        self._dragUpdater = CreateFrame('Frame')
    end

    self._dragUpdater:SetScript('OnUpdate', function()
        if not self.draggingCooldownGroup then return end
        local x, y = GetCursorPosition()
        x, y = x / uiScale, y / uiScale
        local offX = x - parentCenterX
        local offY = y - parentCenterY
        local deltaX = offX - self._dragStartCursorOffX
        local deltaY = offY - self._dragStartCursorOffY
        local newContX = self._dragStartContOffX + deltaX
        local newContY = self._dragStartContOffY + deltaY

        self.cooldownContainer:ClearAllPoints()
        self.cooldownContainer:SetPoint('CENTER', UIParent, 'CENTER', newContX, newContY)
        -- Children are anchored to container; just refresh layout
        self:UpdateCooldownPosition()
    end)
end

function Icons:StopCooldownGroupDrag(draggedFrame)
    -- Stop updater
    if self._dragUpdater then
        self._dragUpdater:SetScript('OnUpdate', nil)
    end

    -- Save final container center offset
    local contX, contY = self.cooldownContainer:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()
    MaxDpsPriorityIcon.db.global.cooldown.position.x = contX - parentCenterX
    MaxDpsPriorityIcon.db.global.cooldown.position.y = contY - parentCenterY

    -- Clear dragging flags
    local maxShown = MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    for i = 1, maxShown do
        local frame = self.cooldownFrames[i]
        if frame then frame.isDragging = false end
    end
    self.draggingCooldownGroup = false

    -- Reposition and ensure visible if testing
    self:UpdateCooldownPosition()
    self:UpdateCooldownVisibility()
    self.draggingCooldownGroup = false
end

-- Priority Icon Methods
function Icons:UpdatePriorityPosition()
    if not self.priorityFrame then return end
    if self.priorityFrame.isDragging then return end -- Don't update position while dragging
    
    local pos = MaxDpsPriorityIcon.db.global.priority.position
    local x, y = pos.x or 0, pos.y or -120
    self.priorityFrame:ClearAllPoints()
    self.priorityFrame:SetPoint('CENTER', UIParent, 'CENTER', x, y)
end

function Icons:UpdatePriorityScale()
    if not self.priorityFrame then return end
    
    local scale = MaxDpsPriorityIcon.db.global.priority.scale or 1.0
    self.priorityFrame:SetScale(scale)
end

function Icons:UpdatePriorityVisibility()
    if self.priorityFrame then
        local enabled = MaxDpsPriorityIcon.db.global.enabled and MaxDpsPriorityIcon.db.global.priority.enabled
        local menuOpen = MaxDpsPriorityIcon.IsConfigOpen and MaxDpsPriorityIcon:IsConfigOpen()
        local combatOk = menuOpen or (not MaxDpsPriorityIcon.db.global.combatOnly or InCombatLockdown())
        self.priorityFrame:SetShown(enabled and combatOk)
    end
end

function Icons:UpdatePriority(spellId)
    if not self.priorityFrame then 
        self:CreatePriorityFrame() 
    end
    
    if not spellId or spellId == '' or not MaxDpsPriorityIcon.db.global.enabled or not MaxDpsPriorityIcon.db.global.priority.enabled then
        if self.priorityFrame and not self.priorityFrame.isDragging then
            self.priorityFrame:Hide()
        end
        return
    end

    local spellTexture = GetSpellTexture(spellId)
    if not spellTexture then
        if self.priorityFrame and not self.priorityFrame.isDragging then
            self.priorityFrame:Hide()
        end
        return
    end

    if self.priorityFrame then
        self.priorityFrame.icon:SetTexture(spellTexture)
        self.priorityFrame.spellId = spellId
        if not self.priorityFrame.isDragging then
            self:UpdatePriorityVisibility()
        end
    end
end

-- Cooldown Icon Methods
function Icons:UpdateCooldownPosition()
    local maxShown = MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    local spacing = 6
    local container = self.cooldownContainer
    if not container then self:EnsureCooldownContainer(); container = self.cooldownContainer end

    -- Position cooldown frames relative to the container only
    for i = 1, maxShown do
        local frame = self.cooldownFrames[i]
        if frame and not frame.isDragging then
            frame:ClearAllPoints()
            local width = frame:GetWidth() or 64
            frame:SetPoint('CENTER', container, 'CENTER', (i - 1) * (width + spacing), 0)
        end
    end
end

function Icons:UpdateCooldownScale()
    local scale = MaxDpsPriorityIcon.db.global.cooldown.scale or 1.0
    local maxShown = MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    for i = 1, maxShown do
        local frame = self.cooldownFrames[i]
        if frame then
            frame:SetScale(scale)
        end
    end
end

function Icons:UpdateCooldownVisibility()
    local enabled = MaxDpsPriorityIcon.db.global.enabled and MaxDpsPriorityIcon.db.global.cooldown.enabled
    local menuOpen = MaxDpsPriorityIcon.IsConfigOpen and MaxDpsPriorityIcon:IsConfigOpen()
    local combatOk = menuOpen or self.draggingCooldownGroup == true or (not MaxDpsPriorityIcon.db.global.combatOnly or InCombatLockdown())
    local show = enabled and combatOk
    local maxShown = MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    for i = 1, maxShown do
        local frame = self.cooldownFrames[i]
        if frame and not frame.isDragging then
            frame:SetShown(show and frame.spellId ~= nil)
        end
    end
end

function Icons:UpdateCooldown(spellId)
    -- Add or refresh a cooldown icon
    local enabled = MaxDpsPriorityIcon.db.global.enabled and MaxDpsPriorityIcon.db.global.cooldown.enabled
    if not enabled or not spellId or spellId == '' then return end
    self:EnsureCooldownCapacity()

    local texture = GetSpellTexture(spellId)
    if not texture then return end

    local maxShown = MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    -- Already present?
    for i = 1, maxShown do
        local frame = self.cooldownFrames[i]
        if frame and frame.spellId == spellId then
            frame.icon:SetTexture(texture)
            self:UpdateCooldownVisibility()
            return
        end
    end

    -- Place in first empty slot
    for i = 1, maxShown do
        local frame = self.cooldownFrames[i]
        if frame and frame.spellId == nil then
            frame.icon:SetTexture(texture)
            frame.spellId = spellId
            self:UpdateCooldownPosition()
            self:UpdateCooldownScale()
            self:UpdateCooldownVisibility()
            return
        end
    end

    -- Shift left and add to the end
    for i = 1, maxShown - 1 do
        local f1, f2 = self.cooldownFrames[i], self.cooldownFrames[i + 1]
        if f1 and f2 then
            f1.spellId = f2.spellId
            if f2.icon:GetTexture() then
                f1.icon:SetTexture(f2.icon:GetTexture())
            end
        end
    end
    local last = self.cooldownFrames[maxShown]
    if last then
        last.icon:SetTexture(texture)
        last.spellId = spellId
    end
    self:UpdateCooldownVisibility()
end

function Icons:RemoveCooldown(spellId)
    if not spellId then return end
    local maxShown = MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    local index = nil
    for i = 1, maxShown do
        local frame = self.cooldownFrames[i]
        if frame and frame.spellId == spellId then
            index = i
            break
        end
    end
    if not index then return end

    -- Shift left from index+1
    for i = index, maxShown - 1 do
        local f1, f2 = self.cooldownFrames[i], self.cooldownFrames[i + 1]
        if f1 then
            if f2 and f2.spellId then
                f1.spellId = f2.spellId
                if f2.icon:GetTexture() then
                    f1.icon:SetTexture(f2.icon:GetTexture())
                end
            else
                f1.spellId = nil
                f1.icon:SetTexture(nil)
            end
        end
    end
    local last = self.cooldownFrames[maxShown]
    if last then
        last.spellId = nil
        last.icon:SetTexture(nil)
    end
    self:UpdateCooldownVisibility()
end

-- Position Management
function Icons:SavePosition(iconType)
    if iconType == 'priority' then
        local frame = self.priorityFrame
        if not frame or frame.isDragging then return end
        local _, _, _, xOfs, yOfs = frame:GetPoint()
        local pos = MaxDpsPriorityIcon.db.global[iconType].position
        pos.x, pos.y = xOfs, yOfs
    else
        -- Save the cooldown container position relative to UIParent center
        if not self.cooldownContainer then return end
        local contX, contY = self.cooldownContainer:GetCenter()
        if not contX or not contY then return end
        local parentCenterX, parentCenterY = UIParent:GetCenter()
        local pos = MaxDpsPriorityIcon.db.global[iconType].position
        pos.x = contX - parentCenterX
        pos.y = contY - parentCenterY
    end
end

function Icons:SavePositions()
    self:SavePosition('priority')
    self:SavePosition('cooldown')
end

-- Utility Methods
function Icons:ClearPriority()
    if self.priorityFrame then
        self.priorityFrame:Hide()
        self.priorityFrame.spellId = nil
    end
    self.priorityTestActive = false
end

function Icons:ClearCooldown()
    local maxShown = MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    for i = 1, maxShown do
        local frame = self.cooldownFrames[i]
        if frame then
            frame:Hide()
            frame.spellId = nil
            frame.icon:SetTexture(nil)
        end
    end
    self.cooldownTestActive = false
end

function Icons:HideAll()
    if self.priorityFrame then self.priorityFrame:Hide() end
    local maxShown = MaxDpsPriorityIcon.db.global.cooldown.maxShown or 3
    for i = 1, maxShown do
        local frame = self.cooldownFrames[i]
        if frame then frame:Hide() end
    end
end
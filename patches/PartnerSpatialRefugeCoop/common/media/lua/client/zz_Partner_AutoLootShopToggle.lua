-- Per-sell-category automatic corpse-loot toggle in the shop detail panel.

require "zz_Partner_AutomaticSellLoot"
require "MSR_ShopDetails"
require "ISUI/ISButton"

local TAG = "[PartnerAutoLootShopToggle]"
local API = MSR.PartnerAutomaticSellLoot
local Details = MSR_ShopDetails

local function getLabel(key, fallback)
    local value = getText(key)
    if not value or value == key then return fallback end
    return value
end

local function refreshButton(self)
    local button = self and self.partnerAutoLootButton or nil
    if not button then return end

    local groupId = self.item and self.item.id or nil
    local requiredLevel = groupId and API.getGroupRequiredLevel(groupId) or nil
    if not requiredLevel or not self.item.isSell then
        button:setVisible(false)
        return
    end

    button:setVisible(true)
    local currentLevel = API.getPlayerUpgradeLevel(self.player)
    if currentLevel < requiredLevel then
        button:setEnable(false)
        button.title = string.format(
            getLabel("UI_Shop_AutoLootLocked", "자동 줍기: %d단계 필요"),
            requiredLevel
        )
        button.backgroundColor = { r = 0.26, g = 0.24, b = 0.28, a = 0.88 }
        button.backgroundColorMouseOver = { r = 0.26, g = 0.24, b = 0.28, a = 0.88 }
        button.borderColor = { r = 0.50, g = 0.47, b = 0.54, a = 0.75 }
        return
    end

    button:setEnable(true)
    if API.isGroupEnabled(self.player, groupId) then
        button.title = getLabel("UI_Shop_AutoLootOn", "자동 줍기: 켜짐")
        button.backgroundColor = { r = 0.16, g = 0.44, b = 0.22, a = 0.92 }
        button.backgroundColorMouseOver = { r = 0.23, g = 0.55, b = 0.30, a = 0.96 }
        button.borderColor = { r = 0.45, g = 0.82, b = 0.50, a = 0.90 }
    else
        button.title = getLabel("UI_Shop_AutoLootOff", "자동 줍기: 꺼짐")
        button.backgroundColor = { r = 0.43, g = 0.18, b = 0.18, a = 0.90 }
        button.backgroundColorMouseOver = { r = 0.55, g = 0.23, b = 0.23, a = 0.95 }
        button.borderColor = { r = 0.75, g = 0.34, b = 0.34, a = 0.85 }
    end
end

local function positionButton(self)
    local button = self and self.partnerAutoLootButton or nil
    if not button then return end
    local width = math.floor(self.width * 0.70)
    local x = (self.width - width) / 2
    local buyY = self.buyButton and self.buyButton:getY() or (self.height - self.padding * 2)
    button:setX(x)
    button:setWidth(width)
    button:setY(buyY - button:getHeight() - 6)
end

local function onToggle(self)
    local groupId = self.item and self.item.id or nil
    if not groupId or not API.isGroupUnlocked(self.player, groupId) then return end
    if API.requestToggle(self.player, groupId) then
        -- Single-player writes immediately. Multiplayer refreshes again when
        -- the authoritative server broadcast arrives.
        refreshButton(self)
        if self.player then self.player:playSound("UIActivateButton") end
    end
end

if not Details._partnerAutoLootToggleInstalled then
    local originalCreateChildren = Details.createChildren
    Details.createChildren = function(self, ...)
        originalCreateChildren(self, ...)
        if not self.partnerAutoLootButton then
            local buttonHeight = math.max(24, math.floor(getTextManager():getFontHeight(UIFont.Small) * 1.9))
            self.partnerAutoLootButton = ISButton:new(0, 0, 100, buttonHeight,
                getLabel("UI_Shop_AutoLootOn", "자동 줍기: 켜짐"), self, onToggle)
            self.partnerAutoLootButton:initialise()
            self.partnerAutoLootButton:setFont(UIFont.Small)
            self.partnerAutoLootButton.textColor = { r = 1, g = 1, b = 1, a = 1 }
            self.partnerAutoLootButton:setVisible(false)
            self:addChild(self.partnerAutoLootButton)
        end
        positionButton(self)
        refreshButton(self)
    end

    local originalSetItem = Details.setItem
    Details.setItem = function(self, item, ...)
        local result = originalSetItem(self, item, ...)
        refreshButton(self)
        return result
    end

    local originalOnResize = Details.onResize
    Details.onResize = function(self, ...)
        local result = originalOnResize(self, ...)
        positionButton(self)
        return result
    end

    local originalPrerender = Details.prerender
    Details.prerender = function(self, ...)
        local result = originalPrerender(self, ...)
        refreshButton(self)
        return result
    end

    Details._partnerAutoLootToggleInstalled = true
end

local function onServerCommand(module, command, args)
    if module ~= API.COMMAND_MODULE or command ~= "AutoLootSettingChanged" then return end
    local player = getPlayer()
    local groupId = args and args.groupId or nil
    if player and API.isKnownGroup(groupId) then
        API.applySettingLocal(player, groupId, args.enabled == true)
        if Details._instance then refreshButton(Details._instance) end
    end
end

Events.OnServerCommand.Add(onServerCommand)
print(TAG .. " per-category shop toggles enabled")

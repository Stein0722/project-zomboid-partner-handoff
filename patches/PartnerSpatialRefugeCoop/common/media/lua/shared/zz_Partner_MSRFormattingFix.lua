-- Avoid translating a formatted message before its arguments are available.
require "MSR_PlayerMessage"

local PM = MSR and MSR.PlayerMessage

if PM and not PM._partnerFormattingFixInstalled then
    local originalGetFormattedText = PM.GetFormattedText

    PM.GetFormattedText = function(messageKey, ...)
        local args = { ... }
        -- B42's Kahlua environment does not always expose Lua's global
        -- next() function.  Calling it here used to throw after an upgrade had
        -- already been committed, which made the shop wallet refund the cost.
        if #args > 0 and type(getTextFormatted) == "function" then
            local messages = PM.GetAllMessages and PM.GetAllMessages() or nil
            local translationKey = messages and messages[messageKey] or nil
            local unpackArgs = unpack or (table and table.unpack)
            if translationKey and type(unpackArgs) == "function" then
                local ok, result = pcall(function()
                    return getTextFormatted(translationKey, unpackArgs(args))
                end)
                if ok and result then
                    return result
                end
            end
        end

        return originalGetFormattedText(messageKey, ...)
    end

    PM._partnerFormattingFixInstalled = true
    print("[PartnerSpatialRefugeCoop] formatted-message warning guard enabled")
end

-- The shop wallet wraps the whole upgrade purchase in pcall().  The refuge
-- saves the new level before it displays the completion message, so a later UI
-- or translation error can look like a failed purchase and refund the cores
-- even though the upgrade is already active.  Normalize that completed state:
-- keep the upgrade and settle any refunded wallet amount exactly once.
local UpgradeLogic = MSR and MSR.UpgradeLogic
local UpgradeData = MSR and MSR.UpgradeData
local ShopData = MSR and MSR.ShopData

if UpgradeLogic and UpgradeData and ShopData
        and type(UpgradeLogic.purchaseUpgrade) == "function"
        and type(UpgradeData.getNextLevelRequirements) == "function"
        and type(UpgradeData.getPlayerUpgradeLevel) == "function"
        and type(ShopData.getCoreBalance) == "function"
        and type(ShopData.trySpendCores) == "function"
        and not UpgradeLogic._partnerCommittedUpgradeWalletGuardInstalled then
    local originalPurchaseUpgrade = UpgradeLogic.purchaseUpgrade
    local coreItem = (MSR.Config and MSR.Config.CORE_ITEM) or "Base.MagicalCore"

    local function hasWalletAuthority()
        return not isClient() or isServer()
    end

    local function getCoreCost(player, upgradeId)
        local total = 0
        local requirements = UpgradeData.getNextLevelRequirements(player, upgradeId) or {}
        for _, requirement in ipairs(requirements) do
            if requirement and requirement.type == coreItem then
                total = total + math.max(0, math.floor(tonumber(requirement.count) or 0))
            end
        end
        return total
    end

    UpgradeLogic.purchaseUpgrade = function(player, upgradeId, targetLevel)
        local authoritative = hasWalletAuthority()
        local expectedCost = authoritative and getCoreCost(player, upgradeId) or 0
        local balanceBefore = authoritative and ShopData.getCoreBalance(player) or 0
        local levelBefore = tonumber(UpgradeData.getPlayerUpgradeLevel(player, upgradeId)) or 0

        local callOk, success, errorMessage = pcall(
            originalPurchaseUpgrade,
            player,
            upgradeId,
            targetLevel
        )
        if not callOk then
            errorMessage = success
            success = false
        end

        if not success and authoritative then
            local savedLevel = tonumber(UpgradeData.getPlayerUpgradeLevel(player, upgradeId)) or 0
            local requestedLevel = tonumber(targetLevel) or 0
            if levelBefore < requestedLevel and savedLevel >= requestedLevel then
                local balanceAfter = ShopData.getCoreBalance(player)
                local expectedBalance = math.max(0, balanceBefore - expectedCost)
                local missingCharge = math.max(0, balanceAfter - expectedBalance)

                if missingCharge > 0 and not ShopData.trySpendCores(player, missingCharge) then
                    print("[PartnerSpatialRefugeCoop] ERROR: committed upgrade wallet settlement failed " ..
                        tostring(upgradeId) .. " level=" .. tostring(targetLevel) ..
                        " missing=" .. tostring(missingCharge))
                    return false, errorMessage
                end

                print("[PartnerSpatialRefugeCoop] recovered committed upgrade after post-save error " ..
                    tostring(upgradeId) .. " level=" .. tostring(targetLevel) ..
                    " walletCost=" .. tostring(expectedCost))
                return true, nil
            end
        end

        if not callOk then
            return false, tostring(errorMessage)
        end
        return success, errorMessage
    end

    UpgradeLogic._partnerCommittedUpgradeWalletGuardInstalled = true
    print("[PartnerSpatialRefugeCoop] committed-upgrade wallet refund guard enabled")
end

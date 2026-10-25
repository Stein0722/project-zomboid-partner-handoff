-- Partner Legend v0.4.7 title-size slider: client-only, no per-frame polling.
-- Separate ModOptions page to avoid clobbering unrelated Partner options.
require "PartnerLegend/Aura"
local ok=pcall(require,"PZAPI/ModOptions")
if not ok or not PZAPI or not PZAPI.ModOptions then
    print("[PartnerLegend] PZAPI ModOptions unavailable; using default 65% title size")
    return
end
local renderer=PartnerLegend and PartnerLegend.AuraRenderer
if not renderer or type(renderer.SetTitleSizePercent)~="function" then
    print("[PartnerLegend] title renderer unavailable; title size options disabled")
    return
end
local options=PZAPI.ModOptions:create("PartnerLegendTitleDisplay", "\237\140\140\237\138\184\235\132\136 \235\160\136\236\160\132\235\147\156 - \236\185\173\237\152\184 \237\145\156\236\139\156")
options:addTitle("\235\176\156\235\176\145 \236\185\173\237\152\184 \237\129\172\234\184\176")
local titleSize=options:addSlider(
    "TitleSizePercent",
    "\236\185\173\237\152\184 \237\129\172\234\184\176 (%)",
    25, 200, 5, 65,
    "\236\164\140 \235\176\176\236\156\168\234\179\188 \235\172\180\234\180\128\237\149\156 \237\153\148\235\169\180 \237\145\156\236\139\156 \237\129\172\234\184\176\236\158\133\235\139\136\235\139\164. \234\184\176\235\179\184\234\176\146 65%. \236\160\129\236\154\169 \237\155\132 \236\166\137\236\139\156 \235\176\152\236\152\129\235\144\169\235\139\136\235\139\164."
)
local function syncTitleSize()
    if titleSize and titleSize.getValue then
        renderer.SetTitleSizePercent(titleSize:getValue())
    end
end
options.apply=syncTitleSize
Events.OnGameStart.Add(syncTitleSize)
print("[PartnerLegend] title-size slider installed (25%-200%, default 65%)")

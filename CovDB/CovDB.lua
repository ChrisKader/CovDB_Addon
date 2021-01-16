--[===[
CovDB by Onlíne
--]===]

local _, ns = ...
ns.REGION = GetCVar("portal"):lower()
ns.dba = {}
ns.dbh = {}
ns.playerFaction, _ = UnitFactionGroup("player")
ns.playerDb = (ns.playerFaction == "Alliance") and ns.dba or ns.dbh
ns.debug = false

ns.covenantConversion = {
    "Kyrian",
    "Venthyr",
    "Night Fae",
    "Necrolord",
    "Unknown"
}

ns.covenantIcon = {
    "Interface\\icons\\ui_sigil_kyrian.blp",
    "Interface\\icons\\ui_sigil_venthyr.blp",
    "Interface\\icons\\ui_sigil_nightfae.blp",
    "Interface\\icons\\ui_sigil_necrolord.blp",
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
}

ns.covenantConversionShort = {
    "KY",
    "VT",
    "NF",
    "NL",
    "UK"
}

ns.playerName = UnitName("player")
ns.playerRealm = GetNormalizedRealmName()

function ns:findCovenant(db, name, realm)
    if db[realm] then
        for i=1,4 do
            for _,v in pairs(db[realm][i]) do
                if v == name then
                    return i
                end
            end
        end
    end
    return 5
end

function ns:SplitName(fullName)
    local name, realm = strsplit("-", fullName, 2)
    realm = realm and realm ~= "" and realm or GetNormalizedRealmName()
    return name, realm
end

local function CovenantTooltip(tooltip, db, name, realm, faction)
    local covenantId = ns:findCovenant(db, name, realm)
    local covenantIcon = covenantId == 5 and "" or "|T".. ns.covenantIcon[covenantId] .. ":16:16|t"
    tooltip:AddLine("Covenant:" .. covenantIcon .. ns.covenantConversion[covenantId])
    tooltip:Show()
end

local function CovDB_EventListner(self, event, ...)
    if event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_PARTY_LEADER" then
        local message, sender = ...
        if message:match("!covenantlist") then

            local covenantId = ns:findCovenant(ns.playerDb, ns.playerName, ns.playerRealm)
            SendChatMessage(ns.playerName .. "-" .. ns.playerRealm .. ": " .. ns.covenantConversion[covenantId], "PARTY")
            for i=1,4 do
                if (UnitName('party'..i)) then
                    local name, realm = UnitName('party' .. i)
                    realm = realm and realm ~= "" and realm or GetNormalizedRealmName()

                    local covenantId = ns:findCovenant(ns.playerDb, name, realm)
                    SendChatMessage(name .. "-" .. realm .. ": " .. ns.covenantConversion[covenantId],"PARTY");
                end
            end
        end
    end

    if event == "UPDATE_MOUSEOVER_UNIT" then
        if UnitIsPlayer("mouseover") then
            local name, realm = ns:SplitName(UnitName("mouseover"))
            local faction = UnitFactionGroup("mouseover")
            db = (faction == "Alliance") and ns.dba or ns.dbh
            CovenantTooltip(GameTooltip, db, name, realm, faction)
        end
    end
end

local function SetLFGTooltip(tooltip, resultID, autoAcceptOption)
    local entry = C_LFGList.GetSearchResultInfo(resultID)
    
    if not entry or not entry.leaderName then
        return
    end

    local name, realm = ns:SplitName(entry.leaderName)
    CovenantTooltip(tooltip, ns.playerDb, name, realm)
end

local function UpdateApplicantMember(member, appID, memberIdx, ...)     
    
    local textName = member.Name:GetText();
    local fullName = C_LFGList.GetApplicantMemberInfo(appID, memberIdx);
    local name, realm = ns:SplitName(fullName)
    local covenantId = ns:findCovenant(ns.playerDb, name, realm);    
    local covenantIcon = covenantId == 5 and "" or "|T".. ns.covenantIcon[covenantId] .. ":10:10|t "
    if covenantId < 5 then
        if ( memberIdx > 1 ) then
            member.Name:SetText(covenantIcon .. textName);
        else
            member.Name:SetText(covenantIcon .. textName);
        end
    end
    
    local nameLength = 100;
    if ( relationship ) then
        nameLength = nameLength - 22;
    end
    
    if ( member.Name:GetWidth() > nameLength ) then
        member.Name:SetWidth(nameLength);
    end
end

local currentResult = {}

local hooked = {}
local OnEnter
local OnLeave

do
    local function HookApplicantButtons(buttons)
        for _, button in pairs(buttons) do
            if not hooked[button] then
                hooked[button] = true
                button:HookScript("OnEnter", OnEnter)
                button:HookScript("OnLeave", OnLeave)
            end
        end
    end

    function OnEnter(self)
        local entry = C_LFGList.GetActiveEntryInfo()
        if entry then
            currentResult.activityID = entry.activityID
        end
        if not currentResult.activityID then
            return
        end
        if self.applicantID and self.Members then
            HookApplicantButtons(self.Members)
        elseif self.memberIdx then

            local fullName = C_LFGList.GetApplicantMemberInfo(self:GetParent().applicantID, self.memberIdx)
            local hasData = false

            local name, realm = ns:SplitName(fullName)

            CovenantTooltip(GameTooltip, ns.playerDb, name, realm)
        end
    end

    function OnLeave(self)
        GameTooltip:Hide()
    end

    -- the player hosting a group looking at applicants
    for i = 1, 14 do
        local button = _G["LFGListApplicationViewerScrollFrameButton" .. i]
        button:HookScript("OnEnter", OnEnter)
        button:HookScript("OnLeave", OnLeave)
    end

end
hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", SetLFGTooltip)
hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", UpdateApplicantMember);
local CovDB_EventFrame = CreateFrame("Frame")
CovDB_EventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
CovDB_EventFrame:RegisterEvent("CHAT_MSG_PARTY")
CovDB_EventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
CovDB_EventFrame:SetScript("OnEvent", CovDB_EventListner)
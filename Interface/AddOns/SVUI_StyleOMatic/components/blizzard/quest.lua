--[[
##############################################################################
_____/\\\\\\\\\\\____/\\\________/\\\__/\\\________/\\\__/\\\\\\\\\\\_       #
 ___/\\\/////////\\\_\/\\\_______\/\\\_\/\\\_______\/\\\_\/////\\\///__      #
  __\//\\\______\///__\//\\\______/\\\__\/\\\_______\/\\\_____\/\\\_____     #
   ___\////\\\__________\//\\\____/\\\___\/\\\_______\/\\\_____\/\\\_____    #
    ______\////\\\________\//\\\__/\\\____\/\\\_______\/\\\_____\/\\\_____   #
     _________\////\\\______\//\\\/\\\_____\/\\\_______\/\\\_____\/\\\_____  #
      __/\\\______\//\\\______\//\\\\\______\//\\\______/\\\______\/\\\_____ #
       _\///\\\\\\\\\\\/________\//\\\________\///\\\\\\\\\/____/\\\\\\\\\\\_#
        ___\///////////___________\///___________\/////////_____\///////////_#
##############################################################################
S U P E R - V I L L A I N - U I   By: Munglunch                              #
##############################################################################
credit: Elv.                      original logic from ElvUI. Adapted to SVUI #
##############################################################################
--]]
--[[ GLOBALS ]]--
local _G = _G;
local unpack  = _G.unpack;
local select  = _G.select;
local ipairs  = _G.ipairs;
local pairs   = _G.pairs;
--[[ ADDON ]]--
local SV = _G.SVUI;
local L = SV.L;
local PLUGIN = select(2, ...);
local Schema = PLUGIN.Schema;

local MAX_NUM_ITEMS = _G.MAX_NUM_ITEMS
--[[ 
########################################################## 
HELPERS
##########################################################
]]--
local QuestFrameList = {
	"QuestLogPopupDetailFrame",
	"QuestLogPopupDetailFrameAbandonButton",
	"QuestLogPopupDetailFrameShareButton",
	"QuestLogPopupDetailFrameTrackButton",
	"QuestLogPopupDetailFrameCancelButton",
	"QuestLogPopupDetailFrameCompleteButton"
};

local function QuestScrollHelper(b, c, d, e)
	b:SetPanelTemplate("Inset")
	b.spellTex = b:CreateTexture(nil, 'ARTWORK')
	b.spellTex:SetTexture([[Interface\QuestFrame\QuestBG]])
	if e then
		 b.spellTex:SetPoint("TOPLEFT", 2, -2)
	else
		 b.spellTex:SetPoint("TOPLEFT")
	end 
	b.spellTex:Size(c or 506, d or 615)
	b.spellTex:SetTexCoord(0, 1, 0.02, 1)
end

local QuestRewardScrollFrame_OnShow = function(self)
	if(not self.Panel) then
		self:SetPanelTemplate("Default")
		QuestScrollHelper(self, 509, 630, false)
		self:Height(self:GetHeight() - 2)
	end
	if(self.spellTex) then
		self.spellTex:Height(self:GetHeight() + 217)
	end
end

local function StyleReward(item)
	if(item and (not item.Panel)) then
		item:RemoveTextures()
		item:SetSlotTemplate(true, 2, 0, 0, 0.5)

		local name = item:GetName()
		if(name) then
			local tex = _G[name.."IconTexture"]
			local icon
			if(tex) then
				icon = tex:GetTexture()
			end
			if(tex and icon) then
				local size = item:GetHeight() - 4
				tex:SetTexture(icon)
				tex:SetTexCoord(0.1, 0.9, 0.1, 0.9)
				tex:ClearAllPoints()
				tex:SetPoint("TOPLEFT", item, "TOPLEFT", 2, -2)
				tex:SetSize(size, size)
			end
		end
	end
end

local function StyleDisplayReward(item)
	if(item and (not item.Panel)) then
		local oldIcon
		if(item.Icon) then
			oldIcon = item.Icon:GetTexture()
		end
		item:RemoveTextures()
		item:SetSlotTemplate(true, 2, 0, 0, 0.5)

		if(oldIcon) then
			item.Icon:SetTexture(oldIcon)
			item.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		end
	end
end

local function StyleQuestRewards()
	local rewardsFrame = QuestInfoFrame.rewardsFrame
	if(not rewardsFrame) then return end
	local parentName = rewardsFrame:GetName()
	for i = 1, 10 do
		local name = ("%s%d"):format(parentName,i)
		StyleReward(_G[name])
	end
	if(rewardsFrame:GetName() == 'MapQuestInfoRewardsFrame') then
		StyleDisplayReward(rewardsFrame.XPFrame)
		StyleDisplayReward(rewardsFrame.RewardSpell)
		StyleDisplayReward(rewardsFrame.MoneyFrame)
		StyleDisplayReward(rewardsFrame.SkillPointFrame)
		StyleDisplayReward(rewardsFrame.PlayerTitleFrame)
	end
end

local Hook_QuestInfoItem_OnClick = function(self)
	_G.QuestInfoItemHighlight:ClearAllPoints()
	_G.QuestInfoItemHighlight:SetAllPoints(self)
end

local Hook_QuestNPCModel = function(self, _, _, _, x, y)
	_G.QuestNPCModel:ClearAllPoints()
	_G.QuestNPCModel:SetPoint("TOPLEFT", self, "TOPRIGHT", x + 18, y)
end

local _hook_GreetingPanelShow = function(self)
	self:RemoveTextures()

	_G.QuestFrameGreetingGoodbyeButton:SetButtonTemplate()
	_G.QuestGreetingFrameHorizontalBreak:Die()
end

local _hook_DetailScrollShow = function(self)
	if not self.Panel then
		self:SetPanelTemplate("Default")
		QuestScrollHelper(self, 509, 630, false)
	end 
	self.spellTex:Height(self:GetHeight() + 217)
end

local _hook_QuestLogPopupDetailFrameShow = function(self)
	local QuestLogPopupDetailFrameScrollFrame = _G.QuestLogPopupDetailFrameScrollFrame;
	if not QuestLogPopupDetailFrameScrollFrame.spellTex then
		QuestLogPopupDetailFrameScrollFrame:SetFixedPanelTemplate("Default")
		QuestLogPopupDetailFrameScrollFrame.spellTex = QuestLogPopupDetailFrameScrollFrame:CreateTexture(nil, 'ARTWORK')
		QuestLogPopupDetailFrameScrollFrame.spellTex:SetTexture([[Interface\QuestFrame\QuestBookBG]])
		QuestLogPopupDetailFrameScrollFrame.spellTex:SetPoint("TOPLEFT", 2, -2)
		QuestLogPopupDetailFrameScrollFrame.spellTex:Size(514, 616)
		QuestLogPopupDetailFrameScrollFrame.spellTex:SetTexCoord(0, 1, 0.02, 1)
		QuestLogPopupDetailFrameScrollFrame.spellTex2 = QuestLogPopupDetailFrameScrollFrame:CreateTexture(nil, 'BORDER')
		QuestLogPopupDetailFrameScrollFrame.spellTex2:SetTexture([[Interface\FrameGeneral\UI-Background-Rock]])
		QuestLogPopupDetailFrameScrollFrame.spellTex2:FillInner()
	end
end
--[[ 
########################################################## 
QUEST PLUGINRS
##########################################################
]]--
local function QuestGreetingStyle()
	if PLUGIN.db.blizzard.enable ~= true or PLUGIN.db.blizzard.greeting ~= true then
		return 
	end
	_G.QuestFrameGreetingPanel:HookScript("OnShow", _hook_GreetingPanelShow)
end 

local function QuestFrameStyle()
	if PLUGIN.db.blizzard.enable ~= true or PLUGIN.db.blizzard.quest ~= true then return end

	PLUGIN:ApplyWindowStyle(QuestLogPopupDetailFrame, true, true)
	PLUGIN:ApplyWindowStyle(QuestFrame, true, true)

	QuestLogPopupDetailFrameScrollFrame:RemoveTextures()
	QuestProgressScrollFrame:RemoveTextures()
	
	local width = QuestLogPopupDetailFrameScrollFrame:GetWidth()
	QuestLogPopupDetailFrame.ShowMapButton:SetWidth(width)
	QuestLogPopupDetailFrame.ShowMapButton:SetButtonTemplate()

	PLUGIN:ApplyWindowStyle(QuestLogPopupDetailFrame)

	QuestLogPopupDetailFrameInset:Die()

	for _,i in pairs(QuestFrameList)do
		if(_G[i]) then
			_G[i]:SetButtonTemplate()
			_G[i]:SetFrameLevel(_G[i]:GetFrameLevel() + 2)
		end
	end
	QuestLogPopupDetailFrameScrollFrame:HookScript('OnShow', _hook_DetailScrollShow)
	QuestLogPopupDetailFrame:HookScript("OnShow", _hook_QuestLogPopupDetailFrameShow)

	PLUGIN:ApplyCloseButtonStyle(QuestLogPopupDetailFrameCloseButton)
	PLUGIN:ApplyScrollFrameStyle(QuestLogPopupDetailFrameScrollFrameScrollBar, 5)
	PLUGIN:ApplyScrollFrameStyle(QuestRewardScrollFrameScrollBar)

	QuestGreetingScrollFrame:RemoveTextures()
	PLUGIN:ApplyScrollFrameStyle(QuestGreetingScrollFrameScrollBar)

	for i = 1, 10 do
		local name = ("QuestInfoRewardsFrameQuestInfoItem%d"):format(i)
		StyleReward(_G[name])
	end

	for i = 1, 10 do
		local name = ("MapQuestInfoRewardsFrameQuestInfoItem%d"):format(i)
		StyleReward(_G[name])
	end

	QuestInfoSkillPointFrame:RemoveTextures()
	QuestInfoSkillPointFrame:Width(QuestInfoSkillPointFrame:GetWidth() - 4)

	local curLvl = QuestInfoSkillPointFrame:GetFrameLevel() + 1
	QuestInfoSkillPointFrame:SetFrameLevel(curLvl)
	QuestInfoSkillPointFrame:SetFixedPanelTemplate("Slot")
	QuestInfoSkillPointFrame:SetBackdropColor(1, 1, 0, 0.5)
	QuestInfoSkillPointFrameIconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	QuestInfoSkillPointFrameIconTexture:SetDrawLayer("OVERLAY")
	QuestInfoSkillPointFrameIconTexture:SetPoint("TOPLEFT", 2, -2)
	QuestInfoSkillPointFrameIconTexture:Size(QuestInfoSkillPointFrameIconTexture:GetWidth()-2, QuestInfoSkillPointFrameIconTexture:GetHeight()-2)
	QuestInfoSkillPointFrameCount:SetDrawLayer("OVERLAY")
	QuestInfoItemHighlight:RemoveTextures()
	QuestInfoItemHighlight:SetFixedPanelTemplate("Slot")
	QuestInfoItemHighlight:SetBackdropBorderColor(1, 1, 0)
	QuestInfoItemHighlight:SetBackdropColor(0, 0, 0, 0)
	QuestInfoItemHighlight:Size(142, 40)

	hooksecurefunc("QuestInfoItem_OnClick", Hook_QuestInfoItem_OnClick)
	hooksecurefunc("QuestInfo_Display", StyleQuestRewards)

	QuestRewardScrollFrame:HookScript("OnShow", QuestRewardScrollFrame_OnShow)

	QuestFrameInset:Die()
	QuestFrameDetailPanel:RemoveTextures(true)
	QuestDetailScrollFrame:RemoveTextures(true)
	QuestScrollHelper(QuestDetailScrollFrame, 506, 615, true)
	QuestProgressScrollFrame:SetFixedPanelTemplate()
	QuestScrollHelper(QuestProgressScrollFrame, 506, 615, true)
	QuestGreetingScrollFrame:SetFixedPanelTemplate()
	QuestScrollHelper(QuestGreetingScrollFrame, 506, 615, true)
	QuestDetailScrollChildFrame:RemoveTextures(true)
	QuestRewardScrollFrame:RemoveTextures(true)
	QuestRewardScrollChildFrame:RemoveTextures(true)
	QuestFrameProgressPanel:RemoveTextures(true)
	QuestFrameRewardPanel:RemoveTextures(true)

	QuestFrameAcceptButton:SetButtonTemplate()
	QuestFrameDeclineButton:SetButtonTemplate()
	QuestFrameCompleteButton:SetButtonTemplate()
	QuestFrameGoodbyeButton:SetButtonTemplate()
	QuestFrameCompleteQuestButton:SetButtonTemplate()

	PLUGIN:ApplyCloseButtonStyle(QuestFrameCloseButton, QuestFrame.Panel)

	for j = 1, 6 do 
		local i = _G["QuestProgressItem"..j]
		local texture = _G["QuestProgressItem"..j.."IconTexture"]
		i:RemoveTextures()
		i:SetFixedPanelTemplate("Inset")
		i:Width(_G["QuestProgressItem"..j]:GetWidth() - 4)
		texture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		texture:SetDrawLayer("OVERLAY")
		texture:SetPoint("TOPLEFT", 2, -2)
		texture:Size(texture:GetWidth() - 2, texture:GetHeight() - 2)
		_G["QuestProgressItem"..j.."Count"]:SetDrawLayer("OVERLAY")
	end

	QuestNPCModel:RemoveTextures()
	QuestNPCModel:SetPanelTemplate("Comic")

	QuestNPCModelTextFrame:RemoveTextures()
	QuestNPCModelTextFrame:SetPanelTemplate("Default")
	QuestNPCModelTextFrame.Panel:SetPoint("TOPLEFT", QuestNPCModel.Panel, "BOTTOMLEFT", 0, -2)

	hooksecurefunc("QuestFrame_ShowQuestPortrait", Hook_QuestNPCModel)

end 
--[[ 
########################################################## 
PLUGIN LOADING
##########################################################
]]--
PLUGIN:SaveCustomStyle(QuestFrameStyle)
PLUGIN:SaveCustomStyle(QuestGreetingStyle)
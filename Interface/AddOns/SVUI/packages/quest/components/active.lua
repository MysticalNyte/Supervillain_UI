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
########################################################## 
LOCALIZED LUA FUNCTIONS
##########################################################
]]--
--[[ GLOBALS ]]--
local _G = _G;
local unpack    = _G.unpack;
local select    = _G.select;
local pairs     = _G.pairs;
local ipairs    = _G.ipairs;
local type      = _G.type;
local error     = _G.error;
local pcall     = _G.pcall;
local tostring  = _G.tostring;
local tonumber  = _G.tonumber;
local tinsert 	= _G.tinsert;
local string 	= _G.string;
local math 		= _G.math;
local table 	= _G.table;
--[[ STRING METHODS ]]--
local format = string.format;
--[[ MATH METHODS ]]--
local abs, ceil, floor, round = math.abs, math.ceil, math.floor, math.round;
--[[ TABLE METHODS ]]--
local tremove, twipe = table.remove, table.wipe;
--[[ 
########################################################## 
GET ADDON DATA
##########################################################
]]--
local SV = select(2, ...)
local L = SV.L
local LSM = LibStub("LibSharedMedia-3.0")
local MOD = SV.SVQuest;
--[[ 
########################################################## 
LOCALS
##########################################################
]]--
local ROW_WIDTH = 300;
local ROW_HEIGHT = 24;
local INNER_HEIGHT = ROW_HEIGHT - 4;
local LARGE_ROW_HEIGHT = ROW_HEIGHT * 2;
local LARGE_INNER_HEIGHT = LARGE_ROW_HEIGHT - 4;

local OBJ_ICON_ACTIVE = [[Interface\COMMON\Indicator-Yellow]];
local OBJ_ICON_COMPLETE = [[Interface\COMMON\Indicator-Green]];
local OBJ_ICON_INCOMPLETE = [[Interface\COMMON\Indicator-Gray]];

local QUEST_ICON = [[Interface\AddOns\SVUI\assets\artwork\Quest\QUEST-INCOMPLETE-ICON]];
local QUEST_ICON_COMPLETE = [[Interface\AddOns\SVUI\assets\artwork\Quest\QUEST-COMPLETE-ICON]];

local DEFAULT_COLOR = {r = 1, g = 0.68, b = 0.1}
--[[ 
########################################################## 
SCRIPT HANDLERS
##########################################################
]]--
local ObjectiveTimer_OnUpdate = function(self, elapsed)
	local statusbar = self.Timer.Bar
	local timeNow = GetTime();
	local timeRemaining = statusbar.duration - (timeNow - statusbar.startTime);
	statusbar:SetValue(timeRemaining);
	if(timeRemaining < 0) then
		-- hold at 0 for a moment
		if(timeRemaining > -1) then
			timeRemaining = 0;
		else
			self:StopTimer();
		end
	end
	local r,g,b = MOD:GetTimerTextColor(statusbar.duration, statusbar.duration - timeRemaining)
	statusbar.Label:SetText(GetTimeStringFromSeconds(timeRemaining, nil, true));
	statusbar.Label:SetTextColor(r,g,b);
end

local ObjectiveProgressBar_OnEvent = function(self, event, ...)
	local statusbar = self.Progress.Bar;
	local percent = 100;
	if(not statusbar.finished) then
		percent = GetQuestProgressBarPercent(statusbar.questID);
	end
	statusbar:SetValue(percent);
	statusbar.Label:SetFormattedText(PERCENTAGE_STRING, percent);
end

local ActiveButton_OnClick = function(self, button)
	MOD.Headers["Active"]:Unset();
end

local ViewButton_OnClick = function(self, button)
	local questIndex = self:GetID();
	if(questIndex and (questIndex ~= 0)) then
		local questID = select(8, GetQuestLogTitle(questIndex));
		if(IsModifiedClick("CHATLINK") and ChatEdit_GetActiveWindow()) then
			local questLink = GetQuestLink(questIndex);
			if(questLink) then
				ChatEdit_InsertLink(questLink);
			end
		elseif(button ~= "RightButton") then
			CloseDropDownMenus();
			if(IsModifiedClick("QUESTWATCHTOGGLE")) then
				local superTrackedQuestID = GetSuperTrackedQuestID();
				RemoveQuestWatch(questIndex);
				if(questID == superTrackedQuestID) then
					QuestSuperTracking_OnQuestUntracked();
				end
			else
				if(IsQuestComplete(questID) and GetQuestLogIsAutoComplete(questIndex)) then
					AutoQuestPopupTracker_RemovePopUp(questID);
					ShowQuestComplete(questIndex);
				else
					QuestLogPopupDetailFrame_Show(questIndex);
				end
			end
			return;
		else
			QuestMapFrame_OpenToQuestDetails(questID);
		end
	end
end

local CloseButton_OnEnter = function(self)
    self:SetBackdropBorderColor(0.1, 0.8, 0.8)
end

local CloseButton_OnLeave = function(self)
    self:SetBackdropBorderColor(0,0,0,1)
end
--[[ 
########################################################## 
TRACKER FUNCTIONS
##########################################################
]]--
local UnsetActiveData = function(self)
	local block = self.Block;
	block:SetHeight(1);
	block.Header.Text:SetText('');
	block.Header.Level:SetText('');
	block.Badge.Icon:SetTexture(0,0,0,0);
	block.Button:SetID(0);
	MOD.CurrentQuest = 0;
	block.Objectives:Reset();
	self:SetHeight(1);
	block:SetAlpha(0);
	self:SetAlpha(0);
	if(MOD.Headers["Quests"]) then
		MOD:UpdateObjectives('FORCED_UPDATE')
	end
end

local SetActiveData = function(self, title, level, icon, questID, questLogIndex, numObjectives, duration, elapsed, bypass)
	local fill_height = 0;
	local objective_rows = 0;
	local block = self.Block;
	-- if((not bypass) and block.RowID == questID) then
	-- 	return
	-- end

	icon = icon or QUEST_ICON;
	block.RowID = questID;

	local color = DEFAULT_COLOR
	if(level and type(level) == 'number') then
		color = GetQuestDifficultyColor(level);
	end
	block.Header.Level:SetTextColor(color.r, color.g, color.b);
	block.Header.Level:SetText(level);
	block.Header.Text:SetText(title);
	block.Badge.Icon:SetTexture(icon);
	block.Button:SetID(questLogIndex);
	MOD.CurrentQuest = questLogIndex;

	local objective_block = block.Objectives;
	objective_block:Reset();
	for i = 1, numObjectives do
		local description, category, completed = GetQuestObjectiveInfo(questID, i);
		if(duration and elapsed and (elapsed < duration)) then
			objective_rows = objective_block:SetTimer(objective_rows, duration, elapsed);
			fill_height = fill_height + (INNER_HEIGHT + 2);
		elseif(description and description ~= '') then
			objective_rows = objective_block:SetInfo(objective_rows, description, completed);
			fill_height = fill_height + (INNER_HEIGHT + 2);
		end
	end

	if(objective_rows > 0) then
		objective_block:SetHeightToScale(fill_height);
		objective_block:FadeIn();
	end

	fill_height = fill_height + (LARGE_ROW_HEIGHT + 8);
	block:SetHeightToScale(fill_height);

	MOD.Docklet.ScrollFrame.ScrollBar:SetValue(0);

	-- local link, texture, _, showCompleted = GetQuestLogSpecialItemInfo(questLogIndex)
	-- if(link and (questLogIndex ~= MOD.CurrentQuest)) then
	-- 	MOD.QuestItem:SetItem(link, texture, questLogIndex)
	-- end

	self:RefreshHeight()
end

local RefreshActiveHeight = function(self)
	if(self.Block.RowID == 0) then
		self:Unset()
	else
		self:FadeIn();
		self.Block:FadeIn();
		self:SetHeight(self.Block:GetHeight())
	end
end

local RefreshActiveObjective = function(self, event, ...)
	if(event) then 
		if(event == 'ACTIVE_QUEST_LOADED') then
			self.Block.RowID = 0
			self:Set(...)
		elseif(event == 'SUPER_TRACKED_QUEST_CHANGED') then
			local questID = ...;
			local questLogIndex = GetQuestLogIndexByID(questID)
			local questWatchIndex = GetQuestWatchIndex(questLogIndex)
			local title, level, suggestedGroup = GetQuestLogTitle(questLogIndex)
			local questID, _, questLogIndex, numObjectives, requiredMoney, completed, startEvent, isAutoComplete, duration, elapsed, questType, isTask, isStory, isOnMap, hasLocalPOI = GetQuestWatchInfo(questWatchIndex);
			self:Set(title, level, nil, questID, questLogIndex, numObjectives, duration, elapsed)
		end
	end
end
--[[ 
########################################################## 
CORE FUNCTIONS
##########################################################
]]--
function MOD:CheckActiveQuest(questID, ...)
	local currentQuestIndex = self.CurrentQuest;
	if(currentQuestIndex and (currentQuestIndex ~= 0)) then
		if(questID) then
			if(select(8, GetQuestLogTitle(currentQuestIndex)) == questID) then
				self.Headers["Active"]:Unset();
			end
		else
			local questLogIndex = select(5, ...);
			if(questLogIndex and (questLogIndex == currentQuestIndex)) then
				self.Headers["Active"]:Set(..., true);
				return true;
			end
		end
	end
	return false;
end

function MOD:UpdateActiveObjective(event, ...)
	self.Headers["Active"]:Refresh(event, ...)
	self:UpdateDimensions();
end

local function UpdateActiveLocals(...)
	ROW_WIDTH, ROW_HEIGHT, INNER_HEIGHT, LARGE_ROW_HEIGHT, LARGE_INNER_HEIGHT = ...;
end

SV.Events:On("QUEST_UPVALUES_UPDATED", "UpdateActiveLocals", UpdateActiveLocals);

function MOD:InitializeActive()
	local scrollChild = self.Docklet.ScrollFrame.ScrollChild;

	local active = CreateFrame("Frame", nil, scrollChild)
    active:SetWidth(ROW_WIDTH);
	active:SetHeight(1);
	active:SetPoint("TOPLEFT", self.Headers["Popups"], "BOTTOMLEFT", 0, 0);

	local block = CreateFrame("Frame", nil, active)
	block:SetPointToScale("TOPLEFT", active, "TOPLEFT", 2, -4);
	block:SetPointToScale("TOPRIGHT", active, "TOPRIGHT", -2, -4);
	block:SetHeightToScale(LARGE_ROW_HEIGHT);

	block.Button = CreateFrame("Button", nil, block)
	block.Button:SetPointToScale("TOPLEFT", block, "TOPLEFT", 0, 0);
	block.Button:SetPointToScale("BOTTOMRIGHT", block, "BOTTOMRIGHT", 0, 8);
	block.Button:SetStylePanel("Framed", "Headline")
	block.Button:SetPanelColor("gold")
	block.Button:SetID(0)
	block.Button.Parent = active;
	block.Button:SetScript("OnClick", ViewButton_OnClick)

	block.Badge = CreateFrame("Frame", nil, block.Button)
	block.Badge:SetPointToScale("TOPLEFT", block.Button, "TOPLEFT", 4, -4);
	block.Badge:SetSizeToScale((LARGE_INNER_HEIGHT - 4), (LARGE_INNER_HEIGHT - 4));
	block.Badge:SetStylePanel("Fixed", "Inset")

	block.Badge.Icon = block.Badge:CreateTexture(nil,"OVERLAY")
	block.Badge.Icon:SetAllPointsIn(block.Badge);
	block.Badge.Icon:SetTexture(QUEST_ICON)
	block.Badge.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	block.Header = CreateFrame("Frame", nil, block.Button)
	block.Header:SetPointToScale("TOPLEFT", block.Badge, "TOPRIGHT", 4, -1);
	block.Header:SetPointToScale("TOPRIGHT", block.Button, "TOPRIGHT", -(ROW_HEIGHT + 4), 0);
	block.Header:SetHeightToScale(INNER_HEIGHT);
	block.Header:SetStylePanel("Default", "Headline")

	block.Header.Level = block.Header:CreateFontString(nil,"OVERLAY")
	block.Header.Level:SetFont(SV.Media.font.roboto, 10, "NONE")
	block.Header.Level:SetShadowOffset(-1,-1)
	block.Header.Level:SetShadowColor(0,0,0,0.5)
	block.Header.Level:SetJustifyH('LEFT')
	block.Header.Level:SetJustifyV('MIDDLE')
	block.Header.Level:SetText('')
	block.Header.Level:SetPointToScale("TOPLEFT", block.Header, "TOPLEFT", 4, 0);
	block.Header.Level:SetPointToScale("BOTTOMLEFT", block.Header, "BOTTOMLEFT", 4, 0);

	block.Header.Text = block.Header:CreateFontString(nil,"OVERLAY")
	block.Header.Text:SetFont(SV.Media.font.roboto, 13, "NONE")
	block.Header.Text:SetTextColor(1,1,0)
	block.Header.Text:SetShadowOffset(-1,-1)
	block.Header.Text:SetShadowColor(0,0,0,0.5)
	block.Header.Text:SetJustifyH('LEFT')
	block.Header.Text:SetJustifyV('MIDDLE')
	block.Header.Text:SetText('')
	block.Header.Text:SetPointToScale("TOPLEFT", block.Header.Level, "TOPRIGHT", 4, 0);
	block.Header.Text:SetPointToScale("BOTTOMRIGHT", block.Header, "BOTTOMRIGHT", 0, 0);

	block.CloseButton = CreateFrame("Button", nil, block.Header, "UIPanelCloseButton")
	block.CloseButton:RemoveTextures()
	block.CloseButton:SetStylePanel("Button", nil, 1, -7, -7, nil, "red")
	block.CloseButton:SetFrameLevel(block.CloseButton:GetFrameLevel() + 4)
	block.CloseButton:SetNormalTexture([[Interface\AddOns\SVUI\assets\artwork\Icons\CLOSE-BUTTON]])
    block.CloseButton:HookScript("OnEnter", CloseButton_OnEnter)
    block.CloseButton:HookScript("OnLeave", CloseButton_OnLeave)
	block.CloseButton:SetPointToScale("RIGHT", block.Header, "RIGHT", (ROW_HEIGHT + 8), 0);
	block.CloseButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	block.CloseButton.Parent = active;
	block.CloseButton:SetScript("OnClick", ActiveButton_OnClick)

	block.Objectives = MOD:NewObjectiveHeader(block);
	block.Objectives:SetPointToScale("TOPLEFT", block.Header, "BOTTOMLEFT", 0, -2);
	block.Objectives:SetPointToScale("TOPRIGHT", block.Header, "BOTTOMRIGHT", 0, -2);
	block.Objectives:SetHeightToScale(1);

	block.RowID = 0;

	active.Block = block;

	active.Set = SetActiveData;
	active.Unset = UnsetActiveData;
	active.Refresh = RefreshActiveObjective;
	active.RefreshHeight = RefreshActiveHeight;

	self.Headers["Active"] = active;

	self.Headers["Active"]:RefreshHeight()

	self:RegisterEvent("SUPER_TRACKED_QUEST_CHANGED", self.UpdateActiveObjective);
end
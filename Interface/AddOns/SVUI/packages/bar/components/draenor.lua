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
local unpack 	= _G.unpack;
local select 	= _G.select;
local pairs 	= _G.pairs;
local string 	= _G.string;
local math 		= _G.math;
--[[ STRING METHODS ]]--
local find, format, split = string.find, string.format, string.split;
local gsub = string.gsub;
--[[ MATH METHODS ]]--
local ceil = math.ceil;
--[[ 
########################################################## 
GET ADDON DATA
##########################################################
]]--
local SV = select(2, ...)
local L = SV.L;
local MOD = SV.SVBar;
--[[ 
########################################################## 
DRAENOR ZONE BUTTON INTERNALS
##########################################################
]]--
local function UpdateSpellCooldown(self)
	if(self:IsShown() and self.spellName) then
		local start, duration, enable = GetSpellCooldown(self.spellName)
		if(duration > 0) then
			self.Cooldown:SetCooldown(start, duration)
			self.Cooldown:Show()
		else
			self.Cooldown:Hide()
		end
	end
end

local DraenorButton_OnDrag = function(self)
	if(self.spellID) then
		PickupSpell(DraenorZoneAbilitySpellID);
	end
end

local DraenorButton_OnEvent = function(self, event)
	if(event == "SPELLS_CHANGED") then
		if(not self.baseName) then
			self.baseName = GetSpellInfo(DraenorZoneAbilitySpellID);
		end
		UpdateSpellCooldown(self)
	elseif(event == 'PLAYER_REGEN_ENABLED') then
		self:SetAttribute('spell', self.attribute)
		self:UnregisterEvent(event)
		UpdateSpellCooldown(self)
	elseif(event == 'UPDATE_BINDINGS') then
		if(self:IsShown()) then
			self:SetAbility()
			self:SetAttribute('binding', GetTime())
		end
	else
		self:Update()
	end

	if(not self.baseName) then
		return;
	end

	local lastState = self.BuffSeen;
	self.BuffSeen = HasDraenorZoneAbility();
	local spellName, _, texture, _, _, _, spellID = GetSpellInfo(self.baseName);

	if(self.BuffSeen) then
		if(not HasDraenorZoneSpellOnBar(self)) then
			self:SetAbility(spellID, spellName, texture);
		else
			self:RemoveAbility();
		end
	else
		DraenorZoneAbilityFrame.CurrentTexture = texture;
	end

	-- if(lastState ~= self.BuffSeen) then
	-- 	UIParent_ManageFramePositions();
	-- 	ActionBarController_UpdateAll(true);
	-- end
end

local DraenorButtonUpdate = function(self)
	if (not self.baseName) then
		return;
	end
	local name, _, tex, _, _, _, spellID = GetSpellInfo(self.baseName);

	DraenorZoneAbilityFrame.CurrentTexture = tex;
	DraenorZoneAbilityFrame.CurrentSpell = name;

	self.Icon:SetTexture(tex);

	local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellID);
	local usesCharges = false;
	if(self.Count) then
		if(maxCharges and maxCharges > 1) then
			self.Count:SetText(charges);
			usesCharges = true;
		else
			self.Count:SetText("");
		end
	end

	local start, duration, enable = GetSpellCooldown(name);
	
	if(usesCharges and charges < maxCharges) then
		CooldownFrame_SetTimer(self.Cooldown, chargeStart, chargeDuration, enable, charges, maxCharges);
	elseif(start) then
		CooldownFrame_SetTimer(self.Cooldown, start, duration, enable);
	end

	self.spellName = name;
	self.spellID = spellID;
end
--[[ 
########################################################## 
PACKAGE CALL
##########################################################
]]--
function MOD:InitializeDraenorBar()
	local draenor = SV.SuperButton:AddSpell("SVUI_DraenorZoneAbility", DraenorButtonUpdate, DraenorButton_OnEvent);

	draenor:RegisterForDrag("LeftButton")
	draenor:SetScript('OnDragStart', DraenorButton_OnDrag)

	draenor:RegisterUnitEvent("UNIT_AURA", "player");
	draenor:RegisterEvent("SPELL_UPDATE_COOLDOWN");
	draenor:RegisterEvent("SPELL_UPDATE_USABLE");
	draenor:RegisterEvent("SPELL_UPDATE_CHARGES");
	draenor:RegisterEvent("SPELLS_CHANGED");
	draenor:RegisterEvent("ACTIONBAR_SLOT_CHANGED");
	DraenorZoneAbilityFrame:UnregisterAllEvents()
end
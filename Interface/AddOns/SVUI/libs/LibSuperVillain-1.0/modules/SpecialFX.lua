--[[
  /$$$$$$                                /$$           /$$ /$$$$$$$$ /$$   /$$
 /$$__  $$                              |__/          | $$| $$_____/| $$  / $$
| $$  \__/  /$$$$$$   /$$$$$$   /$$$$$$$ /$$  /$$$$$$ | $$| $$      |  $$/ $$/
|  $$$$$$  /$$__  $$ /$$__  $$ /$$_____/| $$ |____  $$| $$| $$$$$    \  $$$$/ 
 \____  $$| $$  \ $$| $$$$$$$$| $$      | $$  /$$$$$$$| $$| $$__/     >$$  $$ 
 /$$  \ $$| $$  | $$| $$_____/| $$      | $$ /$$__  $$| $$| $$       /$$/\  $$
|  $$$$$$/| $$$$$$$/|  $$$$$$$|  $$$$$$$| $$|  $$$$$$$| $$| $$      | $$  \ $$
 \______/ | $$____/  \_______/ \_______/|__/ \_______/|__/|__/      |__/  |__/
          | $$                                                                
          | $$                                                                
          |__/                                                                
--]]

--[[ LOCALIZED GLOBALS ]]--
--GLOBAL NAMESPACE
local _G = getfenv(0);
--LUA
local unpack        = _G.unpack;
local select        = _G.select;
local assert        = _G.assert;
local type          = _G.type;
local error         = _G.error;
local pcall         = _G.pcall;
local print         = _G.print;
local ipairs        = _G.ipairs;
local pairs         = _G.pairs;
local next          = _G.next;
local rawset        = _G.rawset;
local rawget        = _G.rawget;
local tostring      = _G.tostring;
local tonumber      = _G.tonumber;
local getmetatable  = _G.getmetatable;
local setmetatable  = _G.setmetatable;
--STRING
local string        = _G.string;
local upper         = string.upper;
local format        = string.format;
local find          = string.find;
local match         = string.match;
local gsub          = string.gsub;
--MATH
local math          = _G.math;
local random        = math.random;
local floor         = math.floor
--TABLE
local table         = _G.table;
local tsort         = table.sort;
local tconcat       = table.concat;
local tinsert       = _G.tinsert;
local tremove       = _G.tremove;
local twipe         = _G.wipe;

--[[ LIB LOCALS ]]--

local DEFAULT_EFFECT = [[Spells\Missile_bomb.m2]];

--[[ LIB CONSTRUCT ]]--

local lib = LibSuperVillain:NewLibrary("SpecialFX")

if not lib then return end

--[[ LIB EFFECT TABLES ]]--

local EFFECTS_LIST = {
    ["holy"]        = {[[Spells\Solar_precast_hand.m2]], -12, 12, 12, -12, 0.23, 0, 0},
    ["shadow"]      = {[[Spells\Shadow_precast_uber_hand.m2]], -12, 12, 12, -12, 0.23, -0.1, 0.1},
    ["arcane"]      = {[[Spells\Cast_arcane_01.m2]], -12, 12, 12, -12, 0.25, 0, 0},
    ["fire"]        = {[[Spells\Bloodlust_state_hand.m2]], -8, 4, 24, -24, 0.23, 0.08, 0},
    ["frost"]       = {[[Spells\Ice_cast_low_hand.m2]], -12, 12, 12, -12, 0.23, -0.1, 0.1},
    ["chi"]         = {[[Spells\Fel_fire_precast_high_hand.m2]], -12, 12, 12, -12, 0.3, 0, 0},
    ["lightning"]   = {[[Spells\Fill_lightning_cast_01.m2]], -12, 12, 12, -12, 1.25, 0, 0},
    ["water"]       = {[[Spells\Monk_drunkenhaze_impact.m2]], -12, 12, 12, -12, 0.9, 0, 0},
    ["earth"]       = {[[Spells\Sand_precast_hand.m2]], -12, 12, 12, -12, 0.23, 0, 0},
};

--[[ EFFECT FRAME METHODS ]]--

local EffectModel_SetAnchorParent = function(self, frame)
    self.___anchorParent = frame;
end

local EffectModel_OnShow = function(self)
    self.FX:UpdateEffect();
end

local EffectModel_UpdateEffect = function(self)
    local effectFile = self.modelFile;
    self:ClearModel();
    self:SetModel(effectFile);
end

local EffectModel_SetEffect = function(self, effectName)
    local effectTable = self.___fx[effectName];
    local parent = self.___anchorParent;

    self:ClearAllPoints();
    self:SetPoint("TOPLEFT", parent, "TOPLEFT", effectTable[2], effectTable[3]);
    self:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", effectTable[4], effectTable[5]);
    
    self:ClearModel();
    self:SetModel(effectTable[1]);
    self:SetCamDistanceScale(effectTable[6]);
    self:SetPosition(0, effectTable[7], effectTable[8]);
    self:SetPortraitZoom(0);

    self.modelFile = effectTable[1];
end 

--[[ LIB METHODS ]]--
function lib:Register(effectName, modelFile, leftX, leftY, rightX, rightY, zoom, posX, posY)
    effectName = effectName:lower();
    if(not EFFECTS_LIST[effectName]) then EFFECTS_LIST[effectName] = {} end;
    EFFECTS_LIST[effectName][1] = modelFile or DEFAULT_EFFECT;
    EFFECTS_LIST[effectName][2] = leftX or 0;
    EFFECTS_LIST[effectName][3] = leftY or 0;
    EFFECTS_LIST[effectName][4] = rightX or 0;
    EFFECTS_LIST[effectName][5] = rightY or 0;
    EFFECTS_LIST[effectName][6] = zoom or 1;
    EFFECTS_LIST[effectName][7] = posX or 0;
    EFFECTS_LIST[effectName][8] = posY or 0;
end;

function lib:SetFXFrame(parent, defaultEffect, noScript, anchorParent)
    local model = CreateFrame("PlayerModel", nil, parent);
    model.___fx = {};
    setmetatable(model.___fx, { __index = EFFECTS_LIST; });
    model.___anchorParent = anchorParent or parent;
    model.SetEffect = EffectModel_SetEffect;
    model.SetAnchorParent = EffectModel_SetAnchorParent;
    model.UpdateEffect = EffectModel_UpdateEffect;

    parent.FX = model;

    if(defaultEffect) then
        model:SetEffect(defaultEffect)
    else
        model:SetCamDistanceScale(1);
        model:SetPosition(0, 0, 0);
        model:SetPortraitZoom(0);
        model:SetModel(DEFAULT_EFFECT);
        model.modelFile = DEFAULT_EFFECT;
    end

    if(not noScript) then
        if(parent:GetScript("OnShow")) then
            parent:HookScript("OnShow", EffectModel_OnShow)
        else
            parent:SetScript("OnShow", EffectModel_OnShow)
        end
    end
end

--[[ MODEL FILES FOUND FOR EFFECTS ]]--

-- [[Spells\Fel_fire_precast_high_hand.m2]]
-- [[Spells\Fire_precast_high_hand.m2]]
-- [[Spells\Fire_precast_low_hand.m2]]
-- [[Spells\Focused_casting_state.m2]]
-- [[Spells\Fill_holy_cast_01.m2]]
-- [[Spells\Fill_fire_cast_01.m2]]
-- [[Spells\Paladin_healinghands_state_01.m2]]
-- [[Spells\Fill_magma_cast_01.m2]]
-- [[Spells\Fill_shadow_cast_01.m2]]
-- [[Spells\Fill_arcane_precast_01.m2]]
-- [[Spells\Ice_cast_low_hand.m2]]
-- [[Spells\Immolate_state.m2]]
-- [[Spells\Immolate_state_v2_illidari.m2]]
-- [[Spells\Intervenetrail.m2]]
-- [[Spells\Invisibility_impact_base.m2]]
-- [[Spells\Fire_dot_state_chest.m2]]
-- [[Spells\Fire_dot_state_chest_jade.m2]]
-- [[Spells\Cast_arcane_01.m2]]
-- [[Spells\Spellsteal_missile.m2]]
-- [[Spells\Missile_bomb.m2]]
-- [[Spells\Shadow_frost_weapon_effect.m2]]
-- [[Spells\Shadow_precast_high_base.m2]]
-- [[Spells\Shadow_precast_high_hand.m2]]
-- [[Spells\Shadow_precast_low_hand.m2]]
-- [[Spells\Shadow_precast_med_base.m2]]
-- [[Spells\Shadow_precast_uber_hand.m2]]
-- [[Spells\Shadow_strikes_state_hand.m2]]
-- [[Spells\Shadowbolt_missile.m2]]
-- [[Spells\Shadowworddominate_chest.m2]]
-- [[Spells\Infernal_smoke_rec.m2]]
-- [[Spells\Largebluegreenradiationfog.m2]]
-- [[Spells\Leishen_lightning_fill.m2]]
-- [[Spells\Mage_arcanebarrage_missile.m2]]
-- [[Spells\Mage_firestarter.m2]]
-- [[Spells\Mage_greaterinvis_state_chest.m2]]
-- [[Spells\Magicunlock.m2]]
-- [[Spells\Chiwave_impact_hostile.m2]]
-- [[Spells\Cripple_state_base.m2]]
-- [[Spells\Monk_expelharm_missile.m2]]
-- [[Spells\Monk_forcespere_orb.m2]]
-- [[Spells\Fill_holy_cast_01.m2]]
-- [[Spells\Fill_fire_cast_01.m2]]
-- [[Spells\Fill_lightning_cast_01.m2]]
-- [[Spells\Fill_magma_cast_01.m2]]
-- [[Spells\Fill_shadow_cast_01.m2]]
-- [[Spells\Sprint_impact_chest.m2]]
-- [[Spells\Spellsteal_missile.m2]]
-- [[Spells\Warlock_destructioncharge_impact_chest.m2]]
-- [[Spells\Warlock_destructioncharge_impact_chest_fel.m2]]
-- [[Spells\Xplosion_twilight_impact_noflash.m2]]
-- [[Spells\Warlock_bodyofflames_medium_state_shoulder_right_purple.m2]]
-- [[Spells\Blink_impact_chest.m2]]
-- [[Spells\Christmassnowrain.m2]]
-- [[Spells\Detectinvis_impact_base.m2]]
-- [[Spells\Eastern_plaguelands_beam_effect.m2]]
-- [[Spells\battlemasterglow_high.m2]]
-- [[Spells\blueflame_low.m2]]
-- [[Spells\greenflame_low.m2]]
-- [[Spells\purpleglow_high.m2]]
-- [[Spells\redflame_low.m2]]
-- [[Spells\poisondrip.m2]]
-- [[Spells\savageryglow_high.m2]]
-- [[Spells\spellsurgeglow_high.m2]]
-- [[Spells\sunfireglow_high.m2]]
-- [[Spells\whiteflame_low.m2]]
-- [[Spells\yellowflame_low.m2]]
-- [[Spells\Food_healeffect_base.m2]]
-- [[Spells\Bloodlust_state_hand.m2]]
-- [[Spells\Deathwish_state_hand.m2]]
-- [[Spells\Disenchant_precast_hand.m2]]
-- [[Spells\Enchant_cast_hand.m2]]
-- [[Spells\Eviscerate_cast_hands.m2]]
-- [[Spells\Fire_blue_precast_hand.m2]]
-- [[Spells\Fire_blue_precast_high_hand.m2]]
-- [[Spells\Fire_precast_hand.m2]]
-- [[Spells\Fire_precast_hand_pink.m2]]
-- [[Spells\Fire_precast_hand_sha.m2]]
-- [[Spells\Fire_precast_high_hand.m2]]
-- [[Spells\Fire_precast_low_hand.m2]]
-- [[Spells\Ice_precast_high_hand.m2]]
-- [[Spells\Sand_precast_hand.m2]]
-- [[Spells\Solar_precast_hand.m2]]
-- [[Spells\Twilight_fire_precast_high_hand.m2]]
-- [[Spells\Vengeance_state_hand.m2]]
-- [[Spells\Fel_djinndeath_fire_02.m2]]
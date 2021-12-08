local mod	= DBM:NewMod("Kel'Thuzad", "DBM-Naxx", 5)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2574 $"):sub(12, -3))
mod:SetCreatureID(15990)
mod:SetMinCombatTime(60)
mod:SetUsedIcons(1, 2, 3, 4, 6)

mod:RegisterCombat("yell", L.Yell)

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_CAST_SUCCESS",
	"UNIT_HEALTH"
)

local warnAddsSoon			= mod:NewAnnounce("warnAddsSoon", 1)
local warnPhase2			= mod:NewPhaseAnnounce(2, 3)
local warnBlastTargets		= mod:NewTargetAnnounce(27808, 2)
local warnFissure			= mod:NewSpellAnnounce(27810, 3)
local warnMana				= mod:NewTargetAnnounce(27819, 2)
local warnChainsTargets		= mod:NewTargetAnnounce(28410, 2)
local warnMindControl		= mod:NewSoonAnnounce(28410, 1)

local specwarnP2Soon		= mod:NewSpecialWarning("specwarnP2Soon")

local blastTimer			= mod:NewBuffActiveTimer(4, 27808)
local timerPhase2			= mod:NewTimer(225, "TimerPhase2")
local timerMindControl		= mod:NewNextTimer(90, 28410)
local timerFissure			= mod:NewNextTimer(15, 27810)
local timerMana				= mod:NewNextTimer(20, 27819)
local timerFrostBlast		= mod:NewNextTimer(30, 27808)

mod:AddBoolOption("BlastAlarm", true)
mod:AddBoolOption("ShowRange", true)

mod:SetBossHealthInfo(
	15990, L.KelThuzad
)

local warnedAdds = false

function mod:OnCombatStart(delay)
	if self.Options.ShowRange then
		self:ScheduleMethod(215-delay, "RangeToggle", true)
	end
	warnedAdds = false
	specwarnP2Soon:Schedule(215-delay)
	timerPhase2:Start()
	timerMindControl:Start(317)
	warnPhase2:Schedule(225)
	self:Schedule(225, DBM.RangeCheck.Show, DBM.RangeCheck, 11)
end

function mod:OnCombatEnd()
	if self.Options.ShowRange then
		self:RangeToggle(false)
	end
end

local frostBlastTargets = {}
local chainsTargets = {}
function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(27808) then -- Frost Blast
		table.insert(frostBlastTargets, args.destName)
		self:UnscheduleMethod("AnnounceBlastTargets")
		self:ScheduleMethod(0.5, "AnnounceBlastTargets")
		if self.Options.BlastAlarm then
			PlaySoundFile("Interface\\Addons\\DBM-Core\\sounds\\alarm1.wav")
		end
		blastTimer:Start()
	elseif args:IsSpellID(27819) then -- Mana Bomb
		warnMana:Show(args.destName)
		self:SetIcon(args.destName, 6, 5.5)
		timerMana:Start()
	elseif args:IsSpellID(28410) then -- Chains of Kel'Thuzad
		table.insert(chainsTargets, args.destName)
		timerMindControl:Start()
		self:UnscheduleMethod("AnnounceChainsTargets")
		if #chainsTargets >= 3 then
			self:AnnounceChainsTargets()
		else
			self:ScheduleMethod(1.0, "AnnounceChainsTargets")
		end
	end
end

function mod:AnnounceChainsTargets()
	warnChainsTargets:Show(table.concat(chainsTargets, "< >"))
	table.wipe(chainsTargets)
end

function mod:AnnounceBlastTargets()
	warnBlastTargets:Show(table.concat(frostBlastTargets, "< >"))
	for i = #frostBlastTargets, 1, -1 do
		self:SetIcon(frostBlastTargets[i], 4 - i, 4.5) 
		frostBlastTargets[i] = nil
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(27810) then
		warnFissure:Show()
		timerFissure:Start()
	end
	if args:IsSpellID(27808) then
		timerFrostBlast:Start()
	end
end

function mod:UNIT_HEALTH(uId)
	if not warnedAdds and self:GetUnitCreatureId(uId) == 15990 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.89 then
		warnedAdds = true
		warnAddsSoon:Show()
	end
end

function mod:RangeToggle(show)
	if show then
		DBM.RangeCheck:Show(10)
	else
		DBM.RangeCheck:Hide()
	end
end

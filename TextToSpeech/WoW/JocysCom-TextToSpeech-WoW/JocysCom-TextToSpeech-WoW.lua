﻿-- Show or hide frame names: /fstack
-- Show events: /eventtrace
--#:\Program Files (x86)\World of Warcraft\WTF\Account\ACCOUNTNAME\SavedVariables.lua - Blizzard's saved variables.
--#:\Program Files (x86)\World of Warcraft\WTF\Account\ACCOUNTNAME\SavedVariables\JocysCom-TextToSpeech-WoW.lua - Per-account settings for each individual AddOn.
--#:\Program Files (x86)\World of Warcraft\WTF\Account\ACCOUNTNAME\RealmName\CharacterName\JocysCom-TextToSpeech-WoW.lua - Per-character settings for each individual AddOn.

-- Debug mode true(enabled) or false(disabled).
local DebugEnabled = false

-- Set variables.
local addonVersion = "Jocys.com Text to Speech World of Warcraft Addon 8.2.5.6 ( 2019-10-12 )"
local addonName = "JocysCom-TextToSpeech-WoW"
local addonPrefix = "JocysComTTS"
-- Message prefix for Monitor to find pixel line.
local messagePrefix =  "|cff2200000|r|cff0022000|r|cff0000220|r|cff2200000|r|cff0022000|r|cff0000220|r"
local unitName = UnitName("player") -- GetUnitName()
local customName = UnitName("player")
local unitClass = UnitClass("player")
local lastArg = nil
local dashIndex = nil
local hashIndex = nil
local messageDoNotDisturb = "Please wait... NPC dialog window is open and text-to-speech is enabled."
local messageStop = "<message command=\"stop\" />"
local macroName = "NPCSaveTTSMacro"
local macroIcon = "INV_Misc_GroupNeedMore"
local macroMessage = "/targetfriend"
local pixelX = 0
local pixelY = 0
local chatMessageLimit = 240
local messagesTable = {}
local NPCNamesTable = {}
local timerEnabled = false

local function Clear(v)
	if v == nil or v == "" then
		return ""
	else
		v = string.gsub(v, "&", " and ")
		v = string.gsub(v, "\"", "")
		return v
	end
end

-- Create attribute name="value".
local function Attribute(n, v)
	if v == nil or v == "" then
		return "", ""
	else
		return " " .. n .. "=\"" .. Clear(v) .. "\"", ""
	end
end

-- Gender()
local function Gender(v)
	if v == nil or v == "" then
		return ""
	else
		if v == 2 then return "Male"
		elseif v == 3 then return "Female"
		else return "Neutral" end
	end
end

function JocysCom_CreateOrUpdateMacro()
	-- Create macro if doesn't exist and slot is available.
	if GetMacroIndexByName(macroName) == 0 then
		local numglobal, numperchar = GetNumMacros()
		if numperchar < 17 then
			CreateMacro(macroName, macroIcon, macroMessage, 1)
			if GetMacroIndexByName(macroName) > 0 then
				print("|cffffff00" .. macroName .. "|r |cff88aaff in|r |cffffff00" .. unitName .. " Specific Macros|r |cff88aaffcreated.|r")
			end
		end
	end
	-- Update macro if exists.
	if GetMacroIndexByName(macroName) > 0 then
		-- Set macro text and icon.
		if #NPCNamesTable > 0 then
			macroIcon = "INV_Misc_GroupNeedMore"
			macroMessage = ""
			-- Add NPC names from table to macro.
			for i, n in pairs(NPCNamesTable) do
				macroMessage = macroMessage .. "/target " .. n .. "\n"
			end
			-- Add at the end of macro.
			macroMessage = macroMessage .. "/JocysComTTS Macro Reset\n"
			-- Debug print.
			if DebugEnabled then
				for i,n in ipairs(NPCNamesTable) do
					print("|cffffff55" .. i .. ". |r",n)
				end
				print("|cff40fb40------------------------------------------------------------------------------------|r")
			end
		else
			macroIcon = "INV_Misc_GroupLooking"
			macroMessage = "/targetfriend"
			-- Print NPC name list.
			if DebugEnabled then
				print("|cff40fb40------------------------------------------------------------------------------------|r")
				print("|cff40fb40NPCSaveTTSMacro (no names):")
				print("|cffffff550. |rTargetFriend")
			end
		end
		-- Edit macro.
		EditMacro(GetMacroIndexByName(macroName), macroName, macroIcon, macroMessage, 1)
	end
end

-- Add NPC name to NPCNamesTable (max 9).
function JocysCom_AddNPCNameToTable(name)
	-- Do not add NPC name if it is already in NPCNamesTable.
	if #NPCNamesTable > 0 then
		for i, n in pairs(NPCNamesTable) do
			if string.find(n, name) then
				if DebugEnabled then
					print("|cff40fb40------------------------------------------------------------------------------------|r")
					print("|cff40fb40NPCSaveTTSMacro name (name exists): |r" .. name)
				end
				return
			end
		end
	else
		-- Add NPC name to NPCNamesTable.
		table.insert(NPCNamesTable, name)
		if DebugEnabled then
			print("|cff40fb40------------------------------------------------------------------------------------|r")
			print("|cff40fb40NPCSaveTTSMacro (name added): |r" .. name)
		end
		-- Remove names exceeding max (9) number.
		if #NPCNamesTable > 9 then
			repeat table.remove(NPCNamesTable, 1)
			until (#NPCNamesTable < 10)
		end
		JocysCom_CreateOrUpdateMacro()
	end
end

-- Remove NPC names from NPCNamesTable.
function JocysCom_RemoveNPCNamesFromTable()
	NPCNamesTable = {}
	JocysCom_CreateOrUpdateMacro()
end

local function JocysCom_AddonCommands(msg, editbox)
	-- pattern matching skips leading whitespace and whitespace between cmd and args.
	-- any whitespace at end of args is retained
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
	if cmd == "Macro" and args == "Reset" then
		JocysCom_RemoveNPCNamesFromTable()
	elseif cmd == "Debug" then
		DebugEnabled = not DebugEnabled
		JocysCom_SaveTocFileSettings()
		if DebugEnabled then
			JocysCom_DebugEnabledSettings()
			print("|cffff0000JocysComTTS Debug: [Enabled]|r")
		else
			JocysCom_DebugEnabledSettings()
			print("|cff00ff00JocysComTTS Debug: [Disabled]|r")
		end
	else
		-- If cmd is nil, display help message.
		print("|cff77ccff------------------------------------------------------------------------------------|r")
		print("|cff77ccffJocys.com Text to Speech addon's slash commands|r")
		print("|cff77ccff------------------------------------------------------------------------------------|r")
		print("|cffffff55/JocysComTTS|r -- Show this help")
		print("|cffffff55/JocysComTTS Debug|r -- Debug enable / disable")
		print("|cffffff55/JocysComTTS Macro Reset|r -- Reset |cff40fb40" .. macroName .. "|r")
		print("|cff77ccff------------------------------------------------------------------------------------|r")
  end
end

SLASH_JocysComTTS1 = '/JocysComTTS'
SlashCmdList["JocysComTTS"] = JocysCom_AddonCommands

function JocysCom_DebugEnabledSettings()
	if DebugEnabled then
		JocysCom_ClipboardMessageFrame:Show()
	else
		JocysCom_ClipboardMessageFrame:Hide()
	end
end

-- Set text.
function JocysCom_AddonTXT_EN()
	-- OptionsFrame title.
	JocysCom_OptionsFrame.TitleText:SetText(addonVersion)
	-- CheckButtons (Options) text.
	JocysCom_ColorMessageCheckButton.text:SetText("|cff808080 Enable|r |cffffffffDisplay|r|cff808080 mode. In|r |cff77ccffTTS Monitor > [Options] Tab > [Monitor: Display] Tab > [Checked] Enable|r|cff808080.|r")
	JocysCom_NetworkMessageCheckButton.text:SetText("|cff808080 Enable|r |cffffffffNetwork|r|cff808080 mode. In|r |cff77ccffTTS Monitor >  [Options] Tab > [Monitor: Network] Tab > [Checked] Enable|r|cff808080.|r")
	JocysCom_ColorMessagePixelYFontString:SetText("|cff808080 [LEFT] and [TOP] position of color pixel line for|r |cff77ccffMonitor|r|cff808080. Default values [0] and [0].|r")
	JocysCom_LockCheckButton.text:SetText("|cff808080 Lock frame with |cffffffff[Options]|r |cff808080and|r |cffffffff[Stop]|r |cff808080buttons. Grab frame by clicking on dark background around buttons.|r")
	JocysCom_MenuCheckButton.text:SetText("|cff808080 [Checked] show menu on right side of |cffffffff[Options]|r |cff808080button. [Unchecked] show menu on left side.|r")
	JocysCom_SaveCheckButton.text:SetText("|cff808080 Save \"target\" and \"mouseover\" NPC's name, gender and type in|r |cffffffffMonitor|r|cff808080. Default: [Checked] |r");
	--JocysCom_FilterCheckButton.text:SetText("|cff808080 Hide detailed information about addon|r |cffffffff<messages>|r |cff808080in chat window. Default: [Unchecked]|r")
	-- Font Strings.
	JocysCom_DialogueScrollFrame_FontString:SetText("When mouse pointer is over this frame...\n\nSCROLL UP will START SPEECH\n\nSCROLL DOWN will STOP SPEECH\n\nClose \"Options\" to make it transparent")
	JocysCom_DescriptionFrameFontString:SetText("|cff808080 All text-to-speech options (voices, pitch, rate, effects, etc.) are in |cff77ccffJocys.Com Text to Speech Monitor|r.\n\nHow it works: When you open NPC dialogue window or receive chat message, |cff77ccffWoW Addon|r creates special message. If |cffffffffDisplay|r mode is selected, |cff77ccffWoW Addon|r converts message into line of coloured pixels and shows it on your display. If |cffffffffNetwork|r mode is selected, |cff77ccffWoW Addon|r sends special addon message to your character. Message can include dialogue text, character name, effect name, etc.. Then, |cff77ccffTTS Monitor|r (which must be running in background) picks-up this message from your display or network traffic and reads it with text-to-speech voice. You can use free text-to-speech voices by Microsoft or you can download and install additional and better text-to-speech voices from |cff77ccffIvona.com|r website. Good voices are English-British \"Amy\" and \"Brian\". English-American \"Salli\" and \"Joey\" are not bad too. For more help and to download or update |cff77ccffWoW Addon|r with |cff77ccffTTS Monitor|r, visit \"Software\" section of |cff77ccffJocys.com|r website.|r")
	JocysCom_ReplaceNameFontString:SetText("|cff808080 Here you can change your name for text to speech from |cff00ff00" .. unitName .. "|r to something else.|r")
	JocysCom_MessageForMonitorFrameFontString:SetText("|cff808080 Latest message for|r |cff77ccffJocys.Com Text to Speech Monitor|r |cff808080... it must be runninng in background:|r")
end

-- Unlock frames.
function JocysCom_OptionsFrame_OnShow()
	JocysCom_StopButtonFrame_Texture:SetColorTexture(0, 0, 0, 0.8)
	--JocysCom_DialogueScrollFrame:EnableMouse(true)
	JocysCom_DialogueScrollFrame_Texture:SetColorTexture(0, 0, 0, 0.8)
	JocysCom_DialogueScrollFrame_FontString:Show()
	--JocysCom_DialogueScrollFrameResizeButton:Show()
end

-- Lock frames.
function JocysCom_OptionsFrame_OnHide()
	if string.len(JocysCom_ReplaceNameEditBox:GetText()) < 2 then
		JocysCom_ReplaceNameEditBox:SetText(unitName)
	end
	JocysCom_StopButtonFrame_Texture:SetColorTexture(0, 0, 0, 0)
	JocysCom_DialogueScrollFrame:EnableMouse(false)
	JocysCom_DialogueScrollFrame_Texture:SetColorTexture(0, 0, 0, 0)
	JocysCom_DialogueScrollFrame_FontString:Hide()
	JocysCom_DialogueScrollFrameResizeButton:Hide()
	JocysCom_ClipboardMessageEditBoxSetFocus()
end

-- MessageStop function.
function JocysCom_SendChatMessageStop(group) -- button = button (mouse wheel down) or check-box.
	-- Disable DND <Busy>.
	if JocysCom_DndCheckButton:GetChecked() then JocysCom_DND(false) end
	-- Add group attribute if goup exists.
	local messageStop = "<message command=\"stop\"" .. Attribute("group", group) .. " />"
	JocysCom_SendMessage(messageStop, true)
	if DebugEnabled and JocysCom_NetworkMessageCheckButton:GetChecked() then print(JocysCom_MessageAddColors(messageStop)) end
end

-- Send sound intro function.
function JocysCom_SendSoundIntro(group)
	messageGroup = "<message command=\"sound\"" .. Attribute("group", group) .. " />"
	-- Send message and do not fill EditBox in Options window.
	JocysCom_SendMessage(messageGroup, false)
	if JocysCom_NetworkMessageCheckButton:GetChecked() and DebugEnabled then print(JocysCom_MessageAddColors(messageGroup)) end

end

-- Register or unregister events.
function JocysCom_SetEvent(checked, ...)
if not JocysCom_NetworkMessageCheckButton:GetChecked() and not JocysCom_ColorMessageCheckButton:GetChecked() then
	checked = false
end
	if checked then
  		for i,v in pairs({...}) do
			JocysCom_OptionsFrame:RegisterEvent(v)
			if DebugEnabled then print("|cffffff55Registered: " .. v .. "|r") end
		end
	else
  		for i,v in pairs({...}) do
			JocysCom_OptionsFrame:UnregisterEvent(v)
			if DebugEnabled then print("|cff558a84Unregistered: " .. v .. "|r") end
		end
	end
end

-- Check and set text.
local function nilCheck(v, d)
	if v == nil then return ""
	elseif d ~= nil then return v .. d
	else return v end
end

-- Load saved event settings.
function JocysCom_LoadEventSettings()
	-- QUESTS and MAIL. GOSSIP_* (open or close frame), QUEST_* (quest), ITEM_* (books, scrolls, plaques, gravestones, mail).
	JocysCom_SetEvent(JocysCom_QuestCB, "GOSSIP_SHOW", "QUEST_GREETING", "QUEST_DETAIL", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_LOG_UPDATE", "ITEM_TEXT_READY", "GOSSIP_CLOSED","MAIL_SHOW", "MAIL_CLOSED")
	-- MONSTER.
	JocysCom_SetEvent(JocysCom_MonsterCB, "CHAT_MSG_MONSTER_EMOTE", "CHAT_MSG_MONSTER_PARTY", "CHAT_MSG_MONSTER_SAY", "CHAT_MSG_MONSTER_WHISPER", "CHAT_MSG_MONSTER_YELL")
	-- EMOTE.
	JocysCom_SetEvent(JocysCom_EmoteCB, "CHAT_MSG_EMOTE", "CHAT_MSG_TEXT_EMOTE")
	-- WHISPER.
	JocysCom_SetEvent(JocysCom_WhisperCB, "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM")
	-- SAY.
	JocysCom_SetEvent(JocysCom_SayCB, "CHAT_MSG_SAY")
	-- YELL.
	JocysCom_SetEvent(JocysCom_YellCB, "CHAT_MSG_YELL")
	-- PARTY.
	JocysCom_SetEvent(JocysCom_PartyLCB, "CHAT_MSG_PARTY_LEADER")
	JocysCom_SetEvent(JocysCom_PartyCB, "CHAT_MSG_PARTY")
	-- GUILD
	JocysCom_SetEvent(JocysCom_OfficerCB, "CHAT_MSG_OFFICER")
	JocysCom_SetEvent(JocysCom_GuildCB, "CHAT_MSG_GUILD", "CHAT_MSG_GUILD_ACHIEVEMENT")
	-- RAID
	JocysCom_SetEvent(JocysCom_RaidLCB, "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING")
	JocysCom_SetEvent(JocysCom_RaidCB, "CHAT_MSG_RAID")
	-- INSTANCE.
	JocysCom_SetEvent(JocysCom_InstanceLCB, "CHAT_MSG_INSTANCE_CHAT_LEADER")
	JocysCom_SetEvent(JocysCom_InstanceCB, "CHAT_MSG_INSTANCE_CHAT")
	-- Save unit name, gender and type.
	JocysCom_SetEvent(JocysCom_SaveCB, "UPDATE_MOUSEOVER_UNIT")
	JocysCom_SetEvent(JocysCom_SaveCB, "PLAYER_TARGET_CHANGED")

	--if DebugEnabled then JocysCom_OptionsFrame:RegisterAllEvents() end
end

-- Register events.
function JocysCom_RegisterEvents()
	C_ChatInfo.RegisterAddonMessagePrefix(addonPrefix) -- Addon message prefix.
	JocysCom_OptionsFrame:SetScript("OnEvent", function(...) JocysCom_OptionsFrame_OnEvent(false, ...) end) -- Register events on JocysCom_OptionsFrame --- JocysCom_OptionsFrame_OnEvent(playButton, ...).
	JocysCom_OptionsFrame:RegisterEvent("ADDON_LOADED") -- Load all addon settings on this event.
	JocysCom_OptionsFrame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Create or edit macro on this event.
	JocysCom_OptionsFrame:RegisterEvent("PLAYER_LOGOUT")
end

function JocysCom_OptionsFrame_OnEvent(button, self, ...)
	local group = ""
	local name = nil
	local sex = nil -- UnitSex(name) -- UnitSex("npc")
	local text = nil
	local speakMessage = nil
	local nameIntro = false
	local soundIntro = false
	local soundEffect = nil

-- event, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...
local event, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID = ...
	--if string.find(event, "COMBAT") ~= nil or string.find(event, "SPELL") ~= nil or string.find(event, "COMPANION") ~= nil or string.find(event, "PET") ~= nil or string.find(event, "EXHAUSTION") ~= nil then return end
	if event == "ADDON_LOADED" and text ~= addonName then return end -- Ignore other addons.
	if event == "CHAT_MSG_WHISPER" and JocysCom_RemoveRealmName(playerName) == unitName then return end -- Don't process your own whispers twice.
	if string.find(tostring(text), "<message") ~= nil then return end -- Don't proceed messages with <message> tags and your own incoming whispers.
	-- Print event details.
	if DebugEnabled then
		print("|cff77ccff------------------------------------------------------------------------------------|r")
		for i,v in pairs({...}) do
			print(i .. ". " .. type(v) .. ": " ..  tostring(v))
		end
	end
	-- Attach and show frames.
	if event == "ADDON_LOADED" or event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "QUEST_LOG_UPDATE" or event == "MAIL_SHOW" or event == "ITEM_TEXT_READY"  then 	-- or event == "QUEST_GREETING"
		JocysCom_AttachAndShowFrames()
	end
	-- Events.
	if event == "ADDON_LOADED" and text == addonName then
		JocysCom_LoadTocFileSettings() -- Load addon settings.
		JocysCom_DebugEnabledSettings() -- Show / Hide clipboard EditBox and other settings.
		JocysCom_MenuCheckButton_OnClick() -- Set MiniMenuFrame on left or right side.
		JocysCom_OptionsFrame_OnHide() -- Set DialogueScrollFrame and make it transparent.
		JocysCom_AddonTXT_EN() -- Set text of elements.
		JocysCom_LoadEventSettings() -- Register or unregister events.
		JocysCom_DialogueScrollFrame:Show()
		JocysCom_DialogueMiniFrame:Show()
		return
	elseif event == "PLAYER_ENTERING_WORLD" then
		JocysCom_CreateOrUpdateMacro()
		return
	elseif event == "PLAYER_LOGOUT" then
		JocysCom_SaveTocFileSettings()
		return
	elseif event == "UPDATE_MOUSEOVER_UNIT" then
		if GossipFrame:IsVisible() or QuestFrame:IsVisible() or QuestMapFrame:IsVisible() or ItemTextFrame:IsVisible() or MailFrame:IsVisible() then return end
		JocysCom_SaveNPC("mouseover")
		return
	elseif event == "PLAYER_TARGET_CHANGED" then
		JocysCom_SaveNPC("target")
		return
	elseif event == "GOSSIP_CLOSED" or event == "MAIL_CLOSED" then
		return
	--QUEST events.
	elseif event == "MAIL_SHOW_JOCYS" then
			local packageIcon, stationeryIcon, sender, subject = GetInboxHeaderInfo(InboxFrame.openMailID) -- packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(InboxFrame.openMailID)
			local bodyText = GetInboxText(InboxFrame.openMailID) -- bodyText, texture, isTakeable, isInvoice = GetInboxText(InboxFrame.openMailID)
			group = "Quest"
			name = sender
			speakMessage = nilCheck(sender, ". ") .. nilCheck(subject, ". ") .. nilCheck(bodyText, ". ")
			nameIntro = JocysCom_NameQuestCheckButton:GetChecked()
			soundIntro = JocysCom_SoundQuestCheckButton:GetChecked()
	elseif event == "QUEST_LOG_UPDATE_JOCYS" then
			-- local questDetailID = QuestMapFrame.DetailsFrame.questID
			-- local questLogIndex = GetQuestLogIndexByID(questDetailID); -- --GetQuestLogIndexByID(QuestLogPopupDetailFrame.questID)
			-- local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(questLogIndex)
			-- local questPortrait, questPortraitText, questPortraitName, questPortraitMount = GetQuestLogPortraitGiver()
			local questDescription, questObjectives = GetQuestLogQuestText()
			group = "Quest"
			local title = JocysCom_TitlesCheckButton:GetChecked() and QuestInfoTitleHeader:GetText() or nil
			speakMessage = nilCheck(title, ". ") .. nilCheck(questObjectives, ". ") .. nilCheck(QuestInfoDescriptionHeader:GetText(), ". ") .. questDescription
			soundIntro = JocysCom_SoundQuestCheckButton:GetChecked()
	elseif event == "GOSSIP_SHOW" or event == "QUEST_GREETING" or event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" or event == "ITEM_TEXT_READY" then
		-- local questID = GetQuestID()
		if event == "ITEM_TEXT_READY" then
			speakMessage = ItemTextGetText()
		elseif event == "GOSSIP_SHOW" then
			speakMessage = GetGossipText()
			-- print("NPCNAME: " .. _G.GossipFrameNpcNameText:GetText());
		elseif event == "QUEST_GREETING" then
			speakMessage = GetGreetingText()
		elseif event == "QUEST_PROGRESS" then
			local title = JocysCom_TitlesCheckButton:GetChecked() and QuestProgressTitleText:GetText() or nil
			speakMessage = 	nilCheck(title, ". ") .. GetProgressText()
		elseif event == "QUEST_COMPLETE" then
			local title = JocysCom_TitlesCheckButton:GetChecked() and QuestInfoTitleHeader:GetText() or nil
			speakMessage = nilCheck(title, ". ") .. GetRewardText()
		elseif event == "QUEST_DETAIL" then
			local title = JocysCom_TitlesCheckButton:GetChecked() and QuestInfoTitleHeader:GetText() or nil
			local objective = JocysCom_ObjectivesCheckButton:GetChecked() and nilCheck(QuestInfoObjectivesHeader:GetText(), ". ") .. GetObjectiveText() or nil
			speakMessage = nilCheck(title, ". ") .. GetQuestText() .. " " .. nilCheck(objective, ". ")
			-- print("NPCNAME: " .. _G.QuestFrameNpcNameText:GetText())
		end
		group = "Quest"
		name = UnitName("npc")
		sex = UnitSex("npc")
		soundEffect = UnitCreatureType("npc") -- Set sound effect (Beast, Dragonkin, Demon, Elemental, Giant, Undead, Humanoid, Critter, Mechanical, Not specified, Totem, Non-combat Pet, Gas Cloud).
		nameIntro = JocysCom_NameQuestCheckButton:GetChecked()
		soundIntro = JocysCom_SoundQuestCheckButton:GetChecked()
	-- MONSTER.
	elseif string.find(event, "MSG_MONSTER") ~= nil then
		-- don't proceed repetitive NPC messages by the same NPC.
		if (lastArg == text .. playerName) then
			if DebugEnabled then print("Repetitive message ignored.") end
			return
		else
			lastArg = text .. playerName
		end
		-- Add NPC name to NPCNamesTable.
		JocysCom_AddNPCNameToTable(playerName)
		group = "Monster"
		name = playerName
		nameIntro = JocysCom_NameMonsterCheckButton:GetChecked()
		soundIntro = JocysCom_SoundMonsterCheckButton:GetChecked()
	-- WHISPER.
	elseif event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		group = "Whisper"
		if DebugEnabled then print("WHISPER Name: " .. name .. " Gender: " .. sex) end
		soundIntro = JocysCom_SoundWhisperCheckButton:GetChecked()
		nameIntro = JocysCom_NameWhisperCheckButton:GetChecked()
	elseif event == "CHAT_MSG_BN_WHISPER_INFORM" then
			name = unitName
			sex = UnitSex(unitName)
			if DebugEnabled then print("BN_WHISPER_INFORM Name: " .. name .. " Gender: " .. sex) end
			group = "Whisper"
			soundIntro = JocysCom_SoundWhisperCheckButton:GetChecked()
			nameIntro = JocysCom_NameWhisperCheckButton:GetChecked()
	elseif event == "CHAT_MSG_BN_WHISPER" then --or event == "CHAT_MSG_BN_CONVERSATION"
		-- bnSenderID = presenceID
		-- local presenceID, accountName, battleTag, isBattleTagPresence, characterName, bnetIDGameAccount, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, messageTime, canSoR, isReferAFriend, canSummonFriend = BNGetFriendInfoByID(bnSenderID)
		local presenceID, accountName, battleTag, isBattleTagPresence, characterName = BNGetFriendInfoByID(bnSenderID)
		if DebugEnabled then print("|cff77ccffbnSenderID:|r " .. tostring(bnSenderID) .. " |cff77ccffpresenceID:|r " .. tostring(presenceID) .. " |cff77ccffaccountName:|r " .. tostring(accountName) .. " |cff77ccffbattleTag:|r " .. tostring(battleTag) .. " |cff77ccffcharacterName:|r " .. tostring(characterName)) end
		-- Select if not nil priority: characterName > battleTag > accountName
		if characterName ~= nil then
			name = JocysCom_RemoveRealmName(characterName)
			sex = UnitSex(name)
			if DebugEnabled then print("BN_WHISPER characterName: " .. tostring(name) .. " Gender: " .. tostring(name)) end
		elseif battleTag ~= nil then
			name = tostring(battleTag)
			-- remove #0000 from batleTag
			if string.find(name, "#") ~= nil then
				local hashIndex = string.find(name, "#")
				name = string.sub(name, 1, hashIndex - 1)
			end
			if DebugEnabled then print("BN_WHISPER battleTag: " .. tostring(name)) end
--		elseif accountName ~= nil then
--			name = accountName
--			if DebugEnabled then print("BN_WHISPER accountName: " .. tostring(name)) end
		else
			name = "Your friend"
		end
		group = "Whisper"
		soundIntro = JocysCom_SoundWhisperCheckButton:GetChecked()
		nameIntro = JocysCom_NameWhisperCheckButton:GetChecked()
	elseif event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" then
		group = "Emote"
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		nameIntro = false
		soundIntro = JocysCom_SoundEmoteCheckButton:GetChecked()
	elseif event == "CHAT_MSG_SAY" then
		group = "Say"
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		nameIntro = JocysCom_NameSayCheckButton:GetChecked()
		soundIntro = JocysCom_SoundSayCheckButton:GetChecked()
	elseif event == "CHAT_MSG_YELL" then
		group = "Yell"
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		nameIntro = JocysCom_NameYellCheckButton:GetChecked()
		soundIntro = JocysCom_SoundYellCheckButton:GetChecked()
	elseif event == "CHAT_MSG_GUILD" then
		group = "Guild"
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		nameIntro = JocysCom_NameGuildCheckButton:GetChecked()
		soundIntro = JocysCom_SoundGuildCheckButton:GetChecked()
	elseif event == "CHAT_MSG_OFFICER" then
		group = "Officer"
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		nameIntro = JocysCom_NameOfficerCheckButton:GetChecked()
		soundIntro = JocysCom_SoundOfficerCheckButton:GetChecked()
	elseif event == "CHAT_MSG_RAID" then
		group = "Raid"
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		nameIntro = JocysCom_NameRaidCheckButton:GetChecked()
		soundIntro = JocysCom_SoundRaidCheckButton:GetChecked()
	elseif event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_RAID_WARNING" then
		group = "RaidLeader"
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		nameIntro = JocysCom_NameRaidLeaderCheckButton:GetChecked()
		soundIntro = JocysCom_SoundRaidLeaderCheckButton:GetChecked()
	elseif event == "CHAT_MSG_PARTY" then
		group = "Party"
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		nameIntro = JocysCom_NamePartyCheckButton:GetChecked()
		soundIntro = JocysCom_SoundPartyCheckButton:GetChecked()
	elseif event == "CHAT_MSG_PARTY_LEADER" then
		group = "PartyLeader"
		nameIntro = JocysCom_NamePartyLeaderCheckButton:GetChecked()
		soundIntro = JocysCom_SoundPartyLeaderCheckButton:GetChecked()
	elseif event == "CHAT_MSG_INSTANCE_CHAT" then
		group = "Instance"
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		nameIntro = JocysCom_NameInstanceCheckButton:GetChecked()
		soundIntro = JocysCom_SoundInstanceCheckButton:GetChecked()
	elseif event == "CHAT_MSG_INSTANCE_CHAT_LEADER" then
		group = "InstanceLeader"
		name = JocysCom_RemoveRealmName(playerName)
		sex = UnitSex(name)
		nameIntro = JocysCom_NameInstanceLeaderCheckButton:GetChecked()
		soundIntro = JocysCom_SoundInstanceLeaderCheckButton:GetChecked()
	else
		return
	end
	-- If event CHAT.
	if string.find(event, "CHAT") ~= nil then
		speakMessage = text
	end
	-- Debug.
	if DebugEnabled then
		print("event: " .. tostring(event))
		print("speakMessage: " .. tostring(speakMessage))
		print("name: " .. tostring(name))
		print("sex: " .. tostring(sex))
		print("group: " .. tostring(group))
		print("soundIntro: " .. tostring(soundIntro))
		print("soundEffect: " .. tostring(soundEffect))
	end
	-- Add name intro to text.
	if nameIntro then
		local introType = ""
		-- Set "whispers", "says" or "yells".
		if group == "Whisper" then
			introType = " whispers. "
		elseif group == "Yell" then
			introType = " yells. "
		else
			introType = " says. "
		end
		-- Add "***Leader" before name. Replace "***Leader" to "*** leader ".
		local messageLeader = ""
		if string.find(group, "Leader") ~= nil then
			messageLeader = string.gsub(group, "Leader", " leader ")
		end
		speakMessage = messageLeader .. name .. " " .. introType .. speakMessage
	end
	-- On Quest event or Quest play.
	if group == "Quest" then
		-- Don't start automatic play if StartOnOpen[0] and Play[0] -- command "play" is not from button-mouse.
		if not JocysCom_StartOnOpenCheckButton:GetChecked() and not button then return end
		-- If StopOnClose[1] remove all old messages and play new message instantly.
		if JocysCom_StopOnCloseCheckButton:GetChecked() then JocysCom_SendChatMessageStop() end
	end
	-- Send message.
	JocysCom_SpeakMessage(event, speakMessage, name, sex, group, soundIntro, soundEffect)
end

-- Remove realm name from name.
function JocysCom_RemoveRealmName(name)
	if name ~= nil and string.find(name, "-") ~= nil then
		name = string.sub(name, 1, string.find(name, "-") - 1)
	end
	return name
end

function JocysCom_Replace(m)
	m = m .. " "
	-- Remove HTML <> tags and text between them.
	if string.find(m, "HTML") ~= nil then
		m = string.gsub(m, "<.->", "")
		m = string.gsub(m, "\"", "")
	end
	-- Remove colors / class / race.
	if string.find(m, "|") ~= nil then
		m = string.gsub(m, "|+", "|")
		-- Remove colors.
		m = string.gsub(m, "|c........", "")
		m = string.gsub(m, "|r", "")
		-- Remove hyperlinks.
		m = string.gsub(m, "|H.-|h", "")
		m = string.gsub(m, "|h", "")
		-- Replace brackets.
		m = string.gsub(m, "%[", " \"")
		m = string.gsub(m, "%]", "\" ")
		-- Fix class / race.
		m = string.gsub(m, "|[%d]+.[%d]+%((.-)%)", "%1")
	end
	-- Remove / Replace.
	m = string.gsub(m, "&", " and ")
	m = string.gsub(m, "%c(%u)", ".%1")
	m = string.gsub(m, "%c", " ")
	m = string.gsub(m, "%s", " ")
		m = string.gsub(m, "%%s ", " ")
	m = string.gsub(m, "[ ]+", " ")
	m = string.gsub(m, "%!+", "!")
	m = string.gsub(m, "%?+", "?")
	m = string.gsub(m, " %.", ".")
	m = string.gsub(m, "%.+", ".")
	m = string.gsub(m, "%!%.", "!")
	m = string.gsub(m, "%?%.", "?")
	m = string.gsub(m, "%?%-", "?")
	m = string.gsub(m, "%?%!%?", "?!")
	m = string.gsub(m, "%!%?%!", "?!")
	m = string.gsub(m, "%!%?", "?!")
	m = string.gsub(m, "%!", "! ")
	m = string.gsub(m, "%?", "? ")
	m = string.gsub(m, " %!", "!")
	m = string.gsub(m, "^%.+", "")
	m = string.gsub(m, ">%.", ".>")
	m = string.gsub(m, "%.+", ". ")
	m = string.gsub(m, "<", " [comment] ")
	m = string.gsub(m, ">", " [/comment] ")
	m = string.gsub(m, "[ ]+", " ")
	m = string.gsub(m, "lvl", "level")
	return m
end

--Send message.
function JocysCom_SendMessage(message, messageOptions)
	if	JocysCom_NetworkMessageCheckButton:GetChecked() then
		C_ChatInfo.SendAddonMessage(addonPrefix, message, "WHISPER", unitName)
		-- Fill EditBox in Options window.
		if messageOptions then JocysCom_MessageForOptionsEditBox(message) end
	else
		JocysCom_AddMessageToTable(message)
	end
end

--Messages.
function JocysCom_SpeakMessage(event, speakMessage, name, sex, group, soundIntro, soundEffect)
	if speakMessage == nil then return end
	-- Replace player name in speakMessage.
	local newUnitName = JocysCom_ReplaceNameEditBox:GetText()
	if string.len(newUnitName) > 1 and newUnitName ~= unitName then
		customName = newUnitName
		speakMessage = string.gsub(speakMessage, unitName, newUnitName)
	else
		customName = unitName
	end
	-- Send player Name, Class and custom Name to Monitor.
	if string.find(speakMessage, customName) ~= nil or string.find(string.lower(speakMessage), string.lower(unitClass)) ~= nil  then
		local messagePlayer = "<message command=\"player\" name=\"" .. unitName .. ", " .. customName .. ", " .. unitClass ..  "\" />"
		-- Send message and do not fill EditBox in Options window.
		JocysCom_SendMessage(messagePlayer, false)
	end
	--Replace text in message.
	speakMessage = JocysCom_Replace(speakMessage)
	-- Send intro sound message.
	if soundIntro and group ~= nil then JocysCom_SendSoundIntro(group) end
	-- Format and send whisper message.
	local chatMessageSP = "<message command=\"play\"" .. Attribute("group", group) .. Attribute("name", name) .. Attribute("gender", Gender(sex)) .. Attribute("effect", soundEffect) .. "><part>"
	local chatMessageSA = "<message command=\"add\"><part>"
	local chatMessageE = "</part></message>"
	local chatMessage
	if JocysCom_NetworkMessageCheckButton:GetChecked() then
		chatMessageLimit = 240
	else
		chatMessageLimit = 10000
	end
	local sizeAdd = chatMessageLimit - string.len(chatMessageSA) - string.len(chatMessageE) - string.len(addonPrefix)
	local sizePlay = chatMessageLimit - string.len(chatMessageSP) - string.len(chatMessageE) - string.len(addonPrefix)
	if DebugEnabled then
	print("|cffaaa7ff------------------------------------------------------------------------------------|r")
	print("|cffaaa7ffMessage max: [|r" .. chatMessageLimit .. "|cffaaa7ff] command=\"add\" size: [|r" ..  sizeAdd .. "|cffaaa7ff] command=\"play\" size: [|r" .. sizePlay .. "|cffaaa7ff]|r")
	end
		local startIndex = 1
		local endIndex = 1
		local part = ""
		local speakMessageLen = string.len(speakMessage)
		local speakMessageRemainingLen = speakMessageLen
		while true do
			local command = ""
			local index = string.find(speakMessage, " ", endIndex)
			if index == speakMessageLen or index == nil then
			   index = speakMessageLen
			   endIndex = speakMessageLen + 1 -- 0-1000
		end
		-- If text length less than max then...
		if speakMessageRemainingLen <= sizePlay then
			part = string.sub(speakMessage, startIndex)
			chatMessage = chatMessageSP .. part .. chatMessageE
			-- Send message and fill EditBox in Options window.
			JocysCom_SendMessage(chatMessage, true)
			-- Debug information
			if JocysCom_NetworkMessageCheckButton:GetChecked() and DebugEnabled then print("|cff77ccffMessage From-To: [|r" .. startIndex  .. "-" .. speakMessageLen .. "|cff77ccff]|r" .. JocysCom_MessageAddColors(chatMessage)) end
				break
			-- If text length more than max then...
			elseif (index - startIndex) > sizeAdd or (index >= speakMessageLen and speakMessageRemainingLen > sizePlay) then
				-- If space is out of size then...
				part = string.sub(speakMessage, startIndex, endIndex - 1)
				chatMessage = chatMessageSA .. part .. chatMessageE
				-- Send message and do not fill EditBox in Options window.
				JocysCom_SendMessage(chatMessage, false)
				if JocysCom_NetworkMessageCheckButton:GetChecked() and DebugEnabled then print("|cff77ccffSpace found:[|r" .. tostring(index) .. "|cff77ccff] Message From-To:[|r" .. startIndex .. "-" .. (endIndex - 1) .. "|cff77ccff]|r" .. JocysCom_MessageAddColors(chatMessage)) end
			startIndex = endIndex
			speakMessageRemainingLen = string.len(string.sub(speakMessage, startIndex))
		end
		-- look for next space.
		endIndex = index + 1
	end
	-- Set MessageForEditBox.
	if JocysCom_NetworkMessageCheckButton:GetChecked() then
		JocysCom_MessageForOptionsEditBox(chatMessageSP .. speakMessage .. chatMessageE)
	end
end

-- Enable / Disable "Do Not Disturb" (DND) / <Busy>
function JocysCom_DND(b)
	if b and JocysCom_DialogueMiniFrame:IsVisible() then
		if not UnitIsDND("player") then SendChatMessage("<" .. unitName .. ">: " .. messageDoNotDisturb, "DND") end
	else
		if UnitIsDND("player") then SendChatMessage("", "DND") end
	end
end

-- DialogueMiniFrame OnShow.
function JocysCom_DialogueMiniFrame_OnShow()
	-- Enable DND <Busy>.
	if JocysCom_DndCheckButton:GetChecked() then JocysCom_DND(true)	end
	if JocysCom_StartOnOpenCheckButton:GetChecked() and MailFrame:IsVisible() then -- QuestMapFrame:IsVisible()
		JocysCom_PlayOpenedFrame()
	end
end

-- DialogueMiniFrame OnHide.
function JocysCom_DialogueMiniFrame_OnHide()
	-- Disable DND <Busy>.
	if JocysCom_DndCheckButton:GetChecked() then JocysCom_DND(false) end
	-- Remove "Quest" messages if StopOnClose enabled.
	if JocysCom_StopOnCloseCheckButton:GetChecked() then JocysCom_SendChatMessageStop("Quest") end
end

-- DND CheckButton OnClick.
function JocysCom_DndCheckButton_OnClick(self)
	PlaySound(856)
	JocysCom_SaveTocFileSettings()
	if self:GetChecked() then
		JocysCom_FilterDND()
		JocysCom_DND(true)
	else
		JocysCom_DND(false)
		JocysCom_FilterDND()
	end
end

-- Play sound and save settings.
function JocysCom_PlaySoundAndSaveSettings()
	PlaySound(856)
	JocysCom_SaveTocFileSettings()
end

-- Lock Enable / Disable.
function JocysCom_LockCheckButton_OnClick()
	PlaySound(856)
	if JocysCom_LockCheckButton:GetChecked() then
		JocysCom_StopButtonFrame:RegisterForDrag()
	else
		JocysCom_StopButtonFrame:RegisterForDrag("LeftButton")
	end
	JocysCom_SaveTocFileSettings()
end

 -- StopButtonFrame position Right or Left.
function JocysCom_MenuCheckButton_OnClick()
	PlaySound(856)
	JocysCom_MiniMenuFrame:ClearAllPoints()
	JocysCom_ColorMessagesCountFontString:ClearAllPoints()
	if JocysCom_MenuCheckButton:GetChecked() then
		JocysCom_MiniMenuFrame:SetPoint("BOTTOMLEFT", JocysCom_StopButtonFrame, "BOTTOMRIGHT", -8, 3)
		JocysCom_ColorMessagesCountFontString:SetPoint("LEFT", JocysCom_StopButtonFrame, "RIGHT", 0, -11)
	else
		JocysCom_MiniMenuFrame:SetPoint("BOTTOMRIGHT", JocysCom_StopButtonFrame, "BOTTOMLEFT", 4, 3)
		JocysCom_ColorMessagesCountFontString:SetPoint("RIGHT", JocysCom_StopButtonFrame, "LEFT", 0, -11)
	end
	JocysCom_SaveTocFileSettings()
end

local function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

-- Enable disable check-boxes (speech).
function JocysCom_CheckButton_OnClick(self, name)
	PlaySound(856)
	if self:GetChecked() == false then
		-- Remove disabled group messages.
		JocysCom_SendChatMessageStop(name)
	end
	JocysCom_SaveTocFileSettings()
	JocysCom_LoadEventSettings()
end

-- Show MiniMenuFrame and set text.
 function JocysCom_MiniMenuFrame_Show(name)
	local fontString = ""
	JocysCom_MiniMenuFrame_FontString:Show()
	if name == "Options" then
		fontString = "|cffddddddMouse over [=] shows Quick Menu.\nMouse click opens Options Window.|r"
	elseif name == "Save" then
		fontString = "|cffddddddSave target name, gender, type in Monitor.\n|r"
	elseif name == "Stop" then
		fontString = "|cffddddddStop text-to-speech and clear all playlist.\n|r"
	elseif name == "Busy" then
		fontString = "|cff6464ffShow <Busy> over your character\nwhen window is open and speech is on.|r"
	elseif name == "Titles" then
		fontString = "|cffefc176Include QUEST TITLES\nin text-to-speech.|r"
	elseif name == "Objectives" then
		fontString = "|cffefc176Include QUEST OBJECTIVES\nin text-to-speech.|r"
	elseif name == "StartOnOpen" then
		fontString = "|cffefc176START to play DIALOGUE, BOOK, etc.\non opening window.|r"
	elseif name == "StopOnClose" then
		fontString = "|cffefc176STOP to play DIALOGUE, BOOK, etc. on\nclosing window. Uncheck to collect quests.|r"
	elseif name == "Quest" then
		fontString = "|cffefc176Play DIALOGUE, BOOK, PLAQUE, etc.\nwindow text.|r"
	elseif name == "Monster" then
		fontString = "|cfffffb9fPlay NPC chat messages.\n|r"
	elseif name == "Whisper" then
		fontString = "|cffffb2ebPlay WHISPER chat messages.\n|r"
	elseif name == "Emote" then
		fontString = "|cffff6b26Play player EMOTE  chat messages.\n|r"
	elseif name == "Say" then
		fontString = "|cffffffffPlay SAY chat messages.\n|r"
	elseif name == "Yell" then
		fontString = "|cffff3f40Play YELL chat messages.\n|r"
	elseif name == "Guild" then
		fontString = "|cff40fb40Play GUILD member chat messages.\n|r"
	elseif name == "Officer" then
		fontString = "|cff40fb40Play GUILD OFFICER chat messages.\n|r"
	elseif name == "RaidLeader" then
		fontString = "|cffff4709Play RAID LEADER chat messages.\n|r"
	elseif name == "Raid" then
		fontString = "|cffff7d00Play RAID member chat messages.\n|r"
	elseif name == "PartyLeader" then
		fontString = "|cffaaa7ffPlay PARTY LEADER chat messages.\n|r"
	elseif name == "Party" then
		fontString = "|cffaaa7ffPlay PARTY member chat messages.\n|r"
	elseif name == "InstanceLeader" then
		fontString = "|cffff4709Play INSTANCE LEADER chat messages.\n|r"
	elseif name == "Instance" then
		fontString = "|cffff7d00Play INSTANCE member chat messages.\n|r"
	-- Play intro sound check-boxes.
	elseif name == "SoundQuest" then
		fontString = "|cffefc176Play intro sound at the beginning of\nDIALOGUE, BOOK, etc. window text.|r"
	elseif name == "SoundMonster" then
		fontString = "|cfffffb9fPlay intro sound at the beginning of\nNPC messages.|r"
	elseif name == "SoundWhisper" then
		fontString = "|cffffb2ebPlay intro sound at the beginning of\nWHISPER messages.|r"
		elseif name == "SoundEmote" then
		fontString = "|cffff6b26Play intro sound at the beginning of\nplayer EMOTE messages.|r"
	elseif name == "SoundSay" then
		fontString = "|cffffffffPlay intro sound at the beginning of\nSAY messages.|r"
	elseif name == "SoundYell" then
		fontString = "|cffff3f40Play intro sound at the beginning of\nYELL messages.|r"
	elseif name == "SoundOfficer" then
		fontString = "|cff40fb40Play intro sound at the beginning of\nGUILD OFFICER messages.|r"
	elseif name == "SoundGuild" then
		fontString = "|cff40fb40Play intro sound at the beginning of\nGUILD member messages.|r"
	elseif name == "SoundRaidLeader" then
		fontString = "|cffff4709Play intro sound at the beginning of\nRAID LEADER messages.|r"
	elseif name == "SoundRaid" then
		fontString = "|cffff7d00Play intro sound at the beginning of\nRAID member messages.|r"
	elseif name == "SoundPartyLeader" then
		fontString = "|cffaaa7ffPlay intro sound at the beginning of\nPARTY LEADER messages.|r"
	elseif name == "SoundParty" then
		fontString = "|cffaaa7ffPlay intro sound at the beginning of\nPARTY member messages.|r"
	elseif name == "SoundInstanceLeader" then
		fontString = "|cffff4709Play intro sound at the beginning of\nINSTANCE LEADER messages.|r"
	elseif name == "SoundInstance" then
		fontString = "|cffff7d00Play intro sound at the beginning of\nINSTANCE member messages.|r"
	-- Add name check-boxes.
	elseif name == "NameQuest" then
		fontString = "|cffefc176Add \"<CharacterName> says.\" to\nDIALOGUE, BOOK, etc. window text.|r"
	elseif name == "NameMonster" then
		fontString = "|cfffffb9fAdd \"<Name> whispers \\ says \\ yells.\" to\nNPC messages.|r"
	elseif name == "NameWhisper" then
		fontString = "|cffffb2ebAdd \"<CharacterName> whispers.\" to\nWHISPER messages.|r"
	elseif name == "NameSay" then
		fontString = "|cffffffffAdd \"<CharacterName> says.\" to\nSAY messages.|r"
	elseif name == "NameYell" then
		fontString = "|cffff3f40Add \"<CharacterName> yells.\" to\nYELL messages.|r"
	elseif name == "NameOfficer" then
		fontString = "|cff40fb40Add \"<CharacterName> says.\" to\nGUILD OFFICER messages.|r"
	elseif name == "NameGuild" then
		fontString = "|cff40fb40Add \"<CharacterName> says.\" to\nGUILD memeber messages.|r"
	elseif name == "NameRaidLeader" then
		fontString = "|cffff4709Add \"<CharacterName> says.\" to\nRAID LEADER messages.|r"
	elseif name == "NameRaid" then
		fontString = "|cffff7d00Add \"<CharacterName> says.\" to\nRAID member messages.|r"
	elseif name == "NamePartyLeader" then
		fontString = "|cffaaa7ffAdd \"<CharacterName> says.\" to\nPARTY LEADER messages.|r"
	elseif name == "NameParty" then
		fontString = "|cffaaa7ffAdd \"<CharacterName> says.\" to\nPARTY memeber messages.|r"
	elseif name == "NameInstanceLeader" then
		fontString = "|cffff4709Add \"<CharacterName> says.\" to\nINSTANCE LEADER messages.|r"
	elseif name == "NameInstance" then
		fontString = "|cffff7d00Add \"<CharacterName> says.\" to\nINSTANCE memeber messages.|r"
	else
		JocysCom_MiniMenuFrame_FontString:Hide()
	end
	JocysCom_MiniMenuFrame_FontString:SetText(fontString)
	JocysCom_MiniMenuFrame:Show()
 end

 -- Hide MiniMenuFrame.
 function JocysCom_MiniMenuFrame_Hide()
	JocysCom_MiniMenuFrame:Hide()
 end

-- [ Stop ] dialog button.
function JocysCom_StopButton_OnClick(name)
	PlaySound(856)
	if JocysCom_ColorMessageCheckButton:GetChecked() then
	JocysCom_ClipboardMessageEditBoxSetFocus()
	end
	if name == "Quest" then
		-- Remove only "Quest" messages -- [■] stop button on dialogue windows.
		JocysCom_SendChatMessageStop(name)
	else
		-- Remove all messages -- [≡][■] stop button on mini frame.
		JocysCom_SendChatMessageStop()
	end
end

-- [ Play ] button.
function JocysCom_PlayButton_OnClick()
	-- Disable DND.
	if JocysCom_DndCheckButton:GetChecked() then JocysCom_DND(true) end
	--if JocysCom_ColorMessageCheckButton:GetChecked() then JocysCom_ClipboardMessageEditBoxSetFocus() end
	JocysCom_PlayOpenedFrame()
end

-- ScrollFrame - scroll-up or scroll-down.
function JocysCom_DialogueScrollFrame_OnMouseWheel(self, delta)
	if delta == 1 then
		JocysCom_PlayButton_OnClick()

	else
		JocysCom_StopButton_OnClick("Quest")
	end
end

function JocysCom_PlayOpenedFrame()
	-- Default.
	local event = nil
	-- Gossip.
	if GossipFrame:IsVisible() then event = "GOSSIP_SHOW"
	-- Quest.
	elseif QuestFrame:IsVisible() then
		if QuestGreetingScrollFrame:IsVisible() then event = "QUEST_GREETING"
		elseif QuestDetailScrollFrame:IsVisible() then event = "QUEST_DETAIL"
		elseif QuestProgressScrollFrame:IsVisible() then event = "QUEST_PROGRESS"
		elseif QuestRewardScrollFrame:IsVisible() then event = "QUEST_COMPLETE"
		end
	-- QuestLog.
	elseif QuestMapFrame:IsVisible() then event = "QUEST_LOG_UPDATE_JOCYS"
	-- Item.
	elseif ItemTextFrame:IsVisible() then event = "ITEM_TEXT_READY"
	-- Mail.
	elseif MailFrame:IsVisible() then event = "MAIL_SHOW_JOCYS"
	end
	-- Return.
	if event ~= nil then JocysCom_OptionsFrame_OnEvent(true, nil, event) end
end

-- Show or Hide JocysCom frames.
function JocysCom_AttachAndShowFrames()
	local frameButton = GossipFrame
	local frameScroll = GossipGreetingScrollFrame
	-- Gossip.
	if GossipFrame:IsVisible() then
		frameButton = GossipFrame
		frameScroll = GossipGreetingScrollFrame
	-- Log.
	elseif QuestMapFrame:IsVisible() then
		frameButton = QuestMapFrame.DetailsFrame
		frameScroll = QuestMapDetailsScrollFrame
	-- Quest.
	elseif QuestFrame:IsVisible() then
		if QuestGreetingScrollFrame:IsVisible() then
			frameScroll = QuestGreetingScrollFrame
		elseif QuestDetailScrollFrame:IsVisible() then
			frameScroll = QuestDetailScrollFrame
		elseif QuestProgressScrollFrame:IsVisible() then
			frameScroll = QuestProgressScrollFrame
		elseif QuestRewardScrollFrame:IsVisible() then
			frameScroll = QuestRewardScrollFrame
		end
		frameButton = QuestFrame
	-- Item.
	elseif ItemTextFrame:IsVisible() then
		frameButton = ItemTextFrame
		frameScroll = ItemTextScrollFrame
	-- Mail.
	elseif MailFrame:IsVisible() then
		frameButton = OpenMailFrame
		frameScroll = OpenMailScrollFrame
	end
	-- ScrollFrame
	JocysCom_DialogueScrollFrame:ClearAllPoints()
	JocysCom_DialogueScrollFrame:SetParent(frameScroll)
	JocysCom_DialogueScrollFrame:SetPoint("TOPLEFT", frameScroll, 4, -4)
	JocysCom_DialogueScrollFrame:SetPoint("BOTTOMRIGHT", frameScroll, -4, 4)
	JocysCom_DialogueScrollFrame:SetFrameLevel(100)
	-- ButtonFrame
	JocysCom_DialogueMiniFrame:ClearAllPoints()
	JocysCom_DialogueMiniFrame:SetParent(frameButton)
	if QuestMapFrame:IsVisible() then
		frameButton = QuestMapFrame
		JocysCom_DialogueMiniFrame:SetPoint("TOPRIGHT", frameButton, "BOTTOMRIGHT", 0, -2) -- Exception for QuestMapFrame.
	else
		JocysCom_DialogueMiniFrame:SetPoint("TOPRIGHT", frameButton, "BOTTOMRIGHT", 0, 1)
	end
	-- If DebugEnabled.
	if DebugEnabled then
		print("|cffabd473------------------------------------------------------------------------------------|r")
		print("|cffabd473PLAY and STOP buttons attached to |r" .. frameButton:GetName())
	end
end

-- [ Options ] button.
function JocysCom_OptionsButton_OnClick()
	if JocysCom_OptionsFrame:IsShown() then
		JocysCom_OptionsFrame:Hide()
	else
		JocysCom_OptionsFrame:Show()
	end
end

-- [ Save ] button.
function JocysCom_SaveNPC(m)
	if UnitIsPlayer(m) or UnitPlayerControlled(m) or UnitName(m) == nil or UnitSex(m) == nil then
		if DebugEnabled then
			print("|cff999999------------------------------------------------------------------------------------|r")
			print("|cff999999Only uncontrollable by players NPC targets will be saved.|r")
		end
	else
		local saveMessage = "<message command=\"save\"" .. Attribute("name", UnitName(m)) .. Attribute("gender", Gender(UnitSex(m))) .. Attribute("effect", UnitCreatureType(m)) .. " />"
		--Send message.
		messageEditBox = "|cff808080" .. saveMessage .. "|r"
		-- Send message and do not fill EditBox in Options window.
		JocysCom_SendMessage(saveMessage, false)
	end
end

-- Clipboard mode Enable / Disable.
function JocysCom_ColorMessageCheckButton_OnClick()
	PlaySound(856)
	if JocysCom_ColorMessageCheckButton:GetChecked() then
		JocysCom_NetworkMessageCheckButton:SetChecked(false)
	end
	JocysCom_ClearForm()
	JocysCom_SaveTocFileSettings()
	JocysCom_LoadEventSettings()
end

-- Nwtwork mode Enable / Disable.
function JocysCom_NetworkMessageCheckButton_OnClick()
	PlaySound(856)
	if JocysCom_NetworkMessageCheckButton:GetChecked() then
		JocysCom_ColorMessageCheckButton:SetChecked(false)
	end
	JocysCom_ClearForm()
	JocysCom_SaveTocFileSettings()
	JocysCom_LoadEventSettings()
end

function JocysCom_ClearForm()
	JocysCom_StopButton_OnClick()
	JocysCom_OptionsEditBox:SetText("")
	JocysCom_ClipboardMessageEditBox:SetText("")
end

-- Add message to table for Clipboard.
function JocysCom_AddMessageToTable(m)
	m = string.gsub(m, "<message ", "<message position=\"" .. pixelX .. "," .. pixelY .. "\" ")
	table.insert(messagesTable, m)
	if DebugEnabled then
		print("|cff77ccff------------------------------------------------------------------------------------|r")
		print("|cff77ccffMessage added [|r" .. #messagesTable .. "|cff77ccff]|r")
	end
	if #messagesTable > 0 then
		JocysCom_ColorMessagesCountFontString:SetText(#messagesTable)
	else
		JocysCom_ColorMessagesCountFontString:SetText("")
	end
	if timerEnabled == false then
		timerEnabled = true
		JocysCom_SendMessagesFromTable()
	end
end

-- Add Colors to message.
function JocysCom_MessageAddColors(m)
	m = string.gsub(m, "%[comment]", "|cff808080[comment]|r|cfff7e593")
	m = string.gsub(m, "%[/comment]", "|r|cff808080[/comment]|r")
	m = string.gsub(m, "<", "|cff808080<")
	m = string.gsub(m, ">", ">|r")
	return m
end

-- Send message to Options EditBox.
function JocysCom_MessageForOptionsEditBox(m)
	if string.find(m, "command=\"sound\"") ~= nil or string.find(m, "command=\"player\"") ~= nil or string.find(m, "command=\"save\"") ~= nil then
		return
	else
		-- Add Colors to message.
		JocysCom_OptionsEditBox:SetText(JocysCom_MessageAddColors(m))
	end
end

-- Send messages from table for Clipboard.

local messageChanged = 5
function JocysCom_SendMessagesFromTable()
	--JocysCom_ButtonFlashing()
	--if JocysCom_ClipboardMessageEditBox:HasFocus() then
		-- Convert message characters to HEX color.
		local messageHEX = messagesTable[1]:gsub(".", function(c) return string.format("%02x", string.byte(c)) end) -- UTF-8 (a ш B Ш C) (61 D188 42 D0A8 43): 61D18842D0A843
		local messageLen = #messageHEX / 2 -- Count bytes-pairs (7): 61 D1 88 42 D0 A8 43
		local mod = math.fmod(messageLen,3) -- Divide (7) by 3: (7)-3-3... = left 1 (less than 3) / 61D188 42D0A8 43 (3 3 1)
		-- Add missing bytes.
		if mod == 1 then
			messageHEX = messageHEX .. "0000" -- If 1 pair left, add 2 pairs (00 00).
		elseif mod == 2 then
			messageHEX = messageHEX .. "00" -- If 2 pairs left, add 1 pair (00).
		end
		-- Split in 6 (3 pairs), reverse (RGB to BGR), create colored pixel: |cff88D1610|r  (|c alpha(ff) red(88) green(D1) blue(61) character(0) |r)
		local message = messageHEX:gsub("(..)(..)(..)", "|cff" .. "%3%2%1" .. "0|r")
		-- Add 5 to red color when message changes.
		if messageChanged > 80 then messageChanged = 10 end
		messageChanged = messageChanged + 5
		local messageChangedColor = "|cff" .. messageChanged .. messageChanged.. messageChanged .. "0|r" -- Set message change value.
		local messageBytes = string.format("%06x", messageLen) -- Add missing bytes to message lenght value.
		local messageBytesColor = "|cff" .. messageBytes .. "0|r" -- Set message lenght as color.
		-- Add prefixes: prefix[6] + change[1] + size[1] + message
		message = messagePrefix .. messageChangedColor .. messageBytesColor ..  message
		-- Debug.
		if DebugEnabled then
			print("|cff77ccff------------------------------------------------------------------------------------|r")
			print("|cff77ccffPrefix: |r" .. messagePrefix .. "|cff77ccff Changed: (|r" .. messageChanged .. "|cff77ccff) |r" .. messageChangedColor .. "|cff77ccff Lenght: (|r" .. messageBytes .. "|cff77ccff) |r" .. messageBytesColor .. "|cff77ccff Message: (|r" .. #messageHEX .. "/2=" .. messageLen .. " L" .. mod .. "|cff77ccff) |r" .. message)
			print("|cff77ccffMessage removed: [|r" .. #messagesTable .. "|cff77ccff]|r " .. JocysCom_MessageAddColors(messagesTable[1]))
		end
		-- Set color frame position.
		pixelX = JocysCom_ColorMessagePixelXEditBox:GetNumber()
		pixelY = JocysCom_ColorMessagePixelYEditBox:GetNumber()
		if pixelY > 0 then pixelY = pixelY * -1 end
		JocysCom_ColorMessageFrame:ClearAllPoints()
		JocysCom_ColorMessageFrame:SetPoint("TOPLEFT", pixelX, pixelY)
		JocysCom_ColorMessageFrame:SetPoint("TOPRIGHT")
		JocysCom_ColorMessageFrame:Show()

		-- Send to pixels.
		JocysCom_ColorMessageFontString:SetText(message)
		-- Send to clipboard
		JocysCom_ClipboardMessageEditBox:SetText(messagesTable[1])
		JocysCom_ClipboardMessageEditBoxSetFocus()
		-- Send to options.
		JocysCom_MessageForOptionsEditBox(messagesTable[1])
		-- Remove sent message after * second.
		--<PREFIX>_wait(delay, func [, param [,param [,...]]])
		JocysCom_wait(0.2, JocysCom_RemoveMessageFromTable)
	--else
		--JocysCom_wait(0.2, JocysCom_SendMessagesFromTable)
	--end
end

function JocysCom_ButtonFlashing()
	if JocysCom_ClipboardMessageEditBox:HasFocus() then
		if UIFrameIsFading(JocysCom_ContinueButton) then
			UIFrameFlashRemoveFrame(JocysCom_ContinueButton)
		end
		JocysCom_ContinueButton:Hide()
		JocysCom_StopButton:Show()
	else
		UIFrameFlash(JocysCom_ContinueButton, 1, 1, 10, true, 0, 0)
		JocysCom_ContinueButton:Show()
		JocysCom_StopButton:Hide()
	end
end

function JocysCom_ClipboardMessageEditBoxSetFocus()
	if DebugEnabled then
		JocysCom_ClipboardMessageFrame:Show()
		-- Clear focus...
		if JocysCom_ClipboardMessageEditBox:HasFocus() then
			JocysCom_ClipboardMessageEditBox:ClearFocus()
		end
		--JocysCom_ClipboardMessageFrame:SetFocus()
		--JocysCom_ClipboardMessageEditBox:HighlightText()
	else
		JocysCom_ClipboardMessageFrame:Hide()
	end
end

function JocysCom_RemoveMessageFromTable()
		local messagesLeft = #messagesTable
		table.remove(messagesTable, 1)
		-- Repeat if there are messages in table.
		if #messagesTable > 0 then
			JocysCom_SendMessagesFromTable()
		else
			timerEnabled = false
		end
		if #messagesTable > 0 then
			JocysCom_ColorMessagesCountFontString:SetText(#messagesTable)
		else
			JocysCom_ColorMessagesCountFontString:SetText("")
		end
end

-- Send messages with delay.
local waitTable = {}
local waitFrame = nil
function JocysCom_wait(delay, func, ...)
	if(type(delay)~="number" or type(func)~="function") then
		return false
	end
	if(waitFrame == nil) then
		waitFrame = CreateFrame("Frame","WaitFrame", UIParent)
		waitFrame:SetScript("onUpdate",function (self,elapse)
			local count = #waitTable
			local i = 1
			while(i<=count) do
				local waitRecord = tremove(waitTable,i)
				local d = tremove(waitRecord,1)
				local f = tremove(waitRecord,1)
				local p = tremove(waitRecord,1)
				if(d>elapse) then
					tinsert(waitTable,i,{d-elapse,f,p})
					i = i + 1
				else
					count = count - 1
					f(unpack(p))
				end
			end
		end)
	end
	tinsert(waitTable,{delay,func,{...}})
	return true
end

---- Enable/Disable DND message filter.
function JocysCom_FilterDND()
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg) return not DebugEnabled and JocysCom_DndCheckButton:GetChecked() and string.find(msg, "You are no longer marked Busy.") ~= nil end)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg) return not DebugEnabled and JocysCom_DndCheckButton:GetChecked() and string.find(msg, "You are now Busy:") ~= nil end)
end

-- Load and apply settings from toc file.
function JocysCom_LoadTocFileSettings()
	-- Set (Debug) value.
	if JocysCom_DebugEnabled == true then DebugEnabled = true else DebugEnabled = false end
	-- Set (Options) CheckButtons.
	if JocysCom_DndCB == false then JocysCom_DndCheckButton:SetChecked(false) else JocysCom_DndCheckButton:SetChecked(true) end
	if JocysCom_NetworkMessageCB == true then JocysCom_NetworkMessageCheckButton:SetChecked(true) else JocysCom_NetworkMessageCheckButton:SetChecked(false) end
	if JocysCom_ColorMessageCB == false then JocysCom_ColorMessageCheckButton:SetChecked(false) else JocysCom_ColorMessageCheckButton:SetChecked(true) end
	-- Set LockCheckButton and StopButtonFrame.
	if JocysCom_LockCB == true then JocysCom_LockCheckButton:SetChecked(true) else JocysCom_LockCheckButton:SetChecked(false) end
	if JocysCom_LockCheckButton:GetChecked() then JocysCom_StopButtonFrame:RegisterForDrag() else JocysCom_StopButtonFrame:RegisterForDrag("LeftButton") end
	-- Set MenuCheckButton and MiniMenuFrame.
	if JocysCom_MenuCB == false then JocysCom_MenuCheckButton:SetChecked(false) else JocysCom_MenuCheckButton:SetChecked(true) end
	-- Set save NPC name, gender and type to Monitor.
	if JocysCom_SaveCB == false then JocysCom_SaveCheckButton:SetChecked(false) else JocysCom_SaveCheckButton:SetChecked(true) end
	-- Add chat message filters.
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", function(self, event, msg) return string.find(msg, "<message") ~= nil end)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", function(self, event, msg) return string.find(msg, "<message") ~= nil end)
	JocysCom_FilterDND()
	-- Set (Options) EditBoxes.
	if JocysCom_ColorMessagePixelXEB == "" or JocysCom_ColorMessagePixelXEB == nil then JocysCom_ColorMessagePixelXEB = 0 JocysCom_ColorMessagePixelXEditBox:SetNumber(JocysCom_ColorMessagePixelXEB) else JocysCom_ColorMessagePixelXEditBox:SetNumber(JocysCom_ColorMessagePixelXEB) end
	if JocysCom_ColorMessagePixelYEB == "" or JocysCom_ColorMessagePixelYEB == nil then JocysCom_ColorMessagePixelYEB = 0 JocysCom_ColorMessagePixelYEditBox:SetNumber(JocysCom_ColorMessagePixelYEB) else JocysCom_ColorMessagePixelYEditBox:SetNumber(JocysCom_ColorMessagePixelYEB) end
	if JocysCom_ReplaceNameEB == "" or JocysCom_ReplaceNameEB == nil then JocysCom_ReplaceNameEB = unitName JocysCom_ReplaceNameEditBox:SetText(JocysCom_ReplaceNameEB) else JocysCom_ReplaceNameEditBox:SetText(JocysCom_ReplaceNameEB) end
	-- Set (MiniFrame) CheckButtons.
	if JocysCom_QuestCB == false then JocysCom_QuestCheckButton:SetChecked(false) else JocysCom_QuestCheckButton:SetChecked(true) end
	if JocysCom_MonsterCB == false then JocysCom_MonsterCheckButton:SetChecked(false) else JocysCom_MonsterCheckButton:SetChecked(true) end
	if JocysCom_WhisperCB == false then JocysCom_WhisperCheckButton:SetChecked(false) else JocysCom_WhisperCheckButton:SetChecked(true) end
	if JocysCom_EmoteCB == false then JocysCom_EmoteCheckButton:SetChecked(false) else JocysCom_EmoteCheckButton:SetChecked(true) end
	if JocysCom_SayCB == false then JocysCom_SayCheckButton:SetChecked(false) else JocysCom_SayCheckButton:SetChecked(true) end
	if JocysCom_YellCB == false then JocysCom_YellCheckButton:SetChecked(false) else JocysCom_YellCheckButton:SetChecked(true) end
	if JocysCom_GuildCB == false then JocysCom_GuildCheckButton:SetChecked(false) else JocysCom_GuildCheckButton:SetChecked(true) end
	if JocysCom_OfficerCB == false then JocysCom_OfficerCheckButton:SetChecked(false) else JocysCom_OfficerCheckButton:SetChecked(true) end
	if JocysCom_PartyCB == false then JocysCom_PartyCheckButton:SetChecked(false) else JocysCom_PartyCheckButton:SetChecked(true) end
	if JocysCom_PartyLCB == false then JocysCom_PartyLeaderCheckButton:SetChecked(false) else JocysCom_PartyLeaderCheckButton:SetChecked(true) end
	if JocysCom_RaidCB == false then JocysCom_RaidCheckButton:SetChecked(false) else JocysCom_RaidCheckButton:SetChecked(true) end
	if JocysCom_RaidLCB == false then JocysCom_RaidLeaderCheckButton:SetChecked(false) else JocysCom_RaidLeaderCheckButton:SetChecked(true) end
	if JocysCom_InstanceCB == false then JocysCom_InstanceCheckButton:SetChecked(false) else JocysCom_InstanceCheckButton:SetChecked(true) end
	if JocysCom_InstanceLCB == false then JocysCom_InstanceLeaderCheckButton:SetChecked(false) else JocysCom_InstanceLeaderCheckButton:SetChecked(true) end
	if JocysCom_TitlesCB == true then JocysCom_TitlesCheckButton:SetChecked(true) else JocysCom_TitlesCheckButton:SetChecked(false) end
	if JocysCom_ObjectivesCB == false then JocysCom_ObjectivesCheckButton:SetChecked(false) else JocysCom_ObjectivesCheckButton:SetChecked(true) end
	if JocysCom_StartOnOpenCB == false then JocysCom_StartOnOpenCheckButton:SetChecked(false) else JocysCom_StartOnOpenCheckButton:SetChecked(true) end
	if JocysCom_StopOnCloseCB == false then JocysCom_StopOnCloseCheckButton:SetChecked(false) else JocysCom_StopOnCloseCheckButton:SetChecked(true) end
	-- Set (MiniFrame) Sound CheckButtons.
	if JocysCom_SQuestCB == true then JocysCom_SoundQuestCheckButton:SetChecked(true) else JocysCom_SoundQuestCheckButton:SetChecked(false) end
	if JocysCom_SMonsterCB == false then JocysCom_SoundMonsterCheckButton:SetChecked(false) else JocysCom_SoundMonsterCheckButton:SetChecked(true) end
	if JocysCom_SWhisperCB == false then JocysCom_SoundWhisperCheckButton:SetChecked(false) else JocysCom_SoundWhisperCheckButton:SetChecked(true) end
	if JocysCom_SEmoteCB == false then JocysCom_SoundEmoteCheckButton:SetChecked(false) else JocysCom_SoundEmoteCheckButton:SetChecked(true) end
	if JocysCom_SSayCB == false then JocysCom_SoundSayCheckButton:SetChecked(false) else JocysCom_SoundSayCheckButton:SetChecked(true) end
	if JocysCom_SYellCB == false then JocysCom_SoundYellCheckButton:SetChecked(false) else JocysCom_SoundYellCheckButton:SetChecked(true) end
	if JocysCom_SGuildCB == false then JocysCom_SoundGuildCheckButton:SetChecked(false) else JocysCom_SoundGuildCheckButton:SetChecked(true) end
	if JocysCom_SOfficerCB == false then JocysCom_SoundOfficerCheckButton:SetChecked(false) else JocysCom_SoundOfficerCheckButton:SetChecked(true) end
	if JocysCom_SPartyCB == false then JocysCom_SoundPartyCheckButton:SetChecked(false) else JocysCom_SoundPartyCheckButton:SetChecked(true) end
	if JocysCom_SPartyLCB == false then JocysCom_SoundPartyLeaderCheckButton:SetChecked(false) else JocysCom_SoundPartyLeaderCheckButton:SetChecked(true) end
	if JocysCom_SRaidCB == false then JocysCom_SoundRaidCheckButton:SetChecked(false) else JocysCom_SoundRaidCheckButton:SetChecked(true) end
	if JocysCom_SRaidLCB == false then JocysCom_SoundRaidLeaderCheckButton:SetChecked(false) else JocysCom_SoundRaidLeaderCheckButton:SetChecked(true) end
	if JocysCom_SInstanceCB == false then JocysCom_SoundInstanceCheckButton:SetChecked(false) else JocysCom_SoundInstanceCheckButton:SetChecked(true) end
	if JocysCom_SInstanceLCB == false then JocysCom_SoundInstanceLeaderCheckButton:SetChecked(false) else JocysCom_SoundInstanceLeaderCheckButton:SetChecked(true) end
	-- Set (MiniFrame) Name CheckButtons.
	if JocysCom_NQuestCB == true then JocysCom_NameQuestCheckButton:SetChecked(true) else JocysCom_NameQuestCheckButton:SetChecked(false) end
	if JocysCom_NMonsterCB == true then JocysCom_NameMonsterCheckButton:SetChecked(true) else JocysCom_NameMonsterCheckButton:SetChecked(false) end
	if JocysCom_NWhisperCB == true then JocysCom_NameWhisperCheckButton:SetChecked(true) else JocysCom_NameWhisperCheckButton:SetChecked(false) end
	if JocysCom_NSayCB == true then JocysCom_NameSayCheckButton:SetChecked(true) else JocysCom_NameSayCheckButton:SetChecked(false) end
	if JocysCom_NYellCB == true then JocysCom_NameYellCheckButton:SetChecked(true) else JocysCom_NameYellCheckButton:SetChecked(false) end
	if JocysCom_NGuildCB == true then JocysCom_NameGuildCheckButton:SetChecked(true) else JocysCom_NameGuildCheckButton:SetChecked(false) end
	if JocysCom_NOfficerCB == true then JocysCom_NameOfficerCheckButton:SetChecked(true) else JocysCom_NameOfficerCheckButton:SetChecked(false) end
	if JocysCom_NPartyCB == true then JocysCom_NamePartyCheckButton:SetChecked(true) else JocysCom_NamePartyCheckButton:SetChecked(false) end
	if JocysCom_NPartyLCB == true then JocysCom_NamePartyLeaderCheckButton:SetChecked(true) else JocysCom_NamePartyLeaderCheckButton:SetChecked(false) end
	if JocysCom_NRaidCB == true then JocysCom_NameRaidCheckButton:SetChecked(true) else JocysCom_NameRaidCheckButton:SetChecked(false) end
	if JocysCom_NRaidLCB == true then JocysCom_NameRaidLeaderCheckButton:SetChecked(true) else JocysCom_NameRaidLeaderCheckButton:SetChecked(false) end
	if JocysCom_NInstanceCB == true then JocysCom_NameInstanceCheckButton:SetChecked(true) else JocysCom_NameInstanceCheckButton:SetChecked(false) end
	if JocysCom_NInstanceLCB == true then JocysCom_NameInstanceLeaderCheckButton:SetChecked(true) else JocysCom_NameInstanceLeaderCheckButton:SetChecked(false) end
end

-- Save settings.
function JocysCom_SaveTocFileSettings()
	JocysCom_DebugEnabled = DebugEnabled
	-- Save check buttons.
	JocysCom_ColorMessagePixelXEB = JocysCom_ColorMessagePixelXEditBox:GetNumber()
	JocysCom_ColorMessagePixelYEB = JocysCom_ColorMessagePixelYEditBox:GetNumber()
	JocysCom_ReplaceNameEB = JocysCom_ReplaceNameEditBox:GetText()
	JocysCom_NetworkMessageCB = JocysCom_NetworkMessageCheckButton:GetChecked()
	JocysCom_ColorMessageCB = JocysCom_ColorMessageCheckButton:GetChecked()
	JocysCom_DndCB = JocysCom_DndCheckButton:GetChecked()
	JocysCom_LockCB = JocysCom_LockCheckButton:GetChecked()
	JocysCom_MenuCB = JocysCom_MenuCheckButton:GetChecked()
	JocysCom_SaveCB = JocysCom_SaveCheckButton:GetChecked();
	JocysCom_QuestCB = JocysCom_QuestCheckButton:GetChecked()
	JocysCom_MonsterCB = JocysCom_MonsterCheckButton:GetChecked()
	JocysCom_WhisperCB = JocysCom_WhisperCheckButton:GetChecked()
	JocysCom_EmoteCB = JocysCom_EmoteCheckButton:GetChecked()
	JocysCom_SayCB = JocysCom_SayCheckButton:GetChecked()
	JocysCom_YellCB = JocysCom_YellCheckButton:GetChecked()
	JocysCom_GuildCB = JocysCom_GuildCheckButton:GetChecked()
	JocysCom_OfficerCB = JocysCom_OfficerCheckButton:GetChecked()
	JocysCom_PartyCB = JocysCom_PartyCheckButton:GetChecked()
	JocysCom_PartyLCB = JocysCom_PartyLeaderCheckButton:GetChecked()
	JocysCom_RaidCB = JocysCom_RaidCheckButton:GetChecked()
	JocysCom_RaidLCB = JocysCom_RaidLeaderCheckButton:GetChecked()
	JocysCom_InstanceCB = JocysCom_InstanceCheckButton:GetChecked()
	JocysCom_InstanceLCB = JocysCom_InstanceLeaderCheckButton:GetChecked()
	JocysCom_TitlesCB = JocysCom_TitlesCheckButton:GetChecked()
	JocysCom_ObjectivesCB = JocysCom_ObjectivesCheckButton:GetChecked()
	JocysCom_StartOnOpenCB = JocysCom_StartOnOpenCheckButton:GetChecked()
	JocysCom_StopOnCloseCB = JocysCom_StopOnCloseCheckButton:GetChecked()
	-- Save sound check buttons.
	JocysCom_SQuestCB = JocysCom_SoundQuestCheckButton:GetChecked()
	JocysCom_SMonsterCB = JocysCom_SoundMonsterCheckButton:GetChecked()
	JocysCom_SWhisperCB = JocysCom_SoundWhisperCheckButton:GetChecked()
	JocysCom_SEmoteCB = JocysCom_SoundEmoteCheckButton:GetChecked()
	JocysCom_SSayCB = JocysCom_SoundSayCheckButton:GetChecked()
	JocysCom_SYellCB = JocysCom_SoundYellCheckButton:GetChecked()
	JocysCom_SGuildCB = JocysCom_SoundGuildCheckButton:GetChecked()
	JocysCom_SOfficerCB = JocysCom_SoundOfficerCheckButton:GetChecked()
	JocysCom_SPartyCB = JocysCom_SoundPartyCheckButton:GetChecked()
	JocysCom_SPartyLCB = JocysCom_SoundPartyLeaderCheckButton:GetChecked()
	JocysCom_SRaidCB = JocysCom_SoundRaidCheckButton:GetChecked()
	JocysCom_SRaidLCB = JocysCom_SoundRaidLeaderCheckButton:GetChecked()
	JocysCom_SInstanceCB = JocysCom_SoundInstanceCheckButton:GetChecked()
	JocysCom_SInstanceLCB = JocysCom_SoundInstanceLeaderCheckButton:GetChecked()
	-- Save name check buttons.
	JocysCom_NQuestCB = JocysCom_NameQuestCheckButton:GetChecked()
	JocysCom_NMonsterCB = JocysCom_NameMonsterCheckButton:GetChecked()
	JocysCom_NWhisperCB = JocysCom_NameWhisperCheckButton:GetChecked()
	JocysCom_NSayCB = JocysCom_NameSayCheckButton:GetChecked()
	JocysCom_NYellCB = JocysCom_NameYellCheckButton:GetChecked()
	JocysCom_NGuildCB = JocysCom_NameGuildCheckButton:GetChecked()
	JocysCom_NOfficerCB = JocysCom_NameOfficerCheckButton:GetChecked()
	JocysCom_NPartyCB = JocysCom_NamePartyCheckButton:GetChecked()
	JocysCom_NPartyLCB = JocysCom_NamePartyLeaderCheckButton:GetChecked()
	JocysCom_NRaidCB = JocysCom_NameRaidCheckButton:GetChecked()
	JocysCom_NRaidLCB = JocysCom_NameRaidLeaderCheckButton:GetChecked()
	JocysCom_NInstanceCB = JocysCom_NameInstanceCheckButton:GetChecked()
	JocysCom_NInstanceLCB = JocysCom_NameInstanceLeaderCheckButton:GetChecked()
end
--Load events and settings.
JocysCom_RegisterEvents()
-- IKEMEN Color Editor Module by jay_ts & m14
-- Updated by Rakíel 02/28/2026
-- Main

local util = require("external.mods.coloredit.coloredit-util")

util.loadMotifExtensions("external/mods/coloredit/coloredit.def", "external/mods/coloredit/coloredit.def")
local coloredit = {}
local m = motif.coloredit_info

m.anim.exclude = type(m.anim.exclude) == "table" and m.anim.exclude or {m.anim.exclude}
for k,v in pairs(m.anim.exclude) do
	m.anim.exclude[k] = tonumber(v)
end
local function isExcluded(anim)
	if anim < tonumber(m.anim.range[1]) then return true end
	if anim > tonumber(m.anim.range[2]) then return true end
	for _,v in pairs(m.anim.exclude) do
		if v == anim then return true end
	end
	return false
end

-- Init anims
local rects         = {"r", "g", "b", "a", "prev"}
local warnings      = {"warning", "yes", "no", "yes.active", "no.active"}
local delete        = {"delete", "yes", "no", "yes.active", "no.active"}
local aCursorBg		= util.loadMotifAnim(m.cell.cursor)
local aSliderBg		= util.loadMotifAnim(m.slider.cursor)
local tsTitle		= util.loadMotifFont(m.title)
local tsSave		= util.loadMotifFont(m.save)
local tsDeleted		= util.loadMotifFont(m.deleted)

local tsWarning = {
	["warning"]			= util.loadMotifFont(m.warning),
	["yes"]				= util.loadMotifFont(m.yes),
	["no"] 				= util.loadMotifFont(m.no),
	["yes.active"]		= util.loadMotifFont(m.yes.active),
	["no.active"] 		= util.loadMotifFont(m.no.active)
}
local tsDelete = {
	["delete"]			= util.loadMotifFont(m.delete),
	["yes"]				= util.loadMotifFont(m.yes),
	["no"] 				= util.loadMotifFont(m.no),
	["yes.active"]		= util.loadMotifFont(m.yes.active),
	["no.active"] 		= util.loadMotifFont(m.no.active)
}
local tsSliderDisplay = {
	["r"] = util.loadMotifFont(m.slider.r.display),
	["g"] = util.loadMotifFont(m.slider.g.display),
	["b"] = util.loadMotifFont(m.slider.b.display),
	["a"] = util.loadMotifFont(m.slider.a.display)
}

-- Itemname declaration
main.t_itemname.coloredit = function()
	return start.f_colorEdit
end

local colorEditedFlag = false

local function animNewWithPalette(sff, anim, ref, pal)
	local data = animNew(sff, anim)
	animLoadPalettes(data, ref)
	data = animPrepare(data, ref)
	data = changeColorPalette(data, pal)
	animUpdate(data)
	return data
end

-- Screen loop
function start.f_colorEdit()
	-- Init itemname vals
	start.f_selectReset(true)
	main.f_default()
	remapInput(1, getLastInputController())
	remapInput(getLastInputController(), 1)
	main.teamMenu[1].single = true
	local ok = false
	main.close = false
	
	-- Select screen phase
	if not start.f_selectScreen() then
		sndPlay(motif.Snd, motif.select_info.cancel.snd[1], motif.select_info.cancel.snd[2])
		bgReset(motif[main.background].BGDef)
		main.f_fadeReset('fadein', motif[main.group])
		playBgm({source = "motif.title", interrupt = true})
		return
	end
	
	-- Color edit phase
	
	playBgm({bgm = m.bgm.path, 
			 loop = tonumber(m.bgm.loop), 
			 volume = tonumber(m.bgm.volume), 
			 loopstart = tonumber(m.bgm.loopstart), 
			 loopend = tonumber(m.bgm.loopend), 
			 startposition = tonumber(m.bgm.startposition), 
			 freqmul = tonumber(m.bgm.freqmul), 
			 loopcount = tonumber(m.bgm.loopcount)
	})
	
	bgReset(motif.coloreditbgdef.BGDef)
	main.f_fadeReset('fadein', m)
	
	-- Init color edit vals
	local ref = start.p[1].t_selected[1].ref
	local pal = start.p[1].t_selected[1].pal
	local def = start.f_getCharData(ref).def
	local air = util.getDefPath(def, "anim")
	local sff = util.getDefPath(def, "sprite")
	local sffVer = util.sffVersion(sff)
	local selectMode = 1
	local selectModeCooldown = 0
	local selectColorData = {}
	local changed = false
	local sprite = sffNew(sff, true)
	local animtable = loadAnimTable(air, sprite)
	
	sffCacheDelete(sff)
	
	local idle = 0
	local anims = {}
	for k,v in pairs(animtable) do
		if not isExcluded(k) then
			table.insert(anims, v)
		end
		if k == 0 then
			idle = #anims
		end
	end
	
	local palDisplay = {}
	local displayRect = {}

	-- cell (x, y), slider, anim, warning, delete
	local cursorPos = {1,2,1,idle,2,2}
	
	local function loadAnim(k)
		--local anim = animGetPreloadedCharData(ref, 0, -1, true)
		local anim = animNewWithPalette(sprite, anims[k], ref, pal)
		util.updateMotifAnim(anim, m.preview)
		local charData = start.f_getCharData(start.f_getCharRef(def))
		animSetScale(anim,
			m.preview.scale[1] * (320 / charData.localcoord),
			m.preview.scale[2] * (320 / charData.localcoord)
		)
		--animDebug(anim)
		return anim
	end
	
	local function copyPalData(anim, pal, tbl, depth)
		for i = 1, depth do
			animPaletteSet(anim, pal, {[i] = {
				tbl[i][1],
				tbl[i][2],
				tbl[i][3],
				tbl[i][4]}
			})
		end
	end

	local anim = loadAnim(cursorPos[4])
	
	animUpdate(anim)
	
	local colorTable = animPaletteGet(anim, pal)
	
	local cols = m.cell.columns
	local rows = math.ceil(#colorTable / cols)
	
	for y = 1, rows do
		palDisplay[y] = {}
		for x = 1, cols do
			palDisplay[y][x] = util.rectNew()
		end
	end
	for _, k in pairs(rects) do
		displayRect[k] = util.rectNew()
	end

	-- Check if act exists, if not then make a new act
	-- with the color data of the chosen palette and
	-- write an entry to the def file containing the
	-- path to the act file.
	-- Unfortunately due to pure lua restrictions, I
	-- cannot customize the custom color path unless I
	-- branch based on OS and I don't wanna do that. fuck
	local act = util.getDefPath(def, "pal" .. tostring(pal))
	if act == nil then
		util.writeDefEntry(def, "Files", "pal" .. tostring(pal), "color" .. tostring(pal) .. ".act")
		act = util.getDefPath(def, "pal" .. tostring(pal))
		util.saveActFile(act, colorTable, #colorTable)
	end
	
	local backup = act .. ".bak"
	
	-- Create backup files
	if m.backupfiles and act and main.f_fileExists(act .. ".bak") == false then
		util.createBackupFile(act)
	end
	
	local saveTextTimer = 0
	local deletedTextTimer = 0
	
	-- MAIN LOOP
	while true do
		-- Cursor index vals
		local idx = (((cursorPos[1] - 1) * cols) + cursorPos[2]) - 1
		animSetPos(anim,
			m.pos[1] + m.preview.offset[1],
			m.pos[2] + m.preview.offset[2])
		
		-- Menu logic
		if main.close and not main.fadeActive then
			bgReset(motif[main.background].BGDef)
			main.f_fadeReset("fadein", motif[main.group])
			playBgm({source = "motif.title"})
			main.close = false
			break
		elseif selectMode == 1 and (getInput(-1, {"m"}) or esc()) then
			if changed == true then 
				sndPlay(motif.Snd, m.done.snd[1], m.done.snd[2])
				selectMode = 0
				cursorPos[5] = 2
			else
				selectMode = 3
				sndPlay(motif.Snd, m.cancel.snd[1], m.cancel.snd[2])
				main.f_fadeReset("fadeout", m)
				playBgm({source = "motif.title", interrupt = true})
				main.close = true
			end
		elseif selectMode == 0 then
			if getInput(-1, m.warning.confirm.key) then
				if cursorPos[5] == 1 then 
					sndPlay(motif.Snd, m.cancel.snd[1], m.cancel.snd[2])
					main.f_fadeReset("fadeout", m)
					playBgm({source = "motif.title", interrupt = true})
					main.close = true
					selectMode = 3
				else 
					sndPlay(motif.Snd, m.cancel.snd[1], m.cancel.snd[2])
					selectMode = 1
				end
			elseif getInput(-1, m.warning.switch.key) then
				sndPlay(motif.Snd, m.move.snd[1], m.move.snd[2])
				cursorPos[5] = (cursorPos[5] == 1) and 2 or 1
			end
		else
			-- Color picking
			if selectMode == 1 then
				if getInput(-1, m.cell.cursor.down.key) then
					sndPlay(motif.Snd, m.move.snd[1], m.move.snd[2])
					cursorPos[1] = (cursorPos[1] == rows) and 1 or (cursorPos[1] + 1)
				end
				if getInput(-1, m.cell.cursor.up.key) then
					sndPlay(motif.Snd, m.move.snd[1], m.move.snd[2])
					cursorPos[1] = (cursorPos[1] == 1) and rows or (cursorPos[1] - 1)
				end
				if getInput(-1, m.cell.cursor.fwd.key) then
					sndPlay(motif.Snd, m.move.snd[1], m.move.snd[2])
        			cursorPos[2] = (cursorPos[2] == cols + 1) and 2 or (cursorPos[2] + 1)
				end
				if getInput(-1, m.cell.cursor.back.key) then
					sndPlay(motif.Snd, m.move.snd[1], m.move.snd[2])
        			cursorPos[2] = (cursorPos[2] == 2) and (cols + 1) or (cursorPos[2] - 1)
				end
				if getInput(-1, m.save.key) then
					util.saveActFile(act, colorTable, #colorTable)
					saveTextTimer = m.save.time
					deletedTextTimer = 0
					sffCacheDelete(sff)
					colorEditedFlag = true
					changed = false
					sndPlay(motif.Snd, m.done.snd[1], m.done.snd[2])
				elseif getInput(-1, m.delete.key) and main.f_fileExists(backup) then
					saveTextTimer = 0
					selectMode = 0.5
					sndPlay(motif.Snd, m.done.snd[1], m.done.snd[2])
				end
				if getInput(-1, m.preview.prev.key) then
					cursorPos[4] = cursorPos[4] - 1
					if cursorPos[4] < 1 then
						cursorPos[4] = #anims
					end
					sndPlay(motif.Snd, m.move.snd[1], m.move.snd[2])
					anim = loadAnim(cursorPos[4])
					copyPalData(anim, pal, colorTable, #colorTable)
				end
				if getInput(-1,m.preview.next.key) then
					cursorPos[4] = cursorPos[4] + 1
					if cursorPos[4] > #anims then
						cursorPos[4] = 1
					end
					sndPlay(motif.Snd, m.move.snd[1], m.move.snd[2])
					anim = loadAnim(cursorPos[4])
					copyPalData(anim, pal, colorTable, #colorTable)
				end
			-- Color editing
			elseif selectMode == 2 then
				local rgba = {colorTable[idx][1], colorTable[idx][2], colorTable[idx][3], colorTable[idx][4]}
				
				if getInput(-1, m.cell.cancel.key) then
					sndPlay(motif.Snd, m.cancel.snd[1], m.cancel.snd[2])
					
					animPaletteSet(anim, pal, {[idx] = {
						selectColorData[1],
						selectColorData[2],
						selectColorData[3],
						selectColorData[4]}
					})
					
					colorTable = animPaletteGet(anim, pal)
				end
				
				local tIncrease = getInputTime(-1, m.slider.increase.key)
				local tDecrease = getInputTime(-1, m.slider.decrease.key)

				if tIncrease > 0 or tDecrease > 0 then
					local activeTime = math.max(tIncrease, tDecrease)
					speed = util.clamp(1, math.ceil((activeTime ^ 2) * 0.001), 20)
				else
					speed = 0
				end

				local function updateColor()
					animPaletteSet(anim, pal, {[idx] = {rgba[1], rgba[2], rgba[3], rgba[4]}})
					colorTable = animPaletteGet(anim, pal)
					changed = true
				end

				if tDecrease > 0 and colorTable[idx][cursorPos[3]] > 0 then
					if tDecrease == 1 or (tDecrease > 10 and tDecrease % 2 == 0) then
						local val = rgba[cursorPos[3]] - (tDecrease > 10 and speed or 1)
						rgba[cursorPos[3]] = math.max(0, val)
						updateColor()
					end
				end

				if tIncrease > 0 and colorTable[idx][cursorPos[3]] < 255 then
					if tIncrease == 1 or (tIncrease > 10 and tIncrease % 2 == 0) then
						local val = rgba[cursorPos[3]] + (tIncrease > 10 and speed or 1)
						rgba[cursorPos[3]] = math.min(255, val)
						updateColor()
					end
				end

				if getInput(-1, m.slider.next.key) then
					sndPlay(motif.Snd, m.move.snd[1], m.move.snd[2])
					cursorPos[3] = (cursorPos[3] == 4) and 1 or (cursorPos[3] + 1)
				elseif getInput(-1, m.slider.prev.key) then
					sndPlay(motif.Snd, m.move.snd[1], m.move.snd[2])
					cursorPos[3] = (cursorPos[3] == 1) and 4 or (cursorPos[3] - 1)
				end
			-- Delete backup
			elseif selectMode == 0.5 then
				if getInput(-1, m.warning.confirm.key) then
					if cursorPos[6] == 1 then
						if os.remove(backup) then
							deletedTextTimer = m.deleted.time
						end
						sndPlay(motif.Snd, m.done.snd[1], m.done.snd[2])
					else
						sndPlay(motif.Snd, m.cancel.snd[1], m.cancel.snd[2])
					end
					selectMode = 1
				end
				if getInput(-1, m.warning.switch.key) then
					sndPlay(motif.Snd, m.move.snd[1], m.move.snd[2])
					cursorPos[6] = (cursorPos[6] == 1) and 2 or 1
				end
			end
		end
		
		-- Change select states
		if selectModeCooldown == 0 and selectMode ~= 0 then
			if selectMode == 1 and getInput(-1, m.cell.select.key) then
				-- Save color table rgba for undo
				selectColorData = {
					colorTable[idx][1],
					colorTable[idx][2],
					colorTable[idx][3],
					colorTable[idx][4]
				}
				selectMode = 2
				selectModeCooldown = 15
				sndPlay(motif.Snd, m.done.snd[1], m.done.snd[2])
			elseif getInput(-1, m.cell.confirm.key) then
				selectMode = 1
				selectModeCooldown = 15
				sndPlay(motif.Snd, m.cancel.snd[1], m.cancel.snd[2])
			end
		end
		
		-- Timer decrements
		if selectModeCooldown > 0 then
			selectModeCooldown = selectModeCooldown - 1
		end

		if saveTextTimer > 0 then
			saveTextTimer = saveTextTimer - 1
		end
		
		if deletedTextTimer > 0 then
			deletedTextTimer = deletedTextTimer - 1
		end
		
		-- Color cell logic
		for x = 1, cols do
			local idx = ((cursorPos[1] - 1) * cols) + x
			local rgba = colorTable[idx]
			local xPos = m.pos[1] + m.cell.offset[1] + ((x - 1) * m.cell.size[1])
			local yPos = m.pos[2] + m.cell.offset[2]
			local r, g, b, a = rgba[1], rgba[2], rgba[3], rgba[4]
				
			if (x + 1) == cursorPos[2] then
				if selectMode == 1 then
					r = util.clamp(0, r + 0x40, 255)
					g = util.clamp(0, g + 0x40, 255)
					b = util.clamp(0, b + 0x40, 255)
				end
				animSetPos(aCursorBg,
					xPos + m.cell.cursor.offset[1],
					yPos + m.cell.cursor.offset[2]
				)
			end
				
			rectSetColor(palDisplay[cursorPos[1]][x], r, g, b)
			rectSetAlpha(palDisplay[cursorPos[1]][x], a, 255 - a)
			rectSetWindow(palDisplay[cursorPos[1]][x],
				xPos,
				yPos,
				xPos + m.cell.size[1],
				yPos + m.cell.size[2])
			rectUpdate(palDisplay[cursorPos[1]][x])
		end
		
		-- Color slider/preview logic
		for i, name in pairs(rects) do
			local value = colorTable[idx][i]
			
			local sliderSize = 1
			if name ~= "prev" then
				sliderSize = value / 255
			end
			
			local xPos = m.pos[1] + m.slider[name].offset[1]
			local yPos = m.pos[2] + m.slider[name].offset[2]
			rectSetWindow(displayRect[name],
				xPos, 
				yPos, 
				xPos + m.slider[name].size[1], 
				yPos - (m.slider[name].size[2] * sliderSize))
			
			if i == cursorPos[3] then
				animSetPos(aSliderBg,
					xPos + m.slider.cursor.offset[1],
					yPos + m.slider.cursor.offset[2])
			end
			
			local text = tsSliderDisplay[name]
			if text then
				textImgSetText(text, string.format("%d", value))
				textImgSetPos(text,
					xPos + m.slider[name].display.offset[1],
					(yPos + m.slider[name].display.offset[2])
					-- attach to slider
					+ (m.slider[name].size[2] * (1.0 - sliderSize))
				)
			end
			
			if name ~= "prev" then		
				rectSetColor(displayRect[name],
					util.clamp(0, m.slider[name].col[1], 255),
					util.clamp(0, m.slider[name].col[2], 255),
					util.clamp(0, m.slider[name].col[3], 255))
			else
				rectSetColor(displayRect[name],
					colorTable[idx][1],
					colorTable[idx][2],
					colorTable[idx][3])
				rectSetAlpha(displayRect[name],
					colorTable[idx][4],
					255 - colorTable[idx][4])
			end
			
			if name == "a" then
				rectSetAlpha(displayRect[name],
					util.clamp(0, m.slider[name].alpha[1], 255),
					util.clamp(0, m.slider[name].alpha[2], 255))
			end
			rectUpdate(displayRect[name], 0)
		end
		
		-- Render
		
		clearColor(motif.coloreditbgdef.bgclearcolor[1], motif.coloreditbgdef.bgclearcolor[2], motif.coloreditbgdef.bgclearcolor[3])
		bgDraw(motif.coloreditbgdef.BGDef, 0)
		
		animUpdate(anim)
		animDraw(anim, 0)
		
		for x = 1, cols do
			rectDraw(palDisplay[cursorPos[1]][x], 0)
		end
		for _, v in pairs(displayRect) do
			rectDraw(v, 0)
		end
		
		animUpdate(aCursorBg)
		animDraw(aCursorBg)
		
		if selectMode == 2 then
			animUpdate(aSliderBg)
			animDraw(aSliderBg)
		end
		
		for _, v in pairs(tsSliderDisplay) do
			textImgDraw(v)
		end
		
		bgDraw(motif.coloreditbgdef.BGDef, 1)
		
		-- Title
		textImgDraw(tsTitle)
		
		-- Save
		if saveTextTimer > 0 then
			textImgSetText(tsSave, string.format(m.save.text, pal))
			textImgDraw(tsSave)
		end
		
		-- Deleted
		if deletedTextTimer > 0 then
			textImgSetText(tsDeleted, string.format(m.deleted.text, pal))
			textImgDraw(tsDeleted)
		end
		
		local function loopWarnings(tbl, idx, txt)
			for _, v in pairs(tbl) do
				local drawFlag = true
				
				if (v == "yes.active" and cursorPos[idx] == 2)
				or (v == "no.active" and cursorPos[idx] == 1)
				or (v == "yes" and cursorPos[idx] == 1)
				or (v == "no" and cursorPos[idx] == 2) then
					drawFlag = false
				end
				
				if drawFlag then
					textImgDraw(txt[v])
				end
			end
		end
		
		-- Delete
		if selectMode == 0.5 then
			loopWarnings(delete, 6, tsDelete)
		end
		
		-- Warning
		if selectMode == 0 and changed == true then
			loopWarnings(warnings, 5, tsWarning)
		end
		
		main.f_fadeAnim(m)
		-- if main.fadeActive or main.fadeCnt > 0 or main.fadeType == 'fadeout' then
		-- 	main.f_cmdBufReset()
		-- end
		refresh()
	end
end

-- Modified default script functions

function start.loadPalettes(a, ref, pal, bypass)
	if bypass or colorEditedFlag or (not ifCharPalsLoaded(ref)) then
		animLoadPalettes(a, ref)
	end
	local srcAnim = a
	a = animPrepare(a, ref)
	animApplyVel(a, srcAnim)
	a = changeColorPalette(a, pal)
	return a
end

function ifCharPalsLoaded(ref)
	for _, v in ipairs(LoadedPals) do
		if v == ref then
			return true
		end
	end
	table.insert(LoadedPals, ref)
	return false
end

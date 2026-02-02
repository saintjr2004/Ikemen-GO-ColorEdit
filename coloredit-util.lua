-- IKEMEN Color Editor Module by jay_ts & m14
-- Utility

local t = {}

-- QOL

function t.clamp(lo, val, hi)
    if val < lo then return lo end
    if val > hi then return hi end
    return val
end

function t.backwards(_t)
	return function(t2, i)
		i=i-1
		if i~=0 then
			return i, t2[i]
		end
	end, _t, #_t+1
end

function t.normpath(path)
	local components = {}
	for comp in path:gmatch("([^/\\]+)") do
		table.insert(components, comp)
	end
	for k,v in t.backwards(components) do
		if v == "." then
			table.remove(components, k)
		end
	end
	for k,v in t.backwards(components) do
		if v == ".." then
			table.remove(components, k)
			table.remove(components, k-1)
		end
	end
	return table.concat(components, "/")
end

-- I/O

function t.readBytes(file,b)
	local bytes = file:read(b)
	local j = 0
	
	for i = b, 1, -1 do
		j = j * 256 + bytes:byte(i)
	end
	
	return j
end

function t.writeDefEntry(def, section, key, value)
	local lines = {}
	local file = io.open(def, "r")

	if not file then
		print("Cannot open file: " .. def)
		return nil
	end

	local inSection = false
	local keyWritten = false

	for line in file:lines() do
		local header = line:match("^%[(.-)%]$")

		if header then
			if inSection and not keyWritten then
				table.insert(lines, key .. " = " .. value)
				key_written = true
			end
			inSection = (header == section)
		end

		if inSection and line:match("^%s*" .. key .. "%s*=") then
			line = key .. " = " .. value
			keyWritten = true
		end

		table.insert(lines, line)
	end

	file:close()

	if inSection and not keyWritten then
		table.insert(lines, key .. " = " .. value)
	end

	file = io.open(def, "w")
	for _, l in ipairs(lines) do
		file:write(l, "\n")
	end
	file:close()

	return true
end

function t.createBackupFile(file)
	local f = io.open(file, "rb")
	if not f then 
		print("Cannot open file: " .. file)
		return nil
	end
	local data = f:read("*a")
	f:close()
	
	local copy = io.open(file .. ".bak", "wb")
	if not copy then
		print("Cannot open file: " .. file .. ".bak")
		return nil
	end
	copy:write(data)
	copy:close()
end

function t.saveActFile(act, tbl)
	local f = io.open(act, "wb")
	
	for i = 256, 1, -1 do
		f:write(string.char(tbl[i][1]))
		f:write(string.char(tbl[i][2]))
		f:write(string.char(tbl[i][3]))
	end
	
	f:close()
end

function t.saveSffFile(sff, pal, tbl)
	local f = io.open(sff, "rb+")
	if not f then
		print("Cannot open file: " .. sff)
		return nil
	end

	f:seek("set", 0x34)
	local ldataOffset = t.readBytes(f, 4)

	f:seek("set", 0x2C)
	local firstPalNode = t.readBytes(f, 4)
	
	f:seek("set", firstPalNode + ((pal - 1) * 0x10) + 8)
	
	local ldataOffsetAdd = t.readBytes(f, 4)

	f:seek("set", ldataOffset + ldataOffsetAdd)
	
	for k, v in pairs(tbl) do
		f:write(string.char(v[1], v[2], v[3], v[4]))
	end
	
	f:close()
	
	return true
end

function t.sffVersion(sff)
	local f = io.open(sff, "rb")
	if not f then
		print("Cannot open file: " .. sff)
		return nil
	end

	local version = {}
	
	f:seek("set", 15)
	version[1] = string.byte(f:read(1))
	f:seek("set", 13)
	version[2] = string.byte(f:read(1))
	
	f:close()
	
	return version
end

function t.getDefPath(def, filetype)
	local f = io.open(def, "r")
	if not f then
		print("Could not open file")
		return nil
	end

	local path = ""
	
	for line in f:lines() do
		path = line:match("^%s*" .. filetype .. "%s*=%s*([%w%p]+)")
		if path then
			break
		end
	end
	
	f:close()
	if not path then return nil end
	return t.normpath(def .. "/../".. path)
end

-- Motif

function t.loadMotifExtensions(default, path)
	local t_base = loadIni(default)

	for k,_ in pairs(t_base) do
		if motif[k] == nil then motif[k] = t_base[k] end
		motif[k] = main.f_tableMerge(t_base[k], motif[k])
	end

	local extension_path = t.normpath(path)

	local extension = loadIni(extension_path)

	for k,_ in pairs(extension) do
		local locale = extension[gameOption("Config.Language"):lower() .. "." .. k]
		if locale then
			extension[k] = main.f_tableMerge(extension[k], locale)
		end
	end

	for k, v in pairs(extension) do
		motif[k] = motif[k] or {}
		motif[k] = main.f_tableMerge(motif[k], v)
		local bgdef = k:lower():match("(.*)def")
		local ref = motif[k]
		if bgdef then
			if not ref["Sff"] then
				if type(ref["spr"]) == "string" and t.fileExists(ref["spr"]) then
					ref["Sff"] = sffNew(ref["spr"])
				else
					ref["Sff"] = motif.Sff
				end
			end
			if not ref["BGDef"] then
				ref["BGDef"] = bgNew(
					motif.Sff,
					extension_path,
					bgdef,
					nil
				)
			end
		end
	end

	return extension
end

function t.loadMotifAnim(section)
	local data = "-1,0, 0,0, -1"
	local anim

	if section.spr then
		local group, item = section.spr[1], section.spr[2]
		group = group or -1
		item = item or 0
		data = string.format("%s,%s, 0,0, -1", group, item)
	end
	if section.anim then
		local action = tonumber(section.anim)
		if action then
			if motif.AnimTable[action] then
				-- thanks k4thos for adding this for me :)
				action = motif.AnimTable[action]
				data = action or data
			end
		end
	end

	anim = animNew(motif.Sff, data)
	t.updateMotifAnim(anim, section)
	return anim
end

function t.updateMotifAnim(anim, section)
	local pair
	pair = section.scale or {1.0, 1.0}
	animSetScale(anim, pair[1], pair[2])
	animSetLocalcoord(anim, motif.info.localcoord[1], motif.info.localcoord[2])
	animSetFacing(anim, section.facing or 0)
	animSetAngle(anim, section.angle or 0)
	animSetXAngle(anim, section.xangle or 0)
	animSetYAngle(anim, section.yangle or 0)
	animSetLayerno(anim, section.layerno or 0)
	pair = section.window or {0, 0, motif.info.localcoord[1], motif.info.localcoord[2]}
	animSetWindow(anim, pair[1], pair[2], pair[3], pair[4])
	animSetFocalLength(anim, section.focallength or 2048)
	animSetProjection(anim, section.projection or "orthographic")
	return anim
end

function t.loadMotifFont(section)
	local text = textImgNew()
	t.updateMotifFont(text, section)
	return text
end

function t.updateMotifFont(text, section)
	local pair
	local font
	pair = section.font or {-1, 0, 0, 255, 255, 255, -1}
	font = pair[1] or -1
	font = motif.Fnt[tonumber(font)]
	if font then
		textImgSetFont(text, font)
	end
	textImgSetBank(text, pair[2] or 0)
	textImgSetAlign(text, pair[3] or 0)
	textImgSetColor(text,
		pair[4] or 255,
		pair[5] or 255,
		pair[6] or 255)
	local concat = section.text
	if type(concat) == "table" then
		concat = table.concat(concat, ", ")
	end
	textImgSetText(text, concat or "")
	textImgSetLocalcoord(text, motif.info.localcoord[1], motif.info.localcoord[2])
	pair = section.offset or {0, 0}
	textImgSetPos(text,
		pair[1] or 0,
		pair[2] or 0)
	pair = section.scale or {1, 1}
	textImgSetScale(text,
		pair[1] or 1,
		pair[2] or 1)
	textImgSetAngle(text, section.angle or 0)
	textImgSetXShear(text, section.xshear or 0)
	textImgSetProjection(text, section.projection or "orthographic")
	textImgSetFocalLength(text, section.focallength or 2048)
	pair = section.window or {0, 0, motif.info.localcoord[1], motif.info.localcoord[2]}
	textImgSetWindow(text,
		pair[1] or 0,
		pair[2] or 0,
		pair[3] or motif.info.localcoord[1],
		pair[4] or motif.info.localcoord[2])
	return text
end

function t.rectNew()
	local rect = rectNew()
	rectSetLocalcoord(rect, motif.info.localcoord[1], motif.info.localcoord[2])
	return rect
end

-- chinese mario

return t
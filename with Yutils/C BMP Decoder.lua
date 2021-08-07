--[[
README:

]]

--Script properties
script_name="C BMP Decoder"
script_description="BMP Decoder v1.0"
script_author="chaaaaang"
script_version="1.0"

local Yutils = require('Yutils')
include('karaskel.lua')
clipboard = require 'aegisub.clipboard'
util = require 'aegisub.util'

local dialog_config = {
	{class="label",label="",x=0,y=0,width=4},--1
	{class="checkbox",name="rel",label="relative",value=true,x=2,y=1},--2
	{class="intedit",name="relative",value=1,x=3,y=1},--3

	{class="checkbox",name="x",label="x",value=true,x=0,y=1},
	{class="checkbox",name="y",label="y",value=true,x=1,y=1},
	{class="checkbox",name="s",label="scale",x=0,y=2,width=2},
	{class="checkbox",name="r",label="rotation",x=0,y=3,width=2}
}
local buttons = {"Run","Quit"}

function mocha(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)
	local xres, yres, ar, artype = aegisub.video_size()

	local d0
	for i=1,1000 do
		if subtitle[i].class=="dialogue" then
			d0 = i
			break
		end
	end
	local MOCHA_DATA = clipboard.get()

	local count,trigger = 0,0
	if MOCHA_DATA~=nil then
		for i in MOCHA_DATA:gmatch("(.-)\n") do
			if i:match("Scale")~=nil or i=="End of Keyframe Data" then break end
			if trigger==1 then
				count = count + 1
			end
			if i:match("Position")~=nil then trigger=1 end
		end
		count = count - 2
	end

	dialog_config[3].value = selected[1]-d0+1
	dialog_config[1].label = "line count: "..#selected..", mocha count: "..count

	local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if pressed=="Quit" then aegisub.cancel() 
	elseif pressed=="Run" then
		if count ~= #selected then aegisub.cancel() end

		local relative = result.relative + d0 - selected[1]

		local line_template = subtitle[result.relative+d0-1]
		local template = line_template.text
		template = template:gsub("\\fsc([%d%.%-]+)","\\fscx%1\\fscy%1")

		-- table
		local POS_DATA,SCALE_DATA,ROTATION_DATA = {},{},{}
		for i in MOCHA_DATA:gmatch("(.-)\n") do
			if i=="End of Keyframe Data" then break end
			if trigger==1 then
				local temp1,temp2 = i:match("%d+\t([%d%.%-]+)\t([%d%.%-]+)")
				if temp1~=nil then
					temp1,temp2 = tonumber(temp1),tonumber(temp2)
					table.insert(POS_DATA,{x=temp1,y=temp2})
				end
			elseif trigger==2 then
				local temp1 = i:match("%d+\t([%d%.%-]+)")
				if temp1~=nil then
					temp1 = tonumber(temp1)
					table.insert(SCALE_DATA,temp1)
				end
			elseif trigger==3 then
				local temp1 = i:match("%d+\t([%d%.%-]+)")
				if temp1~=nil then
					temp1 = tonumber(temp1)
					table.insert(ROTATION_DATA,temp1)
				end
			end

			if i:match("Position")~=nil then trigger=1 
			elseif i:match("Scale")~=nil then trigger=2 
			elseif i:match("Rotation")~=nil then trigger=3 end
		end

		for si,li in ipairs(selected) do
			local line = subtitle[li]
			local linetext = template
			if result.x==true then
				linetext = linetext:gsub("\\pos%(([^,]+)",function (a) return "\\pos("..a + POS_DATA[si].x-POS_DATA[relative].x end)
				linetext = linetext:gsub("\\org%(([^,]+)",function (a) return "\\org("..a + POS_DATA[si].x-POS_DATA[relative].x end)
			end
			if result.y==true then
				linetext = linetext:gsub("(\\pos%([%d%.%-]+,)([%d%.%-]+)",function (a,b) return a..b + POS_DATA[si].y-POS_DATA[relative].y end)
				linetext = linetext:gsub("(\\org%([%d%.%-]+,)([%d%.%-]+)",function (a,b) return a..b + POS_DATA[si].y-POS_DATA[relative].y end)
			end
			if result.s==true then
				linetext = linetext:gsub("\\fscx100\\fscy100","\\fsc1")
				linetext = linetext.."{"
				local temp = ""
				for p,i in linetext:gmatch("({[^}]*})([^{]*)") do
					local mul = tostring(SCALE_DATA[si]/SCALE_DATA[relative])
					mul = string.format("%.2f",mul)
					mul = tonumber(mul)
					i = i:gsub("([%d%.%-]+)",function (a) 
						a = tonumber(a)
						return string.format("%.2f",a*mul*100) end)
					temp = temp..p..i
				end
				linetext = temp
			end
			
			line.text = linetext
			subtitle[li] = line
			aegisub.progress.set(si/#selected*100)
		end
	end

	aegisub.set_undo_point(script_name)
	return selected
end

function importer(subtitle,selected,active)
	
	local path = aegisub.dialog.open('BMP Decoder', '', '', 'BMP files (.bmp)|*.bmp|All Files (.)|.', false, true)

	for si,li in ipairs(selected) do
		
		local line=subtitle[li]
		line.text = "{\\an7\\pos(100,100)\\bord0\\shad0\\fscx100\\fscy100\\p1}"

		local BMP_READER = Yutils.decode.create_bmp_reader(path)
		local width,height = BMP_READER.width(),BMP_READER.height()

		local BMP_DATA = {} -- BMP_DATA[y][x]
		for i=1, height do
			BMP_DATA[i] = {}
		end

		local data_packed = BMP_READER.data_packed()
		local y,x = 1,1
		for sj,lj in ipairs(data_packed) do
			table.insert(BMP_DATA[y],lj)
			x = x + 1
			if x == width + 1 then
				y = y + 1
				x = 1
			end
			aegisub.progress.set(sj/#data_packed*50)
		end
		
		local scale = 1
		local l,r,t,b = 0,1,-1,0
		-- local l,r,t,b = -1*width/2,-1*width/2+1,height/2-1,height/2
		for i = height,1,-1 do
			for j = 1,width do
				local colorstring = util.ass_color(BMP_DATA[i][j].r, BMP_DATA[i][j].g, BMP_DATA[i][j].b)
				local alphastring = util.ass_alpha(255-BMP_DATA[i][j].a)
				line.text = line.text.."{\\c"..colorstring.."\\1a"..alphastring.."}"..string.format("m %d %d l %d %d %d %d %d %d",l*scale,b*scale,r*scale,b*scale,r*scale,t*scale,l*scale,t*scale)
			end
			l,r,t,b = l-width,r-width,t-1,b-1
			aegisub.progress.set(i/height*50+50)
		end

		line.text = line.text:gsub("}{","")
		subtitle[li]=line

		break
	end
	aegisub.set_undo_point(script_name)
	return selected
end

function strip(subtitle,selected,active)
	
	local path = aegisub.dialog.open('BMP Decoder', '', '', 'BMP files (.bmp)|*.bmp|All Files (.)|.', false, true)

	for si,li in ipairs(selected) do
		
		local line=subtitle[li]
		line.text = "{\\an7\\pos(100,100)\\bord0\\shad0\\fscx100\\fscy100\\p1}"
		line.comment = true
		subtitle[li] = line
		line.comment = false

		local BMP_READER = Yutils.decode.create_bmp_reader(path)
		local width,height = BMP_READER.width(),BMP_READER.height()

		local BMP_DATA = {} -- BMP_DATA[y][x]
		for i=1, height do
			BMP_DATA[i] = {}
		end

		local data_packed = BMP_READER.data_packed()
		local y,x = 1,1
		for sj,lj in ipairs(data_packed) do
			table.insert(BMP_DATA[y],lj)
			x = x + 1
			if x == width + 1 then
				y = y + 1
				x = 1
			end
			aegisub.progress.set(sj/#data_packed*50)
		end
		
		local scale = 1
		local l,r,t,b = 0,1,-1,0
		for i = height,1,-1 do
			subtitle.insert(li,line)
			local new_line = subtitle[li]
			for j = 1,width do
				local colorstring = util.ass_color(BMP_DATA[i][j].r, BMP_DATA[i][j].g, BMP_DATA[i][j].b)
				local alphastring = util.ass_alpha(255-BMP_DATA[i][j].a)
				new_line.text = new_line.text.."{\\c"..colorstring.."\\1a"..alphastring.."}"..string.format("m %d %d l %d %d %d %d %d %d",l*scale,b*scale,r*scale,b*scale,r*scale,t*scale,l*scale,t*scale)
			end
			l,r,t,b = l,r,t-1,b-1
			new_line.text = new_line.text:gsub("}{","")
			subtitle[li] = new_line
			
			aegisub.progress.set(i/height*50+50)
		end

		break
	end
	aegisub.set_undo_point(script_name)
	return selected
end

function block(subtitle,selected,active)
	
	local path = aegisub.dialog.open('BMP Decoder', '', '', 'BMP files (.bmp)|*.bmp|All Files (.)|.', false, true)

	for si,li in ipairs(selected) do
		
		local line=subtitle[li]
		line.text = "{\\an7\\pos(100,100)\\bord0\\shad0\\fscx100\\fscy100\\p1}"

		local BMP_READER = Yutils.decode.create_bmp_reader(path)
		local width,height = BMP_READER.width(),BMP_READER.height()

		local BMP_DATA = {} -- BMP_DATA[y][x]
		for i=1, height do
			BMP_DATA[i] = {}
		end

		local data_packed = BMP_READER.data_packed()
		local y,x = 1,1
		for sj,lj in ipairs(data_packed) do
			table.insert(BMP_DATA[y],lj)
			x = x + 1
			if x == width + 1 then
				y = y + 1
				x = 1
			end
			aegisub.progress.set(sj/#data_packed*50)
		end
		
		local scale = 1
		local l,r,t,b = 0,1,-1,0
		-- local l,r,t,b = -1*width/2,-1*width/2+1,height/2-1,height/2
		for j = 1,width do
			for i = height,1,-1 do
				local colorstring = util.ass_color(BMP_DATA[i][j].r, BMP_DATA[i][j].g, BMP_DATA[i][j].b)
				local alphastring = util.ass_alpha(255-BMP_DATA[i][j].a)
				line.text = line.text.."{\\c"..colorstring.."\\1a"..alphastring.."}"..string.format("m %d %d l %d %d %d %d %d %d",l*scale,b*scale,r*scale,b*scale,r*scale,t*scale,l*scale,t*scale)
				l,r,t,b = l-1,r-1,t-1,b-1
			end
			l,r,t,b = l+1,r+1,-1,0
			aegisub.progress.set(j/width*50+50)
		end

		line.text = line.text:gsub("}{","")
		subtitle[li]=line

		break
	end
	aegisub.set_undo_point(script_name)
	return selected
end
--Register macro (no validation function required)
--aegisub.register_macro(script_name.."/mocha",script_description,mocha)
aegisub.register_macro(script_name.."/importer",script_description,importer)
aegisub.register_macro(script_name.."/strip",script_description,strip)
aegisub.register_macro(script_name.."/block",script_description,block)


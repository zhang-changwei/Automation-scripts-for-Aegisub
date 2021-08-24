--[[
README:

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

get info: magick identify path1

get info: magick path1 -identify output.txt

corp: magick path1 -crop 100x50+100+20 +repage path2

rotate: magick path1 -fill rgba(255,255,255,255) -background rgba(0,0,0,0) -rotate "45>" path2 旋转方向相反 >: w>h

shrink edge: magick path1 -trim +repage path2

get info: ffprobe -i path1 -show_streams > otput.txt

]]

--Script properties
script_name="C Picture Tracker"
script_description="Picture Tracker v1.2"
script_author="chaaaaang"
script_version="1.2"

include("karaskel.lua")
clipboard = require 'aegisub.clipboard'

local dialog_config = {
	{class="label",label="",x=0,y=0,width=4},--1
	{class="label",label="reference frame",x=1,y=1},--2
	{class="intedit",name="f",value=1,x=2,y=1},--3
	{class="label",label="vertial shrink",x=1,y=2},--4
	{class="intedit",name="vs",value=0,x=2,y=2},--5
	{class="label",label="horizontal shrink",x=1,y=3},--6
	{class="intedit",name="hs",value=0,x=2,y=3},--7

	{class="checkbox",name="x",label="pos",value=true,x=0,y=1},
	{class="checkbox",name="s",label="scale",x=0,y=2},
	{class="checkbox",name="r",label="rotate",x=0,y=3},

	{class="label",label="effect",x=0,y=4},
	{class="dropdown",name="e",items={"none","paint, default: 5","spread, default: 5,5","swirl, default 360","custom command"},value="none",x=0,y=5,width=2},
	{class="dropdown",name="m",items={"gradient","random"},value="gradient",x=2,y=5},
	{class="edit",name="c",x=0,y=6,width=3,value="custom command:",hint="custom command: use input & output for file path, use \\d for argument"},
	{class="label",label="strength from/min",x=0,y=7,width=2},
	{class="edit",name="argf",x=2,y=7,hint="strength for preview, separate by comma"},
	{class="label",label="strength to/max",x=0,y=8,width=2},
	{class="edit",name="argt",x=2,y=8,hint="separate by comma"}
}
local buttons = {"Track","Preview","Quit"}

function main(subtitle,selected,active)
	local meta,styles=karaskel.collect_head(subtitle,false)
	-- first get png path
	local path = subtitle[active].text:match("\\1img%(([^,%)]+)")
	path = path:gsub("/","\\")
	local path_head = path:gsub("%.png","")

	-- read width & height
	local command1 = string.format('magick %s -format "%%wx%%h" info:',path)
	local file = io.popen(command1)
	local info = file:read()
	file:close()
	local width,height = info:match("(%d+)x(%d+)")
	width,height = tonumber(width),tonumber(height)
	local wlh = (width>=height) and ">" or "<"
	

	-- get mocha data
	local mochatext = clipboard.get()
	local count_m,trigger = 0,0
	local fps
	local posdata, scaledata, rotationdata = {},{},{}
	if mochatext~=nil then
		mochatext = mochatext.."\n"
		for i in mochatext:gmatch("(.-)\n") do
			if i=="End of Keyframe Data" then break end

			if i:match("Units Per Second") then 
				fps = i:match("[%d%.]+")
				fps = tonumber(fps)
			end

			if trigger==1 and i:match("%d")~=nil then 
				count_m = count_m + 1 
				local x,y = i:match("%d+\t([%d%.%-e]+)\t([%d%.%-e]+)")
				x,y = tonumber(x),tonumber(y)
				table.insert(posdata,{x=x,y=y})
			end
			if trigger==2 and i:match("%d")~=nil then 
				local x = i:match("%d+\t([%d%.%-e]+)")
				x = tonumber(x)
				table.insert(scaledata,x)
			end
			if trigger==3 and i:match("%d")~=nil then 
				local x = i:match("%d+\t([%d%.%-e]+)")
				x = tonumber(x)
				table.insert(rotationdata,x)
			end

			if i:match("Rotation")~=nil then trigger=3 end
			if i:match("Scale")~=nil then trigger=2 end
			if i:match("Position")~=nil then trigger=1 end
		end
	else
		count_m = 0 
	end
	if posdata=={} then 
		count_m = 0
	end

	-- get line info
	local frame_S,frame_E = aegisub.frame_from_ms(subtitle[active].start_time),aegisub.frame_from_ms(subtitle[active].end_time)-1
	local count_f = frame_E + 1 - frame_S

	--UI
	dialog_config[1].label = "expected frame count: "..count_f..", mocha frame count: "..count_m
	dialog_config[3].value = frame_S
	local pressed, result = aegisub.dialog.display(dialog_config,buttons)
	if pressed=="Quit" then aegisub.cancel()		
	elseif pressed=="Track" then 
		if count_f~=count_m then aegisub.cancel() end
		-- ref frame
		local line = subtitle[active]
		karaskel.preproc_line(subtitle,meta,styles,line)
		line.comment = true
		subtitle[active] = line
		line.comment = false
		local tag = line.text:match("^{[^}]*}")
		local align = (tag:match("\\an%d")~=nil) and tag:match("\\an(%d)") or line.styleref.align
		local posx,posy = tag:match("\\pos%(([%d%.%-]+),([%d%.%-]+)")
		local orgx,orgy = tag:match("\\org%(([%d%.%-]+),([%d%.%-]+)")
		local fin,fout =  tag:match("\\fad%(([%d%.%-]+),([%d%.%-]+)")
		if posx==nil then posx = line.x end
		if posy==nil then posy = line.y end
		align,posx,posy = tonumber(align),tonumber(posx),tonumber(posy)
		if orgx~=nil then orgx,orgy = tonumber(orgx),tonumber(orgy) end
		if fin~=nil then fin,fout = tonumber(fin),tonumber(fout) end
		tag = "{\\an"..align.."\\bord0\\shad0"
		local frame_ref = result.f-frame_S+1

		-- effect
		local argfs,argts = {},{}
		local command0
		if result.e~="none" then 
			if result.e=="paint, default: 5" then
				command0 = "-paint \\d "
			elseif result.e=="spread, default: 5,5" then
				command0 = "-blur \\d -spread \\d "
			elseif result.e=="swirl, default 360" then
				command0 = "-swirl \\d "
			elseif result.e=="custom command" then
				command0 = result.c:gsub("^ *magick +input +","")
				command0 = command0:gsub("output *$","")
			end

			-- args
			local argtext = result.argf..","
			for i in argtext:gmatch("([^,]+),") do
				i = tonumber(i)
				table.insert(argfs,i)
			end
			argtext = result.argt..","
			for i in argtext:gmatch("([^,]+),") do
				i = tonumber(i)
				table.insert(argts,i)
			end
		end

		-- write
		local j = active
		local index = 1
		for i=frame_S,frame_E do
			subtitle.insert(j,line)
			local l = subtitle[j]
			l.start_time = starttime(i,fps)
			l.end_time = endtime(i,fps)

			-- do the picture stuff
			local draw = ""
			local path_o = path_head.."_"..i..".png"
			local w,h = width,height
			local xdev, ydev = posx-posdata[frame_ref].x, posy-posdata[frame_ref].y

			-- scale & rotation
			if result.s==true or result.r==true then
				if result.s==true and result.r==true then
					command1 = string.format('magick %s -resize %f%% -fill rgba(255,255,255,255) -background rgba(0,0,0,0) -rotate "%f%s" +repage ',
						path, scaledata[index]/scaledata[frame_ref]*100, rotationdata[index]-rotationdata[frame_ref], wlh)
					xdev,ydev = xdev*scaledata[index]/scaledata[frame_ref],ydev*scaledata[index]/scaledata[frame_ref]
				elseif result.s==true then
					command1 = string.format('magick %s -resize %f%% ',
						path, scaledata[index]/scaledata[frame_ref]*100)
					xdev,ydev = xdev*scaledata[index]/scaledata[frame_ref],ydev*scaledata[index]/scaledata[frame_ref]
				else -- result.r==true
					command1 = string.format('magick %s -fill rgba(255,255,255,255) -background rgba(0,0,0,0) -rotate "%f%s" +repage ',
						path, rotationdata[index]-rotationdata[frame_ref], wlh)
				end

				-- effect
				if result.e~="none" then
					local command0copy = command0
					for k=1,#argfs do
						if result.m=="gradient" then 
							command0copy = command0copy:gsub("\\d", interpolate(argfs[k],argts[k],count_f,index,1),1)
						else 
							local argmin,argmax = math.min(argfs[k],argts[k]),math.max(argfs[k],argts[k])
							command0copy = command0copy:gsub("\\d", math.random()*(argmax-argmin)+argmin,1)
						end
					end
					command1 = command1.." "..command0copy
				end

				command1 =command1..path_o
				aegisub.log(command1.."\n")
				local command2 = string.format('magick %s -format "%%wx%%h" info:',path_o)
				os.execute(command1)
				file = io.popen(command2)
				info = file:read()
				file:close()
				w,h = info:match("(%d+)x(%d+)")
				w,h = tonumber(w),tonumber(h)
			else
				path_o = path

				-- effect
				if result.e~="none" then
					path_o = path_head.."_"..i..".png"
					local command0copy = command0
					for k=1,#argfs do
						if result.m=="gradient" then command0copy = command0copy:gsub("\\d", interpolate(argfs[k],argts[k],count_f,index),1)
						else 
							local argmin,argmax = math.min(argfs[k],argts[k]),math.max(argfs[k],argts[k])
							command0copy = command0copy:gsub("\\d", math.random()*(argmax-argmin)+argmin,1)
						end
					end
					command1 = 'magick '..path.." "..command0copy..path_o
					local command2 = string.format('magick %s -format "%%wx%%h" info:',path_o)
					os.execute(command1)
					file = io.popen(command2)
					info = file:read()
					file:close()
					w,h = info:match("(%d+)x(%d+)")
					w,h = tonumber(w),tonumber(h)
				end
			end

			-- position
			if result.x==true then 
				draw = draw..string.format("\\pos(%.3f,%.3f)",posdata[index].x+xdev,posdata[index].y+ydev)
			else
				draw = draw.."\\pos("..posx..","..posy..")"
			end
			
			-- org
			if orgx~=nil then
				if result.x==true then
					local orgxdev, orgydev = orgx-posdata[frame_ref].x, orgy-posdata[frame_ref].y
					if result.r==true then orgxdev,orgydev = orgxdev*scaledata[index]/scaledata[frame_ref],orgydev*scaledata[index]/scaledata[frame_ref] end
					draw = draw..string.format("\\org(%.3f,%.3f)",posdata[index].x+orgxdev,posdata[index].y+orgydev)
				else
					draw = draw.."\\org("..orgx..","..orgy..")"
				end
			end

			-- output
			draw = draw..string.format("\\fscx100\\fscy100\\frz0\\p1\\1img(%s)}m 0 0 l %d 0 l %d %d l 0 %d", path_o, w-result.hs, w-result.hs, h-result.vs, h-result.vs)
			l.text = tag..draw
			subtitle[j] = l
			aegisub.progress.set(index/count_f*100)
			j = j + 1
			index = index + 1
		end

		-- handle fad
		if fin~=nil then
			local time_U = 1000/fps
			if fin~=0 then
				local fs,fj = active,frame_S
				for fi=time_U/2,fin,time_U do
					local l = subtitle[fs]
					local fad = fbffad1(fi,fin,fj,fps)
					l.text = l.text:gsub("^{","{\\fad("..fad..",0)")
					subtitle[fs] = l
					fs = fs + 1
					fj = fj + 1
				end
			end
			if fout~=0 then
				local fs,fj = active+count_f-1,frame_E
				for fi=time_U/2,fout,time_U do
					local l = subtitle[fs]
					local fad = fbffad2(fi,fout,fj,fps)
					l.text = l.text:gsub("^{","{\\fad(0,"..fad..")")
					subtitle[fs] = l
					fs = fs - 1
					fj = fj - 1
				end
			end
		end
	elseif pressed=="Preview" then
		local command0
		if result.e=="none" then aegisub.cancel() 
		elseif result.e=="paint, default: 5" then
			command0 = "magick input -paint \\d output"
		elseif result.e=="spread, default: 5,5" then
			command0 = "magick input -blur \\d -spread \\d output"
		elseif result.e=="swirl, default 360" then
			command0 = "magick input -swirl \\d output"
		elseif result.e=="custom command" then
			command0 = result.c
		end

		-- args
		local args = {}
		local argtext = result.argf..","
		for i in argtext:gmatch("([^,]+),") do
			i = tonumber(i)
			table.insert(args,i)
		end

		-- IM command
		local path_o = path_head.."_pre.png"
		command0 = command0:gsub("input",path)
		command0 = command0:gsub("output",path_o)
		for i=1,#args do
			command0 = command0:gsub("\\d",args[i],1)
		end
		command1 = string.format('magick %s -format "%%wx%%h" info:',path_o)
		os.execute(command0)
		file = io.popen(command1)
		info = file:read()
		file:close()
		width,height = info:match("(%d+)x(%d+)")
		width,height = tonumber(width),tonumber(height)

		-- output
		local line = subtitle[active]
		line.text = line.text:gsub("%.png","_pre.png")
		line.text = line.text:gsub("}.-$",string.format("}m 0 0 l %d 0 %d %d 0 %d",width,width,height,height))
		subtitle[active] = line
	end

	::bottom::
	aegisub.set_undo_point(script_name)
	return selected
end

function starttime(f,fps)
	return math.floor((f-0.5)*(1000/fps)/10)*10
end

function endtime(f,fps)
	return math.floor((f+0.5)*(1000/fps)/10)*10
end

function round(x)
	return math.floor(x+0.5)
end

function fbffad1(i,all,frame,fps)
	local t = round(frame*1000/fps-starttime(frame,fps))
	return round(t/(i/all)) -- t/x = i/all
end

function fbffad2(i,all,frame,fps)
	local t = round(endtime(frame,fps)-frame*1000/fps)
	return round(t/(i/all)) -- t/x = i/all
end

function interpolate(head,tail,N,i,accel)
    -- i 1-N
	if accel==nil then accel = 1 end
	local bias = (1/(N-1)*(i-1))^accel
    return (tail-head)*bias+head
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)

--[[
frosted
disperse
mottle
peelingpaint
pixelize
ripples
sketch
stainedglass
vintage

 -blur 5 -spread 5 毛玻璃
 -paint 5
 -swirl 180
 -charcoal 1
]]
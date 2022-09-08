--[[
]]

script_name="C XML Analyzer"
script_description="XML Analyzer v1.6"
script_author="chaaaaang"
script_version="1.6"

local xmlsimple = require("xmlSimple").newParser()
local clipboard = require("aegisub.clipboard")

-- ########### Frame #############

local function frame2starttime(frame,fps)
    local t = 1000/fps
    return math.floor((frame*t - t/2)/10)*10
end
local function frame2endtime(frame,fps)
    local t = 1000/fps
    return math.floor((frame*t + t/2)/10)*10
end
local function frame2NDF(f, fps)
    local FPS_U =math.ceil(fps)
    local hour,min,sec,frame = math.floor(f/FPS_U/3600),math.floor(f/FPS_U/60)%60,math.floor(f/FPS_U)%60,f%FPS_U
    return string.format("%02d:%02d:%02d:%02d", hour, min, sec, frame)
end

-- ########### NDF #############

local function NDF2frame(t,fps)
    local h,m,s,ms = t:match("(%d+):(%d%d):(%d%d):(%d%d)")
    h,m,s,ms = tonumber(h),tonumber(m),tonumber(s),tonumber(ms)
    return ms + s*math.ceil(fps) + m*60*math.ceil(fps) + h*3600*math.ceil(fps)
end
-- -> double
local function NDF2ms(t,fps)
    local f = NDF2frame(t, fps)
    return f*1000/fps
end
local function NDF2real(t,fps)
    local tinms = NDF2ms(t,fps)
    tinms = round(tinms)
    local h,m,s,ms = math.floor(tinms/1000/3600),math.floor(tinms/1000/60)%60,math.floor(tinms/1000)%60,tinms%1000
    return string.format("%d:%02d:%02d.%03d",h,m,s,ms)
end
local function NDF2starttime(t,fps)
    local f = NDF2frame(t,fps)
    return frame2starttime(f,fps)
end
local function NDF2endtime(t,fps)
    local f = NDF2frame(t,fps) - 1
    return frame2endtime(f,fps)
end

local function NDFadd(t1,t2,fps)
    f1 = NDF2frame(t1, fps)
    f2 = NDF2frame(t2, fps)
    f  = f1 + f2
    return frame2NDF(f, fps)
end
-- t1 - t2 -> NDF
local function NDFminus(t1,t2,fps)
    f1 = NDF2frame(t1, fps)
    f2 = NDF2frame(t2, fps)
    f  = f1 - f2
    return frame2NDF(f, fps)
end
-- a<b -> -1; a=b -> 0; a>b -> 1
local function NDFcompare(a,b)
    local t1 = a:gsub(":", "")
    local t2 = b:gsub(":", "")
    t1, t2 = tonumber(t1), tonumber(t2)
    if t1 < t2 then return -1
    elseif t1 > t2 then return 1
    else return 0
    end
end

-- ########### Real #############

local function Real2frame(t,fps)
    local h,m,s,ms = t:match("(%d+):(%d%d):(%d%d)%.(%d%d%d)")
    h,m,s,ms = tonumber(h),tonumber(m),tonumber(s),tonumber(ms)
    local f = (ms+s*1000+m*60*1000+h*3600*1000)/(1000/fps)
    return round(f)
end

local function Real2NDF(t,fps)
    local f = Real2frame(t, fps)
    local FPS_U =math.ceil(fps)
    local hour,min,sec,frame = math.floor(f/FPS_U/3600),math.floor(f/FPS_U/60)%60,math.floor(f/FPS_U)%60,f%FPS_U
    return string.format("%02d:%02d:%02d:%02d", hour, min, sec, frame)
end

local function Realadd(t1,t2)
    local h1,m1,s1,ms1 = t1:match("(%d+):(%d%d):(%d%d)%.(%d%d%d)")
    local h2,m2,s2,ms2 = t2:match("(%d+):(%d%d):(%d%d)%.(%d%d%d)")
    h1,m1,s1,ms1 = tonumber(h1),tonumber(m1),tonumber(s1),tonumber(ms1)
    h2,m2,s2,ms2 = tonumber(h2),tonumber(m2),tonumber(s2),tonumber(ms2)
    local temp1,temp2,temp3 = 0,0,0
    if ms1+ms2>=1000 then temp1=1 end
    ms1 = (ms1+ms2)%1000
    if s1+s2+temp1>=60 then temp2=1 end
    s1 = (s1+s2+temp1)%60
    if m1+m2+temp2>=60 then temp3=1 end
    m1 = (m1+m2+temp2)%60
    h1 = (h1+h2+temp3)
    return string.format("%d:%02d:%02d.%03d",h1,m1,s1,ms1)
end

local function Realminus(t1,t2)
    local h1,m1,s1,ms1 = t1:match("(%d+):(%d%d):(%d%d)%.(%d%d%d)")
    local h2,m2,s2,ms2 = t2:match("(%d+):(%d%d):(%d%d)%.(%d%d%d)")
    h1,m1,s1,ms1 = tonumber(h1),tonumber(m1),tonumber(s1),tonumber(ms1)
    h2,m2,s2,ms2 = tonumber(h2),tonumber(m2),tonumber(s2),tonumber(ms2)
    local temp1,temp2,temp3 = 0,0,0
    if ms1-ms2<0 then temp1=1 end
    ms1 = (ms1-ms2+1000)%1000
    if s1-s2-temp1<0 then temp2=1 end
    s1 = (s1-s2-temp1+60)%60
    if m1-m2-temp2<0 then temp3=1 end
    m1 = (m1-m2-temp2+60)%60
    h1 = (h1-h2-temp3)
    return string.format("%d:%02d:%02d.%03d",h1,m1,s1,ms1)
end

-- ########### Misc #############

local function fpsgen()
	local f = 10000
	if aegisub.ms_from_frame(f)==nil then return 23.976 end
	local t = (aegisub.ms_from_frame(f)+aegisub.ms_from_frame(f+1))/2
	local fps = f/t*1000
	return round(fps*1000)/1000
end

local function copyfile(source, destination, byte)
    local sourcefile, destinationfile
    if byte==true then
        sourcefile = io.open(source, "rb")
        destinationfile = io.open(destination, "wb")
    else
        sourcefile = io.open(source, "r")
        destinationfile = io.open(destination, "w")
    end
    destinationfile:write(sourcefile:read("*all"))
    sourcefile:close()
    destinationfile:close()
end

local function str2bool(str)
    if str=="true" then return true
    else return false end
end
local function bool2str(bool)
    if bool==true then return "true"
    else return "false" end
end

local function config_read_xml(dialog)
    local path = aegisub.decode_path("?user").."\\xmlanalyzer_config.xml"
    local file = io.open(path, "r")
    if file~=nil then
        file:close()
        local config = require("xmlSimple").newParser():loadFile(path)
        for si,li in ipairs(dialog) do
            for sj,lj in pairs(li) do
                if sj=="class" and lj~="label" then
                    local name = li.name
                    local item = config.Config[name]
                    if item["@Type"]=="boolean" then 
                        dialog[si].value = str2bool(item["@Value"])
                    elseif item["@Type"]=="number" then 
                        dialog[si].value = tonumber(item["@Value"])
                    elseif item["@Type"]=="string" then 
                        dialog[si].value = item["@Value"]
                    end
                    break
                end
            end
        end
    else
        return nil
    end
end
local function config_write_xml(result)
    local path = aegisub.decode_path("?user").."\\xmlanalyzer_config.xml"
    local file = io.open(path, "w")
    file:write('<?xml version="1.0" encoding="UTF-8"?>\n<Config>\n')
    for key,value in pairs(result) do
        if type(value)=="boolean" then 
            file:write(string.format('<%s Type="%s" Value="%s"/>\n', key, type(value), bool2str(value)))
        else
            file:write(string.format('<%s Type="%s" Value="%s"/>\n', key, type(value), value))
        end
    end
    file:write('</Config>')
    file:close()
end

-- ########### Main #############

function simulator(subtitle, selected, active)
	local path = aegisub.dialog.open('XML Analyzer', '', '', 'XML files (.xml)|*.xml|All Files (.)|.', false, true)
    local path_head = path:gsub("[^\\]*%.xml$","")
    local xml = xmlsimple:loadFile(path)
    local events = xml.BDN.Events
    local N = #subtitle + 1

    local event_count = #events.Event
    local fps = xml.BDN.Description.Format["@FrameRate"]
    fps = tonumber(fps)
    if fps==23.976 then fps=24000/1001 
    elseif fps==29.97 then fps=30000/1001 end

    local buffer_report = io.open(path_head.."buffer.txt", "w")

    local intc,outtc = nil,nil
    local silence1, silence2 = false, false
    local epoch_count = 0
    if events.Event[event_count]["@InTC"]=="00:00:00:00" then 
        epoch_count,event_count = 1,event_count-1 
        buffer_report:write("Epoch1, 207360, 49.4%%\n")
    end
    local count = 0 -- max: 64
    local buffer = 0 -- buffer: 4M
    local BUFFER_MAX = 4*1024*1024

    local line = subtitle[#subtitle]
    line.actor = "G"
    line.text  = ""
    line.comment = true

    local data = {}

    for i=1,event_count do
        local t_intc = events.Event[i]["@InTC"]
        local t_outtc = events.Event[i]["@OutTC"]

        -- new epoch (interval > 1 frame) first enter and update before get in the loop
        if outtc==nil or (t_intc~=outtc and NDFminus(t_intc,outtc,fps)~="00:00:00:01") then 
            if outtc~=nil then
                buffer_report:write(string.format("Epoch%d, %d, %.1f%%\n", epoch_count, buffer, buffer/BUFFER_MAX*100))
            end
            data = {} 
            silence1, silence2 = false, false
            count,buffer = 0,0
            epoch_count = epoch_count + 1
        end 
        intc,outtc = t_intc,t_outtc

        local graphics = events.Event[i].Graphic

        if #graphics>=2 then
            for k=1,#graphics do
                local trigger = true
                local tx,ty,tw,th = graphics[k]["@X"],graphics[k]["@Y"],graphics[k]["@Width"],graphics[k]["@Height"]
                tx,ty,tw,th = tonumber(tx),tonumber(ty),tonumber(tw),tonumber(th)

                for _,j in ipairs(data) do
                    if j.w==tw and j.h==th then trigger = false end
                end

                if trigger==true then 
                    table.insert(data,{w=tw,h=th})
                    count = count + 1
                    buffer = buffer + tw*th
                end
            end
            if #graphics>2 then 
                aegisub.log(t_intc..": more than two pictures in a timestamp\n")
            end
        else
            local trigger = true
            local tx,ty,tw,th = graphics["@X"],graphics["@Y"],graphics["@Width"],graphics["@Height"]
            tx,ty,tw,th = tonumber(tx),tonumber(ty),tonumber(tw),tonumber(th)

            for _,j in ipairs(data) do
                if j.w==tw and j.h==th then trigger = false end
            end
            if trigger==true then 
                table.insert(data,{w=tw,h=th})
                count = count + 1
                buffer = buffer + tw*th
            end
        end

        -- log out
        if silence1==false and count>64 then
            aegisub.log(t_intc..": is too close to the previous frame\n")
            silence1 = true
            line.start_time = NDF2ms(t_intc,fps)
            line.end_time = NDF2ms(t_intc,fps)
            line.actor = "G"..epoch_count
            line.text = "*** this Event will be discarded ***. The Time from InTC of previous Event to InTC is too close. and cannot register this Event with previous Epoch, by limitation of the number of different size images in a Epoch.  permitted number is 64."
            subtitle.append(line)
        end

        if silence2==false and buffer>BUFFER_MAX then
            aegisub.log(t_intc..": buffer overflow")
            silence2 = true
            line.start_time = NDF2ms(t_intc,fps)
            line.end_time = NDF2ms(t_intc,fps)
            line.actor = "G"..epoch_count
            line.text = 'buffer overflow.'
            subtitle.append(line)
        end

        -- last event break
        if i==event_count then
            buffer_report:write(string.format("Epoch%d, %d, %.1f%%\n", epoch_count, buffer, buffer/BUFFER_MAX*100))
            break
        end
        aegisub.progress.set(i/event_count*100)
    end

    buffer_report:close()
    aegisub.set_undo_point(script_name) 
    return selected 
end

function borderadder(subtitle, selected, active)
	local path = aegisub.dialog.open('XML Analyzer', '', '', 'XML files (.xml)|*.xml|All Files (.)|.', false, true)
    local xml = xmlsimple:loadFile(path)
    local events = xml.BDN.Events

    --UI
    local dialog_config = {
        {class="checkbox",name="b",label="basic",value=true,x=0,y=0},--1
        {class="checkbox",name="m",label="merge",value=false,x=0,y=1},--2
        {class="label",label="proportion threshold",x=1,y=1},--3
        {class="floatedit",name="mp",value=0.9,x=2,y=1},--4
        {class="checkbox",name="man",label="manual",value=false,x=0,y=2},--5
        {class="checkbox",name="r",label="remember",value=false,x=1,y=0}--6
    }
    local buttons = {"Run","Quit"}
    -- read config
    config_read_xml(dialog_config)
    -- show UI
    local pressed,result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end
    if result.r==true then config_write_xml(result) end
    -- manual
    local man_starttime,man_endtime = subtitle[selected[1]].start_time,subtitle[selected[1]].end_time
    for si,li in ipairs(selected) do
        man_starttime = math.min(man_starttime, subtitle[li].start_time)
        man_endtime   = math.max(man_endtime,   subtitle[li].end_time)
    end

    local event_count = #events.Event
    local fps = xml.BDN.Description.Format["@FrameRate"]
    fps = tonumber(fps)
    if fps==23.976 then fps=24000/1001 
    elseif fps==29.97 then fps=30000/1001 end

    local intc,outtc
    local epoch_intc,epoch_outtc
    local epoch_count = 0
    if events.Event[event_count]["@InTC"]=="00:00:00:00" then epoch_count,event_count = 1,event_count-1 end
    -- local x,y,h,w=1920,1080,0,0

    local line = subtitle[#subtitle]
    line.actor = "G"
    line.text  = ""
    line.comment = false

    local items = {}

    for i=1,event_count do
        local t_intc = events.Event[i]["@InTC"]
        local t_outtc = events.Event[i]["@OutTC"]

        -- new epoch
        if outtc==nil or (t_intc~=outtc and NDFminus(t_intc,outtc,fps)~="00:00:00:01") then 
            -- add border
            if result.b==true then 
                for _,j in ipairs(items) do
                    if #j>1 then
                        local trigger = 0
                        local l,t,r,b = 1921,1081,-1,-1
                        for __,k in ipairs(j) do
                            if l~=k.x or t~=k.y or r~=k.w+k.x or b~=k.h+k.y then trigger=trigger+1 end
                            l,t,r,b = math.min(l,k.x),math.min(t,k.y),math.max(r,k.w+k.x),math.max(b,k.h+k.y)
                        end
                        if trigger>=3 then
                            line.start_time = NDF2starttime(j[1].i,fps)
                            line.end_time   = NDF2endtime(j[#j].o,fps)
                            line.actor      = "G"..epoch_count
                            line.text = string.format("{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord1\\shad0\\1aFF\\3aFD\\p1}m %d %d l %d %d %d %d %d %d",
                                                      math.max(l,1), math.max(t,1), math.min(r,1919), math.max(t,1), math.min(r,1919), math.min(b,1079), math.max(l,1), math.min(b,1079))
                            subtitle.append(line)
                        end
                    end
                end 
            elseif result.m==true then
                local itemoutline = {}
                for _,j in ipairs(items) do
                    local trigger = 0
                    local l,t,r,b = 1921,1081,-1,-1
                    for __,k in ipairs(j) do
                        if l~=k.x or t~=k.y or r~=k.w+k.x or b~=k.h+k.y then trigger=trigger+1 end
                        l,t,r,b = math.min(l,k.x),math.min(t,k.y),math.max(r,k.w+k.x),math.max(b,k.h+k.y)
                    end
                    if trigger>=3 then trigger=true else trigger=false end
                    table.insert(itemoutline, {l=l,t=t,w=r-l,h=b-t,i=j[1].i,o=j[#j].o,trigger=trigger})
                end

                for nj,j in ipairs(itemoutline) do
                    for nk=nj+1,#itemoutline do
                        local k = itemoutline[nk]
                        local judge,l,t,r,b = square_overlap(j.l,j.t,j.w,j.h,k.l,k.t,k.w,k.h)
                        if judge==true then
                            local proportion = overlap_proportion(j.l,j.t,j.w,j.h,k.l,k.t,k.w,k.h)
                            if proportion>=result.mp then
                                j.l, j.t, j.w, j.h, j.trigger = l,t,r-l,b-t,true
                                k.l, k.t, k.w, k.h, k.trigger = l,t,r-l,b-t,true
                                itemoutline[nj],itemoutline[nk] = j,k
                            end
                        end
                    end
                end

                local nj = 1
                while nj<=#itemoutline-1 do
                    local nk=nj+1
                    if itemoutline[nj].trigger==true then
                        while nk<=#itemoutline do
                            if itemoutline[nk].trigger==true then
                                local j,k = itemoutline[nj],itemoutline[nk]
                                if j.l==k.l and j.t==k.t and j.w==k.w and j.h==k.h then
                                    if NDFcompare(k.i,j.o)<=0 and NDFcompare(k.o,j.o)<=0 then
                                        table.remove(itemoutline, nk)
                                        nk = nk - 1
                                    elseif NDFcompare(k.i,j.o)<=0 and NDFcompare(k.o,j.o)>0 then
                                        itemoutline[nj].o = k.o
                                        table.remove(itemoutline, nk)
                                        nk = nk - 1
                                    end
                                end
                            end
                            nk = nk + 1
                        end
                    end
                    nj = nj + 1
                end

                for _,j in ipairs(itemoutline) do
                    if j.trigger==true then
                        line.start_time = NDF2starttime(j.i,fps)
                        line.end_time   = NDF2endtime(j.o,fps)
                        line.actor      = "G"..epoch_count
                        local r,b = j.l+j.w, j.t+j.h
                        line.text = string.format("{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord1\\shad0\\1aFF\\3aFD\\p1}m %d %d l %d %d %d %d %d %d",j.l,j.t,r,j.t,r,b,j.l,b)
                        subtitle.append(line)
                    end
                end
            elseif result.man==true then
                if epoch_intc~=nil then
                    local epoch_starttime,epoch_endtime = NDF2starttime(epoch_intc,fps),NDF2endtime(epoch_outtc,fps)
                    if epoch_starttime>=man_endtime then break 
                    elseif not (epoch_endtime<=man_starttime) then
                        for _,j in ipairs(items) do
                            if #j>1 then
                                local trigger = 0
                                local l,t,r,b = 1921,1081,-1,-1
                                for __,k in ipairs(j) do
                                    local k_st,k_et = NDF2starttime(k.i,fps),NDF2endtime(k.o,fps)
                                    if k_st<man_endtime and k_et>man_starttime then
                                        if l~=k.x or t~=k.y or r~=k.w+k.x or b~=k.h+k.y then trigger=trigger+1 end
                                        l,t,r,b = math.min(l,k.x),math.min(t,k.y),math.max(r,k.w+k.x),math.max(b,k.h+k.y)
                                    end
                                end
                                if trigger>=2 then
                                    line.start_time = math.max(NDF2starttime(j[1].i,fps),man_starttime)
                                    line.end_time   = math.min(NDF2endtime(j[#j].o,fps),man_endtime)
                                    if line.end_time>line.start_time then
                                        line.actor  = "G"..epoch_count
                                        line.text = string.format("{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord1\\shad0\\1aFF\\3aFD\\p1}m %d %d l %d %d %d %d %d %d",l,t,r,t,r,b,l,b)
                                        subtitle.append(line)
                                    end
                                end
                            end
                        end 
                    end
                end
            end 
            -- clear memory
            items = {}
            epoch_intc,epoch_count = t_intc,epoch_count+1
        end 
        intc,outtc = t_intc,t_outtc

        local graphics = events.Event[i].Graphic

        if #graphics>=2 then
            for k=1,#graphics do
                local tx,ty,tw,th = graphics[k]["@X"],graphics[k]["@Y"],graphics[k]["@Width"],graphics[k]["@Height"]
                tx,ty,tw,th = tonumber(tx),tonumber(ty),tonumber(tw),tonumber(th)

                local distance,dx,dy = 3000,2000,2000
                local index = 0
                local w,h = tw,th
                for _,j in ipairs(items) do
                    if j[#j].o==t_intc then
                        local temp = length(j[#j].x,j[#j].y+j[#j].h, tx,ty+th)
                        if temp<distance then
                            distance = temp
                            dx,dy = math.abs(j[#j].x-tx),math.abs(j[#j].y+j[#j].h -ty-th)
                            w,h = j[#j].w,j[#j].h
                            index = _
                        end
                    end
                end

                if dx>w or dy>h then
                    table.insert(items,{})
                    table.insert(items[#items],{x=tx,y=ty,w=tw,h=th,i=t_intc,o=t_outtc})
                else
                    table.insert(items[index],{x=tx,y=ty,w=tw,h=th,i=t_intc,o=t_outtc})
                end
            end
        else
            local tx,ty,tw,th = graphics["@X"],graphics["@Y"],graphics["@Width"],graphics["@Height"]
            tx,ty,tw,th = tonumber(tx),tonumber(ty),tonumber(tw),tonumber(th)

            local distance,dx,dy = 3000,2000,2000
            local index = 0
            local w,h = tw,th
            for _,j in ipairs(items) do
                if j[#j].o==t_intc then
                    local temp = length(j[#j].x,j[#j].y+j[#j].h, tx,ty+th)
                    if temp<distance then
                        distance = temp
                        dx,dy = math.abs(j[#j].x-tx),math.abs(j[#j].y+j[#j].h -ty-th)
                        w,h = j[#j].w,j[#j].h
                        index = _
                    end
                end
            end

            if dx>w or dy>h then
                table.insert(items,{})
                table.insert(items[#items],{x=tx,y=ty,w=tw,h=th,i=t_intc,o=t_outtc})
            else
                table.insert(items[index],{x=tx,y=ty,w=tw,h=th,i=t_intc,o=t_outtc})
            end
        end

        epoch_outtc = t_outtc

        -- last event break
        if i==event_count then
            if true then
                for _,j in ipairs(items) do
                    if #j>1 then
                        local trigger = 0
                        local l,t,r,b = 1921,1081,-1,-1
                        for __,k in ipairs(j) do
                            if l~=k.x or t~=k.y or r~=k.w+k.x or b~=k.h+k.y then trigger=trigger+1 end
                            l,t,r,b = math.min(l,k.x),math.min(t,k.y),math.max(r,k.w+k.x),math.max(b,k.h+k.y)
                        end
                        if trigger>=3 then
                            line.start_time = NDF2starttime(j[1].i,fps)
                            line.end_time   = NDF2endtime(j[#j].o,fps)
                            line.actor      = "G"..epoch_count
                            line.text = string.format("{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord1\\shad0\\1aFF\\3aFD\\p1}m %d %d l %d %d %d %d %d %d",
                                                      math.max(l,1), math.max(t,1), math.min(r,1919), math.max(t,1), math.min(r,1919), math.min(b,1079), math.max(l,1), math.min(b,1079))
                            subtitle.append(line)
                        end
                    end
                end 
            end
            break
        end
        aegisub.progress.set(i/event_count*100)
    end

    aegisub.set_undo_point(script_name) 
    return selected 
end

function patch_overlapjoiner(subtitle, selected, active)
    local i = 1
    while i<=#selected-1 do
        local ii = selected[i]
        local li = subtitle[ii]
        local j = i + 1
        while j<=#selected do
            local ji = selected[j]
            local lj = subtitle[ji]
            if lj.start_time<=li.end_time then
                li = subtitle[ii]
                local l1,t1,r1,b1 = li.text:match("m ([%d]+) ([%d]+) l ([%d]+) [%d]+ [%d]+ ([%d]+)")--ltrtrb
                l1,t1,r1,b1 = tonumber(l1),tonumber(t1),tonumber(r1),tonumber(b1)
                local l2,t2,r2,b2 = lj.text:match("m ([%d]+) ([%d]+) l ([%d]+) [%d]+ [%d]+ ([%d]+)")--ltrtrb
                l2,t2,r2,b2 = tonumber(l2),tonumber(t2),tonumber(r2),tonumber(b2)
                local judge,lnew,tnew,rnew,bnew = square_overlap(l1,t1,r1-l1,b1-t1,l2,t2,r2-l2,b2-t2)
                if judge==true then
                    -- overlap
                    li.end_time = math.max(li.end_time, lj.end_time)
                    li.text = li.text:gsub("}.*$",string.format("}m %d %d l %d %d %d %d %d %d",lnew,tnew,rnew,tnew,rnew,bnew,lnew,bnew))
                    subtitle[ii] = li
                    for k=j+1,#selected do
                        selected[k] = selected[k] - 1
                    end
                    table.remove(selected, j)
                    subtitle.delete(ji)
                else
                    j = j + 1
                end
            else
                j = j + 1
            end
        end
        i = i + 1
    end
    aegisub.set_undo_point(script_name) 
    return selected
end

function slicecutter(subtitle, selected, active)
    -- input xml
	local path = aegisub.dialog.open('XML Analyzer', '', '', 'XML files (.xml)|*.xml|All Files (.)|.', false, true)
    local xml = xmlsimple:loadFile(path)
    local events = xml.BDN.Events

    local event_count = #events.Event
    local fps = xml.BDN.Description.Format["@FrameRate"]
    local title = xml.BDN.Description.Name["@Title"]
    local video_format = xml.BDN.Description.Format["@VideoFormat"]
    fps = tonumber(fps)
    local FPS = fps
    if fps==23.976 then fps=24000/1001 
    elseif fps==29.97 then fps=30000/1001 end

    -- read clipboard
    local slices = {}
    local slicetext = clipboard.get()
    slicetext = slicetext.."\n"
    for li in slicetext:gmatch("(.-)\n") do
        local temp1,temp2,temp3 = li:match("(%d+)%.M2TS[\t ]+([%d:%.]+)[\t ]+([%d:%.]+)")
        table.insert(slices, {text=temp1,time_S=temp2,time_E=temp3})
    end

    -- UI
    local dialog_config = {
        {class="label",label="slice count: "..#slices,x=0,y=0,width=2},
        {class="checkbox",name="realtime",label="use real time format\nX:XX:XX.XXX",value=true,x=0,y=1,height=2},
        {class="checkbox",name="NDFtime",label="use NDF time format\nXX:XX:XX:XX",value=false,x=1,y=1,height=2},
        {class="checkbox",name="ffbs",label="add first frame black screen",value=false,x=0,y=3,width=2}
    }
    local buttons = {"Run","Quit"}

    local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end

    -- convert real time to NDF time
    if result.realtime == true then 
        for si,li in ipairs(slices) do
            local ts,te = Real2NDF(li.time_S,fps),Real2NDF(li.time_E,fps)
            li.time_S,li.time_E = ts,NDFadd(ts,te,fps)
            slices[si] = li
        end
    else
        for si,li in ipairs(slices) do
            li.time_E = NDFadd(li.time_S,li.time_E,fps)
            slices[si] = li
        end
    end

    -- xml head & xml tail
    local xml_head = '<?xml version="1.0" encoding="UTF-8"?>\n'
    xml_head = xml_head..'<BDN Version="0.93" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="BD-03-006-0093b BDN File Format.xsd">\n'
    xml_head = xml_head..'<Description>\n'
    xml_head = xml_head..'<Name Title="'..title..'" Content="" />\n'
    xml_head = xml_head..'<Language Code="zho" />\n'
    xml_head = xml_head..'<Format VideoFormat="'..video_format..'" FrameRate="'..FPS..'" DropFrame="false" />\n'
    xml_head = xml_head..'<Events LastEventOutTC="00:00:00:00" FirstEventInTC="00:00:00:00" ContentInTC="00:00:00:00" ContentOutTC="00:00:00:00" NumberofEvents="0" Type="Graphic" />\n'
    xml_head = xml_head..'</Description>\n'
    xml_head = xml_head..'<Events>\n'
    local xml_tail = '</Events>\n</BDN>'
    local xml_mid = ''

    -- slice count
    local slice_count = 1 -- max: #slices
    local intc_now,outtc_now = slices[1].time_S,slices[1].time_E
    local firsteventintc,lasteventouttc = events.Event[1]["@InTC"],events.Event[1]["@InTC"]
    if NDFcompare(firsteventintc,outtc_now)<0 then
    else
        firsteventintc,lasteventouttc = intc_now,intc_now
    end
    local eventINslice_count = 0
    local trigger = false
    local path_table = {} -- store generated xml path

    -- loop begin
    if events.Event[event_count]["@InTC"]=="00:00:00:00" then event_count = event_count - 1 end -- delete first black frame
    local i = 1
    while i<=event_count do
        local intc = events.Event[i]["@InTC"]
        local outtc = events.Event[i]["@OutTC"]
        local graphics = events.Event[i].Graphic

        :: again ::
        if NDFcompare(outtc,outtc_now)<=0 then -- do nothing
        elseif NDFcompare(intc,outtc_now)>=0 then 
            -- output
            xml_head = xml_head:gsub('ContentInTC="[%d:]+"',string.format('ContentInTC="%s"','00:00:00:00'))
            xml_head = xml_head:gsub('ContentOutTC="[%d:]+"',string.format('ContentOutTC="%s"',NDFminus(outtc_now,intc_now,fps)))
            xml_head = xml_head:gsub('FirstEventInTC="[%d:]+"',string.format('FirstEventInTC="%s"',NDFminus(firsteventintc,intc_now,fps)))
            xml_head = xml_head:gsub('LastEventOutTC="[%d:]+"',string.format('LastEventOutTC="%s"',NDFminus(lasteventouttc,intc_now,fps)))
            xml_head = xml_head:gsub('NumberofEvents="%d+"',string.format('NumberofEvents="%d"',eventINslice_count))

            xml_head = xml_head:gsub('Title="[^"]+"',string.format('Title="%s_slice%s_clip%s"',title,slice_count,slices[slice_count].text))
            local path_new = path:gsub("%.xml$",string.format("_slice%s_clip%s.xml",slice_count,slices[slice_count].text))
            table.insert(path_table, path_new)
            local file = io.open(path_new,"w")
            file:write(xml_head,xml_mid,xml_tail)
            file:close()
            -- update
            slice_count = slice_count + 1
            intc_now,outtc_now = slices[slice_count].time_S,slices[slice_count].time_E
            --clear
            xml_mid = ''
            if NDFcompare(intc,outtc_now)<0 then 
                firsteventintc,lasteventouttc = intc,intc
            else
                firsteventintc,lasteventouttc = intc_now,intc_now
            end
            eventINslice_count = 0
            goto again
        elseif NDFcompare(intc,outtc_now)<0 and NDFcompare(outtc,outtc_now)>0 then
            if trigger==false then
                -- enter the first time
                trigger = true
                outtc = outtc_now
            else
                -- enter the second time
                trigger = false
                intc = outtc_now
                lasteventouttc = outtc_now
                goto again
            end
        end

        -- write data head
        intc,outtc = NDFminus(intc,intc_now,fps),NDFminus(outtc,intc_now,fps)
        xml_mid = xml_mid..'<Event Forced="False" InTC="'..intc..'" OutTC="'..outtc..'">\n'

        if #graphics>=2 then
            for k=1,#graphics do
                local x,y,w,h = graphics[k]["@X"],graphics[k]["@Y"],graphics[k]["@Width"],graphics[k]["@Height"]
                local v = graphics[k]:value()
                xml_mid = xml_mid..string.format('<Graphic Width="%s" Height="%s" X="%s" Y="%s">%s</Graphic>\n',w,h,x,y,v)
            end
        else
            local x,y,w,h = graphics["@X"],graphics["@Y"],graphics["@Width"],graphics["@Height"]
            local v = graphics:value()
            xml_mid = xml_mid..string.format('<Graphic Width="%s" Height="%s" X="%s" Y="%s">%s</Graphic>\n',w,h,x,y,v)
        end

        -- write data tail
        xml_mid = xml_mid..'</Event>\n'

        lasteventouttc = events.Event[i]["@OutTC"]
        eventINslice_count = eventINslice_count + 1
        aegisub.progress.set(i/event_count*100)

        -- output last clip
        if i==event_count then
            xml_head = xml_head:gsub('ContentInTC="[%d:]+"',string.format('ContentInTC="%s"','00:00:00:00'))
            xml_head = xml_head:gsub('ContentOutTC="[%d:]+"',string.format('ContentOutTC="%s"',NDFminus(outtc_now,intc_now,fps)))
            xml_head = xml_head:gsub('FirstEventInTC="[%d:]+"',string.format('FirstEventInTC="%s"',NDFminus(firsteventintc,intc_now,fps)))
            xml_head = xml_head:gsub('LastEventOutTC="[%d:]+"',string.format('LastEventOutTC="%s"',NDFminus(lasteventouttc,intc_now,fps)))
            xml_head = xml_head:gsub('NumberofEvents="%d+"',string.format('NumberofEvents="%d"',eventINslice_count))

            xml_head = xml_head:gsub('Title="[^"]+"',string.format('Title="%s_slice%s_clip%s"',title,slice_count,slices[slice_count].text))
            local path_new = path:gsub("%.xml$",string.format("_slice%s_clip%s.xml",slice_count,slices[slice_count].text))
            table.insert(path_table, path_new)
            local file = io.open(path_new,"w")
            file:write(xml_head,xml_mid,xml_tail)
            file:close()
            break
        end

        if trigger==false then i = i + 1 end
    end
    -- loop end

    -- add first frame black screen
    if result.ffbs==true then
        local pngpath = aegisub.decode_path("?user").."\\00000000.png"
        local path_head = path:gsub("[^\\]*%.xml$","")

        for si,li in ipairs(path_table) do
            local xmlfile = io.open(li,"r")
            xml = xmlfile:read("*all")
            if xml:match("Event Forced=\"False\" InTC=\"00:00:00:00\"")==nil then
                if xml:match("Event Forced=\"False\" InTC=\"00:00:00:01\"")==nil then
                    xml = xml:gsub("</Events>\n</BDN>", '<Event Forced="False" InTC="00:00:00:00" OutTC="00:00:00:02"><Graphic Width="10" Height="10" X="0" Y="0">00000000.png</Graphic></Event>\n</Events>\n</BDN>')
                else
                    xml = xml:gsub("</Events>\n</BDN>", '<Event Forced="False" InTC="00:00:00:00" OutTC="00:00:00:01"><Graphic Width="10" Height="10" X="0" Y="0">00000000.png</Graphic></Event>\n</Events>\n</BDN>')
                end
                xmlfile:close()
                xmlfile = io.open(li, "w")
                xmlfile:write(xml)
            end
            xmlfile:close()
        end
        copyfile(pngpath, path_head.."\\00000000.png", true)
    end
    
    aegisub.log("succeeded")
    aegisub.set_undo_point(script_name) 
    return selected 
end

function timecalculator(subtitle, selected, active)
    local dialog_config = {
        {class="label",label="Source Format",x=0,y=0},--1
        {class="dropdown",name="s",items={"RealTime: X:XX:XX.XXX","NDFTime: XX:XX:XX:XX"},value="NDFTime: XX:XX:XX:XX",x=1,y=0},
        {class="label",label="Operation",x=0,y=1},--3
        {class="dropdown",name="o",items={"Add","Minus","Convert->RealTime","Convert->NDFTime","Convert->Frame"},value="Convert->Frame",x=1,y=1},
        {class="label",label="FPS",x=0,y=2},--5
        {class="floatedit",name="fps",value=23.976,x=1,y=2},--6

        {class="label",label="T1",x=0,y=3},--7
        {class="edit",name="t1",value="",x=1,y=3},--8
        {class="label",label="T2",x=0,y=4},--9
        {class="edit",name="t2",x=1,value="",y=4},--10
        {class="label",label="Result",x=0,y=5},--11
        {class="edit",name="r",value="",x=1,y=5}--12
    }
    local buttons = {"Run","Quit"}
    ::UI::
    local pressed, result = aegisub.dialog.display(dialog_config,buttons)
	if pressed=="Quit" then aegisub.cancel()
    elseif pressed=="Run" then
        local fps = result.fps
        local t
        if result.s=="RealTime: X:XX:XX.XXX" then
            if result.o=="Add" then
                t = Realadd(result.t1,result.t2)
            elseif result.o=="Minus" then
                t = Realminus(result.t1,result.t2)
            elseif result.o=="Convert->NDFTime" then
                t = Real2NDF(result.t1,fps)
            elseif result.o=="Convert->Frame" then
                t= Real2frame(result.t1,fps)
            end
        elseif result.s=="NDFTime: XX:XX:XX:XX" then
            if result.o=="Add" then
                t = NDFadd(result.t1,result.t2,fps)
            elseif result.o=="Minus" then
                t = NDFminus(result.t1,result.t2,fps)
            elseif result.o=="Convert->RealTime" then
                t = NDF2real(result.t1,fps)
            elseif result.o=="Convert->Frame" then
                t = NDF2frame(result.t1,fps)
            end
        end
        dialog_config[2].value = result.s
        dialog_config[4].value = result.o
        dialog_config[6].value = result.fps
        dialog_config[8].value = result.t1
        dialog_config[10].value= result.t2
        dialog_config[12].value= t
        goto UI
    end
    aegisub.set_undo_point(script_name) 
    return selected 
end

function dialogpuller(subtitle, selected, active)
    local fps = fpsgen()
    local time_U = 1000/fps
    for i=1,#selected-1 do
        local ni,nj = selected[i],selected[i+1]
        local li,lj = subtitle[ni],subtitle[nj]
        local frame_E,frame_S = aegisub.frame_from_ms(li.end_time),aegisub.frame_from_ms(lj.start_time)
        if frame_S-frame_E<=1 then
            li.end_time = li.end_time - time_U
            if frame_E==frame_S then lj.start_time = lj.start_time + time_U end
            li.actor,lj.actor = "G","G"
            subtitle[ni],subtitle[nj] = li,lj
        end
    end
end

function forced_window(subtitle, selected, active)
    local path = aegisub.dialog.open('XML Analyzer', '', '', 'XML files (.xml)|*.xml|All Files (.)|.', false, true)
    local path_head = path:gsub("[^\\]*%.xml$","") -- E:\\XXX\\
    local path_new = path:gsub("%.xml$","_FTW.xml")
    local BDNHandler = xmlsimple:loadFile(path)

    local events = BDNHandler.BDN.Events
    local event_count = #events.Event
    local fps = BDNHandler.BDN.Description.Format["@FrameRate"]
    fps = tonumber(event_count)
    if fps==23.976 then fps=24000/1001 
    elseif fps==29.97 then fps=30000/1001 end

    -- conf & python
    local conf_path = path_head.."ForcedWindow.conf"
    local conf_table = {}
    tmpfile = io.open(aegisub.decode_path("?user").."\\ForcedWindow.exe")
    if tmpfile~=nil then
        tmpfile:close()
        pypath = path_head.."ForcedWindow.exe"
        pypathdata = aegisub.decode_path("?user").."\\ForcedWindow.exe"
        os.execute(string.format('copy "%s" "%s"', pypathdata, pypath))
    end

    -- open the new xml to write
    local xmlfile = io.open(path, "r")
    local xmlFTWfile = io.open(path_new, "w")
    local xmlFTW = xmlfile:read("*all")

    -- ass part
    local rule_table = {}
    for si, li in ipairs(selected) do
        if subtitle[li].comment==false then
            local line = subtitle[li]
            local x1,y1,x2,y2,x3,y3 = line.text:match("m +([%d%.]+) +([%d%.]+) +l +([%d%.]+) +([%d%.]+)[l ]+([%d%.]+) +([%d%.]+)")
            x1,x2,y1,y2 = math.min(x1,x2,x3),math.max(x1,x2,x3),math.min(y1,y2,y3),math.max(y1,y2,y3)
            x1,x2,y1,y2 = math.floor(x1),math.floor(x2),math.floor(y1),math.floor(y2)
            local f1, f2 = math.ceil(line.start_time/(1000/fps)), math.ceil(line.end_time/(1000/fps))
            table.insert(rule_table, {i=f1, o=f2, l=x1, t=y1, r=x2, b=y2})
        end
    end

    for i=1, event_count do
        local t_intc = events.Event[i]["@InTC"]
        local t_outtc = events.Event[i]["@OutTC"]
        local graphics = events.Event[i].Graphic
        if #graphics<2 then
            local newgraphics = {} -- for xml
            local pngi = 0
            local png
            for si,ri in ipairs(rule_table) do
                if NDF2frame(t_intc, fps)<ri.o and NDF2frame(t_outtc, fps)>ri.i then
                    local tx,ty,tw,th = graphics["@X"], graphics["@Y"], graphics["@Width"], graphics["@Height"]
                    tx,ty,tw,th = tonumber(tx),tonumber(ty),tonumber(tw),tonumber(th)
        
                    if ri.r > tx and ri.b > ty and ri.l < tx+tw and ri.t < ty+th then
                        png = graphics:value()
                        local png1 = png:gsub("%.png$","_"..pngi..".png")
                        if pngi==2 then aegisub.log("3 windows in one frame") aegisub.cancel() end
                        pngi = pngi + 1
            
                        local info = string.format('<Output Width="%d" Height="%d" X="%d" Y="%d" Name="%s">\n', ri.r-ri.l, ri.b-ri.t, ri.l, ri.t, png1) ..
                            string.format('<Input Width="%d" Height="%d" X="%d" Y="%d" Name="%s"></Input>\n', tw, th, tx, ty, png) ..
                            '</Output>\n'
                        table.insert(conf_table, info)
                        table.insert(newgraphics, {_attr={Width=ri.r-ri.l,Height=ri.b-ri.t,X=ri.l,Y=ri.t}, png1})
                    end
                end
            end           
            if #newgraphics~=0 then
                xmlFTW = xmlFTW:gsub('<Graphic[^\n]+'..png..'</Graphic>\n', function() 
                    local graphicsstr = ""
                    for sj,gj in ipairs(newgraphics) do
                        graphicsstr = graphicsstr..string.format('<Graphic Width="%d" Height="%d" X="%d" Y="%d">%s</Graphic>\n',
                            gj._attr.Width, gj._attr.Height, gj._attr.X, gj._attr.Y, gj[1])
                    end
                    return graphicsstr
                end)
            end
        else
            local newgraphics = {}
            local pngi = 0
            local png, pnga, pngb
            local tx,ty,tw,th,Tx,Ty,Tw,Th
            for si,ri in ipairs(rule_table) do
                if NDF2frame(t_intc, fps)<ri.o and NDF2frame(t_outtc, fps)>ri.i then
                    if pngi==1 then
                        tx,ty,tw,th = graphics[1]["@X"], graphics[1]["@Y"], graphics[1]["@Width"], graphics[1]["@Height"]
                        tx,ty,tw,th = tonumber(tx),tonumber(ty),tonumber(tw),tonumber(th)
                        Tx,Ty,Tw,Th = graphics[2]["@X"], graphics[2]["@Y"], graphics[2]["@Width"], graphics[2]["@Height"]
                        Tx,Ty,Tw,Th = tonumber(Tx),tonumber(Ty),tonumber(Tw),tonumber(Th)

                        pnga, pngb = graphics[1]:value(), graphics[2]:value()
                        png = pnga:gsub("_%d%.png$", "_0_0.png")
                    end

                    local png1 = png:gsub("%d%.png$", pngi..".png")

                    if (ri.r > tx and ri.b > ty and ri.l < tx+tw and ri.t < ty+th) or (ri.r > Tx and ri.b > Ty and ri.l < Tx+Tw and ri.t < Ty+Th) then
                        local info = string.format('<Output Width="%d" Height="%d" X="%d" Y="%d" Name="%s">\n', ri.r-ri.l, ri.b-ri.t, ri.l, ri.t, png1) ..
                            string.format('<Input Width="%d" Height="%d" X="%d" Y="%d">%s</Input>\n', tw, th, tx, ty, pnga) ..
                            string.format('<Input Width="%d" Height="%d" X="%d" Y="%d">%s</Input>\n', Tw, Th, Tx, Ty, pngb) ..
                            '</Output>\n'
                        table.insert(conf_table, info)
                        table.insert(newgraphics, {_attr={WWidth=ri.r-ri.l,Height=ri.b-ri.t,X=ri.l,Y=ri.t}, png1})

                        if pngi==2 then aegisub.log("3 windows in one frame") aegisub.cancel() end
                        pngi = pngi + 1
                    end
                end
            end
            if #newgraphics~=0 then
                xmlFTW = xmlFTW:gsub('<Graphic[^\n]+'..pnga..'</Graphic>\n[^\n]*<Graphic[^\n]+'..pngb..'</Graphic>\n', function() 
                    local graphicsstr = ""
                    for sj,gj in ipairs(newgraphics) do
                        graphicsstr = graphicsstr..string.format('<Graphic Width="%d" Height="%d" X="%d" Y="%d">%s</Graphic>\n',
                            gj._attr.Width, gj._attr.Height, gj._attr.X, gj._attr.Y, gj[1])
                    end
                    return graphicsstr
                end)
            end
        end
        aegisub.progress.set(i/event_count*100)
    end

    conffile = io.open(conf_path, 'r')
    conffile:write('<ForcedWindow>\n')
    conffile:write(table.concat(conf_table, ''))
    conffile:write('</ForcedWindow>\n')
    conffile:close()
    xmlFTWfile:write(xmlFTW)
    xmlFTWfile:close()

    aegisub.log("Succeed!")
    return selected
end

function firstframeblackscreen(subtitle, selected, active)
    local pngpath = aegisub.decode_path("?user").."\\0.png"
    local path = aegisub.dialog.open('XML Analyzer', '', '', 'XML files (.xml)|*.xml|All Files (.)|.', false, true)
    local path_head = path:gsub("[^\\]*%.xml$","")

    local xmlfile = io.open(path,"r")
    local xml = xmlfile:read("*all")
    xml = xml:gsub("</Events>\n</BDN>", '<Event Forced="False" InTC="00:00:00:00" OutTC="00:00:00:08"><Graphic Width="1920" Height="1080" X="0" Y="0">0.png</Graphic></Event>\n</Events>\n</BDN>')
    xmlfile:close()
    xmlfile = io.open(path, "w")
    xmlfile:write(xml)
    xmlfile:close()

    copyfile(pngpath, path_head.."\\0.png", true)
    return selected
end

--********************************************************************************************--
--********************************************************************************************--

function square_overlap(x1,y1,w1,h1,x2,y2,w2,h2)
    local judge = false
    local l,t,r,b = math.min(x1,x2),math.min(y1,y2),math.max(x1+w1,x2+w2),math.max(y1+h1,y2+h2)
    judge = judge or ptINsquare(x1,y1,x2,y2,w2,h2)
    judge = judge or ptINsquare(x1,y1+h1,x2,y2,w2,h2)
    judge = judge or ptINsquare(x1+w1,y1,x2,y2,w2,h2)
    judge = judge or ptINsquare(x1+w1,y1+h1,x2,y2,w2,h2)
    judge = judge or ptINsquare(x2,y2,x1,y1,w1,h1)
    judge = judge or ptINsquare(x2+w2,y2,x1,y1,w1,h1)
    judge = judge or ptINsquare(x2,y2+h2,x1,y1,w1,h1)
    judge = judge or ptINsquare(x2+w2,y2+h2,x1,y1,w1,h1)
    return judge,l,t,r,b
end

function overlap_proportion(x1,y1,w1,h1,x2,y2,w2,h2)
    local l,t,r,b = math.max(x1,x2),math.max(y1,y2),math.min(x1+w1,x2+w2),math.min(y1+h1,y2+h2)
    local s,s1,s2 = (r-l)*(b-t),w1*h1,w2*h2
    return math.max(s/s1,s/s2)
end

function ptINsquare(posx,posy,x,y,w,h)
    if posx>=x and posx<=x+w and posy>=y and posy<=y+h then
        return true
    else
        return false
    end
end

function length(x1,y1,x2,y2) return math.sqrt((x2-x1)^2+(y2-y1)^2)
end

function round(x) return math.floor(x+0.5)
end

--This is what puts your automation in Aegisub's automation list
aegisub.register_macro(script_name.."/Simulator",script_description,simulator)
aegisub.register_macro(script_name.."/BorderAdder",script_description,borderadder)
aegisub.register_macro(script_name.."/ForceTwoWindow",script_description,forced_window)
aegisub.register_macro(script_name.."/FirstFrameBlackScreen",script_description,firstframeblackscreen)
aegisub.register_macro(script_name.."/SliceCutter",script_description,slicecutter)
aegisub.register_macro(script_name.."/TimeCalculator",script_description,timecalculator)
--aegisub.register_macro(script_name.."/Patch_OverlapJoiner",script_description,patch_overlapjoiner)
--aegisub.register_macro(script_name.."/DialogPuller",script_description,dialogpuller)
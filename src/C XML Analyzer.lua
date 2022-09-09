--[[
]]

script_name="C XML Analyzer"
script_description="XML Analyzer v1.6"
script_author="chaaaaang"
script_version="1.6"

local xmlsimple = require("xmlSimple").newParser()
local clipboard = require("aegisub.clipboard")

-- ########### Math #############

local function length(x1,y1,x2,y2) return math.sqrt((x2-x1)^2+(y2-y1)^2)
end
local function round(x) return math.floor(x+0.5)
end

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
    local epoch_ind = 0
    if events.Event[event_count]["@InTC"]=="00:00:00:00" then 
        epoch_ind,event_count = 1,event_count-1 
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
                buffer_report:write(string.format("Epoch%d, %d, %.1f%%\n", epoch_ind, buffer, buffer/BUFFER_MAX*100))
            end
            data = {} 
            silence1, silence2 = false, false
            count,buffer = 0,0
            epoch_ind = epoch_ind + 1
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
            line.actor = "G"..epoch_ind
            line.text = "*** this Event will be discarded ***. The Time from InTC of previous Event to InTC is too close. and cannot register this Event with previous Epoch, by limitation of the number of different size images in a Epoch.  permitted number is 64."
            subtitle.append(line)
        end

        if silence2==false and buffer>BUFFER_MAX then
            aegisub.log(t_intc..": buffer overflow")
            silence2 = true
            line.start_time = NDF2ms(t_intc,fps)
            line.end_time = NDF2ms(t_intc,fps)
            line.actor = "G"..epoch_ind
            line.text = 'buffer overflow.'
            subtitle.append(line)
        end

        -- last event break
        if i==event_count then
            buffer_report:write(string.format("Epoch%d, %d, %.1f%%\n", epoch_ind, buffer, buffer/BUFFER_MAX*100))
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
    local event_count = #events.Event
    local fps = xml.BDN.Description.Format["@FrameRate"]
    fps = tonumber(fps)
    if fps==23.976 then fps=24000/1001 
    elseif fps==29.97 then fps=30000/1001 end

    local intc,outtc
    local epoch_intc,epoch_outtc
    local epoch_ind = 0
    if events.Event[event_count]["@InTC"]=="00:00:00:00" then 
        epoch_ind, event_count = 1, event_count-1 
    end

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
                        line.actor      = "G"..epoch_ind
                        line.text = string.format("{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord1\\shad0\\1aFF\\3aFD\\p1}m %d %d l %d %d %d %d %d %d",
                                                    math.max(l,1), math.max(t,1), math.min(r,1919), math.max(t,1), math.min(r,1919), math.min(b,1079), math.max(l,1), math.min(b,1079))
                        subtitle.append(line)
                    end
                end
            end  
            -- clear memory
            items = {}
            epoch_intc, epoch_ind = t_intc, epoch_ind + 1
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
                        line.actor      = "G"..epoch_ind
                        line.text = string.format("{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord1\\shad0\\1aFF\\3aFD\\p1}m %d %d l %d %d %d %d %d %d",
                                                    math.max(l,1), math.max(t,1), math.min(r,1919), math.max(t,1), math.min(r,1919), math.min(b,1079), math.max(l,1), math.min(b,1079))
                        subtitle.append(line)
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

function recttrimmer(subtitle, selected, active)
    local start_time, end_time, l, t, r, b
    for si, li in ipairs(selected) do
        local line = subtitle[li]
        local l1,t1,r1,b1 = line.text:match("m ([%d]+) ([%d]+) l ([%d]+) [%d]+ [%d]+ ([%d]+)")
        l1,t1,r1,b1 = tonumber(l1),tonumber(t1),tonumber(r1),tonumber(b1)
        if si == 1 then
            start_time = line.start_time
            end_time = line.end_time
            l, t, r, b = l1, t1, r1, b1
        else
            end_time = math.max(end_time, line.end_time)
            start_time = math.min(start_time, line.start_time)
            l, t = math.min(l, l1), math.min(t, t1)
            r, b = math.max(r, r1), math.max(b, b1)
        end
    end
    local offset = 0
    for si, li in ipairs(selected) do
        line = subtitle[li]
        line.start_time = start_time
        line.end_time = end_time
        line.text = line.text:gsub("}.*$",string.format("}m %d %d l %d %d %d %d %d %d", l, t, r, t, r, b, l, b) )
        subtitle[li] = line
        if si ~= 1 then
            subtitle.delete(li - offset)
            offset = offset + 1
        end
    end
    aegisub.set_undo_point(script_name) 
    return {selected[1]}
end

function rectnormalizer(subtitle, selected, active)
    for si, li in ipairs(selected) do
        local line = subtitle[li]
        local x, y = line.text:match("\\pos%( *([%d%.%-]+) *, *([%d%.%-]+) *%)")
        x, y = round(tonumber(x)), round(tonumber(y))
        local l1,t1,r1,b1 = line.text:match("m ([%d]+) ([%d]+) l ([%d]+) [%d]+ [%d]+ ([%d]+)")
        l1,t1,r1,b1 = tonumber(l1),tonumber(t1),tonumber(r1),tonumber(b1)
        line.text = line.text:gsub("}.*$", 
            string.format("}m %d %d l %d %d %d %d %d %d", l1+x, t1+y, r1+x, t1+y, r1+x, b1+y, l1+x, b1+y))
        line.text = line.text:gsub("\\pos%([^%)]+%)", "\\pos(0,0)")
        subtitle[li] = line
    end
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

function forcedwindow(subtitle, selected, active)
    local path = aegisub.dialog.open('XML Analyzer', '', '', 'XML files (.xml)|*.xml|All Files (.)|.', false, true)
    local path_head = path:gsub("[^\\]*%.xml$","") -- E:\\XXX\\
    local path_new = path:gsub("%.xml$","_FW.xml")
    local BDNHandler = xmlsimple:loadFile(path)

    local events = BDNHandler.BDN.Events
    local event_count = #events.Event
    local fps = BDNHandler.BDN.Description.Format["@FrameRate"]
    fps = tonumber(fps)
    if fps==23.976 then fps=24000/1001 
    elseif fps==29.97 then fps=30000/1001 end

    -- conf & python
    local conf_path = path_head.."ForcedWindow.conf"
    local conf_table = {}
    local pypath = path_head.."ForcedWindow.exe"
    local pyfile = io.open(pypath)
    if pyfile == nil then
        local tmpfile = io.open(aegisub.decode_path("?user").."\\ForcedWindow.exe")
        if tmpfile ~= nil then
            tmpfile:close()
            pypathdata = aegisub.decode_path("?user").."\\ForcedWindow.exe"
            os.execute(string.format('copy "%s" "%s"', pypathdata, pypath))
        end
    else
        pyfile:close()
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
                        if pngi == 2 then aegisub.log("3 windows in one frame") aegisub.cancel() end
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
                    if pngi == 0 then
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
                            string.format('<Input Width="%d" Height="%d" X="%d" Y="%d" Name="%s"></Input>\n', tw, th, tx, ty, pnga) ..
                            string.format('<Input Width="%d" Height="%d" X="%d" Y="%d" Name="%s"></Input>\n', Tw, Th, Tx, Ty, pngb) ..
                            '</Output>\n'
                        table.insert(conf_table, info)
                        table.insert(newgraphics, {_attr={Width=ri.r-ri.l,Height=ri.b-ri.t,X=ri.l,Y=ri.t}, png1})

                        if pngi == 2 then aegisub.log("3 windows in one frame") aegisub.cancel() end
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

    conffile = io.open(conf_path, 'w')
    conffile:write('<ForcedWindow>\n')
    conffile:write(table.concat(conf_table, ''))
    conffile:write('</ForcedWindow>\n')
    conffile:close()
    xmlFTWfile:write(xmlFTW)
    xmlFTWfile:close()

    aegisub.log("Succeed!")
    return selected
end

function epochdetector(subtitle, selected, active)
    local path = aegisub.dialog.open('XML Analyzer', '', '', 'XML files (.xml)|*.xml|All Files (.)|.', false, true)
    local BDNHandler = xmlsimple:loadFile(path)

    local events = BDNHandler.BDN.Events
    local event_count = #events.Event
    local fps = BDNHandler.BDN.Description.Format["@FrameRate"]
    fps = tonumber(fps)
    if fps==23.976 then fps=24000/1001 
    elseif fps==29.97 then fps=30000/1001 end

    local epoch_table = {}

    if events.Event[event_count]["@InTC"]=="00:00:00:00" then 
        local tmp = events.Event[event_count]
        event_count = event_count - 1 
        table.insert(epoch_table, {i=NDF2ms(tmp["@InTC"], fps), o=NDF2ms(tmp["@OutTC"], fps)})
    end

    local intc, outtc = events.Event[1]["@InTC"], nil
    for i=1, event_count do
        local t_intc = events.Event[i]["@InTC"]
        local t_outtc = events.Event[i]["@OutTC"]

        -- new epoch (interval > 1 frame) first enter and update before get in the loop
        if outtc~=nil and t_intc~=outtc and NDFminus(t_intc,outtc,fps)~="00:00:00:01" then 
            table.insert(epoch_table, {i=NDF2starttime(intc, fps), o=NDF2endtime(outtc, fps)})
            -- update
            intc = t_intc
        end
        outtc = t_outtc
        if i == event_count then
            table.insert(epoch_table, {i=NDF2starttime(intc, fps), o=NDF2endtime(outtc, fps)})
            break
        end
    end

    local count_undef = 0
    for li=1, #subtitle do
        local line = subtitle[li]
        if line.class == "dialogue" then
            if line.comment == true then
                line.effect = "comment"
            else
                local mid_time = (line.start_time + line.end_time)/2
                local trigger = false
                for i, epoch in ipairs(epoch_table) do
                    if mid_time > epoch.i and mid_time < epoch.o then
                        line.effect = "epoch"..i
                        trigger = true
                        break
                    end
                end
                if trigger == false then
                    line.effect = "undefined"
                    count_undef = count_undef + 1
                end
            end
            subtitle[li] = line
        end
    end
    if count_undef > 0 then
        aegisub.log("Number of lines not in epoches: "..count_undef..". Please check.")
    end
    aegisub.set_undo_point(script_name) 
    return selected
end

function epochselector(subtitle, selected, active)
    local dialog_config = {
        {class="label", label="Select 1 or more epoch(es), Separated by ',' or use 'all'", x=0, y=0},
        {class="edit", name="epoch", x=0, y=1}
    }
    local buttons = {"Run", "Quit"}
    local pressed, result = aegisub.dialog.display(dialog_config, buttons)
    if not pressed=="Run" then aegisub.cancel() end

    local sel_epoches = ","..result.epoch..","

    for li=1, #subtitle do
        local line = subtitle[li]
        if line.class == "dialogue" and line.effect:match("epoch") ~= nil then
            if sel_epoches == ",all," then
                line.comment = false
            elseif sel_epoches:match(","..line.effect:sub(6)..",") ~= nil then
                line.comment = false
            else
                line.comment = true
            end
            subtitle[li] = line
        end
    end
    aegisub.set_undo_point(script_name) 
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

--This is what puts your automation in Aegisub's automation list
aegisub.register_macro(script_name.."/Simulator",script_description,simulator)
aegisub.register_macro(script_name.."/BorderAdder",script_description,borderadder)
aegisub.register_macro(script_name.."/ForcedWindow",script_description,forcedwindow)
aegisub.register_macro(script_name.."/FirstFrameBlackScreen",script_description,firstframeblackscreen)
aegisub.register_macro(script_name.."/SliceCutter",script_description,slicecutter)
aegisub.register_macro(script_name.."/EpochDetector",script_description,epochdetector)
aegisub.register_macro(script_name.."/EpochSelector",script_description,epochselector)
aegisub.register_macro(script_name.."/RectTrimmer",script_description,recttrimmer)
aegisub.register_macro(script_name.."/RectNormalizer",script_description,rectnormalizer)
aegisub.register_macro(script_name.."/TimeCalculator",script_description,timecalculator)
--aegisub.register_macro(script_name.."/DialogPuller",script_description,dialogpuller)
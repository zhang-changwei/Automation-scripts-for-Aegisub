--[[
README:

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

]]

script_name="C XML Analyzer"
script_description="XML Analyzer v1.1"
script_author="chaaaaang"
script_version="1.1" 

local xmlsimple = require("xmlSimple").newParser()
local lfs = require "lfs"
local clipboard = require("aegisub.clipboard")

--This is the main processing function that modifies the subtitles
function simulator(subtitle, selected, active)
	local path = aegisub.dialog.open('XML Analyzer', '', '', 'XML files (.xml)|*.xml|All Files (.)|.', false, true)
    local path_head = path:gsub("[^\\]*%.xml$","")
    local xml = xmlsimple:loadFile(path)
    local events = xml.BDN.Events

    local event_count = xml.BDN.Description.Events["@NumberofEvents"]
    local fps = xml.BDN.Description.Format["@FrameRate"]
    event_count,fps = tonumber(event_count),tonumber(fps)

    local intc,outtc
    -- local x,y,h,w=1920,1080,0,0
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

        -- new epoch
        if t_intc~=outtc then 
            data = {} 
            -- x,y,h,w = 1920,1080,0,0
            count,buffer = 0,0
        end 
        intc,outtc = t_intc,t_outtc

        local graphics = events.Event[i].Graphic

        if #graphics>=2 then
            for k=1,#graphics do
                local trigger,trigger2 = true,true
                local tx,ty,tw,th = graphics[k]["@X"],graphics[k]["@Y"],graphics[k]["@Width"],graphics[k]["@Height"]
                tx,ty,tw,th = tonumber(tx),tonumber(ty),tonumber(tw),tonumber(th)

                local png_path = path_head..graphics[k]:value()
                local png_attr = lfs.attributes(png_path)
                local tsize = png_attr.size

                for _,j in ipairs(data) do
                    if j.w==tw and j.h==th then trigger = false end
                    if j.s==tsize then trigger2 = false end
                end

                if trigger==true or trigger2==true then 
                    table.insert(data,{w=tw,h=th,s=tsize})
                end
                if trigger==true then
                    count = count + 1
                end
                if trigger2==true then
                    buffer = buffer + tsize
                end
            end
            if #graphics>2 then 
                aegisub.log(t_intc..": more than two pictures in a timestamp\n")
            end
        else
            local trigger,trigger2 = true,true
            local tx,ty,tw,th = graphics["@X"],graphics["@Y"],graphics["@Width"],graphics["@Height"]
            tx,ty,tw,th = tonumber(tx),tonumber(ty),tonumber(tw),tonumber(th)

            local png_path = path_head..graphics:value()
            local png_attr = lfs.attributes(png_path)
            local tsize = png_attr.size

            for _,j in ipairs(data) do
                if j.w==tw and j.h==th then trigger = false end
                if j.s==tsize then trigger2 = false end
            end
            if trigger==true or trigger2==true then 
                table.insert(data,{w=tw,h=th,s=tsize})
            end
            if trigger==true then
                count = count + 1
            end
            if trigger2==true then
                buffer = buffer + tsize
            end
        end

        -- log out
        if count>64 then
            aegisub.log(t_intc.." is too close to the previous frame\n")
            outtc = nil
            t_intc = totime(t_intc,fps)
            line.start_time = t_intc
            line.end_time = t_intc
            line.text = "*** this Event will be discarded ***. The Time from InTC of previous Event to InTC is too close. and cannot register this Event with previous Epoch, by limitation of the number of different size images in a Epoch.  permitted number is 64."
            subtitle.append(line)
        end

        if buffer>BUFFER_MAX then
            aegisub.log(t_intc..": limited buffer 4194304 now get "..buffer.."\n")
        end

        aegisub.progress.set(i/event_count*100)
    end

    aegisub.set_undo_point(script_name) 
    return selected 
end

function borderadder(subtitle, selected, active)
	local path = aegisub.dialog.open('XML Analyzer', '', '', 'XML files (.xml)|*.xml|All Files (.)|.', false, true)
    local xml = xmlsimple:loadFile(path)
    local events = xml.BDN.Events

    local event_count = xml.BDN.Description.Events["@NumberofEvents"]
    local fps = xml.BDN.Description.Format["@FrameRate"]
    event_count,fps = tonumber(event_count),tonumber(fps)

    local intc,outtc
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
        if t_intc~=outtc then 
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
                        line.start_time = starttime(j[1].f,fps)
                        line.end_time   = endtime(j[#j].f,fps)
                        line.text = string.format("{\\an7\\pos(0,0)\\fscx100\\fscy100\\bord1\\shad0\\1aFF\\3aFD\\p1}m %d %d l %d %d %d %d %d %d",l,t,r,t,r,b,l,b)
                        subtitle.append(line)
                    end
                end
            end 
            -- clear memory
            items = {}
        end 
        intc,outtc = t_intc,t_outtc

        local graphics = events.Event[i].Graphic

        if #graphics>=2 then
            for k=1,#graphics do
                local tx,ty,tw,th = graphics[k]["@X"],graphics[k]["@Y"],graphics[k]["@Width"],graphics[k]["@Height"]
                tx,ty,tw,th = tonumber(tx),tonumber(ty),tonumber(tw),tonumber(th)

                -- try to get same size events
                local png_frame = graphics[k]:value()
                png_frame = png_frame:gsub("_%d+%.png$","")
                png_frame = tonumber(png_frame)

                local distance = 3000
                local index = 0
                for _,j in ipairs(items) do
                    local temp = length(j[#j].x,j[#j].y,tx,ty)
                    if temp<distance then
                        distance = temp
                        index = _
                    end
                end

                if distance>math.min(tw,th) then
                    table.insert(items,{})
                    table.insert(items[#items],{f=png_frame,x=tx,y=ty,w=tw,h=th})
                else
                    table.insert(items[index],{f=png_frame,x=tx,y=ty,w=tw,h=th})
                end
            end
        else
            local tx,ty,tw,th = graphics["@X"],graphics["@Y"],graphics["@Width"],graphics["@Height"]
            tx,ty,tw,th = tonumber(tx),tonumber(ty),tonumber(tw),tonumber(th)

            -- try to get same size events
            local png_frame = graphics:value()
            png_frame = png_frame:gsub("_%d+%.png$","")
            png_frame = tonumber(png_frame)

            local distance = 3000
            local index = 0
            for _,j in ipairs(items) do
                local temp = length(j[#j].x,j[#j].y,tx,ty)
                if temp<distance then
                    distance = temp
                    index = _
                end
            end

            if distance>math.min(tw,th) then
                table.insert(items,{})
                table.insert(items[#items],{f=png_frame,x=tx,y=ty,w=tw,h=th})
            else
                table.insert(items[index],{f=png_frame,x=tx,y=ty,w=tw,h=th})
            end
        end

        aegisub.progress.set(i/event_count*100)
    end

    aegisub.set_undo_point(script_name) 
    return selected 
end

function slicecutter(subtitle, selected, active)
    -- input xml
	local path = aegisub.dialog.open('XML Analyzer', '', '', 'XML files (.xml)|*.xml|All Files (.)|.', false, true)
    local xml = xmlsimple:loadFile(path)
    local events = xml.BDN.Events

    local event_count = xml.BDN.Description.Events["@NumberofEvents"]
    local fps = xml.BDN.Description.Format["@FrameRate"]
    local title = xml.BDN.Description.Name["@Title"]
    local video_format = xml.BDN.Description.Format["@VideoFormat"]
    event_count,fps = tonumber(event_count),tonumber(fps)
    local FPS = fps
    -- if fps==23.976 then fps=24000/1001 
    -- elseif fps==29.97 then fps=30000/1001 end

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
        {class="checkbox",name="NDFtime",label="use NDF time format\nXX:XX:XX:XX",value=false,x=1,y=1,height=2}
    }
    local buttons = {"Run","Quit"}

    local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end

    -- convert real time to NDF time
    if result.realtime == true then 
        for si,li in ipairs(slices) do
            local ts,te = toNDF(li.time_S,fps),toNDF(li.time_E,fps)
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
            local file = io.open(path_new,"w")
            file:write(xml_head,xml_mid,xml_tail)
            file:close()
            break
        end

        if trigger==false then i = i + 1 end
    end
    -- loop end
    aegisub.log("succeeded")
    aegisub.set_undo_point(script_name) 
    return selected 
end

-- NDF 2 Real time(ms)
function totime(t,fps)
    local h,m,s,ms = t:match("(%d%d):(%d%d):(%d%d):(%d%d)")
    h,m,s,ms = tonumber(h),tonumber(m),tonumber(s),tonumber(ms)
    local f = ms + s*math.ceil(fps) + m*60*math.ceil(fps) + h*3600*math.ceil(fps)
    return f*1000/fps
end

function toNDF(t,fps)
    local h,m,s,ms = t:match("(%d+):(%d%d):(%d%d)%.(%d%d%d)")
    h,m,s,ms = tonumber(h),tonumber(m),tonumber(s),tonumber(ms)
    local f = (ms+s*1000+m*60*1000+h*3600*1000)/(1000/fps)
    f = round(f)
    local FPS_U =math.ceil(fps)
    local hour,min,sec,frame = math.floor(f/FPS_U/3600),math.floor(f/FPS_U/60)%60,math.floor(f/FPS_U)%60,f%FPS_U
    if hour<10 then hour = "0"..hour end
    if min<10 then min = "0"..min end
    if sec<10 then sec = "0"..sec end
    if frame<10 then frame = "0"..frame end
    return hour..":"..min..":"..sec..":"..frame
end

function NDFadd(t1,t2,fps)
    fps = math.ceil(fps)
    local h1,m1,s1,f1 = t1:match("(%d%d):(%d%d):(%d%d):(%d%d)")
    local h2,m2,s2,f2 = t2:match("(%d%d):(%d%d):(%d%d):(%d%d)")
    h1,m1,s1,f1 = tonumber(h1),tonumber(m1),tonumber(s1),tonumber(f1)
    h2,m2,s2,f2 = tonumber(h2),tonumber(m2),tonumber(s2),tonumber(f2)
    local temp1,temp2,temp3 = 0,0,0
    if f1+f2>=fps then temp1=1 end
    f1 = (f1+f2)%fps
    if s1+s2+temp1>=60 then temp2=1 end
    s1 = (s1+s2+temp1)%60
    if m1+m2+temp2>=60 then temp3=1 end
    m1 = (m1+m2+temp2)%60
    h1 = (h1+h2+temp3)
    if h1<10 then h1 = "0"..h1 end
    if m1<10 then m1 = "0"..m1 end
    if s1<10 then s1 = "0"..s1 end
    if f1<10 then f1 = "0"..f1 end
    return h1..":"..m1..":"..s1..":"..f1
end

-- t1 - t2
function NDFminus(t1,t2,fps)
    fps = math.ceil(fps)
    local h1,m1,s1,f1 = t1:match("(%d%d):(%d%d):(%d%d):(%d%d)")
    local h2,m2,s2,f2 = t2:match("(%d%d):(%d%d):(%d%d):(%d%d)")
    h1,m1,s1,f1 = tonumber(h1),tonumber(m1),tonumber(s1),tonumber(f1)
    h2,m2,s2,f2 = tonumber(h2),tonumber(m2),tonumber(s2),tonumber(f2)
    local temp1,temp2,temp3 = 0,0,0
    if f1-f2<0 then temp1=1 end
    f1 = (f1-f2+fps)%fps
    if s1-s2-temp1<0 then temp2=1 end
    s1 = (s1-s2-temp1+60)%60
    if m1-m2-temp2<0 then temp3=1 end
    m1 = (m1-m2-temp2+60)%60
    h1 = (h1-h2-temp3)
    if h1<10 then h1 = "0"..h1 end
    if m1<10 then m1 = "0"..m1 end
    if s1<10 then s1 = "0"..s1 end
    if f1<10 then f1 = "0"..f1 end
    return h1..":"..m1..":"..s1..":"..f1
end

-- a<b -> -1; a=b -> 0; a>b -> 1
function NDFcompare(a,b)
    local h1,m1,s1,f1 = a:match("(%d%d):(%d%d):(%d%d):(%d%d)")
    local h2,m2,s2,f2 = b:match("(%d%d):(%d%d):(%d%d):(%d%d)")
    h1,m1,s1,f1 = tonumber(h1),tonumber(m1),tonumber(s1),tonumber(f1)
    h2,m2,s2,f2 = tonumber(h2),tonumber(m2),tonumber(s2),tonumber(f2)
    if h1<h2 then return -1
    elseif h1>h2 then return 1
    else
        if m1<m2 then return -1
        elseif m1>m2 then return 1
        else
            if s1<s2 then return -1
            elseif s1>s2 then return 1
            else
                if f1<f2 then return -1
                elseif f1>f2 then return 1
                else return 0
                end
            end
        end
    end
end

function length(x1,y1,x2,y2)
    return math.sqrt((x2-x1)^2+(y2-y1)^2)
end

function starttime(frame,fps)
    local t = 1000/fps
    return math.floor((frame*t - t/2)/10)*10
end

function endtime(frame,fps)
    local t = 1000/fps
    return math.floor((frame*t + t/2)/10)*10
end

function round(x)
    return math.floor(x+0.5)
end

function macro_validation(subtitle, selected, active)
    return true
end

--This is what puts your automation in Aegisub's automation list
aegisub.register_macro(script_name.."/simulator",script_description,simulator,macro_validation)
aegisub.register_macro(script_name.."/borderadder",script_description,borderadder,macro_validation)
aegisub.register_macro(script_name.."/slicecutter",script_description,slicecutter,macro_validation)
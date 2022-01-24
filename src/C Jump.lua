--[[
README:

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

]]

script_name="C Jump"
script_description="Jump v1.0"
script_author="chaaaaang"
script_version="1.0" 

include('karaskel.lua')

local dialog_config = {
	{class="checkbox",label="backward",name="backward",x=0,y=0},--1
	{class="checkbox",label="forward",name="forward",x=1,y=0},--2
    {class="label",label="frame",x=0,y=1},--3
    {class="intedit",name="frame",value=0,x=1,y=1},--4
    {class="label",label="time",x=0,y=2},--5
    {class="edit",name="time",value="",x=1,y=2,hint="h:mm:ss:msmsms,0 at high digits can be omitted"}--6
}
local buttons = {"Find Frame","Find Time","Jump out of Mocha Lines","Quit"}

--This is the main processing function that modifies the subtitles
function main(subtitle, selected, active)
    local meta,styles=karaskel.collect_head(subtitle,false)
	local xres, yres, ar, artype = aegisub.video_size()
    local data,tt = {},{}

    -- count
    local N,n,count = #subtitle,#selected,0
    local line_selected

	-- change the content shown in UI
    local timeS,timeE = 0,0
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        karaskel.preproc_line(subtitle,meta,styles,line)
        if line.comment==false then
            if si==1 then 
                timeS,timeE = line.start_time,line.end_time 
                line_selected = li
            else
                timeS,timeE = math.min(timeS,line.start_time),math.max(timeE,line.end_time)
            end
            table.insert(data,line.text_stripped)
        end
    end
    local frameS,frameE = aegisub.frame_from_ms(timeS),aegisub.frame_from_ms(timeE)
	dialog_config[4].value = math.floor((frameS+frameE)/2)
    local time = math.floor((timeS+timeE)/2)
    local hour,minute,second,millisecond = math.floor(time/1000/60/60),math.floor(time%3600000/1000/60),math.floor(time%60000/1000),time%1000
	dialog_config[6].value = hour..":"..minute..":"..second..":"..millisecond

    -- UI
    local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end

    ::loop_start::

	if result.forward==true and result.backward==false then
        -- in case select the last line
        if line_selected+n>N then line_selected=-1*n+1 end

		for i=line_selected+n,N do
            local line = subtitle[i]
            if line.class=="dialogue" and line.comment==false then
                karaskel.preproc_line(subtitle,meta,styles,line)

                local ts,te = line.start_time,line.end_time 
                if pressed=="Find Frame" then
                    local fs,fe = aegisub.frame_from_ms(ts),aegisub.frame_from_ms(te)
                    if fs<=result.frame and fe>=result.frame then
                        table.insert(tt,i)
                        aegisub.set_undo_point(script_name) 
                        return tt
                    end
                elseif pressed=="Find Time" then
                    local h,m,s,ms = result.time:match("(%d*):(%d*):(%d*):(%d*)")
                    h,m,s,ms = tonumber(h),tonumber(m),tonumber(s),tonumber(ms)
                    local t = h*1000*60*60 + m*1000*60 + s*1000 + ms
                    if ts<=t and te>=t then
                        table.insert(tt,i)
                        aegisub.set_undo_point(script_name) 
                        return tt
                    end
                elseif pressed=="Jump out of Mocha Lines" then
                    local same = false
                    for __,j in ipairs(data) do
                        if line.text_stripped==j then 
                            same = true 
                            break
                        end
                    end
                    if same==false then
                        table.insert(tt,i)
                        aegisub.set_undo_point(script_name) 
                        return tt
                    end
                end
            end
            
            --circle
            if i == N then
                if count==1 then break end
                count,line_selected = 1,-1*n+1
                goto loop_start
            end
        end
    elseif result.forward==false and result.backward==true then
        for i=line_selected-1,1,-1 do
            local line = subtitle[i]
            if line.class=="dialogue" and line.comment==false then
                karaskel.preproc_line(subtitle,meta,styles,line)

                local ts,te = line.start_time,line.end_time 
                if pressed=="Find Frame" then
                    local fs,fe = aegisub.frame_from_ms(ts),aegisub.frame_from_ms(te)
                    if fs<=result.frame and fe>=result.frame then
                        table.insert(tt,i)
                        aegisub.set_undo_point(script_name) 
                        return tt
                    end
                elseif pressed=="Find Time" then
                    local h,m,s,ms = result.time:match("(%d*):(%d*):(%d*):(%d*)")
                    h,m,s,ms = tonumber(h),tonumber(m),tonumber(s),tonumber(ms)
                    local t = h*1000*60*60 + m*1000*60 + s*1000 + ms
                    if ts<=t and te>=t then
                        table.insert(tt,i)
                        aegisub.set_undo_point(script_name) 
                        return tt
                    end
                elseif pressed=="Jump out of Mocha Lines" then
                    local same = false
                    for __,j in ipairs(data) do
                        if line.text_stripped==j then 
                            same = true 
                            break
                        end
                    end
                    if same==false then
                        table.insert(tt,i)
                        aegisub.set_undo_point(script_name) 
                        return tt
                    end
                end
            end
            
            --circle
            if i == N then
                if count==1 then break end
                count,line_selected = 1,N+1
                goto loop_start
            end
        end
    else
        aegisub.cancel()
	end
	
    aegisub.set_undo_point(script_name) 
    return selected 
end

function round(x)
	return math.floor(x+0.5)
end

function macro_validation(subtitle, selected, active)
    return true
end

--This is what puts your automation in Aegisub's automation list
aegisub.register_macro(script_name,script_description,main,macro_validation)
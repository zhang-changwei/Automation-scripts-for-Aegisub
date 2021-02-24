--[[
README:


]]

script_name="C Smooth"
script_description="Smooth v1.0"
script_author="chaaaaang"
script_version="1.0" 

include("karaskel.lua")
require("lfs")

function main(subtitle, selected, active)
    local meta,styles=karaskel.collect_head(subtitle,false)

    --count the size N
    local i = 0

    for sa,la in ipairs(selected) do
        local line = subtitle[la]
        local ltext=(line.text:match("^{")==nil) and "{}"..line.text or line.text
		ltext=ltext:gsub("}{","")
        line.text = ltext
        subtitle[la] = line
        i = i + 1
    end
    local N = i
    --end count the size N
    config_table = config_read()

    --GUI
    dialog_config={
        {class="dropdown",name="tagtype",items={"posx","posy","fscx","fscy","frz"},value=config_table.tag,x=0,y=0},
        {class="label",label="index",x=1,y=0},
        {class="intedit",name="index",value=config_table.index,x=2,y=0},
        --100 percent
        {class="label",label="lower threshold",x=0,y=1},
        {class="floatedit",name="lower_threshold",value=config_table.L,x=1,y=1,hint="default: 180"},
        {class="checkbox",name="keep_L",label="keep checking lower_threshold",value=config_table.keep_L,x=2,y=1,width=2},

        {class="label",label="upper threshold",x=0,y=2},
        {class="floatedit",name="upper_threshold",value=config_table.U,x=1,y=2,hint="default: 500"},
        {class="checkbox",name="keep_U",label="keep checking upper_threshold",value=config_table.keep_U,x=2,y=2,width=2},
        --force 0-100
        {class="label",label="force",x=0,y=3},
        {class="floatedit",name="force",value=config_table.F,x=1,y=3,hint="default: 30"},
        {class="checkbox",name="remember",label="remember config",value=config_table.remember,x=2,y=3,width=2},
    }
    buttons={"Run","Quit"}

    pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end

    if (pressed=="Run") then
        if (result["remember"]==true) then config_write(result) end
        result["upper_threshold"] = result["upper_threshold"]/100
        result["lower_threshold"] = result["lower_threshold"]/100
        result["force"] = result["force"]/100
        tag_table={}

        --get the tag information and write it to a table
        if (result["tagtype"]=="posx" or result["tagtype"]=="posy") then
            local i = 0 
            for si,li in ipairs(selected) do
                i = i + 1
                local line = subtitle[li]
                if (result["tagtype"]=="posx") then 
                    local posx = tonumber(line.text:match("\\pos%(([%d%.%-]+)"))
                    table.insert(tag_table,{index=i,value=posx,change=""})
                else
                    local posy = tonumber(line.text:match("\\pos%([%d%.%-]+,([%d%.%-]+)"))
                    table.insert(tag_table,{index=i,value=posy,change=""})
                end
            end
        elseif (result["tagtype"]=="fscx" or result["tagtype"]=="fscy" or result["tagtype"]=="frz") then
            local i = 0
            for si,li in ipairs(selected) do
                i = i + 1
                local line = subtitle[li]
                local tt_table={}
                for tg,tx in line.text:gmatch("({[^}]*})([^{]*)") do
                    table.insert(tt_table,{tag=tg,text=tx})
                end

                local count = 0
                for _,tt in ipairs(tt_table) do
                    tt.tag = tt.tag:gsub("\\"..result["tagtype"],"}\\"..result["tagtype"])
                    tt.tag = tt.tag.."\\"..result["tagtype"].."0"
                    for p,q in tt.tag:gmatch("([^}]*)}\\"..result["tagtype"].."([%d%.%-]+)") do
                        count = count + 1
                        if (count == result["index"]) then
                            table.insert(tag_table,{index=i,value=q,change=""})
                            goto get_information
                        end 
                    end
                    count = count - 1
                end
                :: get_information ::
            end
        end

        --analyze the table
        local sum_diff = 0
        for i=1,N-1 do
            sum_diff = sum_diff + math.abs(tag_table[i+1].value - tag_table[i].value)
        end
        local average_diff = sum_diff / (N-1) + 0.001

        --upper threshold
        local tag_table_upper={}--a copy of tag_table
        for i=2,N-1 do
            local diff_l = math.abs(tag_table[i].value - tag_table[i-1].value)
            local diff_r = math.abs(tag_table[i].value - tag_table[i+1].value)
            if (diff_l/average_diff>=result["upper_threshold"] and diff_r/average_diff>=result["upper_threshold"]) then
                local tag = tag_table[i]
                tag.value = (tag_table[i-1].value + tag_table[i+1].value) / 2
                tag.change = "U"
                table.insert(tag_table_upper,tag)
            end
        end
        for si,upper in ipairs(tag_table_upper) do
            local tag = tag_table[upper.index]
            tag.value = upper.value
            tag.change = upper.change
            tag_table[upper.index] = tag
        end
        --get the average_diff again 
        sum_diff = 0
        for i=1,N-1 do
            sum_diff = sum_diff + math.abs(tag_table[i+1].value - tag_table[i].value)
        end
        average_diff = sum_diff / (N-1) + 0.001
        --lower threshold
        local tag_table_lower={}--a copy of tag_table
        for i=2,N-1 do
            local diff_l = math.abs(tag_table[i].value - tag_table[i-1].value)
            local diff_r = math.abs(tag_table[i].value - tag_table[i+1].value)
            local diff_c = tag_table[i].value - (tag_table[i-1].value + tag_table[i+1].value)/2
            if (diff_l/average_diff>=result["lower_threshold"] or diff_r/average_diff>=result["lower_threshold"]) then
                local tag = tag_table[i]
                tag.value = tag_table[i].value - diff_c * result["force"]
                tag.change = tag.change.."L"
                table.insert(tag_table_lower,tag)
            end
        end
        for si,lower in ipairs(tag_table_lower) do
            local tag = tag_table[lower.index]
            tag.value = lower.value
            tag.change = lower.change
            tag_table[lower.index] = tag
        end
        --analyze tag_table end

        --write back
        if (result["tagtype"]=="posx" or result["tagtype"]=="posy") then
            local i = 0
            for si,li in ipairs(selected) do
                i = i + 1
                local line = subtitle[li]
                local ltext = line.text
                if (result["tagtype"]=="posx") then
                    ltext = ltext:gsub("\\pos%([%d%.%-]+",string.format("\\pos(%.3f",tag_table[i].value))
                else
                    ltext = ltext:gsub("(\\pos%([%d%.%-]+,)[%d%.%-]+",function(a) return string.format("%s%.3f",a,tag_table[i].value) end)
                end
                line.text = ltext
                line.actor = tag_table[i].change
                subtitle[li] = line
            end
        elseif (result["tagtype"]=="fscx" or result["tagtype"]=="fscy" or result["tagtype"]=="frz") then 
            local i = 0
            for si,li in ipairs(selected) do
                i = i + 1
                local line = subtitle[li]
                local ltext = line.text

                local tt_table={}
                for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
                    table.insert(tt_table,{tag=tg,text=tx})
                end

                local rebuild = ""
                local count = 0
                for _,tt in ipairs(tt_table) do
                    if (tt.tag:match("\\"..result["tagtype"])==nil) then
                        rebuild = rebuild..tt.tag..tt.text
                    else
                        tt.tag = tt.tag:gsub("\\"..result["tagtype"],"}\\"..result["tagtype"])
                        tt.tag = tt.tag.."\\"..result["tagtype"].."0"
                        local rebuild_tag = ""

                        for p,q in tt.tag:gmatch("([^}]*)}\\"..result["tagtype"].."([%d%.%-]+)") do
                            count = count + 1
                            if (count == result["index"]) then
                                rebuild_tag = string.format("%s%s\\%s%.2f",rebuild_tag,p,result["tagtype"],tag_table[i].value)
                            else
                                rebuild_tag = rebuild_tag..p.."\\"..result["tagtype"]..q
                            end
                        end
                        rebuild_tag = rebuild_tag:gsub("\\"..result["tagtype"].."[%d%.%-]+$","}")
                        rebuild = rebuild..rebuild_tag..tt.text
                        count = count - 1
                    end
                end
                ltext = rebuild
                line.text = ltext
                line.actor = tag_table[i].change
                subtitle[li] = line
            end
        end
    end
    aegisub.set_undo_point(script_name) 
    return selected 
end

function config_read ()
    local path = ""
    local config_table = {tag="fscx",index=1,U=500,L=180,F=30,remember=false,keep_U=false,keep_L=false}
    for p in lfs.dir("C:\\Users") do
        if (p~="Public" and p:match("Default")==nil) then
            path = "C:\\Users\\"..p.."\\AppData\\Roaming\\Aegisub\\C Smooth.txt"
        end
    end
    if io.open(path,"r") then
        file = io.open(path,"r")
        io.input(file)
        for line in io.lines(path) do
            if line:match("tag") then config_table.tag=line:match(":(.*)")
            elseif line:match("index") then config_table.index=line:match(":(.*)")
            elseif line:match("upper_threshold") then config_table.U=line:match(":(.*)")
            elseif line:match("lower_threshold") then config_table.L=line:match(":(.*)")
            elseif line:match("force") then config_table.F=line:match(":(.*)")
            elseif line:match("keep_U") then config_table.keep_U=line:match(":(.*)")=="true" and true or false
            elseif line:match("keep_L") then config_table.keep_L=line:match(":(.*)")=="true" and true or false
            elseif line:match("remember") then config_table.remember=line:match(":(.*)")=="true" and true or false
            end
        end
        io.close(file)
    end
    return config_table
end

function config_write(result)
    local path = ""
    for p in lfs.dir("C:\\Users") do
        if (p~="Public" and p:match("Default")==nil) then
            path = "C:\\Users\\"..p.."\\AppData\\Roaming\\Aegisub\\C Smooth.txt"
        end
    end
    file = io.open(path,"w+")
    io.output(file)
    io.write("tag:"..result.tagtype.."\n")
    io.write("index:"..result.index.."\n")
    io.write("upper_threshold:"..result.upper_threshold.."\n")
    io.write("lower_threshold:"..result.lower_threshold.."\n")
    io.write("force:"..result.force.."\n")
    keep_U = result.keep_U and "true" or "false"
    keep_L = result.keep_L and "true" or "false"
    remember = result.remember and "true" or "false"
    io.write("keep_U:"..keep_U.."\n")
    io.write("keep_L:"..keep_L.."\n")
    io.write("remember:"..remember)
    io.close(file)
end

--This optional function lets you prevent the user from running the macro on bad input
function macro_validation(subtitle, selected, active)
    --Check if the user has selected valid lines
    --If so, return true. Otherwise, return false
    return true
end

--This is what puts your automation in Aegisub's automation list
aegisub.register_macro(script_name,script_description,main,macro_validation)


--[[
README:

]]

--Script properties
script_name="C Fast Tools"
script_description="Fast Tools"
script_author="chaaaaang"
script_version="1.0"

clipboard = require 'aegisub.clipboard'

function fast_clip_iclip_converter(subtitle, selected)
    for si,li in ipairs(selected) do      
        local line=subtitle[li]
        local linetext = line.text
        linetext = linetext:gsub("(\\i?clip)",function (a)
            if a:match("iclip")~=nil then
                return "\\clip"
            else
                return "\\iclip"
            end
        end)
        line.text = linetext
        subtitle[li]=line
    end
	aegisub.set_undo_point(script_name)
	return selected
end

function fast_copy(subtitle, selected)

    local data = clipboard.get()
    local data_table = {}
    data = data.."\n"

    for i in data:gmatch("(.-)\n") do
        local layer,style,l,r,v,effect,text

        layer = tonumber(i:match("(%d+),"))
        i = i:gsub("[^,]*,","",3)
        style = i:match("(.-),")
        i = i:gsub("[^,]*,","",2)
        l = tonumber(i:match("(.-),"))
        i = i:gsub("[^,]*,","",1)
        r = tonumber(i:match("(.-),"))
        i = i:gsub("[^,]*,","",1)
        v = tonumber(i:match("(.-),"))
        i = i:gsub("[^,]*,","",1)
        effect = i:match("(.-),")
        i = i:gsub("[^,]*,","",1)
        text = i
        -- clear the mocha stuff
        i = i:gsub("^{=%d+}","")
        table.insert(data_table,{ly=layer,s=style,l=l,r=r,v=v,e=effect,t=text})
    end

    for si,li in ipairs(selected) do
        if si>#data_table then break end
        local line=subtitle[li]
        local linetext = line.text
        linetext = data_table[si].t
        line.text = linetext

        line.layer = data_table[si].ly
        line.style = data_table[si].s
        line.margin_l = data_table[si].l
        line.margin_r = data_table[si].r
        
        subtitle[li]=line

        if si==#selected and si<#data_table then
            if li~=#subtitle then
                for j = 1,#data_table-si do
                    subtitle.insert(li+j,line)
                    local new_line = subtitle[li+j]
                    new_line.text = data_table[si+j].t

                    new_line.layer = data_table[si+j].ly
                    new_line.style = data_table[si+j].s
                    new_line.margin_l = data_table[si+j].l
                    new_line.margin_r = data_table[si+j].r

                    subtitle[li+j]=new_line
                end
            else
                for j = 1,#data_table-si do
                    subtitle.append(line)
                    local new_line = subtitle[li+j]
                    new_line.text = data_table[si+j].t

                    new_line.layer = data_table[si+j].ly
                    new_line.style = data_table[si+j].s
                    new_line.margin_l = data_table[si+j].l
                    new_line.margin_r = data_table[si+j].r

                    subtitle[li+j]=new_line
                end
            end
        end
    end

	aegisub.set_undo_point(script_name)
	return selected
end

--Register macro (no validation function required)
aegisub.register_macro(script_name.."/fast_clip_iclip_converter",script_description,fast_clip_iclip_converter)
aegisub.register_macro(script_name.."/fast_copy",script_description,fast_copy)
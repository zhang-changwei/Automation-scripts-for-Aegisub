--[[
README:

Merge Bilingual SUBS

Feature:
Move english SUBS in the previous/next line to this line

Manual:
Select the line and hit the hotkey (If you don't use hotkeys, the script is useless)
]]

--Script properties
script_name="C Merge Bilingual SUBS"
script_description="Merge Bilingual SUBS"
script_author="chaaaaang"
script_version="1.0"


function pre1(subtitle, selected)
    local sel_text = ""
    for sj,lj in ipairs(selected) do
        local line = subtitle[lj]
        sel_text = line.text
    end
    for li=1,#subtitle do
        local line = subtitle[li]
        if (line.class == "dialogue" and line.text == sel_text) then
            local line_pre = subtitle[li-1]
            local text = ""
            if (line_pre.text:match("{[^}]*}")) then
                text = line_pre.text:match("}(.*)")
                line_pre.text = line_pre.text:gsub("}.*","}")
            else
                text = line_pre.text
                line_pre.text = ""
            end
            subtitle[li-1] = line_pre
            line.text = line.text..text
            subtitle[li] = line
        end	
	end
	aegisub.set_undo_point(script_name)
	return selected
end

function pre2(subtitle, selected)
    local sel_text = ""
    for sj,lj in ipairs(selected) do
        local line = subtitle[lj]
        sel_text = line.text
    end
    for li=1,#subtitle do
        local line = subtitle[li]
        if (line.class == "dialogue" and line.text == sel_text) then
            local line_pre = subtitle[li-2]
            local text = ""
            if (line_pre.text:match("{[^}]*}")) then
                text = line_pre.text:match("}(.*)")
                line_pre.text = line_pre.text:gsub("}.*","}")
            else
                text = line_pre.text
                line_pre.text = ""
            end
            subtitle[li-2] = line_pre
            line.text = line.text..text
            subtitle[li] = line
        end	
	end
	aegisub.set_undo_point(script_name)
	return selected
end

function next1(subtitle, selected)
    local sel_text = ""
    for sj,lj in ipairs(selected) do
        local line = subtitle[lj]
        sel_text = line.text
    end
    for li=1,#subtitle do
        local line = subtitle[li]
        if (line.class == "dialogue" and line.text == sel_text) then
            local line_next = subtitle[li+1]
            local text = ""
            if (line_next.text:match("{[^}]*}")) then
                text = line_next.text:match("}(.*)")
                line_next.text = line_next.text:gsub("}.*","}")
            else
                text = line_next.text
                line_next.text = ""
            end
            subtitle[li+1] = line_next
            line.text = line.text..text
            subtitle[li] = line
        end	
	end
	aegisub.set_undo_point(script_name)
	return selected
end

function next2(subtitle, selected)
    local sel_text = ""
    for sj,lj in ipairs(selected) do
        local line = subtitle[lj]
        sel_text = line.text
    end
    for li=1,#subtitle do
        local line = subtitle[li]
        if (line.class == "dialogue" and line.text == sel_text) then
            local line_next = subtitle[li+2]
            local text = ""
            if (line_next.text:match("{[^}]*}")) then
                text = line_next.text:match("}(.*)")
                line_next.text = line_next.text:gsub("}.*","}")
            else
                text = line_next.text
                line_next.text = ""
            end
            subtitle[li+2] = line_next
            line.text = line.text..text
            subtitle[li] = line
        end	
	end
	aegisub.set_undo_point(script_name)
	return selected
end

--Register macro (no validation function required)
aegisub.register_macro(script_name.."/pre2",script_description,pre2)
aegisub.register_macro(script_name.."/pre1",script_description,pre1)
aegisub.register_macro(script_name.."/next1",script_description,next1)
aegisub.register_macro(script_name.."/next2",script_description,next2)

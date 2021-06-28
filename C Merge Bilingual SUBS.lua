--[[
README:

Merge Bilingual SUBS

Feature:
Move english SUBS in the previous/next line to this line

Manual:
Select the line and hit the hotkey (If you don't use hotkeys, the script is useless)

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

]]

--Script properties
script_name="C Merge Bilingual SUBS"
script_description="Merge Bilingual SUBS v1.2"
script_author="chaaaaang"
script_version="1.2"

include('karaskel.lua')

function pre1_eng(subtitle, selected)
    local meta, styles = karaskel.collect_head(subtitle, false)
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        local line_pre = subtitle[li-1]
        karaskel.preproc_line_text(meta, styles, line_pre)
        local text = ""
        if line_pre.text_stripped:match("\\N") then
            text = line_pre.text_stripped:match("\\N(.*)")
            if line_pre.text:match("\\N *{") then
                line_pre.text = line_pre.text:gsub("(\\N{[^}]*}).*","%1")
            else
                line_pre.text = line_pre.text:gsub("\\N.*","\\N")
            end
        else
            text = line_pre.text_stripped
            line_pre.text = ""
        end

        subtitle[li-1] = line_pre

        if line.text:match("\\N{") then
            line.text = line.text:gsub("(\\N{[^}]*})","%1"..text.." ")
        elseif line.text:match("\\N") then
            line.text = line.text:gsub("(\\N)","%1"..text.." ")
        elseif line.text:match("{") then
            line.text = line.text:gsub("({[^}]*})","%1"..text.." ")
        else
            line.text = line.text:gsub("^",text.." ")
        end
        subtitle[li] = line
    end
    
	aegisub.set_undo_point(script_name)
	return selected
end

function pre2_eng(subtitle, selected)
    local meta, styles = karaskel.collect_head(subtitle, false)
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        local line_pre = subtitle[li-2]
        karaskel.preproc_line_text(meta, styles, line_pre)
        local text = ""
        if line_pre.text_stripped:match("\\N") then
            text = line_pre.text_stripped:match("\\N(.*)")
            if line_pre.text:match("\\N *{") then
                line_pre.text = line_pre.text:gsub("(\\N{[^}]*}).*","%1")
            else
                line_pre.text = line_pre.text:gsub("\\N.*","\\N")
            end
        else
            text = line_pre.text_stripped
            line_pre.text = ""
        end

        subtitle[li-2] = line_pre

        if line.text:match("\\N{") then
            line.text = line.text:gsub("(\\N{[^}]*})","%1"..text.." ")
        elseif line.text:match("\\N") then
            line.text = line.text:gsub("(\\N)","%1"..text.." ")
        elseif line.text:match("{") then
            line.text = line.text:gsub("({[^}]*})","%1"..text.." ")
        else
            line.text = line.text:gsub("^",text.." ")
        end
        subtitle[li] = line
    end
    
	aegisub.set_undo_point(script_name)
	return selected
end

function next1_eng(subtitle, selected)
    local meta, styles = karaskel.collect_head(subtitle, false)
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        local line_next = subtitle[li+1]
        karaskel.preproc_line_text(meta, styles, line_next)
        local text = ""
        if line_next.text_stripped:match("\\N") then
            text = line_next.text_stripped:match("\\N(.*)")
            if line_next.text:match("\\N *{") then
                line_next.text = line_next.text:gsub("(\\N{[^}]*}).*","%1")
            else
                line_next.text = line_next.text:gsub("\\N.*","\\N")
            end
        else
            text = line_next.text_stripped
            line_next.text = ""
        end

        subtitle[li+1] = line_next

        if line.text:match("}$") then
            line.text = line.text:gsub("({[^}]*})",""..text.."%1")
        else
            line.text = line.text:gsub("$"," "..text)
        end
        subtitle[li] = line
    end
    
	aegisub.set_undo_point(script_name)
	return selected
end

function next2_eng(subtitle, selected)
    local meta, styles = karaskel.collect_head(subtitle, false)
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        local line_next = subtitle[li+2]
        karaskel.preproc_line_text(meta, styles, line_next)
        local text = ""
        if line_next.text_stripped:match("\\N") then
            text = line_next.text_stripped:match("\\N(.*)")
            if line_next.text:match("\\N *{") then
                line_next.text = line_next.text:gsub("(\\N{[^}]*}).*","%1")
            else
                line_next.text = line_next.text:gsub("\\N.*","\\N")
            end
        else
            text = line_next.text_stripped
            line_next.text = ""
        end

        subtitle[li+2] = line_next

        if line.text:match("}$") then
            line.text = line.text:gsub("({[^}]*})",""..text.."%1")
        else
            line.text = line.text:gsub("$"," "..text)
        end
        subtitle[li] = line
    end
    
	aegisub.set_undo_point(script_name)
	return selected
end

function pre1_chs(subtitle, selected)
    local meta, styles = karaskel.collect_head(subtitle, false)
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        local line_pre = subtitle[li-1]
        karaskel.preproc_line_text(meta, styles, line_pre)
        local text = ""
        if line_pre.text_stripped:match("\\N") then
            text = line_pre.text_stripped:match("(.*)\\N")
            line_pre.text = line_pre.text:gsub("(.*)\\N","\\N")
        else
            text = line_pre.text_stripped
            line_pre.text = ""
        end

        subtitle[li-1] = line_pre

        if line.text:match("^{") then
            line.text = line.text:gsub("^({[^}]*})","%1"..text.."")
        else
            line.text = line.text:gsub("^",text.."")
        end
        subtitle[li] = line
    end
    
	aegisub.set_undo_point(script_name)
	return selected
end

function pre2_chs(subtitle, selected)
    local meta, styles = karaskel.collect_head(subtitle, false)
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        local line_pre = subtitle[li-2]
        karaskel.preproc_line_text(meta, styles, line_pre)
        local text = ""
        if line_pre.text_stripped:match("\\N") then
            text = line_pre.text_stripped:match("(.*)\\N")
            line_pre.text = line_pre.text:gsub("(.*)\\N","\\N")
        else
            text = line_pre.text_stripped
            line_pre.text = ""
        end

        subtitle[li-2] = line_pre

        if line.text:match("^{") then
            line.text = line.text:gsub("^({[^}]*})","%1"..text.."")
        else
            line.text = line.text:gsub("^",text.."")
        end
        subtitle[li] = line
    end
    
	aegisub.set_undo_point(script_name)
	return selected
end

function next1_chs(subtitle, selected)
    local meta, styles = karaskel.collect_head(subtitle, false)
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        local line_next = subtitle[li+1]
        karaskel.preproc_line_text(meta, styles, line_next)
        local text = ""
        if line_next.text_stripped:match("\\N") then
            text = line_next.text_stripped:match("(.*)\\N")
            line_next.text = line_next.text:gsub("(.*)\\N","\\N")
        else
            text = line_next.text_stripped
            line_next.text = ""
        end

        subtitle[li+1] = line_next

        if line.text:match("\\N") then
            line.text = line.text:gsub("\\N",""..text.."\\N")
        elseif line.text:match("}$") then
            line.text = line.text:gsub("({[^}]*})$",""..text.."%1")
        else
            line.text = line.text:gsub("$",""..text)
        end
        subtitle[li] = line
    end
    
	aegisub.set_undo_point(script_name)
	return selected
end

function next2_chs(subtitle, selected)
    local meta, styles = karaskel.collect_head(subtitle, false)
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        local line_next = subtitle[li+2]
        karaskel.preproc_line_text(meta, styles, line_next)
        local text = ""
        if line_next.text_stripped:match("\\N") then
            text = line_next.text_stripped:match("(.*)\\N")
            line_next.text = line_next.text:gsub("(.*)\\N","\\N")
        else
            text = line_next.text_stripped
            line_next.text = ""
        end

        subtitle[li+2] = line_next

        if line.text:match("\\N") then
            line.text = line.text:gsub("\\N",""..text.."\\N")
        elseif line.text:match("}$") then
            line.text = line.text:gsub("({[^}]*})$",""..text.."%1")
        else
            line.text = line.text:gsub("$",""..text)
        end
        subtitle[li] = line
    end
    
	aegisub.set_undo_point(script_name)
	return selected
end

function slide_backward_chs(subtitle, selected)
    local meta, styles = karaskel.collect_head(subtitle, false)
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        local line_next = subtitle[li+1]
        karaskel.preproc_line_text(meta, styles, line_next)
        local text = ""
        if line_next.text_stripped:match("^ ") then
            text = " "
            if line_next.text:match("^{")~=nil then
                line_next.text = line_next.text:gsub("^({[^}]*}) ","%1")
            else
                line_next.text = line_next.text:gsub("^ ","")
            end
        elseif line_next.text_stripped:match("^%-") then
            text = "-"
            if line_next.text:match("^{")~=nil then
                line_next.text = line_next.text:gsub("^({[^}]*})%-","%1")
            else
                line_next.text = line_next.text:gsub("^%-","")
            end
        else
            text = line_next.text_stripped:match("^(...)")
            line_next.text = line_next.text:gsub(text,"",1)
        end
        
        subtitle[li+1] = line_next

        if line.text:match("\\N") then
            line.text = line.text:gsub("\\N",""..text.."\\N")
        elseif line.text:match("}$") then
            line.text = line.text:gsub("({[^}]*})$",""..text.."%1")
        else
            line.text = line.text:gsub("$",""..text)
        end
        subtitle[li] = line
    end
    
	aegisub.set_undo_point(script_name)
	return selected
end

function slide_forward_chs(subtitle, selected)
    local meta, styles = karaskel.collect_head(subtitle, false)
    for si,li in ipairs(selected) do
        local line = subtitle[li]
        local line_next = subtitle[li+1]
        karaskel.preproc_line_text(meta, styles, line)
        local text = ""
        if line.text_stripped:match("\\N") then
            if line.text_stripped:match(" \\N") then
                text = line.text_stripped:match("( )\\N")
                line.text = line.text:gsub("( )\\N","\\N")
            elseif line.text_stripped:match("%-\\N") then
                text = line.text_stripped:match("(%-)\\N")
                line.text = line.text:gsub("(%-)\\N","\\N")
            else
                text = line.text_stripped:match("(...)\\N")
                line.text = line.text:gsub("(...)\\N","\\N")
            end
        else
            if line.text_stripped:match(" $") then
                text = line.text_stripped:match("( )$")
                line.text = line.text:gsub("( )$","")
            elseif line.text_stripped:match("%-$") then
                text = line.text_stripped:match("(%-)$")
                line.text = line.text:gsub("(%-)$","")
            else
                text = line.text_stripped:match("(...)$")
                line.text = line.text:gsub("(...)$","")
            end
        end
        
        subtitle[li] = line

        if line_next.text:match("^{") then
            line_next.text = line_next.text:gsub("^({[^}]*})","%1"..text.."")
        else
            line_next.text = line_next.text:gsub("^",text.."")
        end
        subtitle[li+1] = line_next
    end
    
	aegisub.set_undo_point(script_name)
	return selected
end

--Register macro (no validation function required)
aegisub.register_macro(script_name.."/pre2_eng",script_description,pre2_eng)
aegisub.register_macro(script_name.."/pre1_eng",script_description,pre1_eng)
aegisub.register_macro(script_name.."/next1_eng",script_description,next1_eng)
aegisub.register_macro(script_name.."/next2_eng",script_description,next2_eng)
aegisub.register_macro(script_name.."/pre2_chs",script_description,pre2_chs)
aegisub.register_macro(script_name.."/pre1_chs",script_description,pre1_chs)
aegisub.register_macro(script_name.."/next1_chs",script_description,next1_chs)
aegisub.register_macro(script_name.."/next2_chs",script_description,next2_chs)
aegisub.register_macro(script_name.."/slide_backward_chs",script_description,slide_backward_chs)
aegisub.register_macro(script_name.."/slide_forward_chs",script_description,slide_forward_chs)

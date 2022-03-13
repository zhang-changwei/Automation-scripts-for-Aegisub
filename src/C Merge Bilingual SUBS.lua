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
local re = require('aegisub.re')

function better_bilang_combiner(subtitle, selected)
    local dialog_config = {
        {class='label', label='Better Bilang Combiner v1.3', x=0, y=0, width=4},
        {class='label', label='Selected: ', x=0, y=1, width=2},
        {class='dropdown',name='sel', items={'Chinese Lines','English Lines'}, value='Chinese Lines', x=2, y=1,width=2},
        {class='label', label='Timeline based on:', x=0, y=2, width=3},
        {class='dropdown', name='time', items={'Chinese', 'English'}, value='Chinese', x=3, y=2},

        {class='label', label='delete', x=0, y=3},
        {class='checkbox', label='...', name='deldots', value=true, x=1, y=3},
        {class='checkbox', label='--',  name='delbars', value=true, x=2, y=3},
        {class='checkbox', label='{}',  name='delkets', value=true, x=3, y=3},

        {class='label', label='ignore', x=0, y=4},
        {class='checkbox', label='*', name='ignstar', value=true, x=1, y=4},
        {class='checkbox', label='♪', name='ignsong', value=true, x=2, y=4},
        {class='checkbox', label='#', name='ignwell', value=true, x=3, y=4}
    }
    local buttons = {'Run', 'Quit'}

    local meta,styles=karaskel.collect_head(subtitle,false)
    local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if pressed~="Run" then aegisub.cancel() end    

    local zhoList, engList = {},{}
    local ii = 1 
    while ii<=#subtitle do
        if ii==selected[1] then ii = selected[#selected]
        elseif subtitle[ii].class~='dialogue' then
        else
            local line = subtitle[ii]
            local linetext = line.text:gsub('^ *',''):gsub(' *$','')
            local linetextstriptag = linetext:gsub('{[^}]*}','')
            if line.comment==true then
            elseif (result.ignstar==true and linetextstriptag:match('^.')=='*') 
                or (result.ignsong==true and linetextstriptag:match('^...')=='♪')
                or (result.ignwell==true and linetextstriptag:match('^.')=='#') then
                    line.text = '{\\an8}'..linetext
                    subtitle[ii] = line
            else
                line.text = linetext
                subtitle[ii] = line
                if result.sel=='Chinese Lines' then table.insert(engList, ii)
                else table.insert(zhoList, ii) end
            end
        end
        ii = ii + 1
    end
    for _,i in ipairs(selected) do
        if subtitle[i].class~='dialogue' then
        else
            local line = subtitle[i]
            local linetext = line.text:gsub('^ *',''):gsub(' *$','')
            local linetextstriptag = linetext:gsub('{[^}]*}','')
            if line.comment==true then
            elseif (result.ignstar==true and linetextstriptag:match('^.')=='*') 
                or (result.ignsong==true and linetextstriptag:match('^...')=='♪')
                or (result.ignwell==true and linetextstriptag:match('^.')=='#') then
                    line.text = '{\\an8}'..linetext
                    subtitle[i] = line
            else
                line.text = linetext
                subtitle[i] = line
                if result.sel=='Chinese Lines' then table.insert(zhoList, i)
                else table.insert(engList, i) end
            end
        end
    end

    local zhoH, zhoT, engH, engT = 1,1,1,1
    while zhoH<=#zhoList and engH<=#engList do
        local zhoI ,engI = zhoList[zhoT], engList[engT]
        local zhoLine, engLine = subtitle[zhoI], subtitle[engI]
        local score = getscore(zhoLine, engLine)
        if score<=0 then
            if engLine.end_time<zhoLine.end_time then -- eng behind
                local linetext = ''
                for li in re.gsplit(engLine.text, '\\\\N') do
                    if result.deldots==true then li = li:gsub('^%.%.%.',''):gsub('%.%.%.$','') end
                    if result.delbars==true then li = li:gsub('^%-%-',''):gsub('%-%-$','') end
                    if result.delkets==true then li = li:gsub('{[^}]*}','') end
                    linetext = linetext..li..' '
                end
                engLine.text = linetext:gsub(' $','')
                subtitle[engI] = engLine
                engT = engT + 1
                engH = engT
            else
                local linetext = ''
                for li in re.gsplit(zhoLine.text, '\\\\N') do
                    if result.deldots==true then li = li:gsub('^%.%.%.',''):gsub('%.%.%.$','') end
                    if result.delbars==true then li = li:gsub('^%-%-',''):gsub('%-%-$','') end
                    if result.delkets==true then li = li:gsub('{[^}]*}','') end
                    linetext = linetext..li..' '
                end
                zhoLine.text = linetext:gsub(' $','')
                subtitle[zhoI] = zhoLine
                zhoT = zhoT + 1
                zhoH = zhoT
            end
        else
            local zhoMerge, engMerge = true, true
            -- merge zho
            ::zhoengSTART::
            if zhoMerge==true and zhoT+1<=#zhoList then
                local scoreplus = getscore(subtitle[zhoList[zhoT+1]], engLine)
                if scoreplus>0 then
                    if engT+1<=#engList and getscore(subtitle[zhoList[zhoT+1]], subtitle[engList[engT+1]])<scoreplus or engT==#engList then
                        zhoT, engMerge = zhoT+1, false
                        goto zhoengSTART
                    end
                end
            end
            -- merge english
            if engMerge==true and engT+1<=#engList then
                local scoreplus = getscore(subtitle[engList[engT+1]], zhoLine)
                if scoreplus>0 then
                    if zhoT+1<=#zhoList and getscore(subtitle[zhoList[zhoT+1]], subtitle[engList[engT+1]])<scoreplus or zhoT==#zhoList then
                        engT, zhoMerge = engT+1, false
                        goto zhoengSTART
                    end
                end
            end
            -- merge subtitle
            local linetext = ''
            for i=zhoH,zhoT do
                local zhoLi = subtitle[zhoList[i]]
                for li in re.gsplit(zhoLi.text, '\\\\N') do
                    if result.deldots==true then li = li:gsub('^%.%.%.',''):gsub('%.%.%.$','') end
                    if result.delbars==true then li = li:gsub('^%-%-',''):gsub('%-%-$','') end
                    if result.delkets==true then li = li:gsub('{[^}]*}','') end
                    linetext = linetext..li..' '
                end
                zhoLi.text = ''
                subtitle[zhoList[i]] = zhoLi
            end
            linetext = linetext:gsub(' $','\\N')
            for i=engH,engT do
                local engLi = subtitle[engList[i]]
                for li in re.gsplit(engLi.text, '\\\\N') do
                    if result.deldots==true then li = li:gsub('^%.%.%.',''):gsub('%.%.%.$','') end
                    if result.delbars==true then li = li:gsub('^%-%-',''):gsub('%-%-$','') end
                    if result.delkets==true then li = li:gsub('{[^}]*}','') end
                    linetext = linetext..li..' '
                end
                engLi.text = ''
                subtitle[engList[i]] = engLi
            end
            -- rewrite
            if result.time=='Chinese' then
                zhoLine.text = linetext:gsub(' $','')
                zhoLine.end_time = subtitle[zhoList[zhoT]].end_time
                subtitle[zhoI] = zhoLine
            else
                engLine.text = linetext:gsub(' $','')
                engLine.end_time = subtitle[engList[engT]].end_time
                subtitle[engI] = engLine
            end
            -- update
            zhoT, engT = zhoT + 1, engT + 1
            zhoH, engH = zhoT, engT
        end
        aegisub.progress.set(zhoH/#zhoList*100)
    end
    -- delete blank lines
    local i = 1
    local total = #subtitle
    local data = {}
    while(i<=total) do
        local li = subtitle[i]
        if li.class=="dialogue" and li.comment==false then
            li.text = li.text:gsub("{}","")
            li.text = li.text:gsub(" *","")
            if li.text=="" then
                subtitle.delete(i)
                total = total - 1
            else
                table.insert(data,i)
                i = i + 1
            end
        else
            i = i + 1
        end
    end
    aegisub.set_undo_point(script_name) 
    return data
end

function getscore(line1, line2)
    return math.min(line1.end_time, line2.end_time) - math.max(line1.start_time, line2.start_time)
end

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
aegisub.register_macro(script_name.."/better_bilang_combiner",script_description,better_bilang_combiner)
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

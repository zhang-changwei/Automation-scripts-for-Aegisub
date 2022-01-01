--[[
README:

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

Updated on Fre.8th, 2021
    Bug Fixed
]]


--Script properties
script_name="C Gradient"
script_description="Gradient v2.2"
script_author="chaaaaang"
script_version="2.2"

include("karaskel.lua")
util = require 'aegisub.util'

--GUI
local dialog_config={
    --true: time mode, false: line mode
    {class="checkbox",name="set",label="setting",value=false,x=0,y=0,hint="true: time mode, false: line mode"},
    {class="dropdown",name="mode",items={"replace","append"},value="replace",width=3,x=1,y=0},

    {class="label",label="rule",x=0,y=1},
    {class="edit",name="rule",value="11",width=3,x=1,y=1,hint="%d%d[ht]?,%d%d[ht]?... e.g. 12h,21t"},
    {class="label",label="accel",x=0,y=2},
    {class="floatedit",name="accel",value=1,width=3,x=1,y=2},

    {class="checkbox",name="color_cb",label="color",value=false,x=1,y=3},
    {class="dropdown",name="color",items={"c","1c","2c","3c","4c","1vc","2vc","3vc","4vc"},value="c",x=1,y=4},
    {class="checkbox",name="alpha_cb",label="alpha",value=false,x=2,y=3},
    {class="dropdown",name="alpha",items={"alpha","1a","2a","3a","4a","1va","2va","3va","4va"},value="alpha",x=2,y=4},
    {class="checkbox",name="other_cb",label="others",value=false,x=3,y=3},
    {class="dropdown",name="other",items={"pos","fscx","fscy","fsc","fsp","fsvp","frz","frx","fry","fax","fay","bord","shad","xshad","yshad","blur","t1","t2","clip"},value="pos",x=3,y=4,hint="only vector clip supported"},
    --note
    {class="label",x=0,y=5,label="mode:"},
    {class="label",x=1,y=5,width=4,height=2, 
        label="replace:  the tag should be included in every selected line\n"..
            "append:  keep original tags and add new tags at the head/tail"},
    {class="label",x=0,y=7,label="rule:"},
    {class="label",x=1,y=7,width=4,label="\\d\\d[ht]?,\\d\\d[ht]?...  seperated with ','"},
    {class="label",x=0,y=8, width=2,label="      first number:"},
    {class="label",x=0,y=9, width=2,label="      second number:"},
    {class="label",x=0,y=11,width=2,label="      third [ht]?:"},
    {class="label",x=2,y=8,width=3,label="number of tag block, start from 1"},
    {class="label",x=2,y=9,width=3,height=2,label="the position of tag you want to gradient in all this tag\nin the tag block, start from 1, tags in \\t() should be counted"},
    {class="label",x=2,y=11,width=3,height=2,label="add the tag to the head/tail of the tag block, only work\nin 'append' mode, default = 'h'"},
    {class="label",x=4,y=0, label="      --Gradient v2.2--"}
}
local buttons={"Run","Quit"}

function main(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)

    local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end
    --all false
    if (result["color_cb"]==false and result["alpha_cb"]==false and result["other_cb"]==false) then 
        aegisub.cancel()
    else
        --first get l1 & ln
        --line count = N, time count = T
        local l1,ln = selected[1], selected[#selected]
        local start_f,end_f = aegisub.frame_from_ms(subtitle[l1].start_time), aegisub.frame_from_ms(subtitle[ln].start_time)+1
        local T,N = end_f-start_f, #selected

        for sa,la in ipairs(selected) do
            local line = subtitle[la]
            local ltext = (line.text:match("^{")==nil) and "{}"..line.text or line.text
            ltext = ltext:gsub("}{","")
            line.text = ltext
            subtitle[la] = line
        end

        --second read the rule
        rule_table = read_rule(result["rule"])

        --third read l1 ln information and write in the rule table ///////////////////////////////////////////////////////////////
        local line1 = subtitle[l1]
        local text1 = line1.text
        local linen = subtitle[ln]
        local textn = linen.text

            -- color group
            if (result["color_cb"]==true) then
                local c1234 = "\\"..result.color
                -- \c - \4c
                if result.color=="c" or result.color=="1c" or result.color=="2c" or result.color=="3c" or result.color=="4c"then
                    text1,textn = get_information_ca(text1,textn,rule_table, c1234.."&?H?(%x+)&?", c1234.."&H", c1234.."(&H%x+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \1vc - \4vc
                elseif result.color=="1vc" or result.color=="2vc" or result.color=="3vc" or result.color=="4vc" then
                    text1 = text1:gsub(c1234.."%(&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?%)",
                        function(a,b,c,d) return c1234.."(&H"..a.."&,&H"..b.."&,&H"..c.."&,&H"..d.."&)" end)
                    textn = textn:gsub(c1234.."%(&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?%)",
                        function(a,b,c,d) return c1234.."(&H"..a.."&,&H"..b.."&,&H"..c.."&,&H"..d.."&)" end)
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                    write4_head(text1, rule_table,c1234.."%((&H%x+&),(&H%x+&),(&H%x+&),(&H%x+&)%)")
                    write4_tail(textn, rule_table,c1234.."%((&H%x+&),(&H%x+&),(&H%x+&),(&H%x+&)%)")
                end
            -- alpha group
            elseif (result["alpha_cb"]==true) then
                local a1234 = "\\"..result.alpha
                -- \1a - \4a
                if result.alpha=="alpha" or result.alpha=="1a" or result.alpha=="2a" or result.alpha=="3a" or result.alpha=="4a" then
                    text1,textn = get_information_ca(text1,textn,rule_table, a1234.."&?H?(%x+)&?", a1234.."&H", a1234.."(&H%x+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \1va - \4va
                elseif result.alpha=="1va" or result.alpha=="2va" or result.alpha=="3va" or result.alpha=="4va" then
                    text1 = text1:gsub(a1234.."%(&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?%)",
                        function(a,b,c,d) return a1234.."(&H"..a.."&,&H"..b.."&,&H"..c.."&,&H"..d.."&)" end)
                    textn = textn:gsub(a1234.."%(&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?%)",
                        function(a,b,c,d) return a1234.."(&H"..a.."&,&H"..b.."&,&H"..c.."&,&H"..d.."&)" end)
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                    write4_head(text1, rule_table,a1234.."%((&H%x+&),(&H%x+&),(&H%x+&),(&H%x+&)%)")
                    write4_tail(textn, rule_table,a1234.."%((&H%x+&),(&H%x+&),(&H%x+&),(&H%x+&)%)")
                end
            elseif (result["other_cb"]==true) then
                -- \pos
                if (result["other"]=="pos") then
                    get_information_pos(text1,textn,rule_table,"\\pos%(([%-%d%.]+),([%-%d%.]+)%)")
                -- t1
                elseif (result["other"]=="t1") then
                    get_information_other(text1,textn,rule_table,"\\t%(([%-%d%.]+)")
                -- t2
                elseif (result["other"]=="t2") then
                    get_information_other(text1,textn,rule_table,"\\t%([%-%d%.]+,([%-%d%.]+)")
                -- \clip vector
                elseif (result["other"]=="clip") then
                    get_information_clip(text1,textn,rule_table)
                else
                -- universaltag \fscx \fscy \fsc \fsp \fsvp \frz \frx \fry \fax \fay \bord \shad \xshad \yshad
                    local univeraltag = "\\"..result.other
                    get_information_other(text1,textn,rule_table, univeraltag.."([%-%d%.]+)")
                end
            end

        --fourth rewrite///////////////////////////////////////////////////////////////////////////////////////////////////////
        for si,li in ipairs(selected) do
            if (li==l1 or li==ln) then goto loop_end end

            local line=subtitle[li]
            local ltext = line.text
            local t = aegisub.frame_from_ms(line.start_time) - start_f + 1

            --interpolate01
            local bias = interpolate01(N,T,si,t,result["set"],result["accel"])
            
            local tt_table = {}
            for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
                table.insert(tt_table,{tag=tg,text=tx})
            end

                -- color group
                if (result["color_cb"]==true) then
                    -- \c - \4c
                    if result.color=="c" or result.color=="1c" or result.color=="2c" or result.color=="3c" or result.color=="4c" then
                        ltext = rewrite_c(tt_table,rule_table,result["mode"],bias, "\\"..result.color)
                    -- \1vc - \4vc
                    elseif result.color=="1vc" or result.color=="2vc" or result.color=="3vc" or result.color=="4vc" then
                        ltext = rewrite_vc(tt_table,rule_table,result["mode"],bias, "\\"..result.color)
                    end
                -- alpha group
                elseif (result["alpha_cb"]==true) then
                    -- \1a - \4a
                    if result.alpha=="alpha" or result.alpha=="1a" or result.alpha=="2a" or result.alpha=="3a" or result.alpha=="4a" then
                        ltext = rewrite_a(tt_table,rule_table,result["mode"],bias, "\\"..result.alpha)
                    -- \1va - \4va
                    elseif result.alpha=="1va" or result.alpha=="2va" or result.alpha=="3va" or result.alpha=="4va" then
                        ltext = rewrite_va(tt_table,rule_table,result["mode"],bias, "\\"..result.alpha)
                    end
                elseif (result["other_cb"]==true) then
                    -- \pos
                    if (result["other"]=="pos") then
                        ltext = rewrite_pos(tt_table,rule_table,result["mode"],bias,
                            "\\pos%(([%-%d%.]+),([%-%d%.]+)%)","([^}]*)}\\pos%(([%-%d%.]+),([%-%d%.]+)%)")
                    -- t1
                    elseif (result["other"]=="t1") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias, "\\t%(", "\\t(")
                    -- t2
                    elseif (result["other"]=="t2") then
                        ltext = rewrite_t2(tt_table,rule_table,result["mode"],bias)
                    -- \i?clip vector
                    elseif (result["other"]=="clip") then
                        ltext = rewrite_clip(tt_table,rule_table,result["mode"],bias)
                    else
                    -- \fscx \fscy \fsc \fsp \fsvp \frz \frx \fry \fax \fay \bord \shad \xshad \yshad
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias, "\\"..result.other, "\\"..result.other)
                    end
                else
                end

            line.text = ltext
            subtitle[li]=line
            
            :: loop_end ::
        end
    end
    -- /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	aegisub.set_undo_point(script_name)
	return selected
end

function read_rule(rule)
    rule = rule..","
    rule_table = {}
    for a,b,c in rule:gmatch("(%d)(%d)([ht]?),") do
        -- default=h
        if (c~="h" and c~="t") then c="h" end
        local bl = tonumber(a)
        local po = tonumber(b)
        table.insert(rule_table,{block=bl,position=po,ht=c,head=nil,tail=nil,head2=nil,tail2=nil,other=nil})
    end
    return rule_table
end

function write_head(ltext, rule_table, match)
    local ib=0
    local tt_table={}

    for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
        table.insert(tt_table,{tag=tg,text=tx})
    end
    
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local ir = 0
        for __,rule in ipairs(rule_table) do
            ir = ir + 1
            if (rule.block==ib) then
                local ip = 0
                for p in tt.tag:gmatch(match) do
                    ip = ip + 1
                    if (rule.position==ip) then 
                        subtab = rule_table[ir]
                        subtab.head = p
                        rule_table[ir] = subtab
                    end
                end
            end
        end
    end
end

function write_tail(ltext, rule_table, match)
    local ib=0
    local tt_table={}

    for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
        table.insert(tt_table,{tag=tg,text=tx})
    end
    
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local ir = 0
        for __,rule in ipairs(rule_table) do
            ir = ir + 1
            if (rule.block==ib) then
                local ip = 0
                for p in tt.tag:gmatch(match) do
                    ip = ip + 1
                    if (rule.position==ip) then 
                        subtab = rule_table[ir]
                        subtab.tail = p
                        rule_table[ir] = subtab
                    end
                end
            end
        end
    end
end

function write4_head(ltext, rule_table, match)
    local ib=0
    local tt_table={}

    for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
        table.insert(tt_table,{tag=tg,text=tx})
    end
    
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local ir = 0
        for __,rule in ipairs(rule_table) do
            ir = ir + 1
            if (rule.block==ib) then
                local ip = 0
                for p1,p2,p3,p4 in tt.tag:gmatch(match) do
                    ip = ip + 1
                    if (rule.position==ip) then 
                        subtab = rule_table[ir]
                        subtab.head = {h1=p1,h2=p2,h3=p3,h4=p4}
                        rule_table[ir] = subtab
                    end
                end
            end
        end
    end
end

function write4_tail(ltext, rule_table, match)
    local ib=0
    local tt_table={}

    for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
        table.insert(tt_table,{tag=tg,text=tx})
    end
    
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local ir = 0
        for __,rule in ipairs(rule_table) do
            ir = ir + 1
            if (rule.block==ib) then
                local ip = 0
                for p1,p2,p3,p4 in tt.tag:gmatch(match) do
                    ip = ip + 1
                    if (rule.position==ip) then 
                        subtab = rule_table[ir]
                        subtab.tail = {t1=p1,t2=p2,t3=p3,t4=p4}
                        rule_table[ir] = subtab
                    end
                end
            end
        end
    end
end

function writepos_head(ltext, rule_table, match)
    local ib=0
    local tt_table={}

    for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
        table.insert(tt_table,{tag=tg,text=tx})
    end
    
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local ir = 0
        for __,rule in ipairs(rule_table) do
            ir = ir + 1
            if (rule.block==ib) then
                local ip = 0
                for p1,p2 in tt.tag:gmatch(match) do
                    ip = ip + 1
                    if (rule.position==ip) then 
                        subtab = rule_table[ir]
                        subtab.head = p1
                        subtab.head2 = p2
                        rule_table[ir] = subtab
                    end
                end
            end
        end
    end
end

function writepos_tail(ltext, rule_table, match)
    local ib=0
    local tt_table={}

    for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
        table.insert(tt_table,{tag=tg,text=tx})
    end
    
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local ir = 0
        for __,rule in ipairs(rule_table) do
            ir = ir + 1
            if (rule.block==ib) then
                local ip = 0
                for p1,p2 in tt.tag:gmatch(match) do
                    ip = ip + 1
                    if (rule.position==ip) then 
                        subtab = rule_table[ir]
                        subtab.tail = p1
                        subtab.tail2 = p2
                        rule_table[ir] = subtab
                    end
                end
            end
        end
    end
end

-- match \i?clip%([^%)]+%)
-- iclip rule_table.other -> true, clip rule_table.other -> false
function writeclip_head(ltext, rule_table)
    local ib=0
    local tt_table={}

    for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
        table.insert(tt_table,{tag=tg,text=tx})
    end
    
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local ir = 0
        for __,rule in ipairs(rule_table) do
            ir = ir + 1
            if (rule.block==ib) then
                local ip = 0
                for p0,p1 in tt.tag:gmatch("(\\i?clip)%(([^%)]+)%)") do
                    ip = ip + 1
                    if (rule.position==ip) then 
                        subtab = rule_table[ir]
                        local subtab_head = {}
                        local ic = 0
                        for pre,x,y in p1:gmatch("([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)") do
                            ic = ic + 1
                            table.insert(subtab_head,{pre=pre,x=x,y=y})
                        end
                        subtab.head = clone(subtab_head)
                        subtab.head2 = ic
                        rule_table[ir] = subtab
                    end
                end
            end
        end
    end
end

-- match \i?clip%([^%)]+%)
function writeclip_tail(ltext, rule_table)
    local ib=0
    local tt_table={}

    for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
        table.insert(tt_table,{tag=tg,text=tx})
    end
    
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local ir = 0
        for __,rule in ipairs(rule_table) do
            ir = ir + 1
            if (rule.block==ib) then
                local ip = 0
                for p0,p1 in tt.tag:gmatch("(\\i?clip)%(([^%)]+)%)") do
                    ip = ip + 1
                    if (rule.position==ip) then 
                        subtab = rule_table[ir]
                        local subtab_tail = {}
                        if p0=="\\iclip" then subtab.other=true else subtab.other=false end
                        for pre,x,y in p1:gmatch("([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)") do
                            table.insert(subtab_tail,{pre=pre,x=x,y=y})
                        end
                        subtab.tail = clone(subtab_tail)
                        rule_table[ir] = subtab
                    end
                end
            end
        end
    end
end

--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function interpolate01(N,T,i,t,judge,accel)
    -- true: time mode, false: line mode
    if (judge==false) then
        return (1/(N-1)*(i-1))^accel
    else
        return (1/(T-1)*(t-1))^accel
    end
end

--in string &HXXXXXX& out string &HXXXXXX&
function interpolate_c(bias,head,tail)
    local b1,g1,r1 = head:match("&H([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])")
    local b2,g2,r2 = tail:match("&H([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])([0-9a-fA-F][0-9a-fA-F])")
    b1 = tonumber(b1,16)
    b2 = tonumber(b2,16)
    g1 = tonumber(g1,16)
    g2 = tonumber(g2,16)
    r1 = tonumber(r1,16)
    r2 = tonumber(r2,16)
    local b,g,r = 0,0,0
    if (b1==b2) then b = b1 else b = math.floor((b2-b1)*bias+0.5)+b1 end
    if (g1==g2) then g = g1 else g = math.floor((g2-g1)*bias+0.5)+g1 end
    if (r1==r2) then r = r1 else r = math.floor((r2-r1)*bias+0.5)+r1 end
    return util.ass_color(r, g, b)
end

function interpolate_a(bias,head,tail)
    local a1 = head:match("&H([0-9a-fA-F][0-9a-fA-F])")
    local a2 = tail:match("&H([0-9a-fA-F][0-9a-fA-F])")
    a1 = tonumber(a1,16)
    a2 = tonumber(a2,16)
    local a = 0
    if (a1==a2) then a = a1 else a = math.floor((a2-a1)*bias+0.5)+a1 end
    return util.ass_alpha(a)
end

function interpolate(bias,head,tail)
    local h = tonumber(head)
    local t = tonumber(tail)
    local a = (t-h)*bias+h
    return string.format("%.2f",a)
end

--///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-- match:"\\1c&?H?([0-9a-fA-F]+)&?"     
-- change:"\\1c&H"     
-- match2:"\\1c(&H[0-9a-fA-F]+&)"
function get_information_ca(text1,textn,rule_table,match,change,match2)
    text1 = text1:gsub(match,function(a) return change..a.."&" end)
    textn = textn:gsub(match,function(a) return change..a.."&" end)
    write_head(text1, rule_table,match2)
    write_tail(textn, rule_table,match2)
    return text1,textn
end

function get_information_pos(text1,textn,rule_table,match)
    writepos_head(text1, rule_table,match)
    writepos_tail(textn, rule_table,match)
end

function get_information_other(text1,textn,rule_table,match)
    write_head(text1, rule_table,match)
    write_tail(textn, rule_table,match)
end

-- match \i?clip%([^%)]+%)
function get_information_clip(text1,textn,rule_table)
    writeclip_head(text1, rule_table)
    writeclip_tail(textn, rule_table)
end

function rewrite_c(tt_table,rule_table,mode,bias, color)
    local matchfrom,tagtype,subtail,match,matchtail = color.."&?H?(%x+)&?", color, color.."&HFFFFFF&", "([^}]*)}"..color.."(&H%x+&)", color.."&HFFFFFF&$"
    local rebuild = ""
    local ib = 0
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local apply_true = false
        for _1,rule in ipairs(rule_table) do
            if (rule.block==ib) then
                apply_true = true
                local ip = 0
                local rebuild_tag = ""

                if (mode=="replace") then
                    tt.tag = tt.tag:gsub(matchfrom,function(a) return "}"..tagtype.."&H"..a.."&" end)
                    tt.tag = tt.tag..subtail

                    for p,q in tt.tag:gmatch(match) do
                        ip = ip + 1
                        if (rule.position==ip) then
                            local new_tag = interpolate_c(bias,rule.head,rule.tail)
                            rebuild_tag = rebuild_tag..p..tagtype..new_tag
                        else
                            rebuild_tag = rebuild_tag..p..tagtype..q
                        end
                    end
                    rebuild_tag = rebuild_tag:gsub(matchtail,"}")
                else
                    if (rule.ht=="h") then 
                        rebuild_tag=tt.tag:gsub("^{",function() local htag=interpolate_c(bias,rule.head,rule.tail) return "{"..tagtype..htag end)
                    else 
                        rebuild_tag=tt.tag:gsub("}$",function() local ttag=interpolate_c(bias,rule.head,rule.tail) return tagtype..ttag.."}" end)
                    end
                end
                rebuild = rebuild..rebuild_tag..tt.text
            end
        end
        if (apply_true==false) then rebuild = rebuild..tt.tag..tt.text end
    end
    ltext = rebuild
    return ltext
end

function rewrite_vc(tt_table,rule_table,mode,bias, vc)
    local tagtype,subtail = vc.."(", vc.."(&HFFFFFF&,&HFFFFFF&,&HFFFFFF&,&HFFFFFF&)" -- \\1vc(
    local matchfrom,match,matchtail = vc.."%(&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?%)",
        "([^}]*)}"..vc.."%((&H%x+&),(&H%x+&),(&H%x+&),(&H%x+&)%)",
        vc.."%(&HFFFFFF&,&HFFFFFF&,&HFFFFFF&,&HFFFFFF&%)$"
    local rebuild = ""
    local ib = 0
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local apply_true = false
        for _1,rule in ipairs(rule_table) do
            if (rule.block==ib) then
                apply_true = true
                local ip = 0
                local rebuild_tag = ""
                local rule_head = rule.head
                local rule_tail = rule.tail

                if (mode=="replace") then
                    tt.tag = tt.tag:gsub(matchfrom,
                        function(a,b,c,d) return "}"..tagtype.."&H"..a.."&,&H"..b.."&,&H"..c.."&,&H"..d.."&)" end)
                    tt.tag = tt.tag..subtail

                    for p,q1,q2,q3,q4 in tt.tag:gmatch(match) do
                        ip = ip + 1
                        if (rule.position==ip) then
                            local q1n = interpolate_c(bias,rule_head.h1,rule_tail.t1)
                            local q2n = interpolate_c(bias,rule_head.h2,rule_tail.t2)
                            local q3n = interpolate_c(bias,rule_head.h3,rule_tail.t3)
                            local q4n = interpolate_c(bias,rule_head.h4,rule_tail.t4) 
                            rebuild_tag = rebuild_tag..p..tagtype..q1n..","..q2n..","..q3n..","..q4n..")"
                        else
                            rebuild_tag = rebuild_tag..p..tagtype..q1..","..q2..","..q3..","..q4..")"
                        end
                    end
                    rebuild_tag = rebuild_tag:gsub(matchtail,"}")
                else
                    if (rule.ht=="h") then 
                        rebuild_tag=tt.tag:gsub("^{",function() 
                            local ht1=interpolate_c(bias,rule_head.h1,rule_tail.t1)
                            local ht2=interpolate_c(bias,rule_head.h2,rule_tail.t2)
                            local ht3=interpolate_c(bias,rule_head.h3,rule_tail.t3)
                            local ht4=interpolate_c(bias,rule_head.h4,rule_tail.t4)
                            return "{"..tagtype..ht1..","..ht2..","..ht3..","..ht4..")" end)
                    else 
                        rebuild_tag=tt.tag:gsub("}$",function() 
                            local ht1=interpolate_c(bias,rule_head.h1,rule_tail.t1)
                            local ht2=interpolate_c(bias,rule_head.h2,rule_tail.t2)
                            local ht3=interpolate_c(bias,rule_head.h3,rule_tail.t3)
                            local ht4=interpolate_c(bias,rule_head.h4,rule_tail.t4)
                            return tagtype..ht1..","..ht2..","..ht3..","..ht4..")}" end)
                    end
                end
                rebuild = rebuild..rebuild_tag..tt.text
            end
        end
        if (apply_true==false) then rebuild = rebuild..tt.tag..tt.text end
    end
    ltext = rebuild
    return ltext
end

function rewrite_a(tt_table,rule_table,mode,bias, alpha)
    local matchfrom,tagtype,subtail,match,matchtail = alpha.."&?H?(%x+)&?", alpha, alpha.."&HFF&", "([^}]*)}"..alpha.."(&H%x+&)", alpha.."&HFF&$"
    local rebuild = ""
    local ib = 0
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local apply_true = false
        for _1,rule in ipairs(rule_table) do
            if (rule.block==ib) then
                apply_true = true
                local ip = 0
                local rebuild_tag = ""

                if (mode=="replace") then
                    tt.tag = tt.tag:gsub(matchfrom,function(a) return "}"..tagtype.."&H"..a.."&" end)
                    tt.tag = tt.tag..subtail

                    for p,q in tt.tag:gmatch(match) do
                        ip = ip + 1
                        if (rule.position==ip) then
                            local new_tag = interpolate_a(bias,rule.head,rule.tail)
                            rebuild_tag = rebuild_tag..p..tagtype..new_tag
                        else
                            rebuild_tag = rebuild_tag..p..tagtype..q
                        end
                    end
                    rebuild_tag = rebuild_tag:gsub(matchtail,"}")
                else
                    if (rule.ht=="h") then 
                        rebuild_tag=tt.tag:gsub("^{",function() local htag=interpolate_a(bias,rule.head,rule.tail) return "{"..tagtype..htag end)
                    else 
                        rebuild_tag=tt.tag:gsub("}$",function() local ttag=interpolate_a(bias,rule.head,rule.tail) return tagtype..ttag.."}" end)
                    end
                end
                rebuild = rebuild..rebuild_tag..tt.text
            end
        end
        if (apply_true==false) then rebuild = rebuild..tt.tag..tt.text end
    end
    ltext = rebuild
    return ltext
end

function rewrite_va(tt_table,rule_table,mode,bias, va)
    local tagtype,subtail = va.."(", va.."(&HFF&,&HFF&,&HFF&,&HFF&)" -- \\1vc(
    local matchfrom,match,matchtail = va.."%(&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?,&?H?(%x+)&?%)",
        "([^}]*)}"..va.."%((&H%x+&),(&H%x+&),(&H%x+&),(&H%x+&)%)",
        va.."%(&HFF&,&HFF&,&HFF&,&HFF&%)$"
    local rebuild = ""
    local ib = 0
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local apply_true = false
        for _1,rule in ipairs(rule_table) do
            if (rule.block==ib) then
                apply_true = true
                local ip = 0
                local rebuild_tag = ""
                local rule_head = rule.head
                local rule_tail = rule.tail

                if (mode=="replace") then
                    tt.tag = tt.tag:gsub(matchfrom,
                        function(a,b,c,d) return "}"..tagtype.."&H"..a.."&,&H"..b.."&,&H"..c.."&,&H"..d.."&)" end)
                    tt.tag = tt.tag..subtail

                    for p,q1,q2,q3,q4 in tt.tag:gmatch(match) do
                        ip = ip + 1
                        if (rule.position==ip) then
                            local q1n = interpolate_a(bias,rule_head.h1,rule_tail.t1)
                            local q2n = interpolate_a(bias,rule_head.h2,rule_tail.t2)
                            local q3n = interpolate_a(bias,rule_head.h3,rule_tail.t3)
                            local q4n = interpolate_a(bias,rule_head.h4,rule_tail.t4) 
                            rebuild_tag = rebuild_tag..p..tagtype..q1n..","..q2n..","..q3n..","..q4n..")"
                        else
                            rebuild_tag = rebuild_tag..p..tagtype..q1..","..q2..","..q3..","..q4..")"
                        end
                    end
                    rebuild_tag = rebuild_tag:gsub(matchtail,"}")
                else
                    if (rule.ht=="h") then 
                        rebuild_tag=tt.tag:gsub("^{",function() 
                            local ht1=interpolate_a(bias,rule_head.h1,rule_tail.t1)
                            local ht2=interpolate_a(bias,rule_head.h2,rule_tail.t2)
                            local ht3=interpolate_a(bias,rule_head.h3,rule_tail.t3)
                            local ht4=interpolate_a(bias,rule_head.h4,rule_tail.t4)
                            return "{"..tagtype..ht1..","..ht2..","..ht3..","..ht4..")" end)
                    else 
                        rebuild_tag=tt.tag:gsub("}$",function() 
                            local ht1=interpolate_a(bias,rule_head.h1,rule_tail.t1)
                            local ht2=interpolate_a(bias,rule_head.h2,rule_tail.t2)
                            local ht3=interpolate_a(bias,rule_head.h3,rule_tail.t3)
                            local ht4=interpolate_a(bias,rule_head.h4,rule_tail.t4)
                            return tagtype..ht1..","..ht2..","..ht3..","..ht4..")}" end)
                    end
                end
                rebuild = rebuild..rebuild_tag..tt.text
            end
        end
        if (apply_true==false) then rebuild = rebuild..tt.tag..tt.text end
    end
    ltext = rebuild
    return ltext
end

-- matchfrom "\\pos%(([%-%d%.]+),([%-%d%.]+)%)"    --match "([^W]*)WWW\\pos%(([%-%d%.]+),([%-%d%.]+)%)"
function rewrite_pos(tt_table,rule_table,mode,bias,matchfrom,match)
    local rebuild = ""
    local ib = 0
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local apply_true = false
        for _1,rule in ipairs(rule_table) do
            if (rule.block==ib) then
                apply_true = true
                local ip = 0
                local rebuild_tag = ""

                if (mode=="replace") then
                    tt.tag = tt.tag:gsub(matchfrom,function(a,b) return "}\\pos("..a..","..b..")" end)
                    tt.tag = tt.tag.."\\pos(0,0)"

                    for p,q1,q2 in tt.tag:gmatch(match) do
                        ip = ip + 1
                        if (rule.position==ip) then
                            local posx = interpolate(bias,rule.head,rule.tail)
                            local posy = interpolate(bias,rule.head2,rule.tail2)
                            rebuild_tag = rebuild_tag..p.."\\pos("..posx..","..posy..")"
                        else
                            rebuild_tag = rebuild_tag..p.."\\pos("..q1..","..q2..")"
                        end
                    end
                    rebuild_tag = rebuild_tag:gsub("\\pos%(0,0%)$","}")
                else
                    if (rule.ht=="h") then 
                        rebuild_tag=tt.tag:gsub("^{",function() 
                            local posx = interpolate(bias,rule.head,rule.tail)
                            local posy = interpolate(bias,rule.head2,rule.tail2)
                            return "{\\pos("..posx..","..posy..")" end)
                    else 
                        rebuild_tag=tt.tag:gsub("}$",function() 
                            local posx = interpolate(bias,rule.head,rule.tail)
                            local posy = interpolate(bias,rule.head2,rule.tail2)
                            return "\\pos("..posx..","..posy..")}" end)
                    end
                end
                rebuild = rebuild..rebuild_tag..tt.text
            end
        end
        if (apply_true==false) then rebuild = rebuild..tt.tag..tt.text end
    end
    ltext = rebuild
    return ltext
end

function rewrite_other(tt_table,rule_table,mode,bias, matchtxt, plaintxt)
    local matchfrom,tagtype,subtail,match,matchtail = matchtxt.."([%-%d%.]+)", plaintxt, plaintxt.."0", "([^}]*)}"..matchtxt.."([%-%d%.]+)", matchtxt.."0$"
    local rebuild = ""
    local ib = 0
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local apply_true = false
        for _1,rule in ipairs(rule_table) do
            if (rule.block==ib) then
                apply_true = true
                local ip = 0
                local rebuild_tag = ""

                if (mode=="replace") then
                    tt.tag = tt.tag:gsub(matchfrom,function(a) return "}"..tagtype..a end)
                    tt.tag = tt.tag..subtail

                    for p,q in tt.tag:gmatch(match) do
                        ip = ip + 1
                        if (rule.position==ip) then
                            local new_tag = interpolate(bias,rule.head,rule.tail)
                            rebuild_tag = rebuild_tag..p..tagtype..new_tag
                        else
                            rebuild_tag = rebuild_tag..p..tagtype..q
                        end
                    end
                    rebuild_tag = rebuild_tag:gsub(matchtail,"}")
                else
                    if (rule.ht=="h") then 
                        rebuild_tag=tt.tag:gsub("^{",function() local htag=interpolate(bias,rule.head,rule.tail) return "{"..tagtype..htag end)
                    else 
                        rebuild_tag=tt.tag:gsub("}$",function() local ttag=interpolate(bias,rule.head,rule.tail) return tagtype..ttag.."}" end)
                    end
                end
                rebuild = rebuild..rebuild_tag..tt.text
            end
        end
        if (apply_true==false) then rebuild = rebuild..tt.tag..tt.text end
    end
    ltext = rebuild
    return ltext
end

function rewrite_t2(tt_table,rule_table,mode,bias)
    local rebuild = ""
    local ib = 0
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local apply_true = false
        for _1,rule in ipairs(rule_table) do
            if (rule.block==ib) then
                apply_true = true
                local ip = 0
                local rebuild_tag = ""

                if (mode=="replace") then
                    tt.tag = tt.tag:gsub("\\t%(([%-%d%.]+),([%-%d%.]+)",function(a,b) return "}".."\\t("..a..","..b end)
                    tt.tag = tt.tag.."\\t(0,0"

                    for p,q1,q2 in tt.tag:gmatch("([^}]*)}\\t%(([%-%d%.]+),([%-%d%.]+)") do
                        ip = ip + 1
                        if (rule.position==ip) then
                            local new_tag = interpolate(bias,rule.head,rule.tail)
                            rebuild_tag = rebuild_tag..p.."\\t("..q1..","..new_tag
                        else
                            rebuild_tag = rebuild_tag..p.."\\t("..q1..","..q2
                        end
                    end
                    rebuild_tag = rebuild_tag:gsub("\\t%(0,0","}")
                else
                    aegisub.cancel()
                end
                rebuild = rebuild..rebuild_tag..tt.text
            end
        end
        if (apply_true==false) then rebuild = rebuild..tt.tag..tt.text end
    end
    ltext = rebuild
    return ltext
end

function rewrite_clip(tt_table,rule_table,mode,bias)
    local rebuild = ""
    local ib = 0
    for _,tt in ipairs(tt_table) do
        ib = ib + 1
        local apply_true = false
        for _1,rule in ipairs(rule_table) do
            if (rule.block==ib) then
                apply_true = true
                local ip = 0
                local rebuild_tag = ""

                if (mode=="replace") then
                    tt.tag = tt.tag:gsub("(\\i?clip%([^%)]*%))","}%1")
                    tt.tag = tt.tag.."\\clip()"

                    for p,q,qclip in tt.tag:gmatch("([^}]*)}(\\i?clip)%(([^%)]*)%)") do
                        ip = ip + 1
                        if (rule.position==ip) then
                            local new_tag = ""
                            for ic=1,rule.head2 do
                                local new_x = math.floor(interpolate(bias,rule.head[ic].x,rule.tail[ic].x))
                                local new_y = math.floor(interpolate(bias,rule.head[ic].y,rule.tail[ic].y))
                                new_tag = new_tag..rule.head[ic].pre.." "..new_x.." "..new_y.." "
                            end
                            new_tag = new_tag:gsub(" +"," ")
                            rebuild_tag = rebuild_tag..p..q.."("..new_tag..")"
                        else
                            rebuild_tag = rebuild_tag..p..q.."("..qclip..")"
                        end
                    end
                    rebuild_tag = rebuild_tag:gsub("\\clip%(%)","}")
                else
                    if (rule.ht=="h") then 
                        rebuild_tag=tt.tag:gsub("^{",
                        function() 
                            local new_tag = "{"
                            if rule.other==true then new_tag="{\\iclip(" else new_tag="{\\clip(" end
                            for ic=1,rule.head2 do
                                local new_x = math.floor(interpolate(bias,rule.head[ic].x,rule.tail[ic].x))
                                local new_y = math.floor(interpolate(bias,rule.head[ic].y,rule.tail[ic].y))
                                new_tag = new_tag..rule.head[ic].pre.." "..new_x.." "..new_y.." "
                            end
                            new_tag = new_tag:gsub(" +"," ")
                            return new_tag..")"
                        end)
                    else 
                        rebuild_tag=tt.tag:gsub("}$",
                        function()
                            local new_tag = ""
                            if rule.other==true then new_tag="\\iclip(" else new_tag="\\clip(" end
                            for ic=1,rule.head2 do
                                local new_x = math.floor(interpolate(bias,rule.head[ic].x,rule.tail[ic].x))
                                local new_y = math.floor(interpolate(bias,rule.head[ic].y,rule.tail[ic].y))
                                new_tag = new_tag..rule.tail[ic].pre.." "..new_x.." "..new_y.." "
                            end
                            new_tag = new_tag:gsub(" +"," ")
                            return new_tag..")}"
                        end)
                    end
                end
                rebuild = rebuild..rebuild_tag..tt.text
            end
        end
        if (apply_true==false) then rebuild = rebuild..tt.tag..tt.text end
    end
    ltext = rebuild
    return ltext
end

-- deep copy
function clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)

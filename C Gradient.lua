--[[
README:
Updated on Fre.8th, 2021
    Bug Fixed
]]


--Script properties
script_name="C Gradient"
script_description="Gradient v2.1"
script_author="chaaaaang"
script_version="2.1"

include("karaskel.lua")
util = require 'aegisub.util'

--GUI
dialog_config={
    --true: time mode, false: line mode
    {class="checkbox",name="set",label="setting",value=false,x=0,y=0,hint="true: time mode, false: line mode"},
    {class="dropdown",name="mode",items={"exact match","custom"},value="exact match",width=4,x=1,y=0},

    {class="label",label="rule",x=0,y=1},
    {class="edit",name="rule",value="11",width=4,x=1,y=1,hint="%d%d[ht]?,%d%d[ht]?... e.g. 12h,21t"},
    {class="label",label="accel",x=0,y=2},
    {class="floatedit",name="accel",value=1,width=2,x=1,y=2},

    {class="checkbox",name="color_cb",label="color",value=false,x=1,y=3},
    {class="dropdown",name="color",items={"c","1c","2c","3c","4c","1vc"},value="c",x=1,y=4},
    {class="checkbox",name="alpha_cb",label="alpha",value=false,x=2,y=3},
    {class="dropdown",name="alpha",items={"alpha","1a","2a","3a","4a"},value="alpha",x=2,y=4},
    {class="checkbox",name="other_cb",label="others",value=false,x=3,y=3},
    {class="dropdown",name="other",items={"pos","fscx","fscy","fsc","fsvp","frz","frx","fry","fax","fay","bord","shad","xshad","yshad","t1","t2","clip"},value="pos",x=3,y=4,hint="only vector clip supported"},
    {class="checkbox",name="t_cb",label="\\t",value=false,x=0,y=3,hint="not available"},
    --note
    {class="label",width=6,height=8,x=0,y=5,
        label="mode=\"exact match\": the tag should be included in every selected line\n"..
        "mode=\"custom\": keep original tags and add new tags at the head/tail\n"..
        "rule: %d%d[ht]?,%d%d[ht]?...  seperated with \",\"\n"..
        "    first # : number of tag block, start from 1\n"..
        "    second # : the position of tag you want to gradient in all this tag\n"..
        "        in the tag block, start from 1, tags in \\t() should be counted\n"..
        "    third [ht] : add the tag to the head/tail of the tag block, only work\n"..
        "        in \"custom\" mode, default = \"h\""}
}
buttons={"Run","Quit"}

function main(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)

    pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end
    --all false
    if (result["color_cb"]==false and result["alpha_cb"]==false and result["other_cb"]==false) then 
        aegisub.cancel()
    else
        --first get l1 & ln
        --line count = N, time count = T
        local i,start_f,end_f,l1,ln = 0,0,0,0,0

        for sa,la in ipairs(selected) do
            local line = subtitle[la]
                                    
            if (i == 0) then 
                start_f = aegisub.frame_from_ms(line.start_time) 
                l1 = la
            end

            local ltext = (line.text:match("^{")==nil) and "{}"..line.text or line.text
            ltext = ltext:gsub("}{","")
            line.text = ltext
            subtitle[la] = line

            ln = la
            end_f = aegisub.frame_from_ms(line.start_time)
            i = i + 1
        end
        local T = end_f - start_f + 1
        local N = i

        --second read the rule
        rule_table = read_rule(result["rule"])

        --third read l1 ln information and write in the rule table ///////////////////////////////////////////////////////////////
        local line1 = subtitle[l1]
        local text1 = line1.text
        local linen = subtitle[ln]
        local textn = linen.text

        if not(result["t_cb"]==true and result["mode"]=="custom") then
            -- color group
            if (result["color_cb"]==true) then
                -- \c
                if (result["color"]=="c") then
                    text1,textn = get_information_ca(text1,textn,rule_table,"\\c&?H?([0-9a-fA-F]+)&?","\\c&H","\\c(&H[0-9a-fA-F]+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \1c
                elseif (result["color"]=="1c") then
                    text1,textn = get_information_ca(text1,textn,rule_table,"\\1c&?H?([0-9a-fA-F]+)&?","\\1c&H","\\1c(&H[0-9a-fA-F]+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \2c
                elseif (result["color"]=="2c") then
                    text1,textn = get_information_ca(text1,textn,rule_table,"\\2c&?H?([0-9a-fA-F]+)&?","\\2c&H","\\2c(&H[0-9a-fA-F]+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \3c
                elseif (result["color"]=="3c") then
                    text1,textn = get_information_ca(text1,textn,rule_table,"\\3c&?H?([0-9a-fA-F]+)&?","\\3c&H","\\3c(&H[0-9a-fA-F]+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \4c
                elseif (result["color"]=="4c") then
                    text1,textn = get_information_ca(text1,textn,rule_table,"\\4c&?H?([0-9a-fA-F]+)&?","\\4c&H","\\4c(&H[0-9a-fA-F]+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \1vc
                elseif (result["color"]=="1vc") then
                    text1 = text1:gsub("\\1vc%(&?H?([0-9a-fA-F]+)&?,&?H?([0-9a-fA-F]+)&?,&?H?([0-9a-fA-F]+)&?,&?H?([0-9a-fA-F]+)&?%)",
                        function(a,b,c,d) return "\\1vc(&H"..a.."&,&H"..b.."&,&H"..c.."&,&H"..d.."&)" end)
                    textn = textn:gsub("\\1vc%(&?H?([0-9a-fA-F]+)&?,&?H?([0-9a-fA-F]+)&?,&?H?([0-9a-fA-F]+)&?,&?H?([0-9a-fA-F]+)&?%)",
                        function(a,b,c,d) return "\\1vc(&H"..a.."&,&H"..b.."&,&H"..c.."&,&H"..d.."&)" end)
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                    write4_head(text1, rule_table,"\\1vc%((&H[0-9a-fA-F]+&),(&H[0-9a-fA-F]+&),(&H[0-9a-fA-F]+&),(&H[0-9a-fA-F]+&)%)")
                    write4_tail(textn, rule_table,"\\1vc%((&H[0-9a-fA-F]+&),(&H[0-9a-fA-F]+&),(&H[0-9a-fA-F]+&),(&H[0-9a-fA-F]+&)%)")
                else
                end
            -- alpha group
            elseif (result["alpha_cb"]==true) then
                -- \alpha
                if (result["alpha"]=="alpha") then
                    text1,textn = get_information_ca(text1,textn,rule_table,"\\alpha&?H?([0-9a-fA-F]+)&?","\\alpha&H","\\alpha(&H[0-9a-fA-F]+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \1a
                elseif (result["alpha"]=="1a") then
                    text1,textn = get_information_ca(text1,textn,rule_table,"\\1a&?H?([0-9a-fA-F]+)&?","\\1a&H","\\1a(&H[0-9a-fA-F]+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \2a
                elseif (result["alpha"]=="2a") then
                    text1,textn = get_information_ca(text1,textn,rule_table,"\\2a&?H?([0-9a-fA-F]+)&?","\\2a&H","\\2a(&H[0-9a-fA-F]+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \3a
                elseif (result["alpha"]=="3a") then
                    text1,textn = get_information_ca(text1,textn,rule_table,"\\3a&?H?([0-9a-fA-F]+)&?","\\3a&H","\\3a(&H[0-9a-fA-F]+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                -- \4a
                elseif (result["alpha"]=="4a") then
                    text1,textn = get_information_ca(text1,textn,rule_table,"\\4a&?H?([0-9a-fA-F]+)&?","\\4a&H","\\4a(&H[0-9a-fA-F]+&)")
                    line1.text = text1
                    linen.text = textn
                    subtitle[l1] = line1
                    subtitle[ln] = linen
                else
                end
            elseif (result["other_cb"]==true) then
                -- \pos
                if (result["other"]=="pos") then
                    get_information_pos(text1,textn,rule_table,"\\pos%(([%-%d%.]+),([%-%d%.]+)%)")
                -- \fscx
                elseif (result["other"]=="fscx") then
                    get_information_other(text1,textn,rule_table,"\\fscx([%-%d%.]+)")
                -- \fscy
                elseif (result["other"]=="fscy") then
                    get_information_other(text1,textn,rule_table,"\\fscy([%-%d%.]+)")
                -- \fsc
                elseif (result["other"]=="fsc") then
                    get_information_other(text1,textn,rule_table,"\\fsc([%-%d%.]+)")
                -- \fsvp
                elseif (result["other"]=="fsvp") then
                    get_information_other(text1,textn,rule_table,"\\fsvp([%-%d%.]+)")
                -- \frz
                elseif (result["other"]=="frz") then
                    get_information_other(text1,textn,rule_table,"\\frz([%-%d%.]+)")
                -- \frx
                elseif (result["other"]=="frx") then
                    get_information_other(text1,textn,rule_table,"\\frx([%-%d%.]+)")
                -- \fry
                elseif (result["other"]=="fry") then
                    get_information_other(text1,textn,rule_table,"\\fry([%-%d%.]+)")
                -- \fax
                elseif (result["other"]=="fax") then
                    get_information_other(text1,textn,rule_table,"\\fax([%-%d%.]+)")
                -- \fay
                elseif (result["other"]=="fay") then
                    get_information_other(text1,textn,rule_table,"\\fay([%-%d%.]+)")
                -- \bord
                elseif (result["other"]=="bord") then
                    get_information_other(text1,textn,rule_table,"\\bord([%-%d%.]+)")
                -- \shad
                elseif (result["other"]=="shad") then
                    get_information_other(text1,textn,rule_table,"\\shad([%-%d%.]+)")
                -- \xshad
                elseif (result["other"]=="xshad") then
                    get_information_other(text1,textn,rule_table,"\\xshad([%-%d%.]+)")
                -- \yshad
                elseif (result["other"]=="yshad") then
                    get_information_other(text1,textn,rule_table,"\\yshad([%-%d%.]+)")
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
                end
            end
        end

        --fourth rewrite///////////////////////////////////////////////////////////////////////////////////////////////////////
        local i = 0
        for si,li in ipairs(selected) do
            i = i + 1
            if (li==l1 or li==ln) then goto loop_end end

            local line=subtitle[li]
            local ltext = line.text
            local t = aegisub.frame_from_ms(line.start_time) - start_f + 1

            --interpolate01
            local bias = interpolate01(N,T,i,t,result["set"],result["accel"])
            
            local tt_table = {}
            for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
                table.insert(tt_table,{tag=tg,text=tx})
            end

            -- \t false
            if not(result["t_cb"]==true and result["mode"]=="custom") then
                -- color group
                if (result["color_cb"]==true) then
                    -- \c
                    if (result["color"]=="c") then
                        ltext = rewrite_c(tt_table,rule_table,result["mode"],bias,
                            "\\c&?H?([0-9a-fA-F]+)&?","\\c","\\c&HFFFFFF&","([^}]*)}\\c(&H[0-9a-fA-F]+&)","\\c&HFFFFFF&$")
                    -- \1c    tt_table|rule_table|result["mode"]
                    elseif (result["color"]=="1c") then
                        ltext = rewrite_c(tt_table,rule_table,result["mode"],bias,
                            "\\1c&?H?([0-9a-fA-F]+)&?","\\1c","\\1c&HFFFFFF&","([^}]*)}\\1c(&H[0-9a-fA-F]+&)","\\1c&HFFFFFF&$")
                    -- \2c
                    elseif (result["color"]=="2c") then
                        ltext = rewrite_c(tt_table,rule_table,result["mode"],bias,
                            "\\2c&?H?([0-9a-fA-F]+)&?","\\2c","\\2c&HFFFFFF&","([^}]*)}\\2c(&H[0-9a-fA-F]+&)","\\2c&HFFFFFF&$")
                    -- \3c
                    elseif (result["color"]=="3c") then
                        ltext = rewrite_c(tt_table,rule_table,result["mode"],bias,
                            "\\3c&?H?([0-9a-fA-F]+)&?","\\3c","\\3c&HFFFFFF&","([^}]*)}\\3c(&H[0-9a-fA-F]+&)","\\3c&HFFFFFF&$")
                    -- \4c
                    elseif (result["color"]=="4c") then
                        ltext = rewrite_c(tt_table,rule_table,result["mode"],bias,
                            "\\4c&?H?([0-9a-fA-F]+)&?","\\4c","\\4c&HFFFFFF&","([^}]*)}\\4c(&H[0-9a-fA-F]+&)","\\4c&HFFFFFF&$")
                    -- \1vc
                    elseif (result["color"]=="1vc") then
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

                                    if (result["mode"]=="exact match") then
                                        tt.tag = tt.tag:gsub("\\1vc%(&?H?([0-9a-fA-F]+)&?,&?H?([0-9a-fA-F]+)&?,&?H?([0-9a-fA-F]+)&?,&?H?([0-9a-fA-F]+)&?%)",
                                            function(a,b,c,d) return "}".."\\1vc(&H"..a.."&,&H"..b.."&,&H"..c.."&,&H"..d.."&)" end)
                                        tt.tag = tt.tag.."\\1vc(&HFFFFFF&,&HFFFFFF&,&HFFFFFF&,&HFFFFFF&)"

                                        for p,q1,q2,q3,q4 in tt.tag:gmatch("([^}]*)}\\1vc%((&H[0-9a-fA-F]+&),(&H[0-9a-fA-F]+&),(&H[0-9a-fA-F]+&),(&H[0-9a-fA-F]+&)%)") do
                                            ip = ip + 1
                                            if (rule.position==ip) then
                                                local q1n = interpolate_c(bias,rule_head.h1,rule_tail.t1)
                                                local q2n = interpolate_c(bias,rule_head.h2,rule_tail.t2)
                                                local q3n = interpolate_c(bias,rule_head.h3,rule_tail.t3)
                                                local q4n = interpolate_c(bias,rule_head.h4,rule_tail.t4) 
                                                rebuild_tag = rebuild_tag..p.."\\1vc("..q1n..","..q2n..","..q3n..","..q4n..")"
                                            else
                                                rebuild_tag = rebuild_tag..p.."\\1vc("..q1..","..q2..","..q3..","..q4..")"
                                            end
                                        end
                                        rebuild_tag = rebuild_tag:gsub("\\1vc%(&HFFFFFF&,&HFFFFFF&,&HFFFFFF&,&HFFFFFF&%)$","}")
                                    else
                                        if (rule.ht=="h") then 
                                            rebuild_tag=tt.tag:gsub("^{",function() 
                                                local ht1=interpolate_c(bias,rule_head.h1,rule_tail.t1)
                                                local ht2=interpolate_c(bias,rule_head.h2,rule_tail.t2)
                                                local ht3=interpolate_c(bias,rule_head.h3,rule_tail.t3)
                                                local ht4=interpolate_c(bias,rule_head.h4,rule_tail.t4)
                                                return "{\\1vc("..ht1..","..ht2..","..ht3..","..ht4..")" end)
                                        else 
                                            rebuild_tag=tt.tag:gsub("}$",function() 
                                                local ht1=interpolate_c(bias,rule_head.h1,rule_tail.t1)
                                                local ht2=interpolate_c(bias,rule_head.h2,rule_tail.t2)
                                                local ht3=interpolate_c(bias,rule_head.h3,rule_tail.t3)
                                                local ht4=interpolate_c(bias,rule_head.h4,rule_tail.t4)
                                                return "\\1vc("..ht1..","..ht2..","..ht3..","..ht4..")}" end)
                                        end
                                    end
                                    rebuild = rebuild..rebuild_tag..tt.text
                                end
                            end
                            if (apply_true==false) then rebuild = rebuild..tt.tag..tt.text end
                        end
                        ltext = rebuild
                    -- \2vc
                    elseif (result["color"]=="2vc") then
                    else
                    end
                -- alpha group
                elseif (result["alpha_cb"]==true) then
                    -- \alpha
                    if (result["alpha"]=="alpha") then
                        ltext = rewrite_a(tt_table,rule_table,result["mode"],bias,
                            "\\alpha&?H?([0-9a-fA-F]+)&?","\\alpha","\\alpha&HFF&","([^}]*)}\\alpha(&H[0-9a-fA-F]+&)","\\alpha&HFF&$")
                    -- \1a
                    elseif (result["alpha"]=="1a") then
                        ltext = rewrite_a(tt_table,rule_table,result["mode"],bias,
                            "\\1a&?H?([0-9a-fA-F]+)&?","\\1a","\\1a&HFF&","([^}]*)}\\1a(&H[0-9a-fA-F]+&)","\\1a&HFF&$")
                    -- \2a
                    elseif (result["alpha"]=="2a") then
                        ltext = rewrite_a(tt_table,rule_table,result["mode"],bias,
                            "\\2a&?H?([0-9a-fA-F]+)&?","\\2a","\\2a&HFF&","([^}]*)}\\2a(&H[0-9a-fA-F]+&)","\\2a&HFF&$")
                    -- \3a
                    elseif (result["alpha"]=="3a") then
                        ltext = rewrite_a(tt_table,rule_table,result["mode"],bias,
                            "\\3a&?H?([0-9a-fA-F]+)&?","\\3a","\\3a&HFF&","([^}]*)}\\3a(&H[0-9a-fA-F]+&)","\\3a&HFF&$")
                    -- \4a
                    elseif (result["alpha"]=="4a") then
                        ltext = rewrite_a(tt_table,rule_table,result["mode"],bias,
                            "\\4a&?H?([0-9a-fA-F]+)&?","\\4a","\\4a&HFF&","([^}]*)}\\4a(&H[0-9a-fA-F]+&)","\\4a&HFF&$")
                    else
                    end
                elseif (result["other_cb"]==true) then
                    -- \pos
                    if (result["other"]=="pos") then
                        ltext = rewrite_pos(tt_table,rule_table,result["mode"],bias,
                            "\\pos%(([%-%d%.]+),([%-%d%.]+)%)","([^}]*)}\\pos%(([%-%d%.]+),([%-%d%.]+)%)")
                    -- \fscx
                    elseif (result["other"]=="fscx") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\fscx([%-%d%.]+)","\\fscx","\\fscx0","([^}]*)}\\fscx([%-%d%.]+)","\\fscx0$")
                    -- \fscy
                    elseif (result["other"]=="fscy") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\fscy([%-%d%.]+)","\\fscy","\\fscy0","([^}]*)}\\fscy([%-%d%.]+)","\\fscy0$")
                    -- \fsc
                    elseif (result["other"]=="fsc") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\fsc([%-%d%.]+)","\\fsc","\\fsc0","([^}]*)}\\fsc([%-%d%.]+)","\\fsc0$")
                    -- \fsvp
                    elseif (result["other"]=="fsvp") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\fsvp([%-%d%.]+)","\\fsvp","\\fsvp0","([^}]*)}\\fsvp([%-%d%.]+)","\\fsvp0$")
                    -- \frz
                    elseif (result["other"]=="frz") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\frz([%-%d%.]+)","\\frz","\\frz0","([^}]*)}\\frz([%-%d%.]+)","\\frz0$")
                    -- \frx
                    elseif (result["other"]=="frx") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\frx([%-%d%.]+)","\\frx","\\frx0","([^}]*)}\\frx([%-%d%.]+)","\\frx0$")
                    -- \fry
                    elseif (result["other"]=="fry") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\fry([%-%d%.]+)","\\fry","\\fry0","([^}]*)}\\fry([%-%d%.]+)","\\fry0$")
                    -- \fax
                    elseif (result["other"]=="fax") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\fax([%-%d%.]+)","\\fax","\\fax0","([^}]*)}\\fax([%-%d%.]+)","\\fax0$")
                    -- \fay
                    elseif (result["other"]=="fay") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\fay([%-%d%.]+)","\\fay","\\fay0","([^}]*)}\\fay([%-%d%.]+)","\\fay0$")
                    -- \bord
                    elseif (result["other"]=="bord") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\bord([%-%d%.]+)","\\bord","\\bord0","([^}]*)}\\bord([%-%d%.]+)","\\bord0$")
                    -- \shad
                    elseif (result["other"]=="shad") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\shad([%-%d%.]+)","\\shad","\\shad0","([^}]*)}\\shad([%-%d%.]+)","\\shad0$")
                    -- \xshad
                    elseif (result["other"]=="xshad") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\xshad([%-%d%.]+)","\\xshad","\\xshad0","([^}]*)}\\xshad([%-%d%.]+)","\\xshad0$")
                    -- \yshad
                    elseif (result["other"]=="yshad") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\yshad([%-%d%.]+)","\\yshad","\\yshad0","([^}]*)}\\yshad([%-%d%.]+)","\\yshad0$")
                    -- t1
                    elseif (result["other"]=="t1") then
                        ltext = rewrite_other(tt_table,rule_table,result["mode"],bias,
                            "\\t%(([%-%d%.]+)","\\t(","\\t(0","([^}]*)}\\t%(([%-%d%.]+)","\\t%(0$")
                    -- t2
                    elseif (result["other"]=="t2") then
                        ltext = rewrite_t2(tt_table,rule_table,result["mode"],bias)
                    -- \i?clip vector
                    elseif (result["other"]=="clip") then
                        ltext = rewrite_clip(tt_table,rule_table,result["mode"],bias)
                    else
                    end
                else
                end
            -- \t true and custom mode
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
        return math.pow(1/(N-1)*(i-1),accel)
    else
        return math.pow(1/(T-1)*(t-1),accel)
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

-- subfrom="\\1c&?H?([0-9a-fA-F]+)&?",
-- tagtype="\\1c",
-- subtail="\\1c&HFFFFFF&",
-- match"([^}]*)}\\1c(&H[0-9a-fA-F]+&)",
-- matchtail="\\1c&HFFFFFF&$")
function rewrite_c(tt_table,rule_table,mode,bias,subfrom,tagtype,subtail,match,matchtail)
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

                if (mode=="exact match") then
                    tt.tag = tt.tag:gsub(subfrom,function(a) return "}"..tagtype.."&H"..a.."&" end)
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

function rewrite_a(tt_table,rule_table,mode,bias,subfrom,tagtype,subtail,match,matchtail)
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

                if (mode=="exact match") then
                    tt.tag = tt.tag:gsub(subfrom,function(a) return "}"..tagtype.."&H"..a.."&" end)
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

-- subfrom "\\pos%(([%-%d%.]+),([%-%d%.]+)%)"    --match "([^W]*)WWW\\pos%(([%-%d%.]+),([%-%d%.]+)%)"
function rewrite_pos(tt_table,rule_table,mode,bias,subfrom,match)
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

                if (mode=="exact match") then
                    tt.tag = tt.tag:gsub(subfrom,function(a,b) return "}\\pos("..a..","..b..")" end)
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

function rewrite_other(tt_table,rule_table,mode,bias,subfrom,tagtype,subtail,match,matchtail)
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

                if (mode=="exact match") then
                    tt.tag = tt.tag:gsub(subfrom,function(a) return "}"..tagtype..a end)
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

                if (mode=="exact match") then
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

                if (mode=="exact match") then
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

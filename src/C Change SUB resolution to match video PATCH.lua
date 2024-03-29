--[[
README:

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

Change SUB resolution to match video PATCH

    [Script Info]
    ; Script generated by Aegisub 3.2.2
    ; http://www.aegisub.org/
    Title: Default Aegisub file
    ScriptType: v4.00+
    WrapStyle: 0
    ScaledBorderAndShadow: no
    YCbCr Matrix: TV.709
    PlayResX: 384
    PlayResY: 288

]]

--Script properties
script_name="C Change SUB resolution to match video PATCH"
script_description="Change SUB resolution to match video PATCH v1.2"
script_author="chaaaaang"
script_version="1.3"

include('karaskel.lua')

--GUI
local dialog_config={
    {class="label",label="input resolution",x=0,y=0,width=1},
    {class="dropdown",name="i",items={"384x288","640x480","720x480","800x480","1024x576","1280x720","1440x810","1920x1080","3840x2160","7680x4320"},value="384x288",x=1,y=0},
    {class="label",label="output resolution",x=0,y=1,width=1},
    {class="dropdown",name="o",items={"384x288","640x480","720x480","800x480","1024x576","1280x720","1440x810","1920x1080","3840x2160","7680x4320"},value="1920x1080",x=1,y=1},
    {class="checkbox",name="e",label="scale \\blur, \\be, \\bord and \\shad",value=false,x=0,y=2,width=2,hint="recommend: off"},
    {class="checkbox",name="p",label="scale \\1img",value=false,x=0,y=3},
    {class="label",label="     SUB Resolution\n            Reset v1.3",x=1,y=3,height=2}
}
local buttons={"Run","Quit"}

local function rounding(x)
    return tonumber(string.format('%.3f', x))
end

function main(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)

    local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if pressed ~= "Run" then 
        aegisub.cancel() 
    else
        local iw,ih = result.i:match("(%d+)x(%d+)")
        local ow,oh = result.o:match("(%d+)x(%d+)")
        local rx,ry = tonumber(ow)/tonumber(iw),tonumber(oh)/tonumber(ih)

        for i=1,#subtitle do
            if subtitle[i].class=="style" then
                local style = subtitle[i]
                style.scale_x = rounding(style.scale_x*ry)
                style.scale_y = rounding(style.scale_y*ry)
                style.spacing = rounding(style.spacing*rx/ry)
                style.margin_t = rounding(style.margin_t*ry)
                style.margin_b = rounding(style.margin_b*ry)
                style.margin_l = rounding(style.margin_l*rx)
                style.margin_r = rounding(style.margin_r*rx)

                if result.e==true then
                    style.outline = rounding(style.outline*ry)
                    style.shadow = rounding(style.shadow*ry)
                end
                subtitle[i] = style
            elseif subtitle[i].class=="dialogue" and subtitle[i].comment==false then
                local line = subtitle[i]
                local linetext = line.text
                linetext = linetext:gsub("}{","")

                linetext = linetext:gsub("\\pos%( *([%d%.%-]+) *, *([%d%.%-]+) *%)",
                    function(a,b) return "\\pos("..rounding(a*rx)..","..rounding(b*ry)..")" end)
                linetext = linetext:gsub("\\org%( *([%d%.%-]+) *, *([%d%.%-]+) *%)",
                    function(a,b) return "\\org("..rounding(a*rx)..","..rounding(b*ry)..")" end)
                linetext = linetext:gsub("(\\movev?c?)%( *([%d%.%-]+) *, *([%d%.%-]+) *, *([%d%.%-]+) *, *([%d%.%-]+) *%)",
                    function(p,a,b,c,d) 
                        return p.."("..rounding(a*rx)..","..rounding(b*ry)..","..rounding(c*rx)..","..rounding(d*ry)..")" 
                    end)
                -- moves
                linetext = linetext:gsub("\\moves(%d)(%([^%)]+%))",
                    function(p,a)
                        p = tonumber(p)
                        a = a:gsub(" *([%d%.%-]+) *, *([%d%.%-]+) *",
                            function (x,y) return rounding(x*rx)..","..rounding(y*ry) end, p)
                        return "\\moves"..p..a
                    end)
                -- clip
                linetext = linetext:gsub("(\\i?clip)(%([^%)]+%))",
                    function (p,a)
                        if a:match(",")~=nil then
                            a = a:gsub(" *([%d%.%-]+) *, *([%d%.%-]+) *, *([%d%.%-]+) *, *([%d%.%-]+) *", function (h,j,k,l)
                                return rounding(h*rx)..","..rounding(j*ry)..","..rounding(k*rx)..","..rounding(l*ry) end)
                        else
                            a = a:gsub("([%d%.%-]+) +([%d%.%-]+)",
                                function (b,c) return rounding(b*rx).." "..rounding(c*ry) end)
                        end
                        return p..a
                    end)
                
                linetext = linetext:gsub("\\fsp([%d%.%-]+)", function (a) return "\\fsp"..rounding(a*rx/ry) end)
                linetext = linetext:gsub("\\fsvp([%d%.%-]+)", function (a) return "\\fsvp"..rounding(a*ry) end)
                linetext = linetext:gsub("\\fsc([%d%.%-]+)", "\\fscx%1\\fscy%1")
                linetext = linetext:gsub("\\fscx([%d%.%-]+)", function (a) return "\\fscx"..rounding(a*ry) end)
                linetext = linetext:gsub("\\fscy([%d%.%-]+)", function (a) return "\\fscy"..rounding(a*ry) end)
                -- drawing
                if linetext:match("\\p%d")~=nil then
                    if linetext:match("\\fscx")~=nil then
                        linetext = linetext:gsub("\\fscx([%d%.%-]+)",function (a) return "\\fscx"..rounding(a*rx/ry) end)
                    else
                        karaskel.preproc_line(subtitle,meta,styles,line)
                        linetext = linetext:gsub("^","{\\fscx"..rounding(line.styleref.scale_x*rx).."}")
                        linetext = linetext:gsub("}{","")
                    end
                    -- 1img
                    if result.p==true then 
                        linetext = linetext:gsub("\\1img","\\5img")
                    end
                end
                if result.e==true then
                    linetext = linetext:gsub("\\be([%d%.%-]+)",function (a) return "\\be"..rounding(a*ry) end)
                    linetext = linetext:gsub("\\blur([%d%.%-]+)",function (a) return "\\blur"..rounding(a*ry) end)
                    linetext = linetext:gsub("\\bord([%d%.%-]+)",function (a) return "\\bord"..rounding(a*ry) end)
                    linetext = linetext:gsub("\\([xy]?shad)([%d%.%-]+)",function (a,b) return a..rounding(b*ry) end)
                end

                line.margin_t = rounding(line.margin_t*ry)
                line.margin_b = rounding(line.margin_b*ry)
                line.margin_l = rounding(line.margin_l*rx)
                line.margin_r = rounding(line.margin_r*rx)
                line.text = linetext
                subtitle[i]=line
            end
            aegisub.progress.set((i-1)/#subtitle*100)
        end
    end
    aegisub.log("The convertion has completed.\nPlease reset the resolution of the subtitle manually.")
	aegisub.set_undo_point(script_name)
	return selected
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)

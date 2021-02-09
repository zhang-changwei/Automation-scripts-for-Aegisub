--[[
README:

Translation

Feature:
Translate the values of the tags
which means add values with equivalent inteval (or specific function relationship) to the tags of selected lines
Now \pos \fscx \fscy \[i]clip tags are supported

Manual:
1. Select the lines
2. Check the tag(s) you want to translate on the GUI and set the corresponding three values
   start: the translation value of the first line
   end:   the translation value of the last line
   accel: the gradient function (default value 1 means equivalent interval)
3. Press OK and run

Bug Report:
1. Only zero or one \pos tag can be included in one line

Updated on 21 Jan 2021
    Bug of position recognition fixed
    Name changed to Translation

Updated on 20 Jan 2021
    New feature (scale|clip) added

Updated on 7 Dec 2020
]]

script_name="C Translation"
script_description="Trasnlation"
script_author="chaaaaang"
script_version="1.1" 

include("karaskel.lua")

--GUI
dialog_config={
    {class="checkbox",name="posx",label="posx",value=false,x=0,y=0},
    {class="label",label="posx_start",x=1,y=0},
    {class="floatedit",name="posx_start",value=0,x=2,y=0},
    {class="label",label="posx_end",x=3,y=0},
    {class="floatedit",name="posx_end",value=0,x=4,y=0},
    {class="label",label="accel",x=5,y=0},
    {class="floatedit",name="posx_accel",value=1,x=6,y=0},

    {class="checkbox",name="posy",label="posy",value=false,x=0,y=1},
    {class="label",label="posy_start",x=1,y=1},
    {class="floatedit",name="posy_start",value=0,x=2,y=1},
    {class="label",label="posy_end",x=3,y=1},
    {class="floatedit",name="posy_end",value=0,x=4,y=1},
    {class="label",label="accel",x=5,y=1},
    {class="floatedit",name="posy_accel",value=1,x=6,y=1},

    {class="checkbox",name="fscx",label="fscx",value=false,x=0,y=2},
    {class="label",label="fscx_start",x=1,y=2},
    {class="floatedit",name="fscx_start",value=0,x=2,y=2},
    {class="label",label="fscx_end",x=3,y=2},
    {class="floatedit",name="fscx_end",value=0,x=4,y=2},
    {class="label",label="accel",x=5,y=2},
    {class="floatedit",name="fscx_accel",value=1,x=6,y=2},

    {class="checkbox",name="fscy",label="fscy",value=false,x=0,y=3},
    {class="label",label="fscy_start",x=1,y=3},
    {class="floatedit",name="fscy_start",value=0,x=2,y=3},
    {class="label",label="fscy_end",x=3,y=3},
    {class="floatedit",name="fscy_end",value=0,x=4,y=3},
    {class="label",label="accel",x=5,y=3},
    {class="floatedit",name="fscy_accel",value=1,x=6,y=3},

    {class="checkbox",name="clip_x",label="clip_x",value=false,x=0,y=4},
    {class="label",label="clip_x_start",x=1,y=4},
    {class="floatedit",name="clip_x_start",value=0,x=2,y=4},
    {class="label",label="clip_x_end",x=3,y=4},
    {class="floatedit",name="clip_x_end",value=0,x=4,y=4},
    {class="label",label="accel",x=5,y=4},
    {class="floatedit",name="clip_x_accel",value=1,x=6,y=4},

    {class="checkbox",name="clip_y",label="clip_y",value=false,x=0,y=5},
    {class="label",label="clip_y_start",x=1,y=5},
    {class="floatedit",name="clip_y_start",value=0,x=2,y=5},
    {class="label",label="clip_y_end",x=3,y=5},
    {class="floatedit",name="clip_y_end",value=0,x=4,y=5},
    {class="label",label="accel",x=5,y=5},
    {class="floatedit",name="clip_y_accel",value=1,x=6,y=5},
    --note
    {class="label",x=0,y=6,width=7,label="have to be used in FRAME BY FRAME lines, may use the linetofbf in Relocator first"},
    {class="label",x=0,y=7,width=7,label="accel argument (0,inf), mapped from R by LN function, For convenience, ln(2)=0.69, ln(3)=1.10"},
    {class="label",x=0,y=8,width=7,label="ATTENTION: positive posy means moving downwards"}
    
}
buttons={"Run","Quit"}

function main(subtitle, selected, active)
    local meta,styles=karaskel.collect_head(subtitle,false)
    xres, yres, ar, artype = aegisub.video_size()

    --count the size
    local i = 0
    local start_f = 0
    local end_f = 0
    for sa,la in ipairs(selected) do
        local line=subtitle[la]
        if (i == 0) then start_f = aegisub.frame_from_ms(line.start_time) end
        end_f = aegisub.frame_from_ms(line.start_time)
        i = i + 1
    end
    local N = end_f - start_f + 1

    pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end
    --all false
    if (result["posx"]==false and result["posy"]==false and result["fscx"]==false and result["fscy"]==false and result["clip_x"]==false and result["clip_y"]==false) then 
        aegisub.cancel()
    else
        --loop begins
        for si,li in ipairs(selected) do
            local line=subtitle[li]
            local now_f = aegisub.frame_from_ms(line.start_time)
            local i = now_f - start_f
            karaskel.preproc_line(subtitle,meta,styles,line)
            --preprocession
            if (line.text:match("^{")==nil) then
                linetext = "{}"..line.text
            else
                linetext = line.text
            end
            linetext = linetext:gsub("}{","")
            
            --posx posy
            if (result["posx"]==true or result["posy"]==true) then
                --confirm the \pos is in the tag
                if (linetext:match("^{[^}]*\\pos[^}]*}")==nil) then
                    if (linetext:match("\\an%d")==nil) then
                        linetext=linetext:gsub("^{",string.format("{\\pos(%.3f,%.3f)",line.x,line.y))
                    elseif (linetext:match("\\an1")~=nil) then
                        linetext=linetext:gsub("^{",string.format("{\\pos(%.3f,%.3f)",line.styleref.margin_l,yres-line.styleref.margin_b))
                    elseif (linetext:match("\\an2")~=nil) then
                        linetext=linetext:gsub("^{",string.format("{\\pos(%.3f,%.3f)",xres/2,yres-line.styleref.margin_b))
                    elseif (linetext:match("\\an3")~=nil) then
                        linetext=linetext:gsub("^{",string.format("{\\pos(%.3f,%.3f)",xres-line.styleref.margin_r,yres-line.styleref.margin_b))
                    elseif (linetext:match("\\an4")~=nil) then
                        linetext=linetext:gsub("^{",string.format("{\\pos(%.3f,%.3f)",line.styleref.margin_l,yres/2))
                    elseif (linetext:match("\\an5")~=nil) then
                        linetext=linetext:gsub("^{",string.format("{\\pos(%.3f,%.3f)",xres/2,yres/2))
                    elseif (linetext:match("\\an6")~=nil) then
                        linetext=linetext:gsub("^{",string.format("{\\pos(%.3f,%.3f)",xres-line.styleref.margin_r,yres/2))
                    elseif (linetext:match("\\an7")~=nil) then
                        linetext=linetext:gsub("^{",string.format("{\\pos(%.3f,%.3f)",line.styleref.margin_l,line.styleref.margin_t))
                    elseif (linetext:match("\\an8")~=nil) then
                        linetext=linetext:gsub("^{",string.format("{\\pos(%.3f,%.3f)",xres/2,line.styleref.margin_t))
                    elseif (linetext:match("\\an9")~=nil) then
                        linetext=linetext:gsub("^{",string.format("{\\pos(%.3f,%.3f)",xres-line.styleref.margin_r,line.styleref.margin_t))
                    else
                    end
                end

                if (result["posx"]==true) then
                    local gposx = linetext:match("\\pos%([^,]*")
                    gposx = tonumber(gposx:sub(6))
                    linetext=linetext:gsub("\\pos%([^,]*,",string.format("\\pos(%.3f,", gposx + calculation(result["posx_start"],result["posx_end"],result["posx_accel"],N,i)))
                end
                if (result["posy"]==true) then
                    local gpx, gpy = linetext:match("\\pos%(([^,]*),([^%)]*)%)")
                    gpy = tonumber(gpy)+calculation(result["posy_start"],result["posy_end"],result["posy_accel"],N,i)
                    linetext=linetext:gsub("\\pos%(([^,]*),[^%)]*%)",string.format("\\pos(%s,%.3f)",gpx,gpy))
                end
            end
            --fscx
            if (result["fscx"]==true) then
                if (linetext:match("^{[^}]*\\fscx[^}]*}")==nil) then
                    linetext=linetext:gsub("^{",string.format("{\\fscx%.2f",line.styleref.scale_x))
                end
                linetext = linetext:gsub("\\fscx([%d%.]+)",function(a) 
                    return string.format("\\fscx%.2f", a + calculation(result["fscx_start"],result["fscx_end"],result["fscx_accel"],N,i)) end)
            end
            --fscy
            if (result["fscy"]==true) then
                if (linetext:match("^{[^}]*\\fscy[^}]*}")==nil) then
                    linetext=linetext:gsub("^{",string.format("{\\fscy%.2f",line.styleref.scale_y))
                end
                linetext = linetext:gsub("\\fscy([%d%.]+)",function(a) 
                    return string.format("\\fscy%.2f", a + calculation(result["fscy_start"],result["fscy_end"],result["fscy_accel"],N,i)) end)
            end
            --frz
            if (result["frz"]==true) then
                if (linetext:match("^{[^}]*\\frz[^}]*}")==nil) then
                    linetext=linetext:gsub("^{","{\\frz0")
                end
                linetext = linetext:gsub("\\frz([%d%.%-]+)",function(a) 
                    return string.format("\\frz%.2f", a + calculation(result["frz_start"],result["frz_end"],result["frz_accel"],N,i)) end)
            end
            --fax
            if (result["fax"]==true) then
                linetext = linetext:gsub("\\fax([%d%.%-]+)",function(a) 
                    return string.format("\\fax%.2f", a + calculation(result["fax_start"],result["fax_end"],result["fax_accel"],N,i)) end)
            end
            --fay
            if (result["fay"]==true) then
                linetext = linetext:gsub("\\fay([%d%.%-]+)",function(a) 
                    return string.format("\\fay%.2f", a + calculation(result["fay_start"],result["fay_end"],result["fay_accel"],N,i)) end)
            end
            --clip
            if (result["clip_x"]==true or result["clip_y"]==true) then
                linetext = linetext:gsub("(\\[i]?clip)([^%)]+)%)",
                    function(c,d) 
                        --odd or even xyxy
                        local o_e=0
                        local trs_clip = c 
                        for head,num in d:gmatch("([^%d%.%-]+)([%d%.%-]+)") do
                            if (o_e == 0 and result["clip_x"]==true) then 
                                trs_clip = string.format("%s%s%.2f",trs_clip,head,num+calculation(result["clip_x_start"],result["clip_x_end"],result["clip_x_accel"],N,i))
                            elseif (o_e == 1 and result["clip_y"]==true) then
                                trs_clip = string.format("%s%s%.2f",trs_clip,head,num+calculation(result["clip_y_start"],result["clip_y_end"],result["clip_y_accel"],N,i))
                            else
                                trs_clip = string.format("%s%s%.2f",trs_clip,head,num)
                            end
                            o_e = (o_e + 1)%2
                        end
                        return trs_clip..")" 
                    end)
            end
            --more feature (gradient|smooth) coming
            line.text = linetext
            line.actor = "C"
            subtitle[li] = line
        end
        --loop ends
    end
    aegisub.set_undo_point(script_name) 
    return selected 
end
--i from 0 to N-1
function calculation(s, e, a, N, i)
    local a_in_phy=math.log(a)
    local v0=(e-s-1/2*a_in_phy*(N-1)^2)/(N-1)
    return s+v0*i+1/2*a_in_phy*i^2
end


--This optional function lets you prevent the user from running the macro on bad input
function macro_validation(subtitle, selected, active)
    --Check if the user has selected valid lines
    --If so, return true. Otherwise, return false
    return true
end

--This is what puts your automation in Aegisub's automation list
aegisub.register_macro(script_name,script_description,main,macro_validation)
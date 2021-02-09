--[[
README:

Effect Dissolve

Feature:
Create dissolve effect from \fad code
ATTITION: This script will create A LOT OF lines. Notice it.

Manual:
Select one line and run the script

]]

--Script properties
script_name="C Effect Dissolove"
script_description="Dissolve"
script_author="chaaaaang"
script_version="1.0"

include("karaskel.lua")

--GUI
dialog_config={
    {class="label",label="pixel of x fragment",x=0,y=0},
    {class="floatedit",name="step_x",value=4,x=2,y=0},
    {class="label",label="pixel of y fragment",x=0,y=1},
    {class="floatedit",name="step_y",value=4,x=2,y=1}
}
buttons={"Run","Quit"}

function main(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)
    xres, yres, ar, artype = aegisub.video_size()
    math.randomseed(os.time())

    pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end

	for si,li in ipairs(selected) do
		
		local line=subtitle[li]
        karaskel.preproc_line(subtitle,meta,styles,line)
        
        local ltext = line.text
        subtitle.delete(li)

        --time related
        local fin_time,fout_time = ltext:match("\\fad%(([%d%.]+),([%d%.]+)%)")
        ltext = ltext:gsub("\\fad%([^%)]+%)","")
        
        fin_time = tonumber(fin_time)
        fout_time = tonumber(fout_time)

        line.text = ltext
        --upward clear \fad tag in line

        --width|height|top|left
        ltext = ltext:gsub("\\fsc([%d%.]+)","\\fscx%1\\fscy%1")
        local fsinline = tonumber(ltext:match("\\fs([%d%.]+)"))
        local fscxinline = tonumber(ltext:match("\\fscx([%d%.]+)"))
        local fscyinline = tonumber(ltext:match("\\fscy([%d%.]+)"))
        local an = line.styleref.align
        if (ltext:match("\\an%d")~=nil) then an = tonumber(ltext:match("\\an(%d)")) end
        local left,top,right,bottom,width,height,center,middle=0

        --ratio
        local ratiox,ratioy = 1
        if (ltext:match("\\fs")~=nil) then
            ratiox = tonumber(ltext:match("\\fs([%d%.]+)")) / line.styleref.fontsize
            ratioy = tonumber(ltext:match("\\fs([%d%.]+)")) / line.styleref.fontsize
        end
        if (ltext:match("\\fscx")~=nil) then 
            ratiox = tonumber(ltext:match("\\fscx([%d%.]+)")) / line.styleref.scale_x
        end
        if (ltext:match("\\fscy")~=nil) then 
            ratiox = tonumber(ltext:match("\\fscy([%d%.]+)")) / line.styleref.scale_x
        end
        width = line.width * ratiox
        height = line.height * ratioy

        if     (an == 1) then
            if (ltext:match("\\pos")~=nil) then
                left = tonumber(ltext:match("\\pos%(([^,]+)"))
                bottom = tonumber(ltext:match("\\pos%([^,]+,([^%)]+)"))
            else
                left = line.styleref.margin_l
                bottom = yres-line.styleref.margin_b
            end
            right = left + width
            top = bottom - height
        elseif (an == 2) then
            if (ltext:match("\\pos")~=nil) then
                center = tonumber(ltext:match("\\pos%(([^,]+)"))
                bottom = tonumber(ltext:match("\\pos%([^,]+,([^%)]+)"))
            else
                center = xres/2
                bottom = yres-line.styleref.margin_b
            end
            left = center - width / 2
            right = center + width / 2
            top = bottom - height
        elseif (an == 3) then
            if (ltext:match("\\pos")~=nil) then
                right = tonumber(ltext:match("\\pos%(([^,]+)"))
                bottom = tonumber(ltext:match("\\pos%([^,]+,([^%)]+)"))
            else
                right = xres-line.styleref.margin_r
                bottom = yres-line.styleref.margin_b
            end
            left = right - width
            top = bottom - height
        elseif (an == 4) then
            if (ltext:match("\\pos")~=nil) then
                left = tonumber(ltext:match("\\pos%(([^,]+)"))
                middle = tonumber(ltext:match("\\pos%([^,]+,([^%)]+)"))
            else
                left = line.styleref.margin_l
                middle = yres/2
            end
            right = left + width
            top = middle - height / 2
            bottom = middle + height / 2
        elseif (an == 5) then
            if (ltext:match("\\pos")~=nil) then
                center = tonumber(ltext:match("\\pos%(([^,]+)"))
                middle = tonumber(ltext:match("\\pos%([^,]+,([^%)]+)"))
            else
                center = xres/2
                middle = yres/2
            end
            left = center - width / 2
            right = center + width / 2
            top = middle - height / 2
            bottom = middle + height / 2
        elseif (an == 6) then
            if (ltext:match("\\pos")~=nil) then
                right = tonumber(ltext:match("\\pos%(([^,]+)"))
                middle = tonumber(ltext:match("\\pos%([^,]+,([^%)]+)"))
            else
                right = xres-line.styleref.margin_r
                middle = yres/2
            end
            left = right - width
            top = middle - height / 2
            bottom = middle + height / 2
        elseif (an == 7) then
            if (ltext:match("\\pos")~=nil) then
                left = tonumber(ltext:match("\\pos%(([^,]+)"))
                top = tonumber(ltext:match("\\pos%([^,]+,([^%)]+)"))
            else
                left = line.styleref.margin_l
                top = line.styleref.margin_t
            end
            right = left + width
            bottom = top + height
        elseif (an == 8) then
            if (ltext:match("\\pos")~=nil) then
                center = tonumber(ltext:match("\\pos%(([^,]+)"))
                top = tonumber(ltext:match("\\pos%([^,]+,([^%)]+)"))
            else
                center = xres/2
                top = line.styleref.margin_t
            end
            left = center - width / 2
            right = center + width / 2
            bottom = top + height
        elseif (an == 9) then
            if (ltext:match("\\pos")~=nil) then
                right = tonumber(ltext:match("\\pos%(([^,]+)"))
                top = tonumber(ltext:match("\\pos%([^,]+,([^%)]+)"))
            else
                right = xres-line.styleref.margin_r
                top = line.styleref.margin_t
            end
            left = right - width
            bottom = top + height
        else
        end

        --the loop
        for i=0,width,result["step_x"] do
            for j=0,height,result["step_y"] do
                subtitle.insert(li,line)
                --create a new line called lg
                local lg = subtitle[li]
                local lgtext = lg.text
                --add clip
                lgtext = lgtext:gsub("^({[^}]*)}",function(a) return string.format("%s\\clip(%.2f,%.2f,%.2f,%.2f)}",a,left+i,top+j,left+i+result["step_x"],top+j+result["step_y"]) end)

                lgtext = lgtext:gsub("^{",
                function() 
                    --fi1<fi2
                    local fi1 = math.random(0,math.floor(fin_time))
                    local fi2 = math.random(0,math.floor(fin_time))
                    if (fi1>fi2) then local temp=fi1 fi1=fi2 fi2=temp end
                    return string.format("{\\alpha&HFF&\\t(%d,%d,\\alpha&H00&)",fi1,fi2)
                end)

                lgtext = lgtext:gsub("^({[^}]*)}",
                function(b) 
                    local fo1 = math.random(0,math.floor(fout_time))
                    local fo2 = math.random(0,math.floor(fout_time))
                    if (fo1>fo2) then local temp=fo1 fo1=fo2 fo2=temp end
                    return string.format("%s\\t(%d,%d,\\alpha&HFF&)}",b, line.duration-fo2, line.duration-fo1)
                end)
                lg.text = lgtext
                subtitle[li] = lg
            end
        end
	end
	
	aegisub.set_undo_point(script_name)
	return selected
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)

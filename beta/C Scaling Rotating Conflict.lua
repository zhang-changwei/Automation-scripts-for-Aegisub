--[[
README:

]]

--Script properties
script_name="C Scaling Rotation Conflict"
script_description=""
script_author="chaaaaang"
script_version="1.0"

include("karaskel.lua")

--GUI
dialog_config={
    {class="label",label="suffix",x=0,y=0},
    {class="intedit",name="suffix",value=1,x=0,y=1}
}
buttons={"Run","Quit"}

function main(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)

    pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end

    --get style_name and table
    selected_style = ""
    style_table = {}
	for si,li in ipairs(selected) do
		
		local line=subtitle[li]
		karaskel.preproc_line(subtitle,meta,styles,line)

        local ltext = line.text

        ltext = ltext:gsub("\\fsc([%d%-%.]+)","\\fscx%1\\fscy%1")
		local scale_x = ltext:match("\\fscx([%d%-%.]+)")
        local scale_y = ltext:match("\\fscy([%d%-%.]+)")
        ltext = ltext:gsub("\\fscx[%d%-%.]+","")
        ltext = ltext:gsub("\\fscy[%d%-%.]+","")
        
        selected_style = line.style
        line.style = string.format("%s_%d",line.style,result["suffix"])
        line.text = ltext

        table.insert(style_table,{name=line.style,x=scale_x,y=scale_y})

		subtitle[li]=line
		
        result["suffix"] = result["suffix"] + 1
	end
	--search from first line
    for li=1,#subtitle do
        local style = subtitle[li]
        if (style.class == "style" and style.name == selected_style) then
            subtitle.delete(li)
            for _,sty in ipairs(style_table) do
                subtitle.insert(li,style)
                sg = subtitle[li]
                sg.name = sty.name
                sg.scale_x = sty.x
                sg.scale_y = sty.y
                subtitle[li] = sg

                li = li + 1
            end
            break
        end
    end
	aegisub.set_undo_point(script_name)
	return 0
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)

--[[
README:

]]

--Script properties
script_name="test"
script_description="Capitalize first character of en line"
script_author="chaaaaang"
script_version="1.0"

local Yutils = require('Yutils')
include('karaskel.lua')

local dialog_config = {
	{class="label",label="effect",x=0,y=0},
	{class="dropdown",name="effect",items={"particle","spotlight"},x=0,y=1,width=2}
}
local buttons = {"Detail","Quit"}

function main(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)


		for si,li in ipairs(selected) do
			
			local line=subtitle[li]
			local shape = "m 949 410 l 810 664 1157 568"
			local bound_left,bound_top,bound_right,bound_bottom = Yutils.shape.bounding(shape)
			line.text = bound_left
			subtitle[li]=line
		end

	aegisub.set_undo_point(script_name)
	return selected
end

function daughter_dialog(effect)
	if (effect=="particle") then
		dialog_conf = {
			{class="label",label="particle",x=0,y=0},
			{class="checkbox",label="fade_in",name="fade_in",x=1,y=0},
			{class="checkbox",label="fade_out",name="fade_out",x=1,y=1},
			{class="label",label="fade_time",x=2,y=0},
			{class="floatedit",name="fade_time",value=300,x=2,y=1},
			{class="label",label="move_time",x=3,y=0},
			{class="floatedit",name="move_time",value=1500,x=3,y=1},
			{class="label",label="move_x",x=4,y=0},
			{class="floatedit",name="move_x",value=0,x=4,y=1},
			{class="label",label="move_y",x=5,y=0},
			{class="floatedit",name="move_y",value=0,x=5,y=1}
		}
		button = {"Run","Quit"}
		return dialog_conf,button
	end
end
--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)


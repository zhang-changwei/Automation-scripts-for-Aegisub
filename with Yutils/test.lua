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

-- max height = 0-40 max width = 0-180
-- (0,41) & (271,0)
local dialog_config = {
	{class="label",label="x",x=0,y=0},
	{class="label",label=" ",x=0,y=1},
	{class="label",label="x",x=1,y=0},
	{class="label",label="x",x=1,y=1},
	{class="label",label="x",x=1,y=40}
}
local buttons = {"Read"}

function main(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)
	local xres, yres, ar, artype = aegisub.video_size()

	-- UI stuff
	for j = 2,180 do
		for k = 2,40 do
			if k==2 then table.insert(dialog_config,{class="label",label="x",x=j,y=0}) end
		end
	end
	local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end

		for si,li in ipairs(selected) do
			
			local line=subtitle[li]
			karaskel.preproc_line(subtitle,meta,styles,line)
			local linetext = line.text
				
			subtitle[li]=line
		end

	aegisub.set_undo_point(script_name)
	return selected
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)


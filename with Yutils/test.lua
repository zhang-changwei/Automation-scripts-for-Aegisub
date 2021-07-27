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



		for si,li in ipairs(selected) do
			
			local line=subtitle[li]
			karaskel.preproc_line(subtitle,meta,styles,line)
			local linetext = line.text

			BMP_READER = Yutils.decode.create_bmp_reader("E:\\ZiMuZu\\0_Karaoke\\Yutils\\docs\\favicon.png")
			line.text = BMP_READER.width()
			subtitle[li]=line
		end

	aegisub.set_undo_point(script_name)
	return selected
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)


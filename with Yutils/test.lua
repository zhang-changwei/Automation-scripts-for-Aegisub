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
	{class="label",label="option",x=0,y=0},
	{class="dropdown",name="option",items={"delete SDH comment","spotlight"},x=0,y=1,width=2}
}
local buttons = {"Detail","Quit"}

function main(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)
	local xres, yres, ar, artype = aegisub.video_size()


		for si,li in ipairs(selected) do
			
			local line=subtitle[li]
				karaskel.preproc_line(subtitle,meta,styles,line)
				
				-- line
				local ltxtstripped = line.text_stripped
				local ltext = line.text:match("^{") and line.text or "{}"..line.text
				local ldur = line.duration
				local lsta = line.start_time
				local lend = line.end_time
				local lnum = li
				local lstyle = line.style
				-- tag
				local tag = ltext:match("^{[^}]*}")
				local tag_strip_t = tag:gsub("\\t%([^%)]*%)","")
				local tag_strip_pos = tag:gsub("\\pos%([^%)]*%)","")
				local tag_only_t = "{"
				for t in tag:gmatch("\\t%([^%)]*%)") do	tag_only_t = tag_only_t..t	end
				tag_only_t = tag_only_t.."}"
				-- inline style
				local font = tag_strip_t:match("\\fn") and tag_strip_t:match("\\fn([^\\}]+)") or line.styleref.fontname
				local fontsize = tag_strip_t:match("\\fs%d") and tag_strip_t:match("\\fs([%d%.]+)") or line.styleref.fontsize
				local bold = tag_strip_t:match("\\b%d") and num2bool(tag_strip_t:match("\\b(%d)")) or line.styleref.bold
				local italic = tag_strip_t:match("\\i%d") and num2bool(tag_strip_t:match("\\i(%d)")) or line.styleref.italic
				local underline = tag_strip_t:match("\\u%d") and num2bool(tag_strip_t:match("\\u(%d)")) or line.styleref.underline
				local strikeout = tag_strip_t:match("\\s%d") and num2bool(tag_strip_t:match("\\s(%d)")) or line.styleref.strikeout
				local scale_x = tag_strip_t:match("\\fscx") and tag_strip_t:match("\\fscx([%d%.]+)") or line.styleref.scale_x
				local scale_y = tag_strip_t:match("\\fscy") and tag_strip_t:match("\\fscy([%d%.]+)") or line.styleref.scale_y
				local spacing = tag_strip_t:match("\\fsp") and tag_strip_t:match("\\fsp([%d%.%-]+)") or line.styleref.spacing
				local ca1 = line.styleref.color1
				local ca2 = line.styleref.color2
				local ca3 = line.styleref.color3
				local ca4 = line.styleref.color4
				local angle = tag_strip_t:match("\\frz") and tag_strip_t:match("\\frz([%d%.%-]+)") or line.styleref.angle
				local borderstyle = line.styleref.borderstyle
				local outline = tag_strip_t:match("\\bord") and tag_strip_t:match("\\bord([%d%.]+)") or line.styleref.outline
				local shadow = tag_strip_t:match("\\shad") and tag_strip_t:match("\\shad([%d%.%-]+)") or line.styleref.shadow
				local align = tag_strip_t:match("\\an") and tag_strip_t:match("\\an%d") or line.styleref.align


			-- local font_handle = Yutils.decode.create_font(font,bold,italic,underline,strikeout,fontsize,scale_x/100,scale_y/100,spacing)
			-- 	-- local shape = font_handle.text_to_shape(ltxtstripped)
			-- 	local shape = line.text
			-- 	local pixels = Yutils.shape.to_pixels(shape)

			local bmp = Yutils.decode.create_bmp_reader("E:\\ZiMuZu\\0_Karaoke\\Yutils\\tests\\test.bmp")
			line.text = bmp.file_size()
			subtitle[li]=line
		end

	aegisub.set_undo_point(script_name)
	return selected
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)


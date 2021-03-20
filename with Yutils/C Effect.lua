--[[
README:

]]

--Script properties
script_name="C Effect"
script_description="Effect v1.0"
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
	local xres, yres, ar, artype = aegisub.video_size()
	-- math.randomseed(os.time())

	local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel()
	elseif (pressed=="Detail") then
		local daughter_dialog_config,daughter_buttons = daughter_dialog(result["effect"])
		local d_pressed, d_res = aegisub.dialog.display(daughter_dialog_config,daughter_buttons)
		if (d_pressed=="Quit") then aegisub.cancel() 
		elseif (d_pressed=="Run") then

			local snum = 1
			local style = nil
			for li=1,#subtitle do
				if subtitle[li].class=="style" then
					snum = li
					style = subtitle[li]
					break
				end
			end

			for si,li in ipairs(selected) do
				
				local line=subtitle[li]
				karaskel.preproc_line(subtitle,meta,styles,line)
				
				-- comment the original line
				local ltxtstripped = line.text_stripped
				local ltext = line.text:match("^{") and line.text or "{}"..line.text
				local lnum = li
				local font = ltext:match("\\fn") and ltext:match("\\fn([^\\}]+)") or line.styleref.fontname
				local fontsize = ltext:match("\\fs%d") and ltext:match("\\fs([%d%.]+)") or line.styleref.fontsize
				local bold = ltext:match("\\b%d") and num2bool(ltext:match("\\b(%d)")) or line.styleref.bold
				local italic = ltext:match("\\i%d") and num2bool(ltext:match("\\i(%d)")) or line.styleref.italic
				local underline = ltext:match("\\u%d") and num2bool(ltext:match("\\u(%d)")) or line.styleref.underline
				local strikeout = ltext:match("\\s%d") and num2bool(ltext:match("\\s(%d)")) or line.styleref.strikeout
				local scale_x = ltext:match("\\fscx") and ltext:match("\\fscx([%d%.]+)") or line.styleref.scale_x
				local scale_y = ltext:match("\\fscy") and ltext:match("\\fscy([%d%.]+)") or line.styleref.scale_y
				local spacing = ltext:match("\\fsp") and ltext:match("\\fsp([%d%.%-]+)") or line.styleref.spacing
				local c1 = ltext:match("\\1?c") and ltext:match("\\1?c([^\\}]+)") or line.styleref.color1
				local c2 = ltext:match("\\2c") and ltext:match("\\2c([^\\}]+)") or line.styleref.color2
				local c3 = ltext:match("\\3c") and ltext:match("\\3c([^\\}]+)") or line.styleref.color3
				local c4 = ltext:match("\\4c") and ltext:match("\\4c([^\\}]+)") or line.styleref.color4
				local angle = ltext:match("\\frz") and ltext:match("\\frz([%d%.%-]+)") or line.styleref.angle
				local borderstyle = line.styleref.borderstyle
				local outline = ltext:match("\\bord") and ltext:match("\\bord([%d%.]+)") or line.styleref.outline
				local shadow = ltext:match("\\shad") and ltext:match("\\shad([%d%.%-]+)") or line.styleref.shadow
				local align = ltext:match("\\an") and ltext:match("\\an%d") or line.styleref.align
				-- tag
				local tag = ltext:match("^{[^}]*}")
				local tag_strip_pos = tag:gsub("\\pos%([^%)]*%)","")
				-- position
				local posx,posy,top,left,bottom,right,center,middle = position(ltext,line,xres,yres)

				line.comment = true 
				subtitle[li] = line

				local font_handle = Yutils.decode.create_font(font,bold,italic,underline,strikeout,fontsize,scale_x/100,scale_y/100,spacing)
				local shape = font_handle.text_to_shape(ltxtstripped)
				local pixels = Yutils.shape.to_pixels(shape)

				-- particle effect (using tag_strip_pos)
				if result.effect=="particle" then
					if (d_res.fade_in==true and d_res.fade_out==true) or (d_res.fade_in==false and d_res.fade_out==false) then
						aegisub.cancel()
					end
					-- style
					subtitle.insert(snum,style)
					local new_style = subtitle[snum]
					generate_style(new_style,"particle_"..d_res.suffix,font,fontsize,c1,c2,c3,c4,false,false,false,false,scale_x,scale_y,spacing,angle,borderstyle,0,0,align)
					subtitle[snum] = new_style

					-- content
					if (d_res.shape=="square") then
						if (d_res.fade_in==true) then 
							for j=1,#pixels do
								subtitle.append(line)
								local new_line = subtitle[#subtitle]
								new_line.comment = false
								new_line.style = "particle_"..d_res.suffix
								
								new_line.text = string.format("{\\move(%.2f,%.2f,%.2f,%.2f,%d,%d)",
									left+pixels[j].x-d_res.move_x+math.random(-1*d_res.r,d_res.r), top+pixels[j].y-d_res.move_y+math.random(-1*d_res.r,d_res.r),
									left+pixels[j].x, top+pixels[j].y,--move arg3&4
									math.random(d_res.move_t_r), d_res.move_t+math.random(d_res.move_t_r))
								new_line.text = new_line.text..string.format("\\p1\\fad(%d,0)\\blur2\\t(%d,%d,\\blur0)",
									d_res.fade_t,math.random(d_res.move_t_r),d_res.move_t+math.random(d_res.move_t_r))
								-- color
								if (d_res.c_b==true) then
									new_line.text = new_line.text:gsub("%)$",string.format("\\c%s)",color_html2ass(d_res.c)))
								end
								new_line.text = new_line.text..string.format("%s%s",tag_strip_pos:gsub("^{",""),"m 0 0 l 1 0 1 1 0 1")
								subtitle[#subtitle] = new_line
							end
						else
							for j=1,#pixels do
								subtitle.append(line)
								local new_line = subtitle[#subtitle]
								new_line.comment = false
								new_line.style = "particle_"..d_res.suffix
								
								new_line.text = tag_strip_pos:gsub("}$","")
								new_line.text = new_line.text..string.format("\\move(%.2f,%.2f,%.2f,%.2f,%d,%d)",
									left+pixels[j].x, top+pixels[j].y,
									left+pixels[j].x+d_res.move_x+math.random(-1*d_res.r,d_res.r), top+pixels[j].y+d_res.move_y+math.random(-1*d_res.r,d_res.r),
									line.duration-math.random(d_res.move_t_r)-d_res.move_t,line.duration-math.random(d_res.move_t_r))
								new_line.text = new_line.text..string.format("\\p1\\fad(0,%d)\\t(%d,%d,\\blur2)}m 0 0 l 1 0 1 1 0 1",
									d_res.fade_t,line.duration-math.random(d_res.move_t_r)-d_res.move_t,line.duration-math.random(d_res.move_t_r))
								-- color
								if (d_res.c_b==true) then
									new_line.text = new_line.text:gsub("%)}m 0 0 l 1 0 1 1 0 1$",string.format("\\c%s)}m 0 0 l 1 0 1 1 0 1",color_html2ass(d_res.c)))
								end
								subtitle[#subtitle] = new_line
							end
						end
					-- circle
					elseif (d_res.shape=="circle") then
						if (d_res.fade_in==true) then 
							for j=1,#pixels do
								subtitle.append(line)
								local new_line = subtitle[#subtitle]
								new_line.comment = false
								new_line.style = "particle_"..d_res.suffix
								
								local judge = true
								local pos_r1,pos_r2 = 0,0
								while judge do
									pos_r1,pos_r2 = math.random(-1*d_res.r,d_res.r),math.random(-1*d_res.r,d_res.r)
									judge = not(M.pt_in_circle(left+pixels[j].x-d_res.move_x+pos_r1,top+pixels[j].y-d_res.move_y+pos_r2,center,middle,d_res.r))
								end

								new_line.text = string.format("{\\move(%.2f,%.2f,%.2f,%.2f,%d,%d)",
									left+pixels[j].x-d_res.move_x+pos_r1, top+pixels[j].y-d_res.move_y+pos_r2,
									left+pixels[j].x, top+pixels[j].y,--move arg3&4
									math.random(d_res.move_t_r), d_res.move_t+math.random(d_res.move_t_r))
								new_line.text = new_line.text..string.format("\\p1\\fad(%d,0)\\blur2\\t(%d,%d,\\blur0)",
									d_res.fade_t,math.random(d_res.move_t_r),d_res.move_t+math.random(d_res.move_t_r))
								-- color
								if (d_res.c_b==true) then
									new_line.text = new_line.text:gsub("%)$",string.format("\\c%s)",color_html2ass(d_res.c)))
								end
								new_line.text = new_line.text..string.format("%s%s",tag_strip_pos:gsub("^{",""),"m 0 0 l 1 0 1 1 0 1")
								subtitle[#subtitle] = new_line
							end
						else
							for j=1,#pixels do
								subtitle.append(line)
								local new_line = subtitle[#subtitle]
								new_line.comment = false
								new_line.style = "particle_"..d_res.suffix
								
								local judge = true
								local pos_r1,pos_r2 = 0,0
								while judge do
									pos_r1,pos_r2 = math.random(-1*d_res.r,d_res.r),math.random(-1*d_res.r,d_res.r)
									judge = not(M.pt_in_circle(left+pixels[j].x-d_res.move_x+pos_r1,top+pixels[j].y-d_res.move_y+pos_r2,center,middle,d_res.r))
								end

								new_line.text = tag_strip_pos:gsub("}$","")
								new_line.text = new_line.text..string.format("\\move(%.2f,%.2f,%.2f,%.2f,%d,%d)",
									left+pixels[j].x, top+pixels[j].y,
									left+pixels[j].x+d_res.move_x+pos_r1, top+pixels[j].y+d_res.move_y+pos_r2,
									line.duration-math.random(d_res.move_t_r)-d_res.move_t,line.duration-math.random(d_res.move_t_r))
								new_line.text = new_line.text..string.format("\\p1\\fad(0,%d)\\t(%d,%d,\\blur2)}m 0 0 l 1 0 1 1 0 1",
									d_res.fade_t,line.duration-math.random(d_res.move_t_r)-d_res.move_t,line.duration-math.random(d_res.move_t_r))
								-- color
								if (d_res.c_b==true) then
									new_line.text = new_line.text:gsub("%)}m 0 0 l 1 0 1 1 0 1$",string.format("\\c%s)}m 0 0 l 1 0 1 1 0 1",color_html2ass(d_res.c)))
								end
								subtitle[#subtitle] = new_line
							end
						end
					-- others
					elseif (d_res.shape=="others") then
						local bound_left,bound_top,bound_right,bound_bottom = Yutils.shape.bounding(d_res.shape_code)

						if (d_res.fade_in==true) then 
							for j=1,#pixels do
								subtitle.append(line)
								local new_line = subtitle[#subtitle]
								new_line.comment = false
								new_line.style = "particle_"..d_res.suffix
								
								local judge = true
								local pos_r1,pos_r2 = 0,0
								while judge do
									pos_r1,pos_r2 = math.random(tonumber(bound_left),tonumber(bound_right)),math.random(tonumber(bound_bottom),tonumber(bound_top))
									judge = not(M.pt_in_shape(pos_r1,pos_r2,d_res.shape_code))
								end

								new_line.text = string.format("{\\move(%.2f,%.2f,%.2f,%.2f,%d,%d)",
									pos_r1, pos_r2,
									left+pixels[j].x, top+pixels[j].y,--move arg3&4
									math.random(d_res.move_t_r), d_res.move_t+math.random(d_res.move_t_r))
								new_line.text = new_line.text..string.format("\\p1\\fad(%d,0)\\blur2\\t(%d,%d,\\blur0)",
									d_res.fade_t,math.random(d_res.move_t_r),d_res.move_t+math.random(d_res.move_t_r))
								-- color
								if (d_res.c_b==true) then
									new_line.text = new_line.text:gsub("%)$",string.format("\\c%s)",color_html2ass(d_res.c)))
								end
								new_line.text = new_line.text..string.format("%s%s",tag_strip_pos:gsub("^{",""),"m 0 0 l 1 0 1 1 0 1")
								subtitle[#subtitle] = new_line
							end
						else
							for j=1,#pixels do
								subtitle.append(line)
								local new_line = subtitle[#subtitle]
								new_line.comment = false
								new_line.style = "particle_"..d_res.suffix
								
								local judge = true
								local pos_r1,pos_r2 = 0,0
								while judge do
									pos_r1,pos_r2 = math.random(bound_left,bound_right),math.random(bound_bottom,bound_top)
									judge = not(M.pt_in_shape(pos_r1,pos_r2,d_res.shape_code))
								end

								new_line.text = tag_strip_pos:gsub("}$","")
								new_line.text = new_line.text..string.format("\\move(%.2f,%.2f,%.2f,%.2f,%d,%d)",
									left+pixels[j].x, top+pixels[j].y,
									pos_r1, pos_r2,
									line.duration-math.random(d_res.move_t_r)-d_res.move_t,line.duration-math.random(d_res.move_t_r))
								new_line.text = new_line.text..string.format("\\p1\\fad(0,%d)\\t(%d,%d,\\blur2)}m 0 0 l 1 0 1 1 0 1",
									d_res.fade_t,line.duration-math.random(d_res.move_t_r)-d_res.move_t,line.duration-math.random(d_res.move_t_r))
								-- color
								if (d_res.c_b==true) then
									new_line.text = new_line.text:gsub("%)}m 0 0 l 1 0 1 1 0 1$",string.format("\\c%s)}m 0 0 l 1 0 1 1 0 1",color_html2ass(d_res.c)))
								end
								subtitle[#subtitle] = new_line
							end
						end
					end
				-- spotlight effect
				elseif result.effect=="spotlight" then
				end
			end
		end
	end
	aegisub.set_undo_point(script_name)
	return 0
end

function daughter_dialog(effect)
	if (effect=="particle") then
		dialog_conf = {
			{class="label",label="particle",x=0,y=0},
			{class="checkbox",label="fade_in",name="fade_in",x=0,y=1},
			{class="checkbox",label="fade_out",name="fade_out",x=0,y=2},
			-- basic
			{class="label",label="basic",x=1,y=0},
			{class="label",label="fade time",x=1,y=1},
			{class="intedit",name="fade_t",value=300,x=1,y=2},
			{class="label",label="move time",x=2,y=1},
			{class="intedit",name="move_t",value=1500,x=2,y=2},
			{class="label",label="move time random",x=3,y=1},
			{class="intedit",name="move_t_r",value=1000,x=3,y=2},
			{class="label",label="move_x",x=4,y=1},
			{class="floatedit",name="move_x",value=0,x=4,y=2},
			{class="label",label="move_y",x=5,y=1},
			{class="floatedit",name="move_y",value=0,x=5,y=2},
			-- name
			{class="label",label="style_name_suffix",x=0,y=3},
			{class="intedit",name="suffix",x=0,y=4},
			-- shape
			{class="label",label="shape",x=1,y=3},
			{class="dropdown",name="shape",items={"square","circle","others"},value="square",x=1,y=4},
			{class="label",label="other shape code",x=1,y=5},
			{class="edit",name="shape_code",x=1,y=6,width=2,hint="other shape in ass code, ALERT: BE PATIENT"},
			{class="label",label="radius",x=2,y=4},
			{class="floatedit",name="r",value=150,x=2,y=5,hint="radius for known shape only"},
			-- color 
			{class="checkbox",name="c_b",label="color",value=false,x=3,y=3},
			{class="color",name="c",x=3,y=4},
		}
		button = {"Run","Quit"}
		return dialog_conf,button
	elseif (effect=="spotlight") then
		dialog_conf={
			{class="label",label="spotlight",x=0,y=0}
		}
		button = {"Run","Quit"}
		return dialog_conf,button
	end
end

function num2bool(a)
	if tonumber(a)~=0 then
		return true
	else
		return false
	end
end

function generate_style(style,name,font,fontsize,c1,c2,c3,c4,bold,italic,underline,strikeout,scale_x,scale_y,spacing,angle,borderstyle,outline,shadow,align)
	style.name = name
	style.fontname = font
	style.fontsize = fontsize
	style.color1 = c1
	style.color2 = c2
	style.color3 = c3
	style.color4 = c4
	style.bold = bold
	style.italic = italic
	style.underline = underline
	style.strikeout = strikeout
	style.scale_x = scale_x
	style.scale_y = scale_y
	style.spacing = spacing
	style.angle = angle
	style.borderstyle = borderstyle
	style.outline = outline
	style.shadow = shadow
	style.align = align
end

function color_html2ass(c)
	local r,g,b = c:match("(%x%x)(%x%x)(%x%x)")
	return "&H"..b..g..r.."&"
end

function position(ltext,line,xres,yres)
	local x,y,top,left,bottom,right,center,middle = 0,0,0,0,0,0,0,0
	
	local ratiox,ratioy = 1,1
	if (ltext:match("\\fs%d")~=nil) then
		ratiox = tonumber(ltext:match("\\fs([%d%.]+)")) / line.styleref.fontsize
		ratioy = tonumber(ltext:match("\\fs([%d%.]+)")) / line.styleref.fontsize
	end
	if (ltext:match("\\fscx")~=nil) then 
		ratiox = tonumber(ltext:match("\\fscx([%d%.]+)")) / line.styleref.scale_x
	end
	if (ltext:match("\\fscy")~=nil) then 
		ratioy = tonumber(ltext:match("\\fscy([%d%.]+)")) / line.styleref.scale_y
	end
	local width = line.width * ratiox
	local height = line.height * ratioy
	local an = ltext:match("\\an") and ltext:match("\\an(%d)") or line.styleref.align
	if     (an == 1) then
		if (ltext:match("\\pos")~=nil) then
			left = tonumber(ltext:match("\\pos%(([^,]+)"))
			bottom = tonumber(ltext:match("\\pos%([^,]+,([^%)]+)"))
		else
			left = line.styleref.margin_l
			bottom = yres-line.styleref.margin_b
		end
		x,y = left,bottom
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
		x,y = center,bottom
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
		x,y = right,bottom
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
		x,y = left,middle
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
		x,y = center,middle
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
		x,y = right,middle
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
		x,y = left,top
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
		x,y = center,top
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
		x,y = right,top
		left = right - width
		bottom = top + height
	else
	end
	center,middle = (left+right)/2, (top+bottom)/2
	return x,y,top,left,bottom,right,center,middle
end

M={}

function M.pt_in_circle(x,y,center,middle,r)
	if (x-center)^2+(y-middle)^2<=r^2 then
		return true
	else
		return false
	end
end

function M.pt_in_shape(x,y,shape)
	local bound = Yutils.shape.to_pixels(shape)
	for j=1,#bound do
		if (math.abs(x-bound[j].x)<=0.5 and math.abs(y-bound[j].y)<=0.5) then
			return true
		end
	end
	return false
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)


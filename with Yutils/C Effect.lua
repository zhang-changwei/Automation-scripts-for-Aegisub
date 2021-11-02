--[[
README:

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

]]

--Script properties
script_name="C Effect"
script_description="Effect v1.3.1"
script_author="chaaaaang"
script_version="1.3.1"

local Yutils = require('Yutils')
include('karaskel.lua')

local dialog_config = {
	{class="label",label="effect",x=0,y=0},
	{class="dropdown",name="effect",items={"particle","dissolve","spotlight","clip_blur","clip_gradient","component_split","pixelize","text2shape","bord_contour","shape2bord"},value="particle",x=0,y=1,width=2}
}
local buttons = {"Detail","Quit"}

function main(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)
	local xres, yres, ar, artype = aegisub.video_size()

	local l0,selcount = selected[1],#selected
	local fps = fpsgen()

	-- UI
	local last_effect = config_read_xml(dialog_config)
	local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if pressed~="Detail" then aegisub.cancel() end

	local daughter_config,daughter_buttons = daughter_dialog(result.effect)	
	if result.effect==last_effect then config_read_xml(daughter_config) end
	-- custom config
	custom_config(daughter_config, result.effect)
	local d_pressed, d_res = aegisub.dialog.display(daughter_config,daughter_buttons)
	if d_pressed~="Run" then aegisub.cancel() end
	config_write_xml(result, d_res)

	-- get style snum, style
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
		
		-- line
		local ltxtstripped = line.text_stripped
		ltxtstripped = ltxtstripped:gsub("^ +","")
		ltxtstripped = ltxtstripped:gsub(" +$","")
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
		local xshad,yshad = shadow,shadow
		if tag_strip_t:match("\\xshad") then xshad = tag_strip_t:match("\\xshad([%d%.%-]+)") end
		if tag_strip_t:match("\\yshad") then yshad = tag_strip_t:match("\\yshad([%d%.%-]+)") end
		local align = tag_strip_t:match("\\an%d") and tag_strip_t:match("\\an(%d)") or line.styleref.align
		-- color alpha
		local c1 = tag_strip_t:match("\\1?c&?H?%x") and "&H"..tag_strip_t:match("\\1?c&?H?([%x]+)&?").."&" or "&H"..ca1:match("%x%x(%x%x%x%x%x%x)").."&"
		local c2 = tag_strip_t:match("\\2c&?H?%x")  and "&H"..tag_strip_t:match("\\2c&?H?([%x]+)&?").."&"  or "&H"..ca2:match("%x%x(%x%x%x%x%x%x)").."&"
		local c3 = tag_strip_t:match("\\3c&?H?%x")  and "&H"..tag_strip_t:match("\\3c&?H?([%x]+)&?").."&"  or "&H"..ca3:match("%x%x(%x%x%x%x%x%x)").."&"
		local c4 = tag_strip_t:match("\\4c&?H?%x")  and "&H"..tag_strip_t:match("\\4c&?H?([%x]+)&?").."&"  or "&H"..ca4:match("%x%x(%x%x%x%x%x%x)").."&"
		local alpha = tag_strip_t:match("\\1?al?p?h?a?&?H?%x") and "&H"..tag_strip_t:match("\\1?al?p?h?a?&?H?([%x]+)&?").."&" or "&H"..ca1:match("(%x%x)%x%x%x%x%x%x").."&"
		
		-- tonumber
		fontsize,scale_x,scale_y,spacing,angle,outline,shadow,xshad,yshad,align = tonumber(fontsize),tonumber(scale_x),tonumber(scale_y),tonumber(spacing),tonumber(angle),tonumber(outline),tonumber(shadow),tonumber(xshad),tonumber(yshad),tonumber(align)

		-- position
		local width,height = widthheight(ltxtstripped,line,font,fontsize,bold,italic,underline,strikeout,scale_x,scale_y,spacing,outline,shadow)
		local posx,posy,top,left,bottom,right,center,middle = position(ltext,line,xres,yres,width,height)
		local topL,leftL,bottomL,rightL,centerL,middleL = positionL(angle,posx,posy,top,left,bottom,right)-- consider \\frz

		-- comment the original line
		line.comment = true 
		subtitle[li] = line

		-- comment off & add first {}
		line.comment = false
		line.text = line.text:match("^{") and line.text or "{}"..line.text

		--  Yutils stuff, judge input shape|text
		local shape, shape_bord, pixels_bord, shape_shad, pixels_shad
		if result.effect~="bord_contour" and result.effect~="shape2bord" then 
			local font_handle = Yutils.decode.create_font(font,bold,italic,underline,strikeout,fontsize,scale_x/100,scale_y/100,spacing)
			shape = font_handle.text_to_shape(ltxtstripped) -- text
		else
			shape = ltext:gsub("{[^}]*}","") -- shape
			goto bordshadJUMP
		end
		-- handle outline (pseudo)
		if outline~=0 then 
			local flatten = Yutils.shape.flatten(shape)
			shape_bord = Yutils.shape.to_outline(flatten,outline)
			pixels_bord = Yutils.shape.to_pixels(shape_bord)
		end
		-- handle shadow
		if xshad~=0 or yshad~=0 then 
			if outline~=0 then
				shape_shad = Yutils.shape.filter(shape_bord,function (x,y) return x+xshad,y+yshad end)
			else
				shape_shad = Yutils.shape.filter(shape,function (x,y) return x+xshad,y+yshad end)
			end
			pixels_shad = Yutils.shape.to_pixels(shape_shad)
		end
		::bordshadJUMP::
		local pixels = Yutils.shape.to_pixels(shape)
		::yutilsJUMP::

		-- particle effect (using tag_strip_pos)
		if result.effect=="particle" then
			if (d_res.fade_in==true and d_res.fade_out==true) or (d_res.fade_in==false and d_res.fade_out==false) then aegisub.cancel() end

			local disX,disY = d_res.move_x+d_res.rx, d_res.move_y+d_res.ry

			-- content
			if d_res.adv==false then 
				if d_res.fade_in==true then
					for j=1,#pixels do
						subtitle.append(line)
						local new_line = subtitle[#subtitle]
						
						local pos_r1,pos_r2 = math.random(-1*d_res.rx,d_res.rx),math.random(-1*d_res.ry,d_res.ry)
						local move_t1,move_t2 = math.random(d_res.move_t_r), d_res.move_t+math.random(d_res.move_t_r)
						local x0,y0 = left+pixels[j].x, top+pixels[j].y

						if d_res.third==true then
							new_line.text = string.format("{\\moves3(%d,%d,%d,%d,%d,%d,%d,%d)",
								x0+d_res.move_x+pos_r1, y0+d_res.move_y+pos_r2,
								x0+(d_res.move_x+pos_r1)/2+disX*d_res.curve*(math.random()-0.5), y0+(d_res.move_y+pos_r2)/2+disY*d_res.curve*(math.random()-0.5),
								x0, y0,
								move_t1, move_t2)
						else
							new_line.text = string.format("{\\move(%d,%d,%d,%d,%d,%d)",
								x0+d_res.move_x+pos_r1, y0+d_res.move_y+pos_r2,
								x0, y0,
								move_t1, move_t2)
						end

						new_line.text = new_line.text..string.format("\\p1\\blur2\\alphaFF\\t(%d,%d,\\alpha00)\\t(%d,%d,\\blur0%s)", move_t1, move_t1, move_t1, move_t2, d_res.tags)
						new_line.text = new_line.text..string.format("%s%s",tag_strip_pos:gsub("^{",""),"m 0 0 l 1 0 1 1 0 1")
						subtitle[#subtitle] = new_line

						aegisub.progress.set(j/#pixels*100)
					end
				else
					for j=1,#pixels do
						subtitle.append(line)
						local new_line = subtitle[#subtitle]
						
						local pos_r1,pos_r2 = math.random(-1*d_res.rx,d_res.rx),math.random(-1*d_res.ry,d_res.ry)
						local move_t1,move_t2 = ldur-math.random(d_res.move_t_r)-d_res.move_t,ldur-math.random(d_res.move_t_r)
						local x0,y0 = left+pixels[j].x, top+pixels[j].y

						new_line.text = tag_strip_pos:gsub("}$","")
						if d_res.third==true then
							new_line.text = string.format("{\\moves3(%d,%d,%d,%d,%d,%d,%d,%d)",
								x0+d_res.move_x+pos_r1, y0+d_res.move_y+pos_r2,
								x0+(d_res.move_x+pos_r1)/2+disX*d_res.curve*(math.random()-0.5), y0+(d_res.move_y+pos_r2)/2+disY*d_res.curve*(math.random()-0.5),
								x0, y0,
								move_t1, move_t2)
						else
							new_line.text = new_line.text..string.format("\\move(%d,%d,%d,%d,%d,%d)",
								x0, y0,
								x0+d_res.move_x+pos_r1, y0+d_res.move_y+pos_r2,
								move_t1, move_t2)
						end
						new_line.text = new_line.text..string.format("\\p1\\t(%d,%d,\\blur2%s)\\t(%d,%d,\\alphaFF)}m 0 0 l 1 0 1 1 0 1", move_t1, move_t2, d_res.tags, move_t2, move_t2)
						subtitle[#subtitle] = new_line

						aegisub.progress.set(j/#pixels*100)
					end
				end
			else
				-- kill bord/shad in linetext
				tag_strip_pos = tag_strip_pos:gsub("\\bord[%d%.]+","")
				tag_strip_pos = tag_strip_pos:gsub("\\[xy]?shad[%d%.%-]+","")
				
				for i=math.floor(leftL), math.floor(rightL) do
					for j=math.floor(topL), math.floor(bottomL) do
						--judge: false-> no operation
						local judge = 0
						if true then
							local ii,jj = posL2pos(angle,i+0.5,j+0.5,top,left,posx,posy)
							if M.pt_in_shape2(ii,jj,pixels)==true then judge = 1 goto particle_judge end
							-- outline
							if outline~=0 then
								ii,jj = posL2pos(angle,i+0.5,j+0.5,top,left,posx,posy)
								if M.pt_in_shape2(ii,jj,pixels_bord)==true then judge = 3 goto particle_judge end
							end
							-- shad
							if xshad~=0 or yshad~=0 then
								ii,jj = posL2pos(angle,i+0.5,j+0.5,top,left,posx,posy)
								if M.pt_in_shape2(ii,jj,pixels_shad)==true then judge = 4 goto particle_judge end
							end
						end
						::particle_judge::
						if judge~=0 then
							subtitle.append(line)
							local new_line = subtitle[#subtitle]
							
							local pos_r1,pos_r2 = math.random(-1*d_res.rx,d_res.rx),math.random(-1*d_res.ry,d_res.ry)
							local move_t1,move_t2 = math.random(d_res.move_t_r), d_res.move_t+math.random(d_res.move_t_r)
							local x0,y0 = i,j
							if judge==1 then cn=c1 elseif judge==3 then cn=c3 elseif judge==4 then cn=c4 end

							if d_res.fade_in==true then
								if d_res.third==true then
									new_line.text = string.format("{\\moves3(%d,%d,%d,%d,%d,%d,%d,%d)",
										x0+d_res.move_x+pos_r1, y0+d_res.move_y+pos_r2,
										x0+(d_res.move_x+pos_r1)/2+disX*d_res.curve*(math.random()-0.5), y0+(d_res.move_y+pos_r2)/2+disY*d_res.curve*(math.random()-0.5),
										x0, y0,
										move_t1, move_t2)
								else
									new_line.text = string.format("{\\move(%d,%d,%d,%d,%d,%d)",
										x0+d_res.move_x+pos_r1, y0+d_res.move_y+pos_r2,
										x0, y0,
										move_t1, move_t2)
								end

								new_line.text = new_line.text..string.format("\\p1\\blur2\\alphaFF\\t(%d,%d,\\alpha00)\\t(%d,%d,\\blur0%s)", move_t1, move_t1, move_t1, move_t2, d_res.tags)
								new_line.text = new_line.text..string.format("\\c%s%s%s", cn, tag_strip_pos:gsub("^{",""), "m 0 0 l 1 0 1 1 0 1")
								subtitle[#subtitle] = new_line
							else
								new_line.text = tag_strip_pos:gsub("}$","")
								if d_res.third==true then
									new_line.text = string.format("{\\moves3(%d,%d,%d,%d,%d,%d,%d,%d)",
										x0+d_res.move_x+pos_r1, y0+d_res.move_y+pos_r2,
										x0+(d_res.move_x+pos_r1)/2+disX*d_res.curve*(math.random()-0.5), y0+(d_res.move_y+pos_r2)/2+disY*d_res.curve*(math.random()-0.5),
										x0, y0,
										move_t1, move_t2)
								else
									new_line.text = new_line.text..string.format("\\move(%d,%d,%d,%d,%d,%d)",
										x0, y0,
										x0+d_res.move_x+pos_r1, y0+d_res.move_y+pos_r2,
										move_t1, move_t2)
								end
								new_line.text = new_line.text..string.format("\\c%s\\p1\\t(%d,%d,\\blur2%s)\\t(%d,%d,\\alphaFF)}m 0 0 l 1 0 1 1 0 1", 
									cn, move_t1, move_t2, d_res.tags, move_t2, move_t2)
								subtitle[#subtitle] = new_line
							end
						end
					end
					aegisub.progress.set((i-left)/(right-left)*100)
				end
			end
		-- dissolve
		elseif result.effect=="dissolve" then
			if d_res.fade_in==false and d_res.fade_out==false then aegisub.cancel() end
			if d_res.fade_in==false then d_res.fin_t=0 end
			if d_res.fade_out==false then d_res.fout_t=0 end
			-- the middle part
			subtitle.append(line)
			local line_m = subtitle[#subtitle]
			line_m.start_time = lsta + d_res.fin_t
			line_m.end_time   = lend - d_res.fout_t
			subtitle[#subtitle] = line_m
			-- kill fad in linetext
			line.text = line.text:gsub("\\fade?%([^%)]+%)","")

			for i=math.floor(leftL), math.floor(rightL), d_res.step do
				for j=math.floor(topL), math.floor(bottomL), d_res.step do
					--judge: false-> no operation
					local judge = false
					if d_res.yu==true then
						local ii,jj = posL2pos(angle,i,j,top,left,posx,posy)
						if M.pt_in_shape2(ii,jj,pixels)==true then judge = true goto dissolve_judge end
						ii,jj = posL2pos(angle,i+d_res.step,j,top,left,posx,posy)
						if M.pt_in_shape2(ii,jj,pixels)==true then judge = true goto dissolve_judge end
						ii,jj = posL2pos(angle,i,j+d_res.step,top,left,posx,posy)
						if M.pt_in_shape2(ii,jj,pixels)==true then judge = true goto dissolve_judge end
						ii,jj = posL2pos(angle,i+d_res.step,j+d_res.step,top,left,posx,posy)
						if M.pt_in_shape2(ii,jj,pixels)==true then judge = true goto dissolve_judge end
						-- shad
						if xshad~=0 or yshad~=0 then
							ii,jj = posL2pos(angle,i,j,top,left,posx,posy)
							if M.pt_in_shape2(ii,jj,pixels_shad)==true then judge = true goto dissolve_judge end
							ii,jj = posL2pos(angle,i+d_res.step,j,top,left,posx,posy)
							if M.pt_in_shape2(ii,jj,pixels_shad)==true then judge = true goto dissolve_judge end
							ii,jj = posL2pos(angle,i,j+d_res.step,top,left,posx,posy)
							if M.pt_in_shape2(ii,jj,pixels_shad)==true then judge = true goto dissolve_judge end
							ii,jj = posL2pos(angle,i+d_res.step,j+d_res.step,top,left,posx,posy)
							if M.pt_in_shape2(ii,jj,pixels_shad)==true then judge = true goto dissolve_judge end
						end
						-- outline
						if outline~=0 then
							ii,jj = posL2pos(angle,i,j,top,left,posx,posy)
							if M.pt_in_shape2(ii,jj,pixels_bord)==true then judge = true goto dissolve_judge end
							ii,jj = posL2pos(angle,i+d_res.step,j,top,left,posx,posy)
							if M.pt_in_shape2(ii,jj,pixels_bord)==true then judge = true goto dissolve_judge end
							ii,jj = posL2pos(angle,i,j+d_res.step,top,left,posx,posy)
							if M.pt_in_shape2(ii,jj,pixels_bord)==true then judge = true goto dissolve_judge end
							ii,jj = posL2pos(angle,i+d_res.step,j+d_res.step,top,left,posx,posy)
							if M.pt_in_shape2(ii,jj,pixels_bord)==true then judge = true goto dissolve_judge end
						end
					else judge = true --disenable
					end
					::dissolve_judge::
					if judge==true then
						local rand1,rand2,rand3,rand4 = math.random(0,d_res.fin_t),math.random(0,d_res.fin_t),math.random(0,d_res.fout_t),math.random(0,d_res.fout_t)
						rand1,rand2 = math.min(rand1,rand2),math.max(rand1,rand2)
						rand3,rand4 = math.min(rand3,rand4),math.max(rand3,rand4)
						-- head
						if d_res.fin_t~=0 then
							subtitle.append(line)
							local new_line = subtitle[#subtitle]
							new_line.text = new_line.text:gsub("^{([^}]*)}",
							function (a)
								return string.format("{\\alpha&HFF&\\t(%d,%d,\\alpha&H00&)%s\\clip(%d,%d,%d,%d)}",
									rand1,rand2,a,i,j,i+d_res.step,j+d_res.step)
							end)
							new_line.end_time = lsta + d_res.fin_t
							subtitle[#subtitle] = new_line
						end
						-- tail
						if d_res.fout_t~=0 then
							subtitle.append(line)
							local new_line = subtitle[#subtitle]
							new_line.text = new_line.text:gsub("^{([^}]*)}",
							function (a)
								return string.format("{%s\\t(%d,%d,\\alpha&HFF&)\\clip(%d,%d,%d,%d)}",
									a,d_res.fout_t-rand4,d_res.fout_t-rand3,i,j,i+d_res.step,j+d_res.step)
							end)
							new_line.start_time = lend - d_res.fout_t
							subtitle[#subtitle] = new_line
						end							
					end
				end
				aegisub.progress.set((i-left)/(right-left)*100)
			end
		-- spotlight effect
		elseif result.effect=="spotlight" then
			local spot = {}
			spot.c1, spot.a1 = ca_html2ass(d_res.ca1)
			-- stable
			if d_res.move_on==false then
				-- circle
				if d_res.shape=="circle" then
					subtitle.append(line)
					local new_line = subtitle[#subtitle]
					new_line.text = new_line.text:gsub("^({[^}]*)",function (a)
						return string.format("%s\\iclip(%s)",a,M.draw.circle(d_res.cx1,d_res.cy1,d_res.r1+d_res.ew1)) end )
					subtitle[#subtitle] = new_line

					subtitle.append(line)
					new_line = subtitle[#subtitle]
					new_line.text = new_line.text:gsub("^({[^}]*)",function (a)
						return string.format("%s\\clip(%s)\\c%s\\alpha%s",
						a,M.draw.circle(d_res.cx1,d_res.cy1,d_res.r1),spot.c1,spot.a1) end )
					subtitle[#subtitle] = new_line

					for j=1, d_res.ew1 do
						local space_bias = M.interpolate01(d_res.ew1+2,j+1,1)
						subtitle.append(line)
						new_line = subtitle[#subtitle]
						new_line.text = new_line.text:gsub("^({[^}]*)",function (a)
							return string.format("%s\\clip(%s)\\c%s\\alpha%s",
							a,M.draw.ring(d_res.cx1,d_res.cy1,d_res.r1+j-1,d_res.r1+j),M.interpolate_c(space_bias,spot.c1,c1),M.interpolate_a(space_bias,spot.a1,alpha)) end )
						subtitle[#subtitle] = new_line
					end
				end
			-- move
			elseif d_res.move_on==true then
				spot.t = 1000/d_res.fps
				spot.c2, spot.a2 = ca_html2ass(d_res.ca2)

				if d_res.cx_ru==true then d_res.cx2 = d_res.cx1 end
				if d_res.cy_ru==true then d_res.cy2 = d_res.cy1 end
				if d_res.r_ru==true then d_res.r2 = d_res.r1 end
				if d_res.ew_ru==true then d_res.ew2 = d_res.ew1 end
				if d_res.ca_ru==true then d_res.ca2 = d_res.ca1 end
				if d_res.ang_ru==true then d_res.ang2 = d_res.ang1 end

				if (d_res.shape=="circle") then
					for j=1,ldur/spot.t do
						local time_bias = M.interpolate01(math.floor(ldur/spot.t),j,1)

						spot.x = M.interpolate(time_bias,d_res.cx1,d_res.cx2)
						spot.y = M.interpolate(time_bias,d_res.cy1,d_res.cy2)
						spot.r = M.interpolate(time_bias,d_res.r1,d_res.r2)
						spot.ew= math.floor(M.interpolate(time_bias,d_res.ew1,d_res.ew2)+0.5)
						spot.c = M.interpolate_c(time_bias,spot.c1,spot.c2)
						spot.a = M.interpolate_a(time_bias,spot.a1,spot.a2)

						subtitle.append(line)
						local new_line = subtitle[#subtitle]
						new_line.start_time = lsta + (j-1)*spot.t
						new_line.end_time   = lsta + (j)* spot.t
						new_line.text = new_line.text:gsub("^({[^}]*)",function (a)
							return string.format("%s\\iclip(%s)",a,M.draw.circle(spot.x,spot.y,spot.r+spot.ew)) end )
						subtitle[#subtitle] = new_line

						subtitle.append(line)
						new_line = subtitle[#subtitle]
						new_line.start_time = lsta + (j-1)*spot.t
						new_line.end_time   = lsta + (j)* spot.t
						new_line.text = new_line.text:gsub("^({[^}]*)",function (a)
							return string.format("%s\\clip(%s)\\c%s\\alpha%s",
							a,M.draw.circle(spot.x,spot.y,spot.r),spot.c,spot.a) end )
						subtitle[#subtitle] = new_line

						for k=1, spot.ew do
							local space_bias = M.interpolate01(spot.ew+2,k+1,1)
							subtitle.append(line)
							new_line = subtitle[#subtitle]
							new_line.start_time = lsta + (j-1)*spot.t
							new_line.end_time   = lsta + (j)* spot.t
							new_line.text = new_line.text:gsub("^({[^}]*)",function (a)
								return string.format("%s\\clip(%s)\\c%s\\alpha%s",
								a,M.draw.ring(spot.x,spot.y,spot.r+k-1,spot.r+k),M.interpolate_c(space_bias,spot.c,c1),M.interpolate_a(space_bias,spot.a,alpha)) end )
							subtitle[#subtitle] = new_line
						end
					end
				end
			end
		-- other effect
		elseif result.effect=="clip_blur" then
			if ltext:match("\\i?clip")==nil then aegisub.cancel() end
			if line.text:match("\\pos")==nil then line.text = line.text:gsub("^({[^}]*)}",
				function (a) return a.."\\pos("..posx..","..posy..")}" end) 
			end

			local clip = ltext:match("\\i?clip%(([^%)]*)%)")
			local clip_table,smallest_clip,largest_clip = M.shape.slice_outline(clip,d_res.width,d_res.step)
			local cg_n = #clip_table/2
			local cg_alpha = alpha_html2ass(d_res.alpha)

			if ltext:match("\\clip")~=nil then
				subtitle.append(line)
				local new_line = subtitle[#subtitle]
				new_line.text = new_line.text:gsub("\\clip%([^%)]*%)","\\clip("..smallest_clip..")")
				subtitle[#subtitle] = new_line

				for sj=1, cg_n do
					subtitle.append(line)
					new_line = subtitle[#subtitle]
					new_line.text = new_line.text:gsub("\\clip%([^%)]*%)","\\clip("..clip_table[sj]..")")
					local bias = M.interpolate01(cg_n+2, sj+1, 1)
					local cg_a = M.interpolate_a(bias, alpha, cg_alpha)

					if new_line.text:match("\\1?al?p?h?a?&?H?%x") then
						new_line.text = new_line.text:gsub("\\1?al?p?h?a?&?H?[%x]+&?", "\\alpha"..cg_a)
					else
						new_line.text = new_line.text:gsub("^({[^}]*)}",function (a) return a.."\\alpha"..cg_a.."}" end)
					end
					subtitle[#subtitle] = new_line
				end
			else
				subtitle.append(line)
				local new_line = subtitle[#subtitle]
				new_line.text = new_line.text:gsub("\\iclip%([^%)]*%)","\\iclip("..largest_clip..")")
				subtitle[#subtitle] = new_line

				for sj=1, cg_n do
					subtitle.append(line)
					new_line = subtitle[#subtitle]
					new_line.text = new_line.text:gsub("\\iclip%([^%)]*%)","\\clip("..clip_table[sj+cg_n]..")")
					local bias = M.interpolate01(cg_n+2, sj+1, 1)
					local cg_a = M.interpolate_a(bias, cg_alpha, alpha)

					if new_line.text:match("\\1?al?p?h?a?&?H?%x") then
						new_line.text = new_line.text:gsub("\\1?al?p?h?a?&?H?[%x]+&?", "\\alpha"..cg_a)
					else
						new_line.text = new_line.text:gsub("^({[^}]*)}",function (a) return a.."\\alpha"..cg_a.."}" end)
					end
					subtitle[#subtitle] = new_line
				end
			end
			aegisub.progress.set(si/#selected*100)
		elseif result.effect=="clip_gradient" then
			if ltext:match("\\i?clip")==nil then aegisub.cancel() end
			if line.text:match("\\pos")==nil then line.text = line.text:gsub("^({[^}]*)}",
				function (a) return a.."\\pos("..posx..","..posy..")}" end) 
			end

			local clip = ltext:match("\\i?clip%(([^%)]*)%)")
			local clip_table,smallest_clip,largest_clip = M.shape.slice_outline(clip,d_res.width,d_res.step)
			local cg_n = #clip_table/2
			local cg_color = color_html2ass(d_res.color)

			if ltext:match("\\clip")~=nil then
				subtitle.append(line)
				local new_line = subtitle[#subtitle]
				new_line.text = new_line.text:gsub("\\clip%([^%)]*%)","\\clip("..smallest_clip..")")
				subtitle[#subtitle] = new_line

				for sj=1,cg_n do
					subtitle.append(line)
					new_line = subtitle[#subtitle]
					new_line.text = new_line.text:gsub("\\clip%([^%)]*%)","\\clip("..clip_table[sj]..")")
					local bias = M.interpolate01(cg_n+2,sj+1,1)
					local cg_c = M.interpolate_c(bias,c1,cg_color)

					if new_line.text:match("\\1?c&?H?%x") then
						new_line.text = new_line.text:gsub("\\1?c&?H?[%x]+&?", "\\c"..cg_c)
					else
						new_line.text = new_line.text:gsub("^({[^}]*)}",function (a) return a.."\\c"..cg_c.."}" end)
					end
					subtitle[#subtitle] = new_line
				end
			else
				subtitle.append(line)
				local new_line = subtitle[#subtitle]
				new_line.text = new_line.text:gsub("\\iclip%([^%)]*%)","\\iclip("..largest_clip..")")
				subtitle[#subtitle] = new_line

				for sj=1,cg_n do
					subtitle.append(line)
					new_line = subtitle[#subtitle]
					new_line.text = new_line.text:gsub("\\iclip%([^%)]*%)","\\clip("..clip_table[sj+cg_n]..")")
					local bias = M.interpolate01(cg_n+2,sj+1,1)
					local cg_c = M.interpolate_c(bias,cg_color,c1)

					if new_line.text:match("\\1?c&?H?%x") then
						new_line.text = new_line.text:gsub("\\1?c&?H?[%x]+&?", "\\c"..cg_c)
					else
						new_line.text = new_line.text:gsub("^({[^}]*)}",function (a) return a.."\\c"..cg_c.."}" end)
					end
					subtitle[#subtitle] = new_line
				end
			end
			aegisub.progress.set(si/#selected*100)
		elseif result.effect=="component_split" then
			if (d_res.fin_cb==false and d_res.fout_cb==false) or (d_res.fin_cb==true and d_res.fout_cb==true) then aegisub.cancel() end

			local components = M.shape.split_component(shape)

			if d_res.fin_cb==true then d_res.fout_t = 0
				tag_strip_pos = tag_strip_pos:gsub("^{",string.format("{\\blur3\\t(0,%d,\\blur0)", d_res.fin_t)) end
			if d_res.fout_cb==true then d_res.fin_t = 0
				tag_strip_pos = tag_strip_pos:gsub("}$",string.format("\\t(%d,%d,\\blur3)", ldur-d_res.fout_t,ldur)) end
			tag_strip_pos = tag_strip_pos:gsub("^{",string.format("{\\an7\\fad(%d,%d)",d_res.fin_t,d_res.fout_t))
			tag_strip_pos = tag_strip_pos:gsub("}$",string.format("\\pos(%d,%d)\\p1}", left,top))

			local Ncomp = #components
			for nj,sj in ipairs(components) do
				subtitle.append(line)
				local new_line = subtitle[#subtitle]
				local tagj = tag_strip_pos

				-- move
				if d_res.move_cb==true then
					tagj = tagj:gsub("\\pos%([^%)]*%)","")

					local devT = d_res.move_t
					if d_res.randomize_mt==true then devT = math.random(d_res.move_t/2, d_res.move_t) end

					if d_res.move=="from/to center" then
						local devX,devY=0,0
						repeat
							devX,devY = math.random(-1*d_res.move_range,d_res.move_range),math.random(-1*d_res.move_range,d_res.move_range)
						until (M.pt_in_circle(devX,devY,0,0,d_res.move_range))

						if d_res.fin_cb==true then
							tagj = tagj:gsub("}$",string.format("\\move(%d,%d,%d,%d,%d,%d)}",
								left-devX,top-devY,left,top, 0,devT))
						else
							tagj = tagj:gsub("}$",string.format("\\move(%d,%d,%d,%d,%d,%d)}",
								left,top,left+devX,top+devY, ldur-devT,ldur))
						end
					else
						local devXY = d_res.move_range
						if d_res.randomize_mr==true then devXY = math.random(d_res.move_range) end

						if d_res.fin_cb==true then
							if d_res.move=="from/to left" then
								tagj = tagj:gsub("}$",string.format("\\move(%d,%d,%d,%d,%d,%d)}",
									left-devXY,top,left,top, 0,devT))
							elseif d_res.move=="from/to right" then
								tagj = tagj:gsub("}$",string.format("\\move(%d,%d,%d,%d,%d,%d)}",
									left+devXY,top,left,top, 0,devT))
							elseif d_res.move=="from/to top" then
								tagj = tagj:gsub("}$",string.format("\\move(%d,%d,%d,%d,%d,%d)}",
									left,top-devXY,left,top, 0,devT))
							elseif d_res.move=="from/to bottom" then
								tagj = tagj:gsub("}$",string.format("\\move(%d,%d,%d,%d,%d,%d)}",
									left,top+devXY,left,top, 0,devT))
							end
						else
							if d_res.move=="from/to left" then
								tagj = tagj:gsub("}$",string.format("\\move(%d,%d,%d,%d,%d,%d)}",
									left,top,left-devXY,top, ldur-devT,ldur))
							elseif d_res.move=="from/to right" then
								tagj = tagj:gsub("}$",string.format("\\move(%d,%d,%d,%d,%d,%d)}",
									left,top,left+devXY,top, ldur-devT,ldur))
							elseif d_res.move=="from/to top" then
								tagj = tagj:gsub("}$",string.format("\\move(%d,%d,%d,%d,%d,%d)}",
									left,top,left,top-devXY, ldur-devT,ldur))
							elseif d_res.move=="from/to bottom" then
								tagj = tagj:gsub("}$",string.format("\\move(%d,%d,%d,%d,%d,%d)}",
									left,top,left,top+devXY, ldur-devT,ldur))
							end
						end
					end
				end

				-- time
				if d_res.time_cb==true then
					if d_res.fin_cb==true then
						new_line.start_time = new_line.start_time + math.random(-1*d_res.time_dev,d_res.time_dev)
						new_line.start_time = new_line.start_time + (nj-1)/Ncomp * d_res.time_incre
					else
						new_line.end_time = new_line.end_time + math.random(-1*d_res.time_dev,d_res.time_dev)
						new_line.end_time = new_line.end_time - (Ncomp-nj)/Ncomp * d_res.time_incre
					end
				end

				new_line.text = tagj..sj
				subtitle[#subtitle] = new_line
				aegisub.progress.set(nj/Ncomp*100)
			end
		elseif result.effect=="text2shape" then
			line.text = tag_strip_pos.."{\\an7\\p1\\pos("..left..","..top..")\\fsc100\\bord0\\shad0}"..shape
			line.text = line.text:gsub("}{","")
			subtitle[li] = line
		elseif result.effect=="pixelize" then
			local data = ""
			for i=math.floor(left),math.floor(right),d_res.block do
				for j=math.floor(top),math.floor(bottom),d_res.block do
					if M.pt_in_shape2(i-left,j-top,pixels)==true then
						data = data..string.format("m %d %d l %d %d %d %d %d %d ",i,j,i+d_res.block,j,i+d_res.block,j+d_res.block,i,j+d_res.block)
					end
				end   
			end
			line.comment = false
			line.text = "{\\an7\\p1\\pos(0,0)\\fscx100\\fscy100\\bord0\\shad0}"..data
			subtitle[li] = line
		elseif result.effect=="shape2bord" then
			if d_res.h==-1 then d_res.h = d_res.w end
			local flatten = Yutils.shape.flatten(shape)
			shape_bord = Yutils.shape.to_outline(flatten,d_res.w,d_res.h,d_res.j)
			line.text = tag..shape_bord
			subtitle[li] = line
		elseif result.effect=="bord_contour" then
			if (d_res.fin==true and d_res.fout==true) or (d_res.fin==false and d_res.fout==false) then aegisub.cancel() end

			-- convert to bord
			local flatten = Yutils.shape.flatten(shape)
			shape_bord = Yutils.shape.to_outline(flatten, d_res.w, d_res.w, "miter")
			local outlines = M.shape.split_by_m(shape_bord)
			local OLcount = #outlines
			for i=1,#outlines,2 do
				local ol1 = outlines[i].shape
				local ol1tail = ol1:match("([%d%.%-]+ +[%d%.%-]+)$")
				ol1 = ol1:gsub(" *([%d%.%-]+) +([%d%.%-]+)$","")
				ol1 = ol1:gsub("^m","m "..ol1tail.." l")
				ol1 = M.shape.normalize(ol1)
				local ol2 = M.shape.normalize(outlines[i+1].shape)
				local length1,length2 = M.shape.length(ol1)*d_res.p, M.shape.length(ol2)*d_res.p
				local length1F,length2F = length1/d_res.gs, length2/d_res.gs
				ol1,ol2 = Yutils.shape.split(ol1,d_res.gs).." ", Yutils.shape.split(ol2,d_res.gs)

				local timeU = 1000/fps
				local count = round((lend-lsta)/timeU)

				-- local l1new,l2new = "",""
				local stapre, staX2, staY2 = ol2:match("^([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)")
				ol2 = ol2:gsub("^([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)","")
				local l2new = stapre..staX2.." "..staY2.." "
				staX2, staY2 = tonumber(staX2), tonumber(staY2)
				local staX1, staY1, stapost = ol1:match("([%d%.%-]+) +([%d%.%-]+)([^%d%.%-]+)$")
				ol1 = ol1:gsub("([%d%.%-]+) +([%d%.%-]+)([^%d%.%-]+)$","")
				local l1new = " "..staX1.." "..staY1..stapost
				staX1, staY1 = tonumber(staX1), tonumber(staY1)
				local lencount1, lencount2 = 0,0

				if d_res.fin==true then
					for j=1,count do
						subtitle.append(line)
						local new_line = subtitle[#subtitle]
						new_line.start_time = lsta + math.floor((j-1) * timeU)
						new_line.end_time = lsta + math.floor(j * timeU)

						if d_res.fast==true then
							local l1add,l2add = math.floor(length1F/count*j)-math.floor(length1F/count*(j-1)), math.floor(length2F/count*j)-math.floor(length2F/count*(j-1))
							
							for k=1,l2add do
								local pre,x,y = ol2:match("^([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)")
								ol2 = ol2:gsub("^([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)","")
								l2new = l2new..pre..x.." "..y.." "
							end

							for k=1,l1add do
								local x,y,post = ol1:match("([%d%.%-]+) +([%d%.%-]+)([^%d%.%-]+)$")
								ol1 = ol1:gsub("([%d%.%-]+) +([%d%.%-]+)([^%d%.%-]+)$","")
								l1new = " "..x.." "..y..post..l1new
							end
						else
							local l1j, l2j = length1/count*j, length2/count*j
							while lencount2<l2j do
								local pre,x,y = ol2:match("^([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)")
								if y==nil then break end
								ol2 = ol2:gsub("^([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)","")
								l2new = l2new..pre..x.." "..y.." "
								x,y = tonumber(x), tonumber(y)
								lencount2 = lencount2 + M.math.distance(x,y,staX2,staY2)
								staX2, staY2 = x,y
							end

							while lencount1<l1j do
								local x,y,post = ol1:match("([%d%.%-]+) +([%d%.%-]+)([^%d%.%-]+)$")
								if y==nil then break end
								ol1 = ol1:gsub("([%d%.%-]+) +([%d%.%-]+)([^%d%.%-]+)$","")
								l1new = " "..x.." "..y..post..l1new
								x,y = tonumber(x), tonumber(y)
								lencount1 = lencount1 + M.math.distance(x,y,staX1,staY1)
								staX1, staY1 = x,y
							end
						end

						new_line.text = tag..l2new..l1new
						subtitle[#subtitle] = new_line
						aegisub.progress.set((j/count + i-1)/(OLcount/2)*100)
					end
				else
					for j=count,1,-1 do
						subtitle.append(line)
						local new_line = subtitle[#subtitle]
						new_line.start_time = lsta + math.floor((j-1) * timeU)
						new_line.end_time = lsta + math.floor(j * timeU)

						if d_res.fast==true then
							local l1add,l2add = math.floor(length1F/count*j)-math.floor(length1F/count*(j-1)), math.floor(length2F/count*j)-math.floor(length2F/count*(j-1))
							
							for k=1,l2add do
								local pre,x,y = ol2:match("^([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)")
								ol2 = ol2:gsub("^([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)","")
								l2new = l2new..pre..x.." "..y.." "
							end

							for k=1,l1add do
								local x,y,post = ol1:match("([%d%.%-]+) +([%d%.%-]+)([^%d%.%-]+)$")
								ol1 = ol1:gsub("([%d%.%-]+) +([%d%.%-]+)([^%d%.%-]+)$","")
								l1new = " "..x.." "..y..post..l1new
							end
						else
							local l1j, l2j = length1/count*(count+1-j), length2/count*(count+1-j)
							while lencount2<l2j do
								local pre,x,y = ol2:match("^([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)")
								if y==nil then break end
								ol2 = ol2:gsub("^([^%d%.%-]+)([%d%.%-]+) +([%d%.%-]+)","")
								l2new = l2new..pre..x.." "..y.." "
								x,y = tonumber(x), tonumber(y)
								lencount2 = lencount2 + M.math.distance(x,y,staX2,staY2)
								staX2, staY2 = x,y
							end

							while lencount1<l1j do
								local x,y,post = ol1:match("([%d%.%-]+) +([%d%.%-]+)([^%d%.%-]+)$")
								if y==nil then break end
								ol1 = ol1:gsub("([%d%.%-]+) +([%d%.%-]+)([^%d%.%-]+)$","")
								l1new = " "..x.." "..y..post..l1new
								x,y = tonumber(x), tonumber(y)
								lencount1 = lencount1 + M.math.distance(x,y,staX1,staY1)
								staX1, staY1 = x,y
							end
						end

						new_line.text = tag..l2new..l1new
						subtitle[#subtitle] = new_line
						aegisub.progress.set(((count-j)/count + i-1)/(OLcount/2)*100)
					end
				end
			end
		end
	end
	aegisub.set_undo_point(script_name)
	return selected
end

function daughter_dialog(effect)
	button = {"Run","Quit"}
	if effect=="particle" then
		dialog_conf = {
			{class="label",label="particle",x=0,y=0},
			{class="checkbox",label="fade_in",name="fade_in",value=false,x=0,y=1},
			{class="checkbox",label="fade_out",name="fade_out",value=false,x=0,y=2},
			-- basic
			{class="label",label="basic",x=1,y=0},
			{class="label",label="move time",x=1,y=1},
			{class="intedit",name="move_t",value=1500,x=1,y=2},
			{class="label",label="move time random",x=2,y=1},
			{class="intedit",name="move_t_r",value=1000,x=2,y=2},

			{class="label",label="move_x",x=3,y=1},
			{class="floatedit",name="move_x",value=0,x=3,y=2},
			{class="label",label="move_y",x=4,y=1},
			{class="floatedit",name="move_y",value=0,x=4,y=2},
			-- shape
			{class="label",label="diffusion radius x",x=1,y=3},
			{class="intedit",name="rx",value=150,x=1,y=4},
			{class="label",label="diffusion radius y",x=2,y=3},
			{class="intedit",name="ry",value=150,x=2,y=4},
			-- advanced
			{class="label",label="advanced",x=1,y=5},
			{class="checkbox",label="curve",name="third",value=false,x=1,y=6},
			{class="floatedit",name="curve",value=0,x=1,y=7,hint="0 -> no curve, higher -> more curve"},
			{class="label",label="additional tags",x=2,y=6},
			{class="edit",name="tags",value="",width=2,x=2,y=7},
			{class="checkbox",label="bord/shad/rotate",name="adv",value=false,width=2,x=3,y=6}
		}
	elseif effect=="dissolve" then
		dialog_conf = {
			{class="label",label="dissolve",x=0,y=0},
			{class="checkbox",label="fade_in",name="fade_in",value=false,x=0,y=1},
			{class="checkbox",label="fade_out",name="fade_out",value=false,x=0,y=2},
			-- basic
			{class="label",label="basic",x=1,y=0},
			{class="label",label="fade in time",x=1,y=1},
			{class="intedit",name="fin_t",value=1500,x=1,y=2},
			{class="label",label="fade out time",x=2,y=1},
			{class="intedit",name="fout_t",value=1500,x=2,y=2},
			{class="label",label="particle size",x=3,y=1},
			{class="intedit",name="step",value=4,x=3,y=2},
			-- advanced
			{class="label",label="advanced",x=4,y=0},
			{class="label",label="get fewer lines with more power",x=4,y=1},
			{class="checkbox",label="enable",name="yu",value=true,x=4,y=2}
		}
	elseif effect=="typewriter" then
		dialog_conf = {
			
		}
	elseif effect=="spotlight" then
		dialog_conf={
			{class="label",label="spotlight",x=0,y=0},
			-- shape
			{class="label",label="shape",x=1,y=0},
			{class="dropdown",name="shape",items={"circle"},value="circle",x=1,y=1},
			-- stable
			{class="label",label="stable / move 1",x=2,y=0},
			{class="label",label="center x",value=0,x=2,y=1},
			{class="floatedit",name="cx1",x=2,y=2},
			{class="label",label="center y",value=0,x=3,y=1},
			{class="floatedit",name="cy1",x=3,y=2},
			{class="label",label="radius",x=4,y=1},
			{class="intedit",name="r1",value=10,x=4,y=2},
			{class="label",label="edge width",x=5,y=1},
			{class="intedit",name="ew1",value=30,x=5,y=2},
			{class="label",label="color alpha",x=6,y=1},
			{class="coloralpha",name="ca1",x=6,y=2},
			-- move trigger
			{class="checkbox",name="move_on",label="move",value=false,x=0,y=3},
			{class="label",label="t1",x=0,y=4},
			{class="intedit",name="t1",x=0,y=5},
			{class="label",label="t2",x=1,y=4},
			{class="intedit",name="t2",x=1,y=5},
			{class="checkbox",name="full_time",label="full time",value=true,x=0,y=6},
			-- move
			{class="label",label="move 2",x=2,y=3},
			{class="label",label="center x",x=2,y=4},
			{class="floatedit",name="cx2",x=2,y=5},
			{class="label",label="center y",x=3,y=4},
			{class="floatedit",name="cy2",x=3,y=5},
			{class="label",label="radius",x=4,y=4},
			{class="intedit",name="r2",value=1,x=4,y=5},
			{class="label",label="edge width",x=5,y=4},
			{class="intedit",name="ew2",value=20,x=5,y=5},
			{class="label",label="color alpha",x=6,y=4},
			{class="coloralpha",name="ca2",x=6,y=5},
			-- fps
			{class="label",label="fps",x=7,y=4},
			{class="floatedit",name="fps",value=23.976,x=7,y=5},
			-- remain unchanged
			{class="checkbox",name="cx_ru",label="remain unchanged",x=2,y=6},
			{class="checkbox",name="cy_ru",label="remain unchanged",x=3,y=6},
			{class="checkbox",name="r_ru",label="remain unchanged",x=4,y=6},
			{class="checkbox",name="ew_ru",label="remain unchanged",x=5,y=6},
			{class="checkbox",name="ca_ru",label="remain unchanged",x=6,y=6}
		}
	elseif effect=="clip_blur" then
		dialog_conf = {
			{class="label",label="clip_blur",x=0,y=0},--1

			{class="label",label="width",x=0,y=1},--2
			{class="intedit",name="width",value=30,x=1,y=1},--3
			{class="label",label="step",x=0,y=2},--4
			{class="intedit",name="step",value=3,x=1,y=2},--5
			{class="label",label="alpha",x=0,y=3},--6
			{class="coloralpha",name="alpha",value="&HFFFFFFFF&",x=1,y=3}--7
		}
	elseif effect=="clip_gradient" then
		dialog_conf = {
			{class="label",label="clip_gradient",x=0,y=0},

			{class="label",label="width",x=0,y=1},
			{class="intedit",name="width",value=30,x=1,y=1},
			{class="label",label="step",x=0,y=2},
			{class="intedit",name="step",value=3,x=1,y=2},
			{class="label",label="color",x=0,y=3},
			{class="color",name="color",value="",x=1,y=3}
		}
	elseif effect=="component_split" then
		dialog_conf = {
			{class="label",label="component_split",x=0,y=0},
			{class="checkbox",label="fade_in",name="fin_cb",value=false,x=0,y=1},
			{class="intedit",label="fade_in_time",name="fin_t",value=0,x=0,y=2,hint="fade in time"},
			{class="checkbox",label="fade_out",name="fout_cb",value=false,x=0,y=3},
			{class="intedit",label="fade_out_time",name="fout_t",value=0,x=0,y=4,hint="fade out time"},
			-- move
			{class="checkbox",label="move",name="move_cb",value=false,x=1,y=0},
			{class="label",label="move_direction",x=1,y=1},
			{class="dropdown",name="move",items={"from/to center","from/to left","from/to right","from/to top","from/to bottom"},value="from/to center",x=1,y=2},
			{class="label",label="move_range(pixel)",x=2,y=1},
			{class="intedit",name="move_range",value=500,x=2,y=2},
			{class="checkbox",label="randomize",name="randomize_mr",value=true,x=2,y=3},
			{class="label",label="move_time(ms)",x=3,y=1},
			{class="intedit",name="move_t",value=1500,x=3,y=2},
			{class="checkbox",label="randomize",name="randomize_mt",value=true,x=3,y=3},
			--time
			{class="checkbox",label="time",name="time_cb",value=false,x=1,y=4},
			{class="label",label="time_deviation",x=1,y=5},
			{class="intedit",name="time_dev",value=1000,x=1,y=6},
			{class="label",label="time_increment_for_all",x=2,y=5,width=2},
			{class="intedit",name="time_incre",value=2000,x=2,y=6},
		}
	elseif effect=="pixelize" then
		dialog_conf = {
			{class="label",label="pixelize",x=0,y=0},
			{class="label",label="pixel size",x=0,y=1},
			{class="intedit",name="block",value=5,x=0,y=2}
		}
	elseif effect=="text2shape" then
		dialog_conf = {}
	elseif effect=="shape2bord" then
		dialog_conf = {
			{class="label",label="shape2bord",x=0,y=0},
			{class="label",label="bord width",x=0,y=1},
			{class="floatedit",name="w",value=1,x=1,y=1},
			{class="label",label="bord height",x=0,y=2},
			{class="floatedit",name="h",value=-1,x=1,y=2,hint="-1 -> height = width"},
			{class="label",label="join mode",x=0,y=3},
			{class="dropdown",name="j",items={"round","bevel","miter"},value="round",x=1,y=3}
		}
	elseif effect=="bord_contour" then
		dialog_conf = {
			{class="label",label="bord_contour",x=0,y=0,width=2},
			{class="checkbox",name="fin",label="IN Effect",value=false,x=0,y=1},
			{class="checkbox",name="fout",label="OUT Effect",value=false,x=1,y=1},
			{class="label",label="bord width",x=0,y=2},
			{class="floatedit",name="w",value=1,x=1,y=2},
			{class="label",label="grain size",x=0,y=3},
			{class="intedit",name="gs",value=2,x=1,y=3},
			{class="label",label="proportion",x=0,y=4},
			{class="floatedit",name="p",value=1,x=1,y=4},
			{class="checkbox",name="fast",label="fast but wrong",value=false,x=0,y=5,width=2}
		}
	end
	return dialog_conf,button
end

function custom_config(conf, effect)
	if effect=="clip_blur" then
		conf[7].value = conf[7].value:gsub("#(%x%x)(%x%x)(%x%x)(%x%x)", function (r,g,b,a) return "&H"..a..b..g..r.."&" end)
	else
	end
end

function round(x)
	return math.floor(x+0.5)
end

function num2bool(a)
	if tonumber(a)~=0 then return true
	else return false
	end
end

function color_html2ass(c)
	local r,g,b = c:match("(%x%x)(%x%x)(%x%x)")
	return "&H"..b..g..r.."&"
end

function alpha_html2ass(c)
	a = c:match("%x%x%x%x%x%x(%x%x)")
	return "&H"..a.."&"
end

function ca_html2ass(c)
	local r,g,b,a = c:match("(%x%x)(%x%x)(%x%x)(%x%x)")
	return "&H"..b..g..r.."&","&H"..a.."&"
end

function widthheight(ltext,line,font,fontsize,bold,italic,underline,strikeout,scale_x,scale_y,spacing,outline,shadow)
	local style = line.styleref
	style.fontname = font
	style.fontsize = fontsize
	style.bold = bold
	style.italic = italic
	style.underline = underline
	style.strikeout = strikeout
	style.scale_x = scale_x
	style.scale_y = scale_y
	style.spacing = spacing
	style.outline = outline
	style.shadow = shadow
	local w,h = aegisub.text_extents(style,ltext)
	return w,h
end

function position(ltext,line,xres,yres,width,height)
	local x,y,top,left,bottom,right,center,middle = 0,0,0,0,0,0,0,0

	local an = ltext:match("\\an%d") and tonumber(ltext:match("\\an(%d)")) or line.styleref.align
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

function positionL(angle,x,y,t,l,b,r)
	angle = angle/180*math.pi
	local r1 = x + (r-x)*math.cos(angle) + (b-y)*math.sin(angle)
	local r2 = x + (r-x)*math.cos(angle) - (y-t)*math.sin(angle)
	local l1 = x - (x-l)*math.cos(angle) + (b-y)*math.sin(angle)
	local l2 = x - (x-l)*math.cos(angle) - (y-t)*math.sin(angle)
	local t1 = y - (y-t)*math.cos(angle) - (r-x)*math.sin(angle)
	local t2 = y - (y-t)*math.cos(angle) + (x-l)*math.sin(angle)
	local b1 = y + (b-y)*math.cos(angle) - (r-x)*math.sin(angle)
	local b2 = y + (b-y)*math.cos(angle) + (x-l)*math.sin(angle)
	t,l,b,r = math.min(t1,t2),math.min(l1,l2),math.max(b1,b2),math.max(r1,r2)
	return t,l,b,r,(l+r)/2,(t+b)/2
end

-- output relative position for Yutils
function posL2pos(angle,x,y,t,l,posx,posy)
	angle = angle/180*math.pi
	return (posx-l) + (x-posx)*math.cos(angle)-(y-posy)*math.sin(angle),(posy-t) + (y-posy)*math.cos(angle)+(x-posx)*math.sin(angle)
end

function config_read_xml(dialog)
    local path = aegisub.decode_path("?user").."\\effect_config.xml"
    local file = io.open(path, "r")
    if file~=nil then
		file:close()
        local config = require("xmlSimple").newParser():loadFile(path)
        for si,li in ipairs(dialog) do
            for sj,lj in pairs(li) do
                if sj=="class" and lj~="label" then
                    local name = li.name
                    local item = config.Config[name]
                    if item["@Type"]=="boolean" then 
                        dialog[si].value = str2bool(item["@Value"])
                    elseif item["@Type"]=="number" then 
                        dialog[si].value = tonumber(item["@Value"])
                    elseif item["@Type"]=="string" then 
                        dialog[si].value = item["@Value"]
                    end
					if name=="effect" then return item["@Value"] end
                    break
                end
            end
        end
    else
        return nil
    end
end

function config_write_xml(result, result2)
    local path = aegisub.decode_path("?user").."\\effect_config.xml"
    local file = io.open(path, "w")
    file:write('<?xml version="1.0" encoding="UTF-8"?>\n<Config>\n')
    for key,value in pairs(result) do
        if type(value)=="boolean" then 
            file:write(string.format('<%s Type="%s" Value="%s"/>\n', key, type(value), bool2str(value)))
        else
            file:write(string.format('<%s Type="%s" Value="%s"/>\n', key, type(value), value))
        end
    end
	for key,value in pairs(result2) do
        if type(value)=="boolean" then 
            file:write(string.format('<%s Type="%s" Value="%s"/>\n', key, type(value), bool2str(value)))
        else
            file:write(string.format('<%s Type="%s" Value="%s"/>\n', key, type(value), value))
        end
    end
    file:write('</Config>')
    file:close()
end

function str2bool(str)
    if str=="true" then return true
    else return false end
end

function bool2str(bool)
    if bool==true then return "true"
    else return "false" end
end

function fpsgen()
	local f = 10000
	if aegisub.ms_from_frame(f)==nil then return 23.976 end
	local t = (aegisub.ms_from_frame(f)+aegisub.ms_from_frame(f+1))/2
	-- f = t/(1000/fps) = t/1000*fps
	local fps = f/t*1000
	return round(fps*1000)/1000
end

M={}
M.draw = {}
M.shape = {}
M.math = {}

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

function M.pt_in_shape2(x,y,pixels)
	for j=1,#pixels do
		if (math.abs(x-pixels[j].x)<=0.5 and math.abs(y-pixels[j].y)<=0.5) then
			return true
		end
	end
	return false
end

-- spotlight
function M.draw.circle(x,y,r)
	local c = 0.55228475*r
	local draw = string.format("m %.2f %.2f b %.2f %.2f %.2f %.2f %.2f %.2f ",x,y-r,x+c,y-r,x+r,y-c,x+r,y)
	draw = draw..string.format("b %.2f %.2f %.2f %.2f %.2f %.2f ",x+r,y+c,x+c,y+r,x,y+r)
	draw = draw..string.format("b %.2f %.2f %.2f %.2f %.2f %.2f ",x-c,y+r,x-r,y+c,x-r,y)
	draw = draw..string.format("b %.2f %.2f %.2f %.2f %.2f %.2f",x-r,y-c,x-c,y-r,x,y-r)
	return draw
end

function M.draw.circle_inverse(x,y,r)
	local c = 0.55228475*r
	local draw = string.format("m %.2f %.2f b %.2f %.2f %.2f %.2f %.2f %.2f ",x,y-r,x-c,y-r,x-r,y-c,x-r,y)
	draw = draw..string.format("b %.2f %.2f %.2f %.2f %.2f %.2f ",x-r,y+c,x-c,y+r,x,y+r)
	draw = draw..string.format("b %.2f %.2f %.2f %.2f %.2f %.2f ",x+c,y+r,x+r,y+c,x+r,y)
	draw = draw..string.format("b %.2f %.2f %.2f %.2f %.2f %.2f",x+r,y-c,x+c,y-r,x,y-r)
	return draw
end

function M.draw.ring(x,y,r1,r2)
	local draw = M.draw.circle(x,y,r1).." "
	draw = draw..M.draw.circle_inverse(x,y,r2)	
	return draw
end

-- i = 1 -> 0 , i = N -> 1
function M.interpolate01(N,i,accel)
	if accel==nil then accel = 1 end
    return (1/(N-1)*(i-1))^accel
end

--in string &HXXXXXX& out string &HXXXXXX&
function M.interpolate_c(bias,head,tail)
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

function M.interpolate_a(bias,head,tail)
    local a1 = head:match("&H([0-9a-fA-F][0-9a-fA-F])")
    local a2 = tail:match("&H([0-9a-fA-F][0-9a-fA-F])")
    a1 = tonumber(a1,16)
    a2 = tonumber(a2,16)
    local a = 0
    if (a1==a2) then a = a1 else a = math.floor((a2-a1)*bias+0.5)+a1 end
    return util.ass_alpha(a)
end

function M.interpolate(bias,head,tail)
    local h = tonumber(head)
    local t = tonumber(tail)
    local a = (t-h)*bias+h
    return string.format("%.2f",a)
end

-- shape contain only one m 
-- to keep the last position the same as the first  
-- normalized shape may contain only one space between nums
-- -> shape
function M.shape.normalize(shape)
	local start_x,start_y = shape:match("([%d%.%-]+) +([%d%.%-]+)")
	local end_x,end_y = shape:match("([%d%.%-]+) +([%d%.%-]+)[^%d%.%-]*$")
	if math.abs(start_x-end_x)<M.math.epsilon() and math.abs(start_y-end_y)<M.math.epsilon() then
		shape = shape:gsub("[^%d%.%-]*$"," c")
	else
		shape = shape:gsub("[^%d%.%-]*$",string.format(" l %.2f %.2f c",start_x,start_y))
	end
	shape = shape:gsub(" +"," ")
	return shape
end

-- -> shape
function M.shape.normalize_all(shape)
	local shapes = M.shape.split_by_m(shape)
	local new = ""
	for i,s in ipairs(shapes) do
		new = new..M.shape.normalize(s.shape).." "
	end
	new = new:gsub(" $","")
	return new
end

-- input normalized flatten shape contains one m -> num
function M.shape.length(shape)
	local tx, ty = shape:match("m +([%d%.%-]+) +([%d%.%-]+)")
	tx, ty = tonumber(tx), tonumber(ty)
	local i = true
	local length = 0
	for xx,yy in shape:gmatch("([%d%.%-]+) +([%d%.%-]+)") do
		if i==true then i=false
		else
			xx, yy = tonumber(xx), tonumber(yy)
			length = length + math.sqrt((xx-tx)^2+(yy-ty)^2)
			tx, ty = xx, yy
		end
	end
	return length
end

-- -> shapes .shape , .other = nil
function M.shape.split_by_m(shape)
	local shapes = {}
	for i in shape:gmatch("m[^m]+") do
		i = i:gsub(" $","")
		table.insert(shapes,{shape=i,other=nil})
	end
	return shapes
end

-- shape contain only one m, please normalize it first
-- table .pre -> "b" or "l"   
--        .x1 .y1 .x2 .y2 [for "b" .xc1 .yc1 .xc2 .tc2]
function M.shape.read_line(shape)
	local line_inf = {}
	shape = shape:gsub("m", "")
	local start_x,start_y = shape:match("([%d%.%-]+) +([%d%.%-]+)")
	for pre,i in shape:gmatch("(%a) ([^%a]+)") do
		if pre=="l" then
			for xj,yj in i:gmatch("([%d%.%-]+) ([%d%.%-]+)") do
				table.insert(line_inf,{pre="l",x1=start_x,y1=start_y,x2=xj,y2=yj})
				start_x,start_y = xj,yj
			end
		elseif pre=="b" then
			for xc1,yc1,xc2,yc2,x2,y2 in i:gmatch("([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+) ([%d%.%-]+)") do
				table.insert(line_inf,{pre="b",x1=start_x,y1=start_y,xc1=xc1,xc2=xc2,yc1=yc1,yc2=yc2,x2=x2,y2=y2})
				start_x,start_y = x2,y2
			end
		end
	end
	return line_inf
end

-- shape contain only one m, please normalize it first
-- -> shape
function M.shape.inverse(shape)
	local line_inf = M.shape.read_line(shape)
	local N = #line_inf
	local new = string.format("m %.2f %.2f ",line_inf[N].x2,line_inf[N].y2)
	for i=N,1,-1 do
		if line_inf[i].pre=="l" then
			new = new..string.format("l %.2f %.2f ",line_inf[i].x1,line_inf[i].y1)
		elseif line_inf[i].pre=="b" then
			new = new..string.format("b %.2f %.2f %.2f %.2f %.2f %.2f ",
				line_inf[i].xc2,line_inf[i].yc2,line_inf[i].xc1,line_inf[i].yc1,line_inf[i].x1,line_inf[i].y1)
		end
	end
	new = new.."c"
	return new
end

-- shape contain only one m, please normalize it first 
-- -> anticlockwise: 1, clockwise: -1, else: 0
function M.shape.judge_rotation_direction(shape)
	local flatten_shape = Yutils.shape.flatten(shape)
	local line_inf = M.shape.read_line(flatten_shape)
	local area = 0
	for si,li in ipairs(line_inf) do
		area = area + (li.y1+li.y2)*(li.x2-li.x1)/2
	end
	if area>0 then
		return 1 -- anticlockwise
	elseif area<0 then
		return -1 -- clockwise
	else 
		return 0
	end
end

-- shape -> shapes  
-- simple shape: simply connected
function M.shape.slice_outline(shape,width,step)
	local half_width = width/2
	-- local n = math.floor(half_width/step)
	local rd1,rd2 = nil,nil
	shape = M.shape.normalize(shape)

	-- 2n+1 from inside to outside
	local shape_table = {}
	shape_table[1] = shape
	local new = {}

	for i=step,half_width,step do
		local outline = Yutils.shape.to_outline(shape,i,i)
		local outlines = M.shape.split_by_m(outline)
		outlines[1].shape = M.shape.normalize(outlines[1].shape)
		outlines[2].shape = M.shape.normalize(outlines[2].shape)
		local x1,y1 = outlines[1].shape:match("([%d%.%-]+) ([%d%.%-]+)")
		local judge = M.pt_in_shape(x1,y1,outlines[2].shape)

		-- true -> [1] in, [2] out
		if judge==true then
			table.insert(shape_table,1,outlines[1].shape)
			table.insert(shape_table,outlines[2].shape)
		else
			table.insert(shape_table,outlines[1].shape)
			table.insert(shape_table,1,outlines[2].shape)
		end
	end

	-- rd: rotation_direction
	rd1 = M.shape.judge_rotation_direction(shape_table[1])
	for i=1,#shape_table-1 do
		rd2 = M.shape.judge_rotation_direction(shape_table[i+1])
		if rd1==rd2 then
			shape_table[i+1] = M.shape.inverse(shape_table[i+1])
			rd1 = -1*rd2
		else
			rd1 = rd2
		end
		table.insert(new,shape_table[i].." "..shape_table[i+1])
	end
	return new,shape_table[1],shape_table[#shape_table]
end

-- shape -> shapes
function M.shape.split_component(shape)
	local shapes = M.shape.split_by_m(shape)

	for ni,si in ipairs(shapes) do
		si.shape = M.shape.normalize(si.shape)
		si.other = {inside={},outside={},i=0,o=0,del=false,dn={},pn=nil} -- shape num inside & outside daughter & parent node
	end

	-- get inside & outside information
	for ni,si in ipairs(shapes) do
		local xi,yi = si.shape:match("([%d%.%-]+) ([%d%.%-]+)")
		
		for nj,sj in ipairs(shapes) do
			if nj~=ni then
				local judge = M.pt_in_shape(xi,yi,sj.shape)
			
				-- true -> si in sj
				if judge==true then
					table.insert(sj.other.inside,ni)
					sj.other.i = sj.other.i + 1
					table.insert(si.other.outside,nj)
					si.other.o = si.other.o + 1
				end
			end
		end
	end

	local new = {}

	-- get parent & daughter node information
	for ni,si in ipairs(shapes) do
		-- first find the tree with more than two node (not top node)
		if si.other.o~=0 then
			for nj,Nj in ipairs(si.other.outside) do
				if si.other.o-1==shapes[Nj].other.o then
					-- write down pn & dn information
					-- if si.other.pn==nil then si.other.pn = Nj end
					table.insert(shapes[Nj].other.dn,ni)
					break
				end
			end
		end
	end

	local del_count = 0
	while del_count<#shapes do		
		for ni,si in ipairs(shapes) do
			-- first the top of the tree
			if si.other.del==false and si.other.o==0 then
				local new_shape = si.shape
				-- something in si
				if si.other.i~=0 then
					local dnum_table = si.other.dn -- table
					for nj,dnum in ipairs(dnum_table) do
						new_shape = new_shape.." "..shapes[dnum].shape
						-- delete
						shapes[dnum].other.del = true
						del_count = del_count + 1 
					end
					
					-- minus the number
					local n_del = 1 + #dnum_table
					for nk,inum in ipairs(si.other.inside) do
						shapes[inum].other.o = shapes[inum].other.o - n_del
					end
				-- else nothing in si <=> si is the smallest
				end
				table.insert(new,new_shape)
				si.other.del = true
				del_count = del_count + 1
			end
		end
	end

	return new
end

function M.math.epsilon()
	return 0.00001
end

function M.math.rotate(x,y,angle)
	if math.abs(x)<M.math.epsilon() and math.abs(y)<M.math.epsilon() then return x,y end
	local temp = math.atan(y,x)
	local distance = math.sqrt(x^2+y^2)
	return distance*math.cos(temp-angle),distance*math.sin(temp-angle)
end

function M.math.distance(x1,y1,x2,y2)
	return math.sqrt((x2-x1)^2+(y2-y1)^2)
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)


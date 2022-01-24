--[[
README:

]]

--Script properties
script_name="Effect: life game"
script_description="life game v1.0"
script_author="chaaaaang"
script_version="1.0"

local Yutils = require('Yutils')
include('karaskel.lua')

function main(subtitle, selected)
    local meta,styles=karaskel.collect_head(subtitle,false)
	local xres, yres, ar, artype = aegisub.video_size()

    -- the pixel of every block
    local block = 5
    local data = ""
    local x_min,x_max,y_min,y_max = 0,0,0,0

		for si,li in ipairs(selected) do

			local line=subtitle[li]
			karaskel.preproc_line(subtitle,meta,styles,line)

			if si==1 then		
				-- line
				local ltxtstripped = line.text_stripped
				local ltext = line.text:match("^{") and line.text or "{}"..line.text
				-- tag
				local tag = ltext:match("^{[^}]*}")
				local tag_strip_t = tag:gsub("\\t%([^%)]*%)","")
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

                local font_handle = Yutils.decode.create_font(font,bold,italic,underline,strikeout,fontsize,scale_x/100,scale_y/100,spacing)
				local shape = font_handle.text_to_shape(ltxtstripped)
                local pixels = Yutils.shape.to_pixels(shape)

                local posx,posy,top,left,bottom,right,center,middle = position(ltext,line,xres,yres)
                x_min,x_max,y_min,y_max = center,center,middle,middle

                for i=math.floor(left),math.floor(right),block do
                    for j=math.floor(top),math.floor(bottom),block do
                        if pt_in_shape(i-left,j-top,pixels)==true then
                            data = data..string.format("m %d %d l %d %d %d %d %d %d ",i,j,i+block,j,i+block,j+block,i,j+block)
                            x_min,x_max,y_min,y_max = math.min(x_min,i),math.max(x_max,i),math.min(y_min,j),math.max(y_max,j)
                        end
                    end   
                end
			else
                local data_temp = ""
				local data_table = {}
				
				for x,y in data:gmatch("m ([%d%-]+) ([%d%-]+)") do
					local c1,c2,c3,c4,c6,c7,c8,c9 = 0,0,0,0,0,0,0,0
					x,y = tonumber(x),tonumber(y)
					for sj,lj in ipairs(data_table) do
						if x-block==lj.x and y-block==lj.y then
							data_table[sj].c = lj.c + 1
							c7 = 1
						elseif x==lj.x and y-block==lj.y then
							data_table[sj].c = lj.c + 1
							c8 = 1
						elseif x+block==lj.x and y-block==lj.y then
							data_table[sj].c = lj.c + 1
							c9 = 1
						elseif x-block==lj.x and y==lj.y then
							data_table[sj].c = lj.c + 1
							c4 = 1
						elseif x+block==lj.x and y==lj.y then
							data_table[sj].c = lj.c + 1
							c6 = 1
						elseif x-block==lj.x and y+block==lj.y then
							data_table[sj].c = lj.c + 1
							c1 = 1
						elseif x==lj.x and y+block==lj.y then
							data_table[sj].c = lj.c + 1
							c2 = 1
						elseif x+block==lj.x and y+block==lj.y then
							data_table[sj].c = lj.c + 1
							c3 = 1
						end
					end
					if c1==0 then table.insert(data_table,{x=x-block,y=y+block,c=1}) end
					if c2==0 then table.insert(data_table,{x=x,y=y+block,c=1}) end
					if c3==0 then table.insert(data_table,{x=x+block,y=y+block,c=1}) end
					if c4==0 then table.insert(data_table,{x=x-block,y=y,c=1}) end
					if c6==0 then table.insert(data_table,{x=x+block,y=y,c=1}) end
					if c7==0 then table.insert(data_table,{x=x-block,y=y-block,c=1}) end
					if c8==0 then table.insert(data_table,{x=x,y=y-block,c=1}) end
					if c9==0 then table.insert(data_table,{x=x+block,y=y-block,c=1}) end
				end

				for sj,lj in ipairs(data_table) do
					if lj.c==3 or (lj.c==2 and data:match(string.format("m %d %d",lj.x,lj.y))~=nil) then
						local i,j = lj.x,lj.y
						data_temp = data_temp..string.format("m %d %d l %d %d %d %d %d %d ",i,j,i+block,j,i+block,j+block,i,j+block)
						x_min,x_max,y_min,y_max = math.min(x_min,i),math.max(x_max,i),math.min(y_min,j),math.max(y_max,j)
					end
				end
				
                data = data_temp
            end
            line.text = "{\\an7\\p1\\pos(0,0)\\fsc100\\bord0\\shad0}"..data
			subtitle[li]=line
            aegisub.progress.set(si/#selected*100)
		end

	aegisub.set_undo_point(script_name)
	return selected
end

function num2bool(a)
	if tonumber(a)~=0 then
		return true
	else
		return false
	end
end

function position(ltext,line,xres,yres)
	local x,y,top,left,bottom,right,center,middle = 0,0,0,0,0,0,0,0

	local ratiox,ratioy = 1,1
	if (ltext:match("\\fs%d")~=nil) then
		ratiox = tonumber(ltext:match("\\fs([%d%.]+)")) / line.styleref.fontsize
		ratioy = tonumber(ltext:match("\\fs([%d%.]+)")) / line.styleref.fontsize
	end
	if (ltext:match("\\fscx")~=nil) then 
		ratiox = ratiox * tonumber(ltext:match("\\fscx([%d%.]+)")) / line.styleref.scale_x
	end
	if (ltext:match("\\fscy")~=nil) then 
		ratioy = ratioy * tonumber(ltext:match("\\fscy([%d%.]+)")) / line.styleref.scale_y
	end
	local width = line.width * ratiox
	local height = line.height * ratioy
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

function pt_in_shape(x,y,pixels)
	for j=1,#pixels do
		if (math.abs(x-pixels[j].x)<=0.5 and math.abs(y-pixels[j].y)<=0.5) then
			return true
		end
	end
	return false
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)


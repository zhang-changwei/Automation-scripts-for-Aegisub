--[[
README:

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

]]

script_name="C Utilities"
script_description="Utilities v1.1"
script_author="chaaaaang"
script_version="1.1" 

include('karaskel.lua')
re = require 'aegisub.re'
clipboard = require 'aegisub.clipboard'

local dialog_config = {
	{class="label",label="Options",x=0,y=0},
	{class="dropdown",name="option",
		items={"Centralize Drawing","Delete Empty Lines","Delete SDH Comment",
		"Dialog Checker","Move!","Seperate Bilingual SUBS by \\N","Swap SUBS Splitted by \\N"},
		x=1,y=0,width=4},
    -- Delete SDH Comment
    {class="label",label="Delete SDH Comment",x=0,y=1,width=2},
    {class="checkbox",name="SDH_m",label="[...]",value=true,x=0,y=2},
    {class="checkbox",name="SDH_s",label="(...)",value=true,x=1,y=2},
    {class="checkbox",name="SDH_l",label="{...}",value=false,x=0,y=3},
    {class="checkbox",name="SDH_h",label="<...>",value=false,x=1,y=3},
    {class="checkbox",name="SDH_M",label="【...】",value=false,x=0,y=4},
    {class="checkbox",name="SDH_S",label="（...）",value=false,x=1,y=4},
	{class="checkbox",name="SDH_speaker",label="automatically remove speaker",value=false,x=0,y=5,width=3,hint="ATTENTION: it many lead to some errors, be careful!"},
    {class="checkbox",name="SDH_o",label="other patterns",value=false,x=0,y=6},
    {class="edit",name="SDH_other",x=0,y=7,width=2,hint="seperate by comma without any blank"},
    {class="label",label="to",x=0,y=8},
    {class="edit",name="SDH_to",value=" ",x=0,y=9,width=2,hint="default: one blank"},
	-- Move!
	{class="label",label="Move!",x=3,y=1,width=2},
	{class="checkbox",name="move_pos",label="pos",value=true,x=3,y=2},
	{class="checkbox",name="move_clip",label="clip",value=false,x=4,y=2},
	{class="checkbox",name="move_move",label="move",value=false,x=3,y=3},
	{class="checkbox",name="move_move2",label="moves3/moves4",value=false,x=4,y=3},
	{class="label",label="x",x=3,y=4},
	{class="floatedit",name="move_x",value=0,x=4,y=4},
	{class="label",label="y",x=3,y=5},
	{class="floatedit",name="move_y",value=0,x=4,y=5},
	-- Dialog Checker
	{class="label",label="Dialog Checker",x=3,y=6,width=2},
	{class="checkbox",label="overlap checker",name="dialog_olp",value=true,x=3,y=7,width=2},
	{class="checkbox",label="bilang checker",name="dialog_bl",value=true,x=3,y=8,width=2},
	{class="checkbox",label="overlength checker",name="dialog_ol",value=true,x=3,y=9,width=2},
	{class="label",label="buffer",x=3,y=10},
	{class="floatedit",name="dialog_bf",value=300,x=4,y=10,hint="ACT ON overlength checker, larger buffer means narrower space for SUBS."},
    -- note
	{class="label",label="      ",x=2,y=1},
	
    {class="label",label="Centralize Drawing:",x=0,y=11},
	{class="label",label="require Yutils library, only work under \\an7 tag.",x=1,y=11,width=6},
	{class="label",label="Delete Empty Lines:",x=0,y=12},
	{class="label",label="the program may not terminate properly, just ignore it.",x=1,y=12,width=6},
	{class="label",label="Dialog Checker:",x=0,y=13},
	{class="label",label="Yutils library is required for overlength checker.",x=1,y=13,width=6},
	{class="label",label="Move!:",x=0,y=14},
	{class="label",label="Yutils library is required for vector clip movement.",x=1,y=14,width=6}
}
local buttons = {"Run","Quit"}

--This is the main processing function that modifies the subtitles
function main(subtitle, selected, active)
    local meta,styles=karaskel.collect_head(subtitle,false)
	local xres, yres, ar, artype = aegisub.video_size()

    local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if (pressed=="Quit") then aegisub.cancel() end

	local log = {}
	log.overlength,log.overlap,log.bilang = 0,0,0
	local N = #selected

	-- Delete Empty Lines
	if result.option=="Delete Empty Lines" then
		local i = 1
		local total = #subtitle
		while(i<=total) do
			local li = subtitle[i]
			if li.class=="dialogue" then
				li.text = li.text:gsub("{}","")
				li.text = li.text:gsub(" *","")
				if li.text=="" then
					subtitle.delete(i)
					total = total - 1
				else
					i = i + 1
				end
			else
				i = i + 1
			end
		end
		goto loop_end
	end

    for si,li in ipairs(selected) do
        local line=subtitle[li]
        karaskel.preproc_line(subtitle,meta,styles,line)

        local linetext = line.text:match("^{")~=nil and line.text or "{}"..line.text
        linetext = linetext:gsub("}{","")

        -- Centralize Drawing
        if result.option=="Centralize Drawing" then
            local Yutils = require('Yutils')

            local posx,posy = drawing_position(linetext,line,xres,yres)
            if linetext:match("\\pos")==nil then linetext=linetext:gsub("^{","{\\pos("..posx..","..posy..")") end
            if linetext:match("\\an%d")==nil then linetext=linetext:gsub("^{","{\\an"..line.styleref.align) end
            if linetext:match("\\fsc[%d%.]")~=nil then linetext=linetext:gsub("\\fsc([%d%.%-]+)","\\fscx%1\\fscy%1") end
            if linetext:match("\\fscy")==nil then linetext=linetext:gsub("^{","{\\fscy"..line.styleref.scale_y) end
            if linetext:match("\\fscx")==nil then linetext=linetext:gsub("^{","{\\fscx"..line.styleref.scale_x) end

            if linetext:match("\\an(%d)")~="7" then 
                aegisub.log("Please add \'\\an7\' tag first")
                aegisub.cancel()
            end

            local pnum = linetext:match("\\p(%d)")
            local scale_x = linetext:match("\\fscx([%d%.]+)")/100
            local scale_y = linetext:match("\\fscy([%d%.]+)")/100

            local shape = linetext:match("^{[^}]*}([^{]*)")
            local flatten_shape = Yutils.shape.flatten(shape)
            local xmin,ymin = flatten_shape:match("([%d%.%-]+) +([%d%.%-]+)")
            local xmax,ymax = xmin,ymin

            for x,y in flatten_shape:gmatch("([%d%.%-]+) +([%d%.%-]+)") do
                xmin = math.min(x,xmin)
                xmax = math.max(x,xmax)
                ymin = math.min(y,ymin)
                ymax = math.max(y,ymax)
            end
            local cx,cy = (xmin+xmax)/2, (ymin+ymax)/2
            local px,py = posx+cx*scale_x/(2^(pnum-1)) , posy+cy*scale_y/(2^(pnum-1))
            linetext = linetext:gsub("\\pos[^%)]+%)","\\pos("..px..","..py..")")

            shape = Yutils.shape.filter(shape, function (x,y) return x-cx,y-cy end)

            linetext = linetext:gsub("^({[^}]*})[^{]*",function (a) return a..shape end)
        elseif result.option=="Delete SDH Comment" then
            linetext = linetext:gsub("^{}","")
            if result.SDH_m==true then linetext = linetext:gsub("%[[^]]*]",result.SDH_to) end
            if result.SDH_s==true then linetext = linetext:gsub("%([^%)]*%)",result.SDH_to) end
            if result.SDH_l==true then linetext = linetext:gsub("{[^}]*}",result.SDH_to) end
            if result.SDH_h==true then linetext = linetext:gsub("<[^>]*>",result.SDH_to) end
            if result.SDH_M==true then linetext = re.sub(linetext, "【[^】]*】", result.SDH_to) end
            if result.SDH_S==true then linetext = re.sub(linetext, "（[^）]*）", result.SDH_to) end
            if result.SDH_o==true then
                for i in result.SDH_other:gmatch("([^,]+)") do
                    linetext = re.sub(linetext,i,result.SDH_to)
                end
            end
			if result.SDH_speaker==true then
				linetext = linetext:gsub("(%p)[^%p]-: *","%1"..result.SDH_to)
				linetext = linetext:gsub("^[^%p]-: *","")
			end
		elseif result.option=="Dialog Checker" then
			linetext = linetext:gsub("^{}","")
			if result.dialog_ol==true then
				local _,count = linetext:gsub("\\N","")
				if count==0 then
					local w1 = line.width
					if linetext:match("\\fsc[%d%.]")~=nil then w1=w1*linetext:match("\\fsc([%d%.]+)")/line.styleref.scale_x end
					if linetext:match("\\fscx[%d%.]")~=nil then w1=w1*linetext:match("\\fscx([%d%.]+)")/line.styleref.scale_x end
					if linetext:match("\\fs[%d%.]")~=nil then w1=w1*linetext:match("\\fs([%d%.]+)")/line.styleref.fontsize end
					if w1>=xres-result.dialog_bf then 
						line.actor = line.actor.."overlength "
						log.overlength = log.overlength + 1
					end
				elseif count==1 then
					local Yutils = require('Yutils')
					local chs,eng = linetext:match("(.*)\\N(.*)")
					local chss,engs = chs:gsub("{([^}]*)}",""),eng:gsub("{([^}]*)}","")
					
					local name,scale_x,size,hspace = line.styleref.fontname,line.styleref.scale_x,line.styleref.fontsize,line.styleref.spacing
					if chs:match("\\fn")~=nil then name=chs:match("\\fn([^\\}]+)") end
					if chs:match("\\fsc[%d%.]")~=nil then scale_x=chs:match("\\fsc([%d%.]+)") end
					if chs:match("\\fscx[%d%.]")~=nil then scale_x=chs:match("\\fscx([%d%.]+)") end
					if chs:match("\\fs[%d%.]")~=nil then size=chs:match("\\fs([%d%.]+)") end
					if chs:match("\\fsp[%d%.%-]")~=nil then hspace=chs:match("\\fs([%d%.%-]+)") end

					local name2,scale_x2,size2,hspace2 = name,scale_x,size,hspace
					if eng:match("\\r")~=nil then 
						for j=1,1000 do
							if subtitle[j].class=="style" and subtitle[j].style.name==eng:match("\\r([^\\}]+)") then
								name2 = subtitle[j].style.fontname
								scale_x2 = subtitle[j].style.scale_x
								size2 = subtitle[j].style.fontsize
								hspace2 = subtitle[j].style.spacing
								break
							end
						end
					end
					if eng:match("\\fn")~=nil then name2=eng:match("\\fn([^\\}]+)") end
					if eng:match("\\fsc[%d%.]")~=nil then scale_x2=eng:match("\\fsc([%d%.]+)") end
					if eng:match("\\fscx[%d%.]")~=nil then scale_x2=eng:match("\\fscx([%d%.]+)") end
					if eng:match("\\fs[%d%.]")~=nil then size2=eng:match("\\fs([%d%.]+)") end
					if eng:match("\\fsp[%d%.%-]")~=nil then hspace2=eng:match("\\fs([%d%.%-]+)") end
					
					local CHS_HANDLE = Yutils.decode.create_font(name,false,false,false,false,size,scale_x/100,1,hspace)
					local ENG_HANDLE = Yutils.decode.create_font(name2,false,false,false,false,size2,scale_x2/100,1,hspace2)
					local w1,w2 = CHS_HANDLE.text_extents(chss).width,ENG_HANDLE.text_extents(engs).width

					if w1>=xres-result.dialog_bf or w2>=xres-result.dialog_bf then
						line.actor = line.actor.."overlength "
						log.overlength = log.overlength + 1
					end
				end
			end
			
			if result.dialog_olp==true and si~=N and line.end_time>subtitle[li+1].start_time then
				line.actor = line.actor.."overlap "
				local nextline = subtitle[li+1]
				nextline.actor = nextline.actor.."overlap "
				subtitle[li+1] = nextline
				log.overlap = log.overlap + 1
			end
			if result.dialog_bl==true then
				local _,count = linetext:gsub("\\N","")
				if count==1 then
					local chs,eng = linetext:match("(.*)\\N(.*)")
					chs = chs:gsub("{[^}]*}","")
					eng = eng:gsub("{[^}]*}","")
					eng = eng:gsub(" *","")
					if chs:match("[\128-\191]")~=nil and eng~="" then
					else
						line.actor = line.actor.."bilang "
						log.bilang = log.bilang + 1
					end
				else
					line.actor = line.actor.."bilang "
					log.bilang = log.bilang + 1
				end
			end
		elseif result.option=="Empty Mocha Data" then
			local start_f,end_f = aegisub.frame_from_ms(line.start_time),aegisub.frame_from_ms(line.end_time)
			local data = ""
			data = data.."Adobe After Effects 6.0 Keyframe Data\n"
			data = data.."\n"
			data = data.." Units Per Second	23.976\n"
			data = data.." Source Width	1920\n"
			data = data.." Source Height	1080\n"
			data = data.." Source Pixel Aspect Ratio	1\n"
			data = data.." Comp Pixel Aspect Ratio	1\n"
			data = data.."\n"
			data = data.."Position\n"
			data = data.." Frame	X pixels	Y pixels	Z pixels\n"
			for i=0,end_f-start_f-1 do
				data = data.." "..i.." 0 0 0\n"
			end
			data = data.."\n"
			data = data.."Scale\n"
			data = data.." Frame	X percent	Y percent	Z percent\n"
			for i=0,end_f-start_f-1 do
				data = data.." "..i.." 100 100 100\n"
			end
			data = data.."\n"
			data = data.."Rotation\n"
			data = data.." Frame	Degrees\n"
			for i=0,end_f-start_f-1 do
				data = data.." "..i.." 0\n"
			end
			data = data.."\n"
			data = data.."End of Keyframe Data\n"
			aegisub.log(data.."\nThe Mocha Data have been copied to the clipboard!")
			clipboard.set(data)
			aegisub.cancel()
		elseif result.option=="Move!" then
			if result.move_pos==true then
				if linetext:match("\\move[^v]")==nil then
					local x,y = drawing_position(linetext,line,xres,yres)
					if linetext:match("\\pos")==nil then linetext=linetext:gsub("^{","{\\pos("..x..","..y..")") end
					linetext = linetext:gsub("\\pos%(([^,]*),([^%)]*)%)",function (a,b) return "\\pos("..a+result.move_x..","..b+result.move_y..")" end)
				end
			end

			if result.move_clip==true then
				if linetext:match("\\i?clip%([%d%.%- ]+,")~=nil then
					linetext = linetext:gsub("(\\i?clip)%( *([%d%.%-]+) *, *([%d%.%-]+) *, *([%d%.%-]+) *, *([%d%.%-]+) *%)",
					function (p,a,b,c,d)
						return p.."("..a+result.move_x..","..b+result.move_y..","..c+result.move_x..","..d+result.move_y..")"
					end)
				else
					local Yutils = require('Yutils')
					linetext = linetext:gsub("(\\i?clip)%(([^%)]*)%)",
					function (p,a)
						a = Yutils.shape.filter(a,function (x,y) return x+result.move_x,y+result.move_y end)
						return p.."("..a..")"
					end)
				end
			end

			if result.move_move==true then
				linetext = linetext:gsub("\\move%( *([%d%.%-]+) *, *([%d%.%-]+) *, *([%d%.%-]+) *, *([%d%.%-]+) *",
				function (a,b,c,d)
					return "\\move("..a+result.move_x..","..b+result.move_y..","..c+result.move_x..","..d+result.move_y
				end)
			end

			if result.move_move2==true then
				local mnum = tonumber(linetext:match("\\moves(%d)"))
				linetext = linetext:gsub("(\\moves%d)%(([^%)]*)%)",
				function (p,a)
					local i = 0
					local new_a = ""
					for x,y in a:gmatch(" *([%d%.%-]+) *, *([%d%.%-]+) *") do
						i = i + 1
						if i<=mnum then
							x,y = tonumber(x),tonumber(y)
							x,y = x+result.move_x,y+result.move_y
						end
						new_a = new_a..x..","..y..","
					end
					new_a = new_a:gsub(",$","")
					return p.."("..new_a..")"
				end)
			end
		elseif result.option=="Seperate Bilingual SUBS by \\N" then
			linetext = linetext:gsub("^{}","")
			linetext=linetext:gsub("([\128-\191][^ ]*) +([\1-\127]+)$","%1\\N%2")
        elseif result.option=="Swap SUBS Splitted by \\N" then
			linetext = linetext:gsub("^{}","")
			if linetext:match("\\N *{[^}]*}") then
				linetext = linetext:gsub("(.*)\\N *({[^}]*})(.*)","%3\\N%2%1")
			else
				linetext = linetext:gsub("(.*)\\N(.*)","%2\\N%1")
			end
		else
			linetext = linetext:gsub("^{}","")
		end

        line.text=linetext
        subtitle[li]=line
    end

	-- log output
	if result.option=="Dialog Checker" then
		aegisub.log(log.overlength.." overlength mistake(s),\n"..log.overlap.." overlap mistake(s),\n"..log.bilang.." bilang mistake(s) have been found!")
	end
	
	:: loop_end ::
    aegisub.set_undo_point(script_name) 
    return selected 
end

function drawing_position(ltext,line,xres,yres)
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
	return x,y
end

function macro_validation(subtitle, selected, active)
    return true
end

--This is what puts your automation in Aegisub's automation list
aegisub.register_macro(script_name,script_description,main,macro_validation)
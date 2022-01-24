--[[
README:

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

Font Resizing (Mocha Deshaking)

Feature:
Desize the \fs and correspondingly Amplify the \fscx \fscy to make the size of text seemingly the same.
Now \fs \fscx \fscy \fsc \fsp supported.
	e.g. \fs50 -> \fs5\fscx1000\fscy1000
It works well in deshaking Mocha, try it if you don't believe it.

Manual:
1. Select the line(s) and run the script, run it before or after applying Mocha

Bug Report:
1. \t(\fs) is not supported

Updated on 21st Jan 2021
	inline scale mistake fixed
	fsp keeps to 3 decimal places
]]

script_name="C Font Resizing (Mocha Deshaking)"
script_description="Font Resizing (Mocha Deshaking) v1.3"
script_author="lyger modified by chaaaaang"
script_version="1.3"

include("karaskel.lua")

function refont(sub, sel)

	local meta,styles=karaskel.collect_head(sub,false)
	
	for si,li in ipairs(sel) do
		
		local line=sub[li]
		
		karaskel.preproc_line(sub,meta,styles,line)
		
		--The next few steps will break the line up into tag-text pairs
		
		--First ensures that the line begins with an override tag block
		--x = A and B or C means if A, then x = B, else x = C
		ltext=(line.text:match("^{")==nil) and "{}"..line.text or line.text
		
		--each closed curly brace, otherwise adjacent override blocks with no text in between won't match
		ltext=ltext:gsub("}{","") --new
		ltext=ltext:gsub("\\fsc([%d%.]+)","\\fscx%1\\fscy%1")
		
		--Then ensure that the first tag includes \fs \fscx \fscy tag
		if ltext:match("^{[^}]*\\fs[%d%.]+[^}]*}")==nil then
			ltext=ltext:gsub("^{",string.format("{\\fs%.1f",line.styleref.fontsize))
		end
		if ltext:match("^{[^}]*\\fscy[%d%.]+[^}]*}")==nil then
			ltext=ltext:gsub("^{",string.format("{\\fscy%.2f",line.styleref.scale_y))
		end
		if ltext:match("^{[^}]*\\fscx[%d%.]+[^}]*}")==nil then
			ltext=ltext:gsub("^{",string.format("{\\fscx%.2f",line.styleref.scale_x))
		end

		--These store the current values of the three parameters at the part of the line
		--we are looking at
		--Since we have not started looking at the line yet, these are set to the style defaults
		cur_fs=line.styleref.fontsize
		cur_fscx=line.styleref.scale_x
		cur_fscy=line.styleref.scale_y
		cur_fsp=0.
		if (line.styleref.spacing~=0) then
			if ltext:match("^{[^}]*\\fsp[%d%.%-]+[^}]*}")==nil then
				ltext=ltext:gsub("^{",string.format("{\\fsp%.3f",line.styleref.spacing))
			end
			cur_fsp=line.styleref.spacing
		end

		-- vector picture
		if (ltext:match("\\p%d")~=nil) then
			ltext = ltext:gsub("\\p(%d)",function (a) return "\\p"..a+3	end)
			ltext = ltext:gsub("\\fscx([%d%.]+)",function (a) return "\\fscx"..a*8	end)
			ltext = ltext:gsub("\\fscy([%d%.]+)",function (a) return "\\fscy"..a*8	end)
			if (ltext:match("{\\p%d}$")~=nil) then
				ltext = ltext:gsub("{\\p%d}$","{\\p0}")
			end
			line.text = ltext
			sub[li] = line
			goto loop_end
		end

		--Store these pairs in a new data structure
		tt_table={}
		for tg,tx in ltext:gmatch("({[^}]*})([^{]*)") do
			table.insert(tt_table,{tag=tg,text=tx})
		end
		
		--This is where the new text will be stored
		rebuilt_text=""
		
		--Now rebuild the line piece-by-piece using the tag-text pairs stored in tt_table
		for _,tt in ipairs(tt_table) do
			--x = A or B means x = A if A is not nil, otherwise x = B

			--first handle the \fs tag
			local n_fs="" --PLEASE MAKE SURE NO \t(\fs) CODE IS USED
			local i=0
			for nfs in tt.tag:gmatch("\\fs[%d%.]+") do
				n_fs=nfs
				i=i+1
			end
			if (i>=2) then
				tt.tag:gsub("\\fs[%d%.]+","")
				tt.tag:gsub("^{",string.format("{%s",n_fs))
			end
			if (i>=1) then 
				cur_fs=tonumber(n_fs:match("[%d%.]+"))
			end

			new_fs=(cur_fs>10) and math.floor(cur_fs/10) or 1
			factor=cur_fs/new_fs
			tt.tag=tt.tag:gsub("\\fs[%d%.]+", "\\fs"..new_fs)

			--make sure there is fscx fscy in the tag
			local tagcopy = tt.tag
			tagcopy = tagcopy:gsub("\\t%([^%)]*\\fsc[xy][^%)]*%)","")
			if (tagcopy:match("\\fscy")==nil) then tt.tag = tt.tag:gsub("^{",string.format("{\\fscy%d",cur_fscy)) end

			if (tagcopy:match("\\fscx")==nil) then tt.tag = tt.tag:gsub("^{",string.format("{\\fscx%d",cur_fscx)) end
			
			--*new* delete all blanks and readd blanks behind \fscx \fscy \fsp use 'WWW'
			tt.tag=tt.tag:gsub("(\\fscx[%d%.%-]+)","%1}")
			tt.tag=tt.tag:gsub("(\\fscy[%d%.%-]+)","%1}")
			tt.tag=tt.tag:gsub("(\\fsp[%d%.%-]+)","%1}")
			-- table tgs means tagsplit
			local rebuilt_tag=""
			for tgs in tt.tag:gmatch("([^}]+)}") do
				if (tgs:match("\\fscx[%d%.%-]+")~=nil) then 
					cur_fscx=tonumber(tgs:match("\\fscx([%d%.%-]+)"))
					new_fscx=math.floor(cur_fscx*factor)
					tgs=tgs:gsub("\\fscx[%d%.%-]+",string.format("\\fscx%d",new_fscx))
				end
				if (tgs:match("\\fscy[%d%.%-]+")~=nil) then 
					cur_fscy=tonumber(tgs:match("\\fscy([%d%.%-]+)"))
					new_fscy=math.floor(cur_fscy*factor)
					tgs=tgs:gsub("\\fscy[%d%.%-]+",string.format("\\fscy%d",new_fscy))
				end
				if (tgs:match("\\fsp[%d%.%-]+")~=nil) then 
					cur_fsp=tonumber(tgs:match("\\fsp([%-%d%.]+)"))
					new_fsp=cur_fsp/factor
					tgs=tgs:gsub("\\fsp[%d%.%-]+",string.format("\\fsp%.3f",new_fsp))
				end
				rebuilt_tag = rebuilt_tag..tgs
			end
			tt.tag = rebuilt_tag.."}"
			rebuilt_text=rebuilt_text..tt.tag..tt.text
		end
		
		line.text=rebuilt_text
		
		sub[li]=line

		::loop_end::
		
	end
	
	--Set undo point and maintain selection
	aegisub.set_undo_point(script_name)
	return sel
	
end

--Register macro
aegisub.register_macro(script_name,script_description,refont)
--[[
README:

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

]]

script_name="C Replace Plus"
script_description="Replace Plus v1.0"
script_author="chaaaaang"
script_version="1.0" 

--This is the main processing function that modifies the subtitles
function main(subtitle, selected, active)
	local count_rule = 1

	local dialog_config = {
		{class="label",label="Match",x=0,y=0},--1
		{class="edit",name="match",value="~",x=1,y=0,width=2},--2
		{class="label",label="Str",x=0,y=1},--3
		{class="edit",name="str",value="",x=1,y=1,width=2},--4
		{class="label",label="Support: (value)ldur; (function)random(a,b); (capture)cap1-9",x=0,y=2,width=3},--5
		-- rules
		{class="label",label="Rule#1",x=0,y=3},--6
		{class="edit",name="r1",value="",x=1,y=3,width=2}--7
	}
	local buttons = {"Run","Add One Rule","Quit"}
	
	::UI::
    local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if not (pressed=="Run" or pressed=="Add One Rule") then aegisub.cancel() 
	elseif pressed=="Add One Rule" then
		dialog_config[2].value = result.match
		dialog_config[4].value = result.str
		count_rule = count_rule + 1
		local temp1,temp2 = "Rule#"..count_rule,"r"..count_rule
		table.insert(dialog_config,{class="label",label=temp1,x=0,y=count_rule+2})
		table.insert(dialog_config,{class="edit",name=temp2,value="",x=1,y=count_rule+2,width=2})
		goto UI
	end

	-- count_capture
	result.match = result.match:gsub("\\\\","\\")
	result.str = result.str:gsub("\\\\","\\")
	local match_temp = result.match:gsub("%%%(","")
	local _,count_capture = match_temp:gsub("%(","")

    for si,li in ipairs(selected) do
        local line=subtitle[li]
        local ldur = line.end_time-line.start_time

        local linetext = line.text:match("^{")~=nil and line.text or "{}"..line.text
        linetext = linetext:gsub("}{","")
		local _,count_match = linetext:gsub("{[^}]*"..result.match.."[^}]*}", "")

		-- substitute the match with ~
		linetext = linetext:gsub("{([^}]*)}", function (a)
			local a1 = ""
			if count_capture>0 then
				a1 = a:gsub(result.match, function (...)
					local b = {...}
					return "~"..table.concat(b,",")..",~"
				end)
			else
				a1 = a:gsub(result.match,"~")
			end
			return "{"..a1.."}"
		end)

		for i=1,count_match do
			-- get capture args
			local capture_table = {}
			if count_capture>0 then
				local capture_string = linetext:match("~([%d%.%-,]+)~")
				for j in capture_string:gmatch("([^,]+),") do
					j = tonumber(j)
					table.insert(capture_table,j)
				end
				linetext = linetext:gsub("~([%d%.%-,]+)~","~")
			end
			-- write rules into the table
			local rule_table = {}
			for j=1,count_rule do
				local rname = "r"..j
				local rule_temp = result[rname]
				-- head & tail ()
				if rule_temp:match("^%(")==nil then
					rule_temp = rule_temp:gsub("^","(")
					rule_temp = rule_temp:gsub("$",")")
				end
				-- value: ldur,sstart,send,sdur
				rule_temp = rule_temp:gsub("ldur",ldur)
				rule_temp = rule_temp:gsub("sstart",ldur/count_match*(i-1))
				rule_temp = rule_temp:gsub("send",ldur/count_match*(i))
				rule_temp = rule_temp:gsub("sdur",ldur/count_match)
				rule_temp = rule_temp:gsub("sindex",i)
				rule_temp = rule_temp:gsub("scount",count_match)
				rule_temp = rule_temp:gsub("lindex",si)
				rule_temp = rule_temp:gsub("lcount",#selected)
				-- capture: cap%d
				rule_temp = rule_temp:gsub("cap(%d)",function (a)
					a = tonumber(a)
					return capture_table[a]
				end)
				-- rule calculation
				while rule_temp:match("%(")~=nil do
					rule_temp = rule_temp:gsub("([a-z]*%([^%(%)]*%))",function (a) return calculation(a) end)
				end
				rule_temp = tonumber(rule_temp)
				table.insert(rule_table,rule_temp)
			end

			-- write rules into the str
			local str_temp = result.str
			for j=1,count_rule do
				local judge_str_pre,judge_str_post = str_temp:match("(.-)\\d"),str_temp:match("\\d(.+)")
				if  (judge_str_pre:match("\\t%($")~=nil and judge_str_post:match("^,\\d")~=nil) or
					(judge_str_pre:match("\\move%([%d%.%-]+,[%d%.%-]+,[%d%.%-]+,[%d%.%-]+,$") and judge_str_post:match("^,\\d")~=nil) then
					rule_table[j],rule_table[j+1] = math.min(rule_table[j],rule_table[j+1]),math.max(rule_table[j],rule_table[j+1])
				end
				str_temp = str_temp:gsub("\\d",rule_table[j],1)
			end

			-- rewrite the sub with the str
			linetext = linetext:gsub("({[^}]*)".."~".."([^}]*})", function (h,t)
				return h..str_temp..t
			end, 1)
		end

        line.text=linetext
        subtitle[li]=line
		aegisub.progress.set((si-1)/#selected*100)
    end
	
	:: loop_end ::
    aegisub.set_undo_point(script_name) 
    return selected 
end

-- str: [a-z]*%([^%(%)]*%)
function calculation(str)
	local pre,strin = str:match("([a-z]*)%(([^%)]*)%)")
	if pre~=nil and pre~="" then
		if pre=="random" then
			local a,b = strin:match("([%d%.%-]+),([%d%.%-]+)")
			a,b = tonumber(a),tonumber(b)
			a,b = math.min(a,b),math.max(a,b)
			return math.random(a,b)
		end
	else
		local pa,a,x,pb,b = strin:match("(%-?)([%d%.]+)([%+%-%*/])(%-?)([%d%.]+)")
		if x~=nil and x~="" then
			a,b = tonumber(a),tonumber(b)
			if pa=="-" then a = -1*a end
			if pb=="-" then b = -1*b end
			if x=="+" then return a+b
			elseif x=="-" then return a-b
			elseif x=="*" then return a*b
			elseif x=="/" and b~=0 then return a/b
			else 
				aegisub.log("math error")
				aegisub.cancel()
			end
		else
			-- only one number
			strin = tonumber(strin)
			return strin
		end
	end
end

function macro_validation(subtitle, selected, active)
    return true
end

--This is what puts your automation in Aegisub's automation list
aegisub.register_macro(script_name,script_description,main,macro_validation)
--[[
README:

]]

--Script properties
script_name="C Capitalize First Character"
script_description="Capitalize first character of en line"
script_author="chaaaaang"
script_version="1.0"


function main(subtitle, selected)
    
	for si,li in ipairs(selected) do
		
		local line=subtitle[li]
		
        local ltext = line.text

		ltext = ltext:gsub("} *(%l)",function(a) return "}"..a:upper() end)
		ltext = ltext:gsub("} *%- +(%l)",function(b) return "}- "..b:upper() end)
        
        line.text = ltext

		subtitle[li]=line
		
	end
	
	aegisub.set_undo_point(script_name)
	return selected
end

--Register macro (no validation function required)
aegisub.register_macro(script_name,script_description,main)

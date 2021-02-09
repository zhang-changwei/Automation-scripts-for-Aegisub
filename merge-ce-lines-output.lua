--[[
README:

Put some explanation about your macro at the top! People should know what it does and how to use it.
]]

script_name="Merge-CE-Lines-Output"
script_description="Merge-CE-Lines-Output"
script_author="chaaaaang"
script_version="1.0" 

--This is the main processing function that modifies the subtitles
function main(subtitle, selected, active)
    time = os.time()
    local file = io.open(string.format("E:\\ZiMuZu\\merge%d.txt",time),"w+")
    io.output(file)
    for si,li in ipairs(selected) do
        line=subtitle[li]
        
        line.text=line.text:gsub("{[^}]*}"," ")
        line.text=line.text:gsub("%[[^%]]*%]"," ")
        line.text=line.text:gsub(" +"," ")

        io.write(line.text.."\n")
    
    end
    io.close(file)

    aegisub.set_undo_point(script_name) 
    return selected 
end




--This optional function lets you prevent the user from running the macro on bad input
function macro_validation(subtitle, selected, active)
    --Check if the user has selected valid lines
    --If so, return true. Otherwise, return false
    return true
end

--This is what puts your automation in Aegisub's automation list
aegisub.register_macro(script_name,script_description,main,macro_validation)
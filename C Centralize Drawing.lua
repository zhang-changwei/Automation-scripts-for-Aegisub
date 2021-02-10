--[[
README:

Put some explanation about your macro at the top! People should know what it does and how to use it.
]]

script_name="C Centralize Drawing"
script_description="Centralize Drawing"
script_author="chaaaaang"
script_version="1.0" 

--This is the main processing function that modifies the subtitles
function Centralization(subtitle, selected, active)
    
    for si,li in ipairs(selected) do
        line=subtitle[li]
        
        if (line.text:match("\\pos")==nil) then line.text=line.text:gsub("^{","{\\pos(0,0)")
        if (line.text:match("\\an")==nil) then line.text=line.text:gsub("^{","{\\an7") end
    
        line:text=line.text:gsub("\\fsc[%d%.%-]+","")
        line:text=line.text:gsub("\\fscx[%d%.%-]+","")
        line:text=line.text:gsub("\\fscy[%d%.%-]+","")
        line.text=line.text:gsub("\\an%d","\\an7")
        line.text=line.text:gsub("\\pos%([^%)]+%)","\\pos(0,0)\\fscx100\fscy100")
        
        pos = string.match(line.text, "m +%-?%d+.*")
        i = 1
        totalx = 0
        totaly = 0
        posx = {}
        posy = {}
        for xy in string.gmatch(pos, "%-?%d+%.?%d*") do
            i = i + 1
            index = math.floor(i/2.0)
            chose = i%2
            if (chose == 0) then
                posx[index] = tonumber(xy)
                --totalx = totalx + tonumber(xy)
                if (index == 1) then 
                    x_max=tonumber(xy)
                    x_min=tonumber(xy)
                end
                if (tonumber(xy)>x_max) then x_max=tonumber(xy) end
                if (tonumber(xy)<x_min) then x_min=tonumber(xy) end
            else
                posy[index] = tonumber(xy)
                --totaly = totaly + tonumber(xy)
                if (index == 1) then
                    y_max=tonumber(xy)
                    y_min=tonumber(xy)
                end
                if (tonumber(xy)>y_max) then y_max=tonumber(xy) end
                if (tonumber(xy)<y_min) then y_min=tonumber(xy) end
            end
        end
        --averagex = totalx / index
        --averagey = totaly / index
        averagex = ( x_max + x_min ) / 2
        averagey = ( y_max + y_min ) / 2

        newdrawing = "m "
        for j=1, 2*index do
            if ((j+1)%2==0) then
                newdrawing = newdrawing..tostring(posx[math.floor((j+1)/2.0)]-averagex).." "
            else
                newdrawing = newdrawing..tostring(posy[math.floor((j+1)/2.0)]-averagey).." "
            end
        end
        newdrawing = newdrawing:gsub("(m %-?%d+%.?%d* %-?%d+%.?%d* )","%1l ")

        line.text=line.text:gsub("m %-?%d+.*",newdrawing)
        line.text=line.text:gsub("\\pos%(.*%)",string.format("\\pos(%.3f,%.3f)",averagex,averagey))
        subtitle[li]=line
    end

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
aegisub.register_macro(script_name,script_description,Centralization,macro_validation)
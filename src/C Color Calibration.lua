--[[
README:

goto my repository https://github.com/zhang-changwei/Automation-scripts-for-Aegisub for the latest version

]]

script_name="C Color Calibration"
script_description="Color Calibration v1.2"
script_author="chaaaaang"
script_version="1.2" 

include('karaskel.lua')

local function round(x)
	return math.floor(x + 0.5)
end

local function putmask(x)
    if x > 1 then
        x = 1
    elseif x < 0 then
        x = 0
    end
    return x
end

function config(subtitle, selected, active)
    local dialog_config = {
        {class='label', label='transfer function', x=0, y=0},
        {class='dropdown', name='tf', items={'PQ', 'HLG'}, value='PQ', x=1, y=0},
        {class='label', label='parameter', x=0, y=1},
        {class='intedit', name='p1', value=30, x=1, y=1}
    }
    local buttons = {'Run', 'Quit'}

    local path = aegisub.decode_path('?user')..'\\ColorCalibration.txt'
    local file = io.open(path, 'r')
    if file ~= nil then
        dialog_config[2].value = file:read()
        dialog_config[4].value = tonumber(file:read())
        file:close()
    end

    local pressed, result = aegisub.dialog.display(dialog_config,buttons)
    if pressed == 'Run' then 
        file = io.open(path, 'w')
        file:write(result.tf .. '\n' .. result.p1 .. '\n')
        file:close()
    end
    aegisub.set_undo_point(script_name) 
    return selected 
end

function sdr2hdr(subtitle, selected, active)
    local function eotf_sRGB(v)
        if v <= 0.04045 then
            return v/12.92
        else
            return ((v + 0.055)/1.055)^2.4
        end
    end
    local function sRGB_to_RGB2020(r, g, b)
        local mat = {
            { 0.62744137,  0.32929746,  0.04335146},
            { 0.06902762,  0.91958067,  0.01136142},
            { 0.01636424,  0.08801716,  0.89556497},
        }
        r = mat[1][1]*r + mat[1][2]*g + mat[1][3]*b
        g = mat[2][1]*r + mat[2][2]*g + mat[2][3]*b
        b = mat[3][1]*r + mat[3][2]*g + mat[3][3]*b
        return r, g, b
    end
    local function oetf_PQ_BT2100(Y)
        local c1, c2, c3 = 107/128, 2413/128, 2392/128
        local m1, m2 = 1305/8192, 2523/32
        Y = 59.5208 * Y
        -- OETF BT709
        if Y < 0.018 then
            Y = 4.5 * Y
        else
            Y = 1.099 * Y^0.45 - 0.099
        end
        -- EOTF BT1884
        Y = 100 * math.max(0, Y)^2.4 / 10000
        -- OOTF PQ BT2100
        return ((c1 + c2 * Y^m1) / (1 + c3 * Y^m1))^m2
    end
    local function oetf_HLG_BT2100(E)
        if E <= 1/12 then
            return math.sqrt(3*E)
        else
            local a = 0.17883277
            local b = 0.28466892
            local c = 0.55991073
            return a * math.log(12*E - b) + c
        end
    end
    local function RGB2020_to_YCbCr(R, G, B)
        local Kr, Kb = 0.2627, 0.0593 -- BT2020
        local Y_min, Y_max, C_min, C_max = 16/255, 235/255, 16/255, 240/255

        local Y = Kr * R + (1 - Kr - Kb) * G + Kb * B
        local Cb = 0.5 * (B - Y) / (1 - Kb)
        local Cr = 0.5 * (R - Y) / (1 - Kr)
        Y = Y * (Y_max - Y_min) + Y_min
        Cb = Cb * (C_max - C_min)
        Cr = Cr * (C_max - C_min)
        Cb = Cb + (C_max + C_min) / 2
        Cr = Cr + (C_max + C_min) / 2
        return Y, Cb, Cr
    end
    local function YCbCr_to_RGB709(Y, Cb, Cr)
        local Kr, Kb = 0.2126, 0.0722 -- BT709
        local Y_min, Y_max, C_min, C_max = 16/255, 235/255, 16/255, 240/255

        Y = Y - Y_min
        Cb = Cb - (C_max + C_min) / 2
        Cr = Cr - (C_max + C_min) / 2
        Y = Y / (Y_max - Y_min)
        Cb = Cb / (C_max - C_min)
        Cr = Cr / (C_max - C_min)
        local R = Y + (2 - 2 * Kr) * Cr
        local B = Y + (2 - 2 * Kb) * Cb
        local G = (Y - Kr * R - Kb * B) / (1 - Kr - Kb)

        return R, G, B
    end
    local function color(c)
        local len = string.len(c)
        local a = ''
        if len == 8 then
            a = string.sub(c, 1, 2)
            c = string.sub(c, 3)
        elseif len == 6 then
        else
            return c
        end
        local b, g, r = c:match('(%x%x)(%x%x)(%x%x)')
        b = tonumber(b, 16)/255
        g = tonumber(g, 16)/255
        r = tonumber(r, 16)/255
        
        b = eotf_sRGB(b)
        g = eotf_sRGB(g)
        r = eotf_sRGB(r)

        r, g, b = sRGB_to_RGB2020(r, g, b)

        r, g, b = r/params[1], g/params[1], b/params[1]

        if transferfunc == 'PQ' then
            r = oetf_PQ_BT2100(r)
            g = oetf_PQ_BT2100(g)
            b = oetf_PQ_BT2100(b)
        else
            r = oetf_PQ_BT2100(r)
            g = oetf_PQ_BT2100(g)
            b = oetf_PQ_BT2100(b)
        end
        r, g, b = YCbCr_to_RGB709(RGB2020_to_YCbCr(r, g, b))
        r = round(r * 255)
        g = round(g * 255)
        b = round(b * 255)
        return string.format('&H%s%02X%02X%02X&', a, b, g, r)
    end

    -- count
    local N = #selected
    -- params
    local path = aegisub.decode_path('?user')..'\\ColorCalibration.txt'
    local file = io.open(path, 'r')
    transferfunc = nil
    params = {}
    if file ~= nil then
        transferfunc = file:read()
        table.insert(params, tonumber(file:read()))
        file:close()
    else
        transferfunc = 'PQ'
        params = {30}
    end 

    for si, li in ipairs(selected) do
        local line = subtitle[li]
        local linetext = line.text

        linetext = linetext:gsub('(\\[1234]?c)&?H?([%x]+)&?', function (pre, c)
            return pre .. color(c)
        end)
        linetext = linetext:gsub('(\\[1234]vc)%( *&?H?([%x]+)&? *, *&?H?([%x]+)&? *, *&?H?([%x]+)&? *, *&?H?([%x]+)&? *%)',
        function (pre, c1, c2, c3, c4)
            return string.format('%s(%s,%s,%s,%s)', pre, color(c1), color(c2), color(c3), color(c4))
        end)

        line.text = linetext
        subtitle[li] = line
        aegisub.progress.set(si/N * 100)
    end
    
    aegisub.set_undo_point(script_name) 
    return selected 
end

function hdr2sdr(subtitle, selected, active)
    local function RGB709_to_YCbCr(R, G, B)
        local Kr, Kb = 0.2126, 0.0722 -- BT2020
        local Y_min, Y_max, C_min, C_max = 16/255, 235/255, 16/255, 240/255

        local Y = Kr * R + (1 - Kr - Kb) * G + Kb * B
        local Cb = 0.5 * (B - Y) / (1 - Kb)
        local Cr = 0.5 * (R - Y) / (1 - Kr)
        Y = Y * (Y_max - Y_min) + Y_min
        Cb = Cb * (C_max - C_min)
        Cr = Cr * (C_max - C_min)
        Cb = Cb + (C_max + C_min) / 2
        Cr = Cr + (C_max + C_min) / 2
        return Y, Cb, Cr
    end
    local function YCbCr_to_RGB2020(Y, Cb, Cr)
        local Kr, Kb = 0.2627, 0.0593 -- BT709
        local Y_min, Y_max, C_min, C_max = 16/255, 235/255, 16/255, 240/255

        Y = Y - Y_min
        Cb = Cb - (C_max + C_min) / 2
        Cr = Cr - (C_max + C_min) / 2
        Y = Y / (Y_max - Y_min)
        Cb = Cb / (C_max - C_min)
        Cr = Cr / (C_max - C_min)
        local R = Y + (2 - 2 * Kr) * Cr
        local B = Y + (2 - 2 * Kb) * Cb
        local G = (Y - Kr * R - Kb * B) / (1 - Kr - Kb)

        return R, G, B
    end
    local function oetf_inverse_PQ_BT2100(Y)
        local c1, c2, c3 = 107/128, 2413/128, 2392/128
        local m1, m2 = 1305/8192, 2523/32

        -- ST1884
        Vp = Y^(1/m2)
        Y = math.max(0, Vp - c1)
        Y = 10000 * (Y / (c2 - c3 * Vp))^(1/m1) / 100
        -- EOTF INVERSE BT1886
        Y = Y^(1/2.4)
        -- OETF INVERSE BT709
        if Y < 0.081 then
            Y = Y / 4.5
        else
            Y = ((Y + 0.099) / 1.099)^(1/0.45)
        end
        return Y / 59.5208
    end
    local function RGB2020_to_sRGB(r, g, b)
        local mat = {
            { 1.66030349, -0.58757014, -0.07289006},
            {-0.12437560,  1.13283448, -0.00835974},
            {-0.01811228, -0.10058361,  1.11877033},
        }
        r = mat[1][1]*r + mat[1][2]*g + mat[1][3]*b
        g = mat[2][1]*r + mat[2][2]*g + mat[2][3]*b
        b = mat[3][1]*r + mat[3][2]*g + mat[3][3]*b
        return r, g, b
    end
    local function eotf_inverse_sRGB(v)
        if v <= 0.0031308 then
            return v * 12.92
        else
            return 1.055 * v^(1/2.4) - 0.055
        end
    end
    local function color(c)
        local len = string.len(c)
        local a = ''
        if len == 8 then
            a = string.sub(c, 1, 2)
            c = string.sub(c, 3)
        elseif len == 6 then
        else
            return c
        end
        local b, g, r = c:match('(%x%x)(%x%x)(%x%x)')
        b = tonumber(b, 16)/255
        g = tonumber(g, 16)/255
        r = tonumber(r, 16)/255
        
        r, g, b = YCbCr_to_RGB2020(RGB709_to_YCbCr(r, g, b))
        r, g, b = putmask(r), putmask(g), putmask(b)

        if transferfunc == 'PQ' then
            r = oetf_inverse_PQ_BT2100(r)
            g = oetf_inverse_PQ_BT2100(g)
            b = oetf_inverse_PQ_BT2100(b)
        else
            r = oetf_inverse_PQ_BT2100(r)
            g = oetf_inverse_PQ_BT2100(g)
            b = oetf_inverse_PQ_BT2100(b)
        end
        r, g, b = r*params[1], g*params[1], b*params[1]
        r, g, b = putmask(r), putmask(g), putmask(b)

        r, g, b = RGB2020_to_sRGB(r, g, b)
        r, g, b = putmask(r), putmask(g), putmask(b)

        b = eotf_inverse_sRGB(b)
        g = eotf_inverse_sRGB(g)
        r = eotf_inverse_sRGB(r)

        r = round(r * 255)
        g = round(g * 255)
        b = round(b * 255)
        return string.format('&H%s%02X%02X%02X&', a, b, g, r)
    end

    -- count
    local N = #selected
    -- params
    local path = aegisub.decode_path('?user')..'\\ColorCalibration.txt'
    local file = io.open(path, 'r')
    transferfunc = nil
    params = {}
    if file ~= nil then
        transferfunc = file:read()
        table.insert(params, tonumber(file:read()))
        file:close()
    else
        transferfunc = 'PQ'
        params = {30}
    end 

    for si, li in ipairs(selected) do
        local line = subtitle[li]
        local linetext = line.text

        linetext = linetext:gsub('(\\[1234]?c)&?H?([%x]+)&?', function (pre, c)
            return pre .. color(c)
        end)
        linetext = linetext:gsub('(\\[1234]vc)%( *&?H?([%x]+)&? *, *&?H?([%x]+)&? *, *&?H?([%x]+)&? *, *&?H?([%x]+)&? *%)',
        function (pre, c1, c2, c3, c4)
            return string.format('%s(%s,%s,%s,%s)', pre, color(c1), color(c2), color(c3), color(c4))
        end)

        line.text = linetext
        subtitle[li] = line
        aegisub.progress.set(si/N * 100)
    end
    
    aegisub.set_undo_point(script_name) 
    return selected 
end

function macro_validation(subtitle, selected, active)
    return true
end

--This is what puts your automation in Aegisub's automation list
aegisub.register_macro(script_name..'/sdr2hdr', script_description, sdr2hdr, macro_validation)
aegisub.register_macro(script_name..'/hdr2sdr', script_description, hdr2sdr, macro_validation)
aegisub.register_macro(script_name..'/config', script_description, config, macro_validation)
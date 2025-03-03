local fonts = {}

function cl_PProtect.setFont(f, s, b, a, sh, sy)
    b, a, sh, sy = b or 500, a or false, sh or false, sy or false
    local fstr = string.format('pprotect_%s_%d_%d_%s_%s', f, s, b, tostring(a):sub(1, 1), tostring(sh):sub(1, 1))

    if fonts[fstr] then
        return fstr
    end

    surface.CreateFont(fstr, {
        font = f,
        size = s,
        weight = b,
        antialias = a,
        shadow = sh,
        symbol = sy
    })

    fonts[fstr] = true

    return fstr
end

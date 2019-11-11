-- Foo bar

function do_naughty()
    local t={}
    for i=1,255 do
        for j=1,255 do
            t[string.format("%s%s%s%s%s", "Proof of ", string.char(i), "oncep", string.char(j), " that small changes get lost.")] = "world"
        end
    end
end

function do_nice()
    local t={}
    for i=1,255 do
        for j=1,255 do
            t[string.format("%s%s%s%s%s", "Proof of c", string.char(i), "n", string.char(j), "ept that small changes get lost.")] = "world"
        end
    end
end

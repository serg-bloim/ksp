CLEARSCREEN.
switch to 0.
local dir is "bin".
local max_files is 0.
local files is OPEN(dir):LIST:VALUES.
local selected is 0.
declare function select{
    declare parameter i.
    set i to mod(i, max_files).
    if i < 0 {
        set i to i + max_files.
    }
    print " " at (0, selected).
    print ">" at (0, i).
    set selected to i.
}
declare function print_files{
    CLEARSCREEN.
    set max_files to 0.
    for f in files{
        print " - " + (max_files+1) + ") " + f:NAME.
        set max_files to max_files + 1.
    }
    select(selected).
}
print_files.
local in is terminal:input.
until 0 {
    until not in:haschar {
        local ch to in:getchar.
        local num is ch:TONUMBER(-1).
        if num >= 0 and num <= max_files {
            if num = 0 {
                set num to 10.
            }
            select(num - 1).
        } else if ch = in:UPCURSORONE {
            select(selected-1).
        } else if ch = in:DOWNCURSORONE{
            select(selected+1).
        } else if ch = in:ENTER{
            RUNPATH(dir + "/" + files[selected]:NAME).
            print_files.
        }
    }
}
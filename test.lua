--[[
    Execute tests from directory.
    * It will search for the directory, looking for all functions withing module named *Test.lua.
    * For all test executed, if it fails, report. If no error is detected, print passed.

    test [test_arg]
]]

-- Lua libraries.
local lfs = require("lfs")

-- Project libraries.
local log = require("lib.log")
local argparse = require("lib.argparse")


--[[
    Usage: test.lua [-h] <input> [<input>] ...

    Execute *Test functions inside file or folder.

    Arguments:
    input                 A File or Directory defining *Test functions to test.

    Options:
    -h, --help            Show this help message and exit.
]]

local parser = argparse()
    :name "test.lua"
    :description "Execute *Test functions inside file or folder."
parser:argument("input", "A File or Directory defining *Test functions to test.")
    :args "+"

local args = parser:parse()
local inputs = args.input


-- Testing functions.
function testfile(file)
end

function testdir(dir)
end


-- Script execution.
for i = 1, #inputs do
    input_mode = lfs.attributes(inputs[i], "mode")
    if input_mode == "directory" then
        testdir(inputs[i])
    elseif input_mode == "file" then
        testfile(inputs[i])
    else
        log("error", string.format("'%s' not a folder nor file.", inputs[i]))
    end
end

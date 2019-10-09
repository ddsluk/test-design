--[[***************************
 * Copyright (c) 2011, 2012 Fundação CERTI.
 * All rights reserved.
 ***********************]]--

require("OutputAdapter")

TestUtils = {}
TestUtils.expectFailMsg = 'Expect failed!'
TestUtils.assertFailMsg = 'Assertion failed!'
--TestUtils.UNIT_TESTING = false

function TestUtils.fromWhereWasICalled()
	local lvl = 5
	if TestUtils.UNIT_TESTING then lvl = 6 end
	local _, m = pcall(function () error('wrong error', lvl) end)
	--print('\n', m)
	--print(debug.traceback())
	local _, b = TestUtils.getErrorInfo(m)
	return b
end

function TestUtils.incrementAssertCount()
	if (TestRunner and TestRunner.currentAssertCount) then
		TestRunner.currentAssertCount = TestRunner.currentAssertCount + 1
	end
end

function getCurrentTable()
        local fenv = getfenv(2)
        local fname = ""
        for k, v in pairs(_G) do
                if (v == fenv) then
                        fname = k
                end
        end
        --print("Current Table: ", fname)
        return fname
end

function TestUtils.getErrorInfo(param)
	local fname, lnumber, msg = string.match(param, "(.+):(%d+):(.*)")
	--[[
	print("\n***************************************************")
	print("***************************************************")
	print(fname, lnumber, msg)
	print("***************************************************")
	print("***************************************************")
	--]]
	return fname, lnumber, msg
end

--- Verify if the first parameter is true, and does not stop the execution of the test file if it fails.
-- If the first parameter is not true ,or cannot be considered 'true' under Lua type conversion rules, this assertion fails and the message passed as second parameter is sent to the test runner as a fail message.
-- @param bool The parameter to be checked (expected to be true)
-- @param msg The message to be sent as a fail message. 

function expectTrue(bool, msg)
	assert(OutputAdapter, "OutputAdapter not found!")
	TestUtils.incrementAssertCount()
	if (not bool) then
		if (not msg) then
			msg = TestUtils.expectFailMsg
		end
		local a = TestUtils.fromWhereWasICalled()
		OutputAdapter.signalFail({type='expect', line=a, msgs={tostring(msg)}})
	end
end

--- Verify if the first parameter is false, and does not stop the execution of the test file if it fails.
-- If the first parameter is not false ,or cannot be considered 'false' under Lua type conversion rules, this assertion fails and the message passed as second parameter is sent to the test runner as a fail message.
-- @param bool The parameter to be checked (expected to be false)
-- @param msg The message to be sent as a fail message.

function expectFalse(bool, msg)
	assert(OutputAdapter, "OutputAdapter not found!")
	TestUtils.incrementAssertCount()
	if (bool) then
		if (not msg) then
			msg = TestUtils.expectFailMsg
		end
		local a = TestUtils.fromWhereWasICalled()
		OutputAdapter.signalFail({type='expect', line=a, msgs={tostring(msg)}})
	end
end

--- Verify if the first and second parameters are equal, and does not stop the execution of the test file if it fails.
-- If the first parameter is not equal to the second, this assertion fails and the message passed as third parameter is sent to the test runner as a fail message.
-- @param p1 The first parameter to be tested for equality
-- @param p2 The second parameter to be tested for equality
-- @param msg The message to be sent as a fail message.

function expectEqual(p1, p2, msg)
	assert(OutputAdapter, "OutputAdapter not found!")
	TestUtils.incrementAssertCount()
	if (p1 ~= p2) then
		if (not msg) then
			msg = TestUtils.expectFailMsg
		end
		local a = TestUtils.fromWhereWasICalled()
		OutputAdapter.signalFailCompare({type='expect', line=a, expected=p2, was=p1, msgs={tostring(msg)}})
	end
end

--- Verify if the first parameter is true, and stops the execution of the test file if it fails.
-- If the first parameter is not true ,or cannot be considered 'true' under Lua type conversion rules, this assertion fails and the message passed as second parameter is sent to the test runner as a fail message. This assertion stops the execution of the test file when it fails.
-- @param bool The parameter to be checked (expected to be true)
-- @param msg The message to be sent as a fail message. 

function assertTrue(bool, msg)
	assert(OutputAdapter, "OutputAdapter not found!")
	TestUtils.incrementAssertCount()
	if (not bool) then
		if (not msg) then
			msg = TestUtils.assertFailMsg
		end
		local a = TestUtils.fromWhereWasICalled()
		
		OutputAdapter.signalFail({type='assert', line=a, msgs={tostring(msg)}})
		error(TestUtils.assertFailMsg, 3)
	end
end

--- Verify if the first parameter is false, and stops the execution of the test file if it fails.
-- If the first parameter is not false ,or cannot be considered 'false' under Lua type conversion rules, this assertion fails and the message passed as second parameter is sent to the test runner as a fail message. This assertion stops the execution of the test file when it fails.
-- @param bool The parameter to be checked (expected to be false)
-- @param msg The message to be sent as a fail message.

function assertFalse(bool, msg)
	assert(OutputAdapter, "OutputAdapter not found!")
	TestUtils.incrementAssertCount()
	if (bool) then
		if (not msg) then
			msg = TestUtils.assertFailMsg
		end
		local a = TestUtils.fromWhereWasICalled()
		
		OutputAdapter.signalFail({type='assert', line=a, msgs={tostring(msg)}})
		error(TestUtils.assertFailMsg, 3)
	end
end

--- Verify if the first and second parameters are equal, and stops the execution of the test file if it fails.
-- If the first parameter is not equal to the second, this assertion fails and the message passed as third parameter is sent to the test runner as a fail message. This assertion stops the execution of the test file when it fails.
-- @param p1 The first parameter to be tested for equality
-- @param p2 The second parameter to be tested for equality
-- @param msg The message to be sent as a fail message.

function assertEqual(p1, p2, msg)
	assert(OutputAdapter, "OutputAdapter not found!")
	TestUtils.incrementAssertCount()
	if (p1 ~= p2) then
		if (not msg) then
			msg = TestUtils.assertFailMsg
		end
		local a = TestUtils.fromWhereWasICalled()
		OutputAdapter.signalFailCompare({type='assert', line=a, expected=p1, was=p2, msgs={tostring(msg)}})
		error(TestUtils.assertFailMsg, 3)
	end
end

--- Fails a test, and does not stop the execution of the test file if it fails.
-- This function explicitly fails a test, with the parameter passed sent to the test runner as a fail message.
-- @param msg The message to be sent as a fail message.

function fail(msg)
	assert(OutputAdapter, "OutputAdapter not found!")
	TestUtils.incrementAssertCount()
	if (not msg) then
		msg = TestUtils.expectFailMsg
	end
	local a = TestUtils.fromWhereWasICalled()
	OutputAdapter.signalFail({type='expect', line=a, msgs={tostring(msg)}})
end

--- Validates that a pixel is of a specific color, and does not stop the execution of the test file.
-- This function receives as a parameter the coordinates of a pixel in the screen and compares the color of that pixel, as obtained using the method canvas:pixel(), with the color value passed as a parameter to the function.
-- If it fails, the text passed as the fourth parameter is sent to the test runner as a fail message.
-- Optionally, a debug flag, the fifth parameter, may be set to true, which will cause a small square to be drawn around the pixel, to aid in visually verifying which pixel is being tested.
-- Optionally, an off-screen canvas may be tested, and this canvas is passed as a sixth parameter. If it is not passed, the main canvas is tested.
-- @param x is the horizontal coordinate of the pixel to test
-- @param y is the vertical coordinate of the pixel to test
-- @param rgbaStr is the pixel expected color, in the format '0xaabbccdd'
-- @param rationale (optional) is a fail message when the verification fails e.g. 'point is outside the clip area'
-- @param debug (optional), if true will draw a small square around the tested pixel
-- @param tgtCanvas (optional) is the canvas from where the pixel will be grabbed, or the main canvas if not informed

function assertPixel(x, y, rgbaStr, rationale, debug, tgtCanvas)
	if (not tgtCanvas) then
		tgtCanvas = canvas
	end
   	local r, g, b, a = tgtCanvas:pixel(x, y)
   	local color = ((((r*256+g)*256)+b)*256)+a
   	expectTrue(color == tonumber(rgbaStr), " The pixel in "..x..","..y.." should be "..
   		rgbaStr.." but was 0x"..string.format("%x", color)..": "..rationale)
   	r, g, b, a = tgtCanvas:attrColor()
   	if (debug) then
	   	tgtCanvas:attrColor('black')
	   	tgtCanvas:drawRect('frame', x-2, y-2, 5, 5)
	   	tgtCanvas:attrColor('gray')
	   	tgtCanvas:drawRect('frame', x-3, y-3, 7, 7)
	   	tgtCanvas:attrColor(r, g, b, a)
	   	tgtCanvas:flush()
   	end
end

--- Validates that a pixel is of a specific color, and does not stop the execution of the test file.
-- This function receives as parameters the coordinates of the pixel in the screen, or in an offscreen canvas, and compares the color of that pixel with the expected Red, Green, Blue and Alpha components, passed as parameters.
-- If it fails, the text passed as the senventh parameter is sent to the test runner as a fail message.
-- @param x is the horizontal coordinate of the pixel to test
-- @param y is the vertical coordinate of the pixel to test
-- @param red is the red component of the expected color
-- @param green is the green component of the expected color
-- @param blue is the blue component of the expected color
-- @param alpha is the alpha component of the expected color
-- @param msg is a fail message when the verification fails e.g. 'point is outside the clip area'
-- @param tgtCanvas (optional) is the canvas from where the pixel will be grabbed, or the main canvas if not informed

function assertRGBAPixel(x, y, red, green, blue, alpha, msg, tgtCanvas)
	if (not tgtCanvas) then
		tgtCanvas = canvas
	end
   	local r, g, b, a = tgtCanvas:pixel(x, y)
   	expectEqual(r, red, ' RED component at ' .. x .. ', '.. y .. msg)
   	expectEqual(g, green, ' GREEN component at ' .. x .. ', '.. y .. msg)
   	expectEqual(b, blue, ' BLUE component at ' .. x .. ', '.. y .. msg)
   	expectEqual(a, alpha, ' ALPHA component at ' .. x .. ', '.. y .. msg)   	
end

---Validates that exists a pixel of a specific color in a specific area.
-- This function receives as parameters the coordinates and the dimensions of the area in the screen, or in an offscreen canvas, and compares the color of each pixel of the area with the expected Red, Green, Blue and Alpha components, passed as parameters.
-- If it fails, the text passed as msg parameter is sent to the test runner as a fail message.
-- @param x is the horizontal coordinate of the area
-- @param y is the vertical coordinate of the area
-- @param height is the area height
-- @param width is the area width
-- @param red is the red component of the expected color
-- @param green is the green component of the expected color
-- @param blue is the blue component of the expected color
-- @param alpha is the alpha component of the expected color
-- @param msg is a fail message when the verification fails e.g. 'point is outside the clip area'
-- @param tgtCanvas (optional) is the canvas from where the pixel will be grabbed, or the main canvas if not informed

function assertRegionHasColor(x, y, height, width, red, green, blue, alpha, msg, tgtCanvas)
	if (not tgtCanvas) then
		tgtCanvas = canvas
	end
	local pixelExists = false
	for py = y, height+y, 1 do
		for px = x, width+x, 1 do
			local r, g, b, a = tgtCanvas:pixel(px, py)
			if (r == red and g == green and b == blue and a == alpha) then 
				pixelExists = true
				px = width+x+1
				py = height+y+1
			end
		end
	end	
	expectTrue(pixelExists, msg)
end

---Validates that not exists a pixel of a specific color in a specific area.
-- This function receives as parameters the coordinates and the dimensions of the area in the screen, or in an offscreen canvas, and compares the color of each pixel of the area with the not expected Red, Green, Blue and Alpha components, passed as parameters.
-- If it fails, the text passed as msg parameter is sent to the test runner as a fail message.
-- @param x is the horizontal coordinate of the area
-- @param y is the vertical coordinate of the area
-- @param height is the area height
-- @param width is the area width
-- @param red is the red component of the unexpected color
-- @param green is the green component of the unexpected color
-- @param blue is the blue component of the unexpected color
-- @param alpha is the alpha component of the unexpected color
-- @param msg is a fail message when the verification fails e.g. 'point is inside the clip area'
-- @param tgtCanvas (optional) is the canvas from where the pixel will be grabbed, or the main canvas if not informed

function assertRegionDoesntHaveColor(x, y, height, width, red, green, blue, alpha, msg, tgtCanvas)
	if (not tgtCanvas) then
		tgtCanvas = canvas
	end
	local pixelExists = false
	for py = y, height+y, 1 do
		for px = x, width+x, 1 do
			local r, g, b, a = tgtCanvas:pixel(px, py)
			if (r==red and g==green and b==blue and a==alpha) then 
				pixelExists = true
				px = width+x+1
				py = height+y+1
			end
		end
	end	
	expectFalse(pixelExists, msg)
end

---Splits a string into subtrings depending on the token and store the substrings in a table
-- This function receives as parameters the original string and the token that will be used to split this string
-- If the string does not have the token, then an empty table is returned.
-- @param value is the original string
-- @param token is the token that is going to be used to split the string contained in value parameter

function split(value, token)
	local function occurences(value, token)
		number = 0
		for c in string.gmatch(value,".") do
			if c == token then
				number = number +1
			end
		end
		return number
	end
	
	local values = {}
	local times = occurences(value,token)
	if times == 0 then
		return {}
	end
	
	for i = 1,times do
		pos = string.find(value, ",")
		if(pos) then
			table.insert(values, string.sub(value, 0, pos-1))
			value = string.sub(value,pos+1, string.len(value))
		end
	end
	if string.len(value)> 0 then
		table.insert(values, value)
	end
	return values
end


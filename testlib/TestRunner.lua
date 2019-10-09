--[[***************************
 * Copyright (c) 2011, 2012 Fundação CERTI.
 * All rights reserved.
 ***********************]]--

require("TestUtils")

TestRunner = {}

TestRunner.okCode = 'OK'
TestRunner.failCode = 'FAIL'
TestRunner.pendingCode = 'PENDING'
TestRunner.currentStatus = 'OK'
TestRunner.currentStMessage = 'All tests passed'
TestRunner.currentTestHandlers = {}
TestRunner.currentTestFunctions = {}
TestRunner.currentFunctionPosition = 0
TestRunner.currentAssertCount = 0

function TestRunner.getInstance()
	return TestRunner
end

function TestRunner.init()
	--print('IN INIT')
	TestRunner.testList = {}
	TestRunner.currentTestHandlers = {}
	TestRunner.currentTestFunctions = {}
	TestRunner.currentFunctionPosition = 0
	TestRunner.currentAssertCount = 0
	TestRunner.currentStatus = 'OK'
	TestRunner.currentTestClasses = {}
	event.register(TestRunner.mainHandler)
	--print('LEAVING INIT')
end

function TestRunner.registerHandler(func)
	event.register(func)
end

function TestRunner.loadTestFiles()
	--print('settings.testFile: ', settings.testFile)
	if (settings and settings.testFile) then
		for w in string.gmatch(settings.testFile, '([%.%/%w]+)%;*') do
			local res, msg = pcall(dofile, w)
			if (not res) then
				print('LUA ERROR: ', msg)
			else
				local testClass = string.match(w, '%/*(%w+)%.')
				for k, v in pairs(_G) do
					if (k == testClass and type(v) == 'table') then
						table.insert(TestRunner.currentTestClasses, v)
					end
				end
			end
		end
	end
end

function TestRunner.runTests()
	TestRunner.loadTestFiles()
	if (#TestRunner.testList > 0) then
		--TestRunner.testList[1].run()
		for k, v in ipairs(TestRunner.testList) do
			TestRunner.beginTime = event.uptime()
			OutputAdapter.signalInit(v)
			OutputAdapter.signalBeginVerifications()
			local result, msg = pcall(v.run)
			if ( not result) then
				TestRunner.processError(msg)
			end
			TestRunner.checkStatus()
			OutputAdapter.signalEndVerifications()
			OutputAdapter.signalStatus(TestRunner.currentStatus, TestRunner.currentStMessage)
			local time0 = TestRunner.beginTime or 0
			OutputAdapter.signalEnd(event.uptime() - time0)
			TestRunner.resetStatus()
		end
	end
	OutputAdapter.signalFinish()
end

function TestRunner.executeNextTest()
	if TestRunner.testList[1] then
		TestRunner.runningTest = table.remove(TestRunner.testList, 1)
		if TestRunner.runningTest then
			TestRunner.beginTime = event.uptime()
			OutputAdapter.signalInit(TestRunner.runningTest)
			OutputAdapter.signalBeginVerifications()
			local res, msg = pcall(TestRunner.runningTest.run)
			if (not res) then
				TestRunner.processError(msg)
			end
		end
	elseif TestRunner.currentTestClasses[1] then
		TestRunner.runningTest = table.remove(TestRunner.currentTestClasses, 1)
		local hasRunMethod = false
		local testsToRun = {}
		local testsToSchedule = {}
		for k, v in pairs(TestRunner.runningTest) do
			if (type(v) == 'function' and string.sub(k, 1, 4) == 'test') then
				table.insert(testsToRun, v)
			elseif (type(v) == 'function' and string.sub(k, 1, 8) == 'schedule') then
				table.insert(testsToSchedule, v)
			end
		end
		if (#testsToRun == 0 and #testsToSchedule == 0) then
			event.post('in', { class = 'user', type = 'endAllTests' })
			return
		end
		TestRunner.beginTime = event.uptime()
		OutputAdapter.signalInit(TestRunner.runningTest)
		OutputAdapter.signalBeginVerifications()
		for i = 1, #testsToRun do
		--	local res, msg = pcall(v)
			local res, msg = pcall(table.remove(testsToRun))
			if (not res) then
				TestRunner.processError(msg)
				return
			end
		end
		if (#testsToSchedule > 0) then
			for i = 1, #testsToSchedule do
				TestRunner.scheduleTestFunction(table.remove(testsToSchedule))
			end
			TestRunner.nextTestFunction()
		else
			TestRunner.testFinished()
		end
	else
		event.post('in', { class = 'user', type = 'endAllTests' })
	end
end

function TestRunner.proceedToNextTest()
	OutputAdapter.signalEndVerifications()
	TestRunner.checkStatus()
	OutputAdapter.signalStatus(TestRunner.currentStatus, TestRunner.currentStMessage)
	local time0 = TestRunner.beginTime or 0
	OutputAdapter.signalEnd(event.uptime() - time0)
	TestRunner.resetStatus()
	event.post('in', { class = 'user', type = 'runTests' })
end

function TestRunner.registerTest(tst)
	table.insert(TestRunner.testList, tst)
end


function TestRunner.clearTests()
	TestRunner.testList = {}
end

function TestRunner.resetStatus()
	TestRunner.currentStatus = TestRunner.okCode
	TestRunner.currentStMessage = 'All tests passed'
	TestRunner.currentTestHandlers = {}
end

function TestRunner.checkStatus()
	if (TestRunner.currentAssertCount < 1 and TestRunner.currentStatus ~= TestRunner.failCode) then
		TestRunner.currentStatus = TestRunner.failCode
		TestRunner.currentStMessage = 'No assert method was called'
	end
end

function TestRunner.unregisterTest(tst)
	for k, v in pairs(TestRunner.testList) do
		if (v == tst) then
			table.remove(TestRunner.testList, k)
		end
	end
end

function TestRunner.mainHandler(evt)
	if evt.class == 'ncl' then
		if evt.type == 'presentation' then
			if evt.action == 'start' then
				if (not evt.label or evt.label == '') then
					event.post('in', { class = 'user', type = 'registerTest' })
					OutputAdapter.signalBeginEverything()
				end
			end
		end
	elseif evt.class == 'user' then
		if evt.type == 'registerTest' then
			TestRunner.loadTestFiles()
			event.post('in', { class = 'user', type = 'runTests' })
		elseif evt.type == 'runTests' then
			TestRunner.executeNextTest()
		elseif evt.type == 'testFinished' then
			--event.post('in', { class = 'user', type = 'runTests' })
			TestRunner.proceedToNextTest()
		elseif evt.type == 'endAllTests' then
			OutputAdapter.signalFinish()
		end
	end
	if (#TestRunner.currentTestHandlers > 0) then
		for k, v in ipairs(TestRunner.currentTestHandlers) do
			local r, msg = pcall(v, evt)
			if (not r) then
				TestRunner.processError(msg)
			end
		end
	end
end

function TestRunner.testFinished()
	event.post('in', { class = 'user', type = 'testFinished' })
end

--- Registers a test handler, a function to be called for every received event.
-- This function will be added to the test handler list.
-- The test handler will be called using pcall(), so that any errors that may happen in this function will not crash the Lua player and simply fail the test.
-- All events received by the test agent will be passed to all event handlers registered using this mechanism. Any filtering must be made in the event handler.
-- @param func The function that will be called for every event received.

function TestRunner.registerTestHandler(func)
	table.insert(TestRunner.currentTestHandlers, func)
end

--- Removes a function that was to be called for every received event.
-- If the parameter provided in func is a function that was previously registered as a test handler, the function will be removed from the list and will no longer be called when an event is received.
-- If the parameter is not a previously registered test handler, nothing happens.
-- @param func The function that will be removed from the event handler list.

function TestRunner.deregisterTestHandler(func)
	for k, v in ipairs(TestRunner.currentTestHandlers) do
		if v == func then
			table.remove(TestRunner.currentTestHandlers, k)
		end
	end
end

--- Schedules a function to be run at a later time, in protected mode.
-- This function schedules a timer (using event.timer()) after which the provided function (func) will be called, in protected mode (using pcall()), to protect the Lua player from any errors that may occur.
-- @param time The time, in milisseconds, to wait until the function in run.
-- @param func The function that will be run after the specified time.

function TestRunner.testTimer(time, func)
	event.timer(time, function()
				local r, msg = pcall(func)
				if (not r) then
					TestRunner.processError(msg)
				end
			end)
end

--- Sends a command to take a picture of the screen to the ATE test runner.
-- This function sends a command to the ATE test runner that causes it to take a picture of the TV screen.
-- The caption provided is used to help the ATE user to interpret the picture, to help determine if the test was successful.
-- Providing the callback function permits the test flow to continue after the picure is taken, being given sufficient time for the ATE to take the picture.
-- If the callback is not provided, the function will return immediately and any wait and synchronization must be done by the test itself.
-- Note that the process of taking a picture of the screen is not instantaneous after calling this function.
-- The command sent to the ATE has to be processed and the camera hardware and the image capture software need some time to record the image.
-- Taking a picture of the screen sets the status of the test to PENDING, except when the test fails or an error occurs.
-- @param caption A text that is shown in the GUI near the picture.
-- @param callback (optional) A Lua function that is called after the command is sent to the ATE test runner.

function TestRunner.snapshot(caption, callback)
	if (callback) then
		TestRunner.testTimer(4000, callback)
	end
	OutputAdapter.signalSnapshot(caption)
	TestRunner.setPending()
end

function TestRunner.setPending()
	TestRunner.currentStatus = TestRunner.pendingCode
	TestRunner.currentStMessage = 'There is pending test'
end

--- Sends to the test runner a command to generate a remote control signal to the TV.
-- This function sends a command to the test runner to use the infrared transmitter of the ATE to send remote control key signals to the TV.
-- The function returns immediately, but the effect is not instantaneously, since the ATE must receive the command and the IR transmitter must generate the correct code.
-- @param key A string representing the remote control key signal to be generated. Must be one of the following strings: KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0,
-- BACK, NAV_UP, NAV_LEFT, NAV_RIGHT, NAV_DOWN, KEY_RED, KEY_GREEN, KEY_YELLOW, KEY_BLUE, VOLUME_UP, ENTER, EXIT

function TestRunner.rc(key)
	OutputAdapter.signalRC(key)
end

--- Sets the NCL property identified by prop to the value val.
-- This function attributes to the property (of the Lua player running the test agent - TestRunner.lua) whose name is provided in the parameter prop, the value provided in the parameter val.
-- The event.post() function is called with an NCL attribution event, with the action set to start, and right after it event.post() is called again, for an NCL attribution event with the action set to stop.
-- Both events have the value set to val.
-- @param prop The name of the property to be set (this property must exist in the NCL media element that refers to the Lua player running the test agent)
-- @param val The value to set the property to.  

function TestRunner.setNCLProperty(prop, val)
	local e1 = { class = 'ncl', type = 'attribution', action = 'start', name = prop, value = val }
	event.post(e1)
	local e2 = { class = 'ncl', type = 'attribution', action = 'stop', name = prop, value = val }
	event.post(e2)
end

function TestRunner.scheduleTestFunction(f)
	table.insert(TestRunner.currentTestFunctions, f)
end

--- Ends the current test case and makes the Lua agent run the next scheduled test case or ends the tests.
-- This function is used to signal to the test agent that the current test has ended, when the test case is of the type schedule*().
-- In this case, the test agent will not proceed to the next test when the scedule*() function returns.
-- Instead, it will assume that the test is waiting for NCL events, or timer events, or for any other event or transition either in NCL or in the Lua player.
-- This allows for test cases to be run assynchronously with NCL and other events and state machines.
-- When the test case is over, the last call of the test is a call to TestRunner.nextTestFunction().
-- This call ends the test case and causes the agent to run the next schedule*() test function.
-- If no such function exists, the test suite (the test file) will end.
-- If this function is never called in a schedule*() type test case, the test agent will not end the test and proceed to the next, causing the test to finish with a timeout error.

function TestRunner.nextTestFunction()
	TestRunner.currentFunctionPosition = TestRunner.currentFunctionPosition + 1
	if (TestRunner.currentTestFunctions[TestRunner.currentFunctionPosition]) then
		local res, msg = pcall(TestRunner.currentTestFunctions[TestRunner.currentFunctionPosition])
		if (not res) then
			TestRunner.processError(msg)
		end
	else
		TestRunner.testFinished()
	end
end

function TestRunner.processError(msg)
	print('LUA: ', msg)
	event.post('in', { class = 'user', type = 'testFinished' })
	if (TestRunner.currentStatus == TestRunner.okCode) then
		TestRunner.currentStatus = TestRunner.failCode
		TestRunner.currentStMessage = 'An error occurred during the test'
	end
end

--- Sends a command to the test runner to begin recording video.
-- This function sends a command to the ATE to start recording video.
-- The function returns immediately, but the command takes some time to be received by the ATE test runner and to actually start recording video.
-- The video will be recorded until stopped by a call to TestRunner.stopVideo() or a timeout is triggered.
-- Calling this function causes the test status to be set to PENDING, unless the test fails or an error occurs.
-- @param caption The text that will be used as a caption, to help the user of the ATE to interpret the video as a test result.
-- @see TestRunner.stopVideo()

function TestRunner.startVideo(caption)
	print('*****   Starting video recording   *****')
	OutputAdapter.signalStartVideo(caption)
	TestRunner.setPending()
end

--- Sends a command to the test runner to stop a video recording.
-- This function sends a command to the ATE test runner to stop video recording.
-- The function returns immediately, but the ATE will take some time to receive and process the command.
-- If this function is not called the ATE will keep recording a video until a timeout occurs.
-- @see TestRunner.startVideo()

function TestRunner.stopVideo()
	print('*****   Stoping video recording   *****')
	OutputAdapter.signalStopVideo()
end

--- Sends a command to the test runner to begin recording audio.
-- This function sends a command to the ATE to start recording audio.
-- The function returns immediately, but the command takes some time to be received by the ATE test runner and to actually start recording audio.
-- The video will be recorded until stopped by a call to TestRunner.stopAudio() or a timeout is triggered.
-- Calling this function causes the test status to be set to PENDING, unless the test fails or an error occurs.
-- @param caption The text that will be used as a caption, to help the user of the ATE to interpret the audio as a test result.
-- @see TestRunner.stopAudio()

function TestRunner.startAudio(caption)
	print('*****   Starting audio recording   *****')
    OutputAdapter.signalStartAudio(caption)
    TestRunner.setPending()
end

--- Sends a command to the test runner to stop an audio recording.
-- This function sends a command to the ATE test runner to stop audio recording.
-- The function returns immediately, but the ATE will take some time to receive and process the command.
-- If this function is not called the ATE will keep recording audio until a timeout occurs.
-- @see TestRunner.startAudio()

function TestRunner.stopAudio()
	print('*****   Stoping audio recording   *****')
	OutputAdapter.signalStopAudio()
end

TestRunner.init()

--TestRunner.runTests()

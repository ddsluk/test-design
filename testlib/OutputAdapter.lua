--[[***************************
 * Copyright (c) 2011, 2012 Fundação CERTI.
 * All rights reserved.
 ***********************]]--

OutputAdapter = {}

OutputAdapter.SEPARATOR = ""
OutputAdapter.LINESTART = "#ATE#"
OutputAdapter.LINEEND = "#ETA#"
OutputAdapter.ENDTEST = "#$ATE_END$#"

function OutputAdapter.write(...)
	line = table.concat(arg)
	length = string.len(line)
	checksum = "$C" .. CRC(line, length) .. "C$"

	print(OutputAdapter.LINESTART .. checksum .. table.concat(arg) .. OutputAdapter.LINEEND)
	print(OutputAdapter.LINESTART .. checksum .. table.concat(arg) .. OutputAdapter.LINEEND)

	if (io ~= nil and io.flush ~= nil and type(io.flush) == 'function') then
		io.flush()
	end
end

function OutputAdapter.setStatusToFail(par)
	if (TestRunner) then
		TestRunner.currentStatus = 'FAIL'
		if par == 'assert' then
			TestRunner.currentStMessage = 'Assertions have failed'
		elseif par == 'expect' then
			TestRunner.currentStMessage = 'Expect have failed'
		end
	end
end

function OutputAdapter.signalFail(param)
	local fline = param.line or ""
	OutputAdapter.write('<verification type="', param.type, '" line="', fline, '" message="', table.concat(param.msgs), '"/>')
	OutputAdapter.setStatusToFail(param.type)
end

function OutputAdapter.signalFailCompare(param)
	local fline = param.line or ""
	OutputAdapter.write('<verification type="', param.type, '" line="', fline, '" message="', param.msgs[1], ' Expected ', tostring(param.expected), ', was ', tostring(param.was), '. ', table.concat(param.msgs, "", 2), '"/>') 
	OutputAdapter.setStatusToFail(param.type)
end

OutputAdapter.currentTestName = ""
function OutputAdapter.signalInit(testCase)
	if (testCase and type(testCase) == 'table') then
		if testCase.name then
			OutputAdapter.currentTestName = tostring(testCase.name)
		else
			OutputAdapter.currentTestName = OutputAdapter.getThisTable(testCase)
		end
	else
		OutputAdapter.currentTestName = OutputAdapter.getCurrentTable()
	end
	
	OutputAdapter.write("<test>")
	OutputAdapter.write("<id>", os.time(), "</id>")
	OutputAdapter.write("<name>", tostring(OutputAdapter.currentTestName), "</name>")
end

function OutputAdapter.signalBeginVerifications()
	OutputAdapter.write("<verifications>")
end

function OutputAdapter.signalEndVerifications()
	OutputAdapter.write("</verifications>")
end

function OutputAdapter.signalEnd(elapsedTime)
	OutputAdapter.write('<elapsedTime>', tostring(elapsedTime), '</elapsedTime>')
	OutputAdapter.write('</test>')
end

function OutputAdapter.signalFinish()
	OutputAdapter.write('</tests>')
	print(OutputAdapter.ENDTEST)
end

function OutputAdapter.signalStatus(status, msg)
	OutputAdapter.write('<status code="', status, '" message="', msg, '"/>')
end

snapCount = 0

function OutputAdapter.signalSnapshot(txt)
	snapCount = snapCount+1
	imgName = OutputAdapter.currentTestName..snapCount
	OutputAdapter.write('<adapter><cam><snapshot name="', imgName, '" caption="', txt , '"/></cam></adapter>')
	expectTrue(true)
end

function OutputAdapter.signalStartVideo(caption)
	snapCount = snapCount + 1
	OutputAdapter.write('<adapter><cam><video name="', OutputAdapter.currentTestName .. snapCount, '" caption="', caption, '">')
	expectTrue(true)
end

function OutputAdapter.signalStopVideo()
	OutputAdapter.write('</video></cam></adapter>')
end

function OutputAdapter.signalStartAudio(caption)
	snapCount = snapCount + 1
	OutputAdapter.write('<adapter><audio name="', OutputAdapter.currentTestName .. snapCount, '" caption="', caption, '">')
	expectTrue(true)
end

function OutputAdapter.signalStopAudio()
	OutputAdapter.write('</audio></adapter>')
end

function OutputAdapter.signalRC(txt)
	OutputAdapter.write('<adapter><rc><key name="', txt, '"/></rc></adapter>')
end

function OutputAdapter.signalBeginEverything()
	OutputAdapter.write('<tests>')
end

function OutputAdapter.getCurrentTable()
        local fenv = getfenv(3)
        local fname = ""
        for k, v in pairs(_G) do
                if (v == fenv) then
                        fname = k
                end
        end
	--print("")
	--print(debug.traceback())
        --print("Current Table: ", fname)
        return fname
end

function OutputAdapter.getThisTable(t)
	local fname = ""
	for k, v in pairs(_G) do
		if (v == t) then
			fname = k
		end
	end
	return fname
end

OR, XOR, AND = 1, 3, 4

function bitoper(a, b, oper)
   local r, m, s = 0, 2^52
   repeat
      s,a,b = a+b+m, a%m, b%m
      r,m = r + m*oper%(s-a-b), m/2
   until m < 1
   return r
end

function CRC(data, length)
    sum = 65535
    local d
    for i = 1, length do
        d = string.byte(data, i)
        sum = ByteCRC(sum, d)
    end
    return sum
end

function ByteCRC(sum, data)
    sum = bitoper(sum, data, XOR)
    for i = 0, 7 do  
    	if (bitoper(sum, 1, AND) == 0) then
          sum = rightShift(sum, 1)
        else
          sum = bitoper(rightShift(sum, 1), 0xA001, XOR)
        end
    end
    return sum
end

function rightShift(value,shift)
	return math.floor(value/2^shift)
end

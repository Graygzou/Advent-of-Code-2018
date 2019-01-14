  --#################################################################
--# @author: Grégoire Boiron                                      #
--# @date: 12/XX/2018                                             #
--#                                                               #
--# Template used for every main script for the day X of the AoC  #
--#################################################################

local P = {} -- packages

--#################################################################
-- Package settings
--#################################################################

if _REQUIREDNAME == nil then
  day19 = P
else
  _G[_REQUIREDNAME] = P
end

--#################################################################
-- Work needs to be here
--#################################################################

------------------------------------------------------------------------
--
------------------------------------------------------------------------
function applyArithmeticOpcode(registers, instruction, mode, opcodeFunction, args)
  local A = nil
  local B = nil
  if mode == 0 then
    -- Register mode
    A = tonumber(registers[tonumber(instruction[1])+1])
    B = tonumber(registers[tonumber(instruction[2])+1])
  elseif mode == 1 then
    -- Immediate mode
    A = tonumber(registers[tonumber(instruction[1])+1])
    B = tonumber(instruction[2])
  end
  --print("A = ", A)
  --print("B = ", B)
  registers[tonumber(instruction[3])+1] = opcodeFunction(A, B, args)
  return registers
end

------------------------------------------------------------------------
--
------------------------------------------------------------------------
function applyAssignmentOpcode(registers, instruction, mode)
  local A = nil
  if mode == 0 then
    -- Register mode
    A = tonumber(registers[tonumber(instruction[1])+1])
  elseif mode == 1 then
    -- Immediate mode
    A = tonumber(instruction[1])
  end
  --print("A = ", A)
  registers[tonumber(instruction[3])+1] = A
  return registers
end

------------------------------------------------------------------------
--
------------------------------------------------------------------------
function applyComparaisonOpcode(registers, instruction, mode, opcodeFunction)
  local A = nil
  local B = nil
  if mode == 0 then
    -- immediate/register mode
    A = tonumber(instruction[1])
    B = tonumber(registers[tonumber(instruction[2])+1])
  elseif mode == 1 then
    -- register/immediate mode
    A = tonumber(registers[tonumber(instruction[1])+1])
    B = tonumber(instruction[2])
  elseif mode == 2 then
    -- register/register mode
    A = tonumber(registers[tonumber(instruction[1])+1])
    B = tonumber(registers[tonumber(instruction[2])+1])
  end
  --print("A = ", A)
  --print("B = ", B)
  if opcodeFunction(A, B) then
    registers[tonumber(instruction[3])+1] = 1
  else
    registers[tonumber(instruction[3])+1] = 0
  end
  return registers
end

------------------------------------------------------------------------
-- partOne - function used for the part 1
-- Params:
--    - inputFile : file handler, input handle.
-- Return
--    the final result for the part 1.
------------------------------------------------------------------------
local function partOne (nbRegisters, inputFile)
  local registerBoundInstruction = nil
  local instructions = {}

  local functionsRef = {
    ["addr"]  = function(r, i) return applyArithmeticOpcode(r, i, 0, function (a, b) return a + b; end); end,                          -- addr
    ["addi"]  = function(r, i) return applyArithmeticOpcode(r, i, 1, function (a, b) return a + b; end); end,                          -- addi
    ["mulr"]  = function(r, i) return applyArithmeticOpcode(r, i, 0, function (a, b) return a * b; end); end,                          -- mulr
    ["muli"]  = function(r, i) return applyArithmeticOpcode(r, i, 1, function (a, b) return a * b; end); end,                          -- muli
    ["banr"]  = function(r, i) return applyArithmeticOpcode(r, i, 0, binaryOperation, {function (a, b) return bit32.band(a, b); end}); end,       -- banr
    ["bani"]  = function(r, i) return applyArithmeticOpcode(r, i, 1, binaryOperation, {function (a, b) return bit32.band(a, b); end}); end,       -- bani
    ["borr"]  = function(r, i) return applyArithmeticOpcode(r, i, 0, binaryOperation, {function (a, b) return bit32.bor(a, b); end}); end,       -- borr
    ["bori"]  = function(r, i) return applyArithmeticOpcode(r, i, 1, binaryOperation, {function (a, b) return bit32.bor(a, b); end}); end,       -- bori
    ["setr"]  = function(r, i) return applyAssignmentOpcode(r, i, 0); end,                                                             -- setr
    ["seti"] = function(r, i) return applyAssignmentOpcode(r, i, 1); end,                                                             -- seti
    ["gtir"] = function(r, i) return applyComparaisonOpcode(r, i, 0, function (a, b) return tonumber(a) > tonumber(b); end); end,     -- gtir
    ["gtri"] = function(r, i) return applyComparaisonOpcode(r, i, 1, function (a, b) return tonumber(a) > tonumber(b); end); end,     -- gtri
    ["gtrr"] = function(r, i) return applyComparaisonOpcode(r, i, 2, function (a, b) return tonumber(a) > tonumber(b); end); end,     -- gtrr
    ["eqir"] = function(r, i) return applyComparaisonOpcode(r, i, 0, function (a, b) return tonumber(a) == tonumber(b); end); end,    -- eqir
    ["eqri"] = function(r, i) return applyComparaisonOpcode(r, i, 1, function (a, b) return tonumber(a) == tonumber(b); end); end,    -- eqri
    ["eqrr"] = function(r, i) return applyComparaisonOpcode(r, i, 2, function (a, b) return tonumber(a) == tonumber(b); end); end,    -- eqrr
  }

  -- We consider there is at least one register
  local matchingString = "(%d+)"
  -- Construct the matchingString (depend on the number of registers)
  for nbReg = 2, nbRegisters do
    matchingString = matchingString .. ",*%s*(%d+)"
  end
  local fileLines = helper.saveLinesToArray(inputFile);

  -- Retrieve all instructions in order and seperate input/ output registers.
  for lineIndex = 1, #fileLines do
    if fileLines[lineIndex]:find("#ip") then
      registerBoundInstruction = string.match(fileLines[lineIndex], "%d")
    else
      local registersInput = {}
      local registersOutput = nil
      local nextInstructionPointer = nil

      local instruction = { string.match(fileLines[lineIndex], matchingString) }
      if fileLines[lineIndex]:find("setr") or fileLines[lineIndex]:find("seti") then
        registersInput = { instruction[1] }
        registersOutput = instruction[3]
      else
        registersInput = { instruction[1], instruction[2] }
        registersOutput = instruction[3]
      end

      table.insert(instructions, {
        ip = lineIndex-1,
        name = fileLines[lineIndex]:sub(1,4),
        instruct = instruction,
        input = registersInput,
        output = registersOutput,
      })
    end
  end

  print("instruc", registerBoundInstruction)

  for i = 1, #instructions do
    string = "#ip " .. instructions[i].ip .. " // "
    for j = 1, #instructions[i].input do
      string = string .. " " .. instructions[i].input[j]
    end
    string = string .. " // " .. instructions[i].output
    print(string)
  end

  -- Try to identify loop in the program
  local markedInstructions = {}
  local previousInstructionPointer = 1

  local currentInstructionPointer = previousInstructionPointer
  local registers = { 0, 0, 0, 0, 0, 0 }

  print(currentInstructionPointer)

  local stop = false
  while not stop do
    local debugString = ""

    -- Test
    print("here", currentInstructionPointer)
    print(instructions[currentInstructionPointer].ip)

    if not list.contains(markedInstructions, instructions[currentInstructionPointer].ip) then
      -- Marked the current instruction
      table.insert(markedInstructions, instructions[currentInstructionPointer].ip)
    else
      stop = true
    end

    debugString = debugString .. "["
    for reg = 1, #registers do
      debugString = debugString .. registers[reg] .. ", "
    end
    debugString = debugString .. "] "
    debugString = debugString .. instructions[currentInstructionPointer].name .. " "
    for reg = 1, #instructions[currentInstructionPointer].instruct do
      debugString = debugString .. instructions[currentInstructionPointer].instruct[reg] .. " "
    end

    -- Go the next instruction
    if tonumber(instructions[currentInstructionPointer].output) == tonumber(registerBoundInstruction) then
      -- Modify the register 0 => Identify a jump
      previousInstructionPointer = currentInstructionPointer

      -- Compute it
      print("Compute ", instructions[currentInstructionPointer].name)
      registers = functionsRef[instructions[currentInstructionPointer].name](registers, instructions[currentInstructionPointer].instruct)
    else
      -- normal execution = go to the next line
      -- just compute
      registers = functionsRef[instructions[currentInstructionPointer].name](registers, instructions[currentInstructionPointer].instruct)
    end

    debugString = debugString .. "["
    for reg = 1, #registers do
      debugString = debugString .. registers[reg] .. ", "
    end
    debugString = debugString .. "] "

    -- Move to the next instruction
    registers[tonumber(registerBoundInstruction)+1] = registers[tonumber(registerBoundInstruction)+1] + 1

    -- Update the index for the next instruction
    currentInstructionPointer = registers[tonumber(registerBoundInstruction)+1] + 1

    print("DEBUG : ", debugString)
  end

  print(previousInstructionPointer)
  print(currentInstructionPointer-1)

  for i =1, #markedInstructions do
    print(markedInstructions[i])
  end

  --[[
  local currentInstructionPointer = nil
  for lineIndex = 1, #fileLines do
    if fileLines[lineIndex]:find("#ip") then
      firstInstructionPointer = string.match(fileLines[lineIndex], "%d")
      currentInstructionPointer = firstInstructionPointer
    else
      local registers = { 0, 0, 0, 0, 0 }
      local registersInput = {}
      local registersOutput = nil
      local nextInstructionPointer = nil

      local instruction = { string.match(fileLines[lineIndex], matchingString) }
      if fileLines[lineIndex]:find("setr") or fileLines[lineIndex]:find("seti") then
        registersInput = { instruction[1] }
        registersOutput = instruction[3]
      else
        registersInput = { instruction[1], instruction[2] }
        registersOutput = instruction[3]
      end

      print("o",registersOutput)
      print("c",currentInstructionPointer)
      if tonumber(registersOutput) == tonumber(currentInstructionPointer) then
      --if tonumber(registersOutput) == i then
        -- Compute it
        print("Compute ", fileLines[lineIndex]:sub(1,4))
        finalRegisters = functionsRef[fileLines[lineIndex]:sub(1,4)](registers, instruction)

        for i = 1, #finalRegisters do
          print("yy", finalRegisters[i])
        end

        registers = finalRegisters
        nextInstructionPointer = finalRegisters[tonumber(currentInstructionPointer)+1]
        print(nextInstructionPointer)
      else
        nextInstructionPointer = currentInstructionPointer + 1
      end

      table.insert(instructions, {
        input = registersInput,
        output = registersOutput,
        instructPointeur = currentInstructionPointer,
        nextInstructPointeur = nextInstructionPointer,
        registers = registers,
      })
      currentInstructionPointer = nextInstructionPointer
    end
  end
  --]]


  -- TODO

  return 0;
end

------------------------------------------------------------------------
-- partTwo - function used for the part 2
-- Params:
--    - inputFile : file handler, input handle.
-- Return
--    the final result for the part 2.
------------------------------------------------------------------------
local function partTwo (inputFile)

  -- TODO

  return 0;
end


--#################################################################
-- Main - Main function
--#################################################################
function day19Main (filename)

  local nbRegisters = 3

  -- Read the input file and put it in a file handle
  local inputFile = assert(io.open(filename, "r"));

  local partOneResult = partOne(nbRegisters, inputFile)

  -- Reset the file handle position to the beginning to use it again
  inputFile:seek("set");

  local partTwoResult = partTwo(inputFile)

  -- Finally close the file
  inputFile:close();

  print("Result part one :", partOneResult);
  print("Result part two :", partTwoResult);

end

--#################################################################
-- Package end
--#################################################################

day19 = {
  day19Main = day19Main,
}

return day19

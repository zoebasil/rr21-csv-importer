local StudioService = game:GetService("StudioService")

local toolbar = plugin:CreateToolbar("RR21 CSV Importer")
local importButton = toolbar:CreateButton("importCsv", "Import CSV", "rbxassetid://6253836852", "Import CSV")

local Csv = require(script.Csv)
local Templates = require(script.Templates)

local stringStartColumn = 5

local function forEachString(rowValues, callback)
	for columnNum = stringStartColumn, #rowValues do
		callback(columnNum, rowValues[columnNum])
	end
end

importButton.Click:Connect(function()
	local result = StudioService:PromptImportFile({ "csv" })
	local csvSheet
	if typeof(result) == "table" then
		csvSheet = result[1]
	else
		csvSheet = result
	end

	local csvContent = csvSheet:GetBinaryContents()
	local f = Csv.openstring(csvContent)

	local numNames = 0
	local localeIds = {}
	local stringsByLocaleId = {}
	local stringChunks = {}
	local currentChunk = nil
	local questions = {}
	local answers = {}
	local responses = {}

	local rowNum = 0
	for rowValues in f:lines() do
		rowNum += 1

		-- Establish Locale ID's from the first row
		if rowNum == 1 then
			for i = stringStartColumn, #rowValues do
				table.insert(localeIds, rowValues[i])
			end

			for _, localeId in ipairs(localeIds) do
				stringsByLocaleId[localeId] = {}
			end

			continue
		end

		local tagType, tagName, tagNumber = string.match(rowValues[1], "(%w+):(%w+):*(%w*)")
		local spriteId = rowValues[2]

		if tagType then
			print("rowNum", rowNum, "tagType", tagType, "tagName", tagName)
		end

		if tagType == "name" then
			numNames += 1
			table.insert(stringChunks, numNames, {
				name = tagName,
				stringId = numNames,
			})

			forEachString(rowValues, function(columnNum, string)
				local stringsForThisLocale = stringsByLocaleId[localeIds[columnNum - 3]]
				table.insert(stringsForThisLocale, numNames, string)
			end)
			continue
		end

		forEachString(rowValues, function(columnNum, string)
			local stringsForThisLocale = stringsByLocaleId[localeIds[columnNum - 3]]

			table.insert(stringsForThisLocale, string)
		end)

		local thisString = {
			stringIndex = #stringsByLocaleId[localeIds[1]],
			spriteId = spriteId,
		}

		if tagType == "chunk" then
			print("starting chunk", tagName)
			local chunk = {
				name = tagName,
				strings = {},
			}
			currentChunk = chunk
			table.insert(stringChunks, currentChunk)
		elseif tagType == "q" then -- Question
			local questionAnswers = answers[tagName]

			if questionAnswers then
				thisString.answers = questionAnswers
			else
				answers[tagName] = {}
				thisString.answers = answers[tagName]
			end

			questions[tagName] = thisString
		elseif tagType == "a" then -- Answer
			local answerNumber = tonumber(tagNumber)

			local questionAnswers = answers[tagName] or {}
			answers[tagName] = questionAnswers

			questionAnswers[answerNumber] = thisString

			local answerReponses = responses[tagName] or {}
			responses[tagName] = answerReponses

			local thisAnswerResponses = answerReponses[answerNumber]

			if thisAnswerResponses then
				thisString.responses = thisAnswerResponses
			else
				answerReponses[answerNumber] = {}
				thisString.responses = answerReponses[answerNumber]
			end
			continue
		elseif tagType == "r" then -- Response
			local answerNumber = tonumber(tagNumber)

			local answerReponses = responses[tagName] or {}
			responses[tagName] = answerReponses

			local thisAnswerResponses = answerReponses[answerNumber] or {}
			answerReponses[answerNumber] = thisAnswerResponses

			table.insert(thisAnswerResponses, thisString)
			continue
		end

		table.insert(currentChunk.strings, thisString)
	end

	local folder = Instance.new("Folder", workspace)
	folder.Name = "Raw Strings"
	for _, localeId in ipairs(localeIds) do
		local stringsScript = Instance.new("ModuleScript", folder)
		stringsScript.Name = localeId
		local stringsForLocale = stringsByLocaleId[localeId]

		stringsScript.Source = Templates.generateStringArray(stringsForLocale)
	end

	local chunkMapScript = Instance.new("ModuleScript", workspace)
	chunkMapScript.Name = "ChunkMap"
	chunkMapScript.Source = Templates.generateStringChunkMap(stringChunks)
end)

local Templates = {}

local stringArrayTemplate = [[return {%s
}]]

function Templates.generateStringArray(strings)
	local finalStr = ""
	for _, str in ipairs(strings) do
		str = string.gsub(str, "\n", "")
		str = string.gsub(str, '"', '\\"')
		str = '\n\t"' .. str .. '",'
		finalStr = finalStr .. str
	end
	return string.format(stringArrayTemplate, finalStr)
end

local chunkMapTemplate = [[local import = require(game.ReplicatedStorage.Lib.Import)
local HardenConstants = import("Utils/HardenConstants")

return HardenConstants.map({%s})
]]

local chunkTemplate = [[%s = {%s
}]]

local nameChunkTemplate = "%s = %d"

local upgradeChunkTemplate = [[%s = {
	upgradeName = %d,
	upgradeDesc = %d,
}]]

local stringEntryTemplate = [[{
	stringIndex = %d,
	spriteId = "%s",
	dialogEvent = "%s",
	characterId = %s,
}]]

local answerStringEntryTemplate = [[{
	stringIndex = %d,
}]]

local answerStringWithResponsesTemplate = [[{
	stringIndex = %d,
	responses = {%s
	},
}]]

local stringEntryWithAnswersTemplate = [[{
	stringIndex = %d,
	spriteId = "%s",
	dialogEvent = "%s",
	characterId = %s,
	answers = {%s
	},
}]]

function Templates.generateStringChunkMap(stringChunks)
	local mapContents = ""
	for _, chunk in ipairs(stringChunks) do
		if chunk.isName then
			local chunkEntry = string.format(nameChunkTemplate, chunk.name, chunk.stringIndex)
			chunkEntry = "\n" .. chunkEntry .. ","
			chunkEntry = string.gsub(chunkEntry, "\n", "\n\t")

			mapContents = mapContents .. chunkEntry
			continue
		end

		if chunk.isUpgrade then
			local chunkEntry = string.format(upgradeChunkTemplate, chunk.name, chunk.upgradeName, chunk.upgradeDesc)
			chunkEntry = "\n" .. chunkEntry .. ","
			chunkEntry = string.gsub(chunkEntry, "\n", "\n\t")

			mapContents = mapContents .. chunkEntry
			continue
		end

		local chunkContents = ""
		for _, stringData in ipairs(chunk.strings) do
			local stringEntry

			if stringData.answers then
				local stringEntryAnswers = ""

				for _, answer in ipairs(stringData.answers) do
					local answerEntry

					if answer.responses and #answer.responses > 0 then
						local answerEntryResponses = ""
						for _, response in ipairs(answer.responses) do
							local responseEntry = string.format(
								stringEntryTemplate,
								response.stringIndex,
								response.spriteId,
								tostring(response.dialogEvent),
								tostring(response.characterId)
							)

							responseEntry = "\n" .. responseEntry .. ","
							responseEntry = string.gsub(responseEntry, "\n", "\n\t\t")
							answerEntryResponses = answerEntryResponses .. responseEntry
						end

						answerEntry = string.format(
							answerStringWithResponsesTemplate,
							answer.stringIndex,
							answerEntryResponses
						)
					else
						answerEntry = string.format(answerStringEntryTemplate, answer.stringIndex)
					end

					answerEntry = "\n" .. answerEntry .. ","
					answerEntry = string.gsub(answerEntry, "\n", "\n\t\t")
					stringEntryAnswers = stringEntryAnswers .. answerEntry
				end

				stringEntry = string.format(
					stringEntryWithAnswersTemplate,
					stringData.stringIndex,
					stringData.spriteId,
					tostring(stringData.dialogEvent),
					tostring(stringData.characterId),
					stringEntryAnswers
				)
			else
				stringEntry = string.format(
					stringEntryTemplate,
					stringData.stringIndex,
					stringData.spriteId,
					tostring(stringData.dialogEvent),
					tostring(stringData.characterId)
				)
			end

			stringEntry = "\n" .. stringEntry .. ","
			stringEntry = string.gsub(stringEntry, "\n", "\n\t")
			chunkContents = chunkContents .. stringEntry
		end

		local chunkEntry = string.format(chunkTemplate, chunk.name, chunkContents)
		chunkEntry = "\n" .. chunkEntry .. ","
		chunkEntry = string.gsub(chunkEntry, "\n", "\n\t")

		mapContents = mapContents .. chunkEntry
	end

	return string.format(chunkMapTemplate, mapContents)
end

return Templates

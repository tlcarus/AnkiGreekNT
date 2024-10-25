local csv = require"csv"
local kjv_file = csv.open("kjv.csv",{separator=","})
local verse_file = csv.open("greek_textus_receptus_utf8.csv",{separator="	"})
local vocab_file = csv.open("strongs.csv",{separator=","})
local vocab,kjv,output={},{},{}

local function parseRobinsonCode(code)
    -- Lookup tables for code components
    local partOfSpeech = {
        ["N"] = "Noun",
        ["A"] = "Adjective",
        ["R"] = "Relative pronoun",
        ["C"] = "Reciprocal pronoun",
        ["D"] = "Demonstrative pronoun",
        ["T"] = "Definite article",
        ["K"] = "Correlative pronoun",
        ["I"] = "Interrogative pronoun",
        ["X"] = "Indefinite pronoun",
        ["Q"] = "Correlative or interrogative pronoun",
        ["F"] = "Reflexive pronoun",
        ["S"] = "Possessive adjective",
        ["P"] = "Personal pronoun",
        ["V"] = "Verb",
        ["ADV"] = "Adverb",
        ["CONJ"] = "Conjunction",
        ["COND"] = "Conditional particle",
        ["PRT"] = "Particle",
        ["PREP"] = "Preposition",
        ["INJ"] = "Interjection",
        ["ARAM"] = "Aramaic transliterated word",
        ["HEB"] = "Hebrew transliterated word",
    }

    local tense = {
        ["P"] = "Present",
        ["I"] = "Imperfect",
        ["F"] = "Future",
        ["A"] = "Aorist",
        ["X"] = "Perfect",
        ["Y"] = "Pluperfect"
    }

    local voice = {
        ["A"] = "Active",
        ["M"] = "Middle",
        ["P"] = "Passive",
        ["E"] = "Middle or passive deponent",
        ["D"] = "Middle deponent",
        ["O"] = "Passive deponent",
        ["N"] = "Middle or passive deponent"
    }

    local mood = {
        ["I"] = "Indicative",
        ["S"] = "Subjunctive",
        ["O"] = "Optative",
        ["M"] = "Imperative",
        ["N"] = "Infinitive",
        ["P"] = "Participle"
    }

    local case = {
        ["N"] = "Nominative",
        ["V"] = "Vocative",
        ["G"] = "Genitive",
        ["D"] = "Dative",
        ["A"] = "Accusative"
    }

    local number = {
        ["S"] = "Singular",
        ["P"] = "Plural"
    }

    local gender = {
        ["M"] = "Masculine",
        ["F"] = "Feminine",
        ["N"] = "Neuter"
    }

    local person = {
        ["1"] = "First",
        ["2"] = "Second",
        ["3"] = "Third"
    }

    -- Initialize result table
    local result = {}
    
    -- Handle undeclined forms first
    if not string.find(code, "-") then
        result["Part of Speech"] = partOfSpeech[code] or "Unknown"
        return result
    end

    -- Split the code into its components
    local parts = {}
    for part in string.gmatch(code, "[^-]+") do
        table.insert(parts, part)
    end

    -- Parse the basic part of speech
    result["Part of Speech"] = partOfSpeech[parts[1]:sub(1,1)] or "Unknown"

    -- If it's a verb (starts with V-), parse verbal properties
    if parts[1] == "V" then
        if #parts[2] >= 1 then result["Tense"] = tense[parts[2]:sub(1,1)] or "Unknown" end
        if #parts[2] >= 2 then result["Voice"] = voice[parts[2]:sub(2,2)] or "Unknown" end
        if #parts[2] >= 3 then result["Mood"] = mood[parts[2]:sub(3,3)] or "Unknown" end
        
        -- Person (if present)
        if #parts[2] >= 4 then
            local pers = parts[2]:sub(4,4)
            if person[pers] then
                result["Person"] = person[pers]
            end
        end
    end

    -- Parse case, number, gender for the last part
    local lastPart = parts[#parts]
    
    -- Case
    if #lastPart >= 1 then
        result["Case"] = case[lastPart:sub(1,1)] or nil
    end
    
    -- Number
    if #lastPart >= 2 then
        result["Number"] = number[lastPart:sub(2,2)] or nil
    end
    
    -- Gender
    if #lastPart >= 3 then
        result["Gender"] = gender[lastPart:sub(3,3)] or nil
    end

    return result
end

-- Function to format the output nicely
local function formatMorphology(code)
    local result = parseRobinsonCode(code)
    local output = ""
    
    -- Order of presentation
    local order = {
        "Part of Speech",
        "Tense",
        "Voice",
        "Mood",
        "Person",
        "Case",
        "Number",
        "Gender"
    }
    
    -- Build formatted string
    for _, key in ipairs(order) do
        if result[key] then
            output = output .. key .. ": <i>" .. result[key] .. "</i><br>"
        end
    end
    
    return output
end

local function parseBookName(b)
	local names = {
		"Matthew",
		"Mark",
		"Luke",
		"John",
		"Acts",
		"Romans",
		"1 Corinthians",
		"2 Corinthians",
		"Galatians",
		"Ephesians",
		"Philippians",
		"Colossians",
		"1 Thessalonians",
		"2 Thessalonians",
		"1 Timothy",
		"2 Timothy",
		"Titus",
		"Philemon",
		"Hebrews",
		"James",
		"1 Peter",
		"2 Peter",
		"1 John",
		"2 John",
		"3 John",
		"Jude",
		"Revelation",
	}
	return names[tonumber(b)-39]
end


------------------------------------------


local n = 0
for fields in vocab_file:lines() do
	n=n+1
  vocab[tostring(n)]=fields
end

for fields in kjv_file:lines() do
	local b,c,v,t = fields[3],fields[4],fields[5],fields[6]
	kjv[b] = kjv[b] or {}
	kjv[b][c] = kjv[b][c] or {}
	kjv[b][c][v] = t:gsub("¶ ","")
end

for fields in verse_file:lines() do
	local b,c,v,text = fields[1]:sub(1,2),fields[2],fields[3],fields[6]:gsub("{[^{}]*VAR2[^{}]*}", "")
	local defs = {}
	local words = {}
	for section in text:gmatch("[^%a%d%s]+%s+[%w%-]+[ %w%-]*") do
		local parts = {}
		for part in section:gmatch("%S+") do
    	table.insert(parts, part)
    end
    local num = parts[2]:sub(2,-1)
		if vocab[num] then 
	    table.insert(words,string.format(
	    	[[<span class="word" onmouseover="show('%d')" onclick="show('%d')">%s </span>]],
	    	#words+1,#words+1,parts[1]
	    ))
	    
			local def = string.format(
				[[<div id="%d" class="def"> <b>%s</b> (%s %s): %s <br> %s</div>]],
				--id    word           strongs   robinsons      definition     morphology
				#words, vocab[num][2], parts[2], parts[#parts], vocab[num][5], "<p>"..formatMorphology(parts[#parts]).."</p>"
				)
	  	table.insert(defs,def)
	  end
	end
	
	local book = parseBookName(b)
	local card = table.concat({
    table.concat(words), -- greek verse
    kjv[b][c][v], -- kjv verse
    book.." "..c..":"..v, -- book name, chapter number:verse number
    table.concat(defs).."<br>", -- glossary
    "GreekNT::"..book -- book tags
  },"	")
  table.insert(output,card)
  
end

local outFile = io.open("NTdeck.tsv", "w")
outFile:write(
	[[
#separator:tab
#tags column:5	
#columns Greek	English Verse	Glossary Tags
]]..
	table.concat(output,"\n"))
outFile:close()

print("Done!")
--[=[
	@class DubitUtils.fzy

	The lua implementation of the fzy string matching algorithm.
	This script is a forked version of src/fzy_lua.lua in https://github.com/swarn/fzy-lua
]=]
--

local SCORE_GAP_LEADING = -0.005
local SCORE_GAP_TRAILING = -0.005
local SCORE_GAP_INNER = -0.01
local SCORE_MATCH_CONSECUTIVE = 1.0
local SCORE_MATCH_SLASH = 0.9
local SCORE_MATCH_WORD = 0.8
local SCORE_MATCH_CAPITAL = 0.7
local SCORE_MATCH_DOT = 0.6
local SCORE_MAX = math.huge
local SCORE_MIN = -math.huge
local MATCH_MAX_LENGTH = 1024

local fzy = {}

--[=[
	Check if `needle` is a subsequence of the `haystack`.

	Usually called before `score` or `positions`.
	
	@within DubitUtils.fzy

	@param needle string
	@param haystack string
	@param caseSensitive boolean? -- defaults to false

	@return boolean
]=]
function fzy.hasMatch(needle, haystack, caseSensitive)
	if not caseSensitive then
		needle = string.lower(needle)
		haystack = string.lower(haystack)
	end

	local j = 1
	for i = 1, string.len(needle) do
		j = string.find(haystack, needle:sub(i, i), j, true)
		if not j then
			return false
		else
			j = j + 1
		end
	end

	return true
end

local function isLower(c)
	return c:match("%l")
end

local function isUpper(c)
	return c:match("%u")
end

local function precomputeBonus(haystack)
	local matchBonus = {}

	local lastChar = "/"
	for i = 1, string.len(haystack) do
		local thisChar = haystack:sub(i, i)
		if lastChar == "/" or lastChar == "\\" then
			matchBonus[i] = SCORE_MATCH_SLASH
		elseif lastChar == "-" or lastChar == "_" or lastChar == " " then
			matchBonus[i] = SCORE_MATCH_WORD
		elseif lastChar == "." then
			matchBonus[i] = SCORE_MATCH_DOT
		elseif isLower(lastChar) and isUpper(thisChar) then
			matchBonus[i] = SCORE_MATCH_CAPITAL
		else
			matchBonus[i] = 0
		end

		lastChar = thisChar
	end

	return matchBonus
end

local function compute(needle, haystack, D, M, caseSensitive)
	-- Note that the match bonuses must be computed before the arguments are
	-- converted to lowercase, since there are bonuses for camelCase.
	local matchBonus = precomputeBonus(haystack)
	local n = string.len(needle)
	local m = string.len(haystack)

	if not caseSensitive then
		needle = string.lower(needle)
		haystack = string.lower(haystack)
	end

	-- Because lua only grants access to chars through substring extraction,
	-- get all the characters from the haystack once now, to reuse below.
	local haystackChars = {}
	for i = 1, m do
		haystackChars[i] = haystack:sub(i, i)
	end

	for i = 1, n do
		D[i] = {}
		M[i] = {}

		local prevScore = SCORE_MIN
		local gapScore = i == n and SCORE_GAP_TRAILING or SCORE_GAP_INNER
		local needleChar = needle:sub(i, i)

		for j = 1, m do
			if needleChar == haystackChars[j] then
				local score = SCORE_MIN
				if i == 1 then
					score = ((j - 1) * SCORE_GAP_LEADING) + matchBonus[j]
				elseif j > 1 then
					local a = M[i - 1][j - 1] + matchBonus[j]
					local b = D[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE
					score = math.max(a, b)
				end
				D[i][j] = score
				prevScore = math.max(score, prevScore + gapScore)
				M[i][j] = prevScore
			else
				D[i][j] = SCORE_MIN
				prevScore = prevScore + gapScore
				M[i][j] = prevScore
			end
		end
	end
end

--[=[
	Compute a matching score.
	
	@within DubitUtils.fzy

	@param needle string -- must be a subequence of `haystack`, or the result is undefined.
	@param haystack string
	@param caseSensitive boolean? -- defaults to false

	@return number -- higher scores indicate better matches. See also `get_score_min` and `get_score_max`.
]=]

function fzy.score(needle, haystack, caseSensitive)
	local n = string.len(needle)
	local m = string.len(haystack)

	if n == 0 or m == 0 or m > MATCH_MAX_LENGTH or n > m then
		return SCORE_MIN
	elseif n == m then
		return SCORE_MAX
	else
		local D = {}
		local M = {}
		compute(needle, haystack, D, M, caseSensitive)
		return M[n][m]
	end
end

--[=[
	Compute the locations where fzy matches a string.

	Determine where each character of the `needle` is matched to the `haystack` in the optimal match.
	
	@within DubitUtils.fzy

	@param needle string -- must be a subequence of `haystack`, or the result is undefined.
	@param haystack string
	@param caseSensitive boolean? -- defaults to false

	@return {number} -- indices, where `indices[n]` is the location of the `n`th character of `needle` in `haystack`.
	@return number -- the same matching score returned by `score`
]=]

function fzy.positions(needle, haystack, caseSensitive)
	local n = string.len(needle)
	local m = string.len(haystack)

	if n == 0 or m == 0 or m > MATCH_MAX_LENGTH or n > m then
		return {}, SCORE_MIN
	elseif n == m then
		local consecutive = {}
		for i = 1, n do
			consecutive[i] = i
		end
		return consecutive, SCORE_MAX
	end

	local D = {}
	local M = {}
	compute(needle, haystack, D, M, caseSensitive)

	local positions = {}
	local matchRequired = false
	local j = m
	for i = n, 1, -1 do
		while j >= 1 do
			if D[i][j] ~= SCORE_MIN and (matchRequired or D[i][j] == M[i][j]) then
				matchRequired = (i ~= 1) and (j ~= 1) and (M[i][j] == D[i - 1][j - 1] + SCORE_MATCH_CONSECUTIVE)
				positions[i] = j
				j = j - 1
				break
			else
				j = j - 1
			end
		end
	end

	return positions, M[n][m]
end

--[=[
	Apply `has_match` and `positions` to an array of haystacks.    

	@within DubitUtils.fzy

	@param needle string
	@param haystacks {string}
	@param caseSensitive boolean? -- defaults to false

	@return {{number, {number}, number}} -- {{idx, positions, score}, ...}: an array with one entry per matching line in `haystacks`, each entry giving the index of the line in `haystacks` as well as the equivalent to the return value of `positions` for that line.
]=]
function fzy.filter(needle, haystacks, caseSensitive)
	local result = {}

	for i, line in ipairs(haystacks) do
		if fzy.hasMatch(needle, line, caseSensitive) then
			local p, s = fzy.positions(needle, line, caseSensitive)
			table.insert(result, { i, p, s })
		end
	end

	return result
end

-- The lowest value returned by `score`.
--
-- In two special cases:
--  - an empty `needle`, or
--  - a `needle` or `haystack` larger than than `get_max_length`,
-- the `score` function will return this exact value, which can be used as a
-- sentinel. This is the lowest possible score.
function fzy.getScoreMin()
	return SCORE_MIN
end

-- The score returned for exact matches. This is the highest possible score.
function fzy.getScoreMax()
	return SCORE_MAX
end

-- The maximum size for which `fzy` will evaluate scores.
function fzy.getMaxLength()
	return MATCH_MAX_LENGTH
end

-- The minimum score returned for normal matches.
--
-- For matches that don't return `get_score_min`, their score will be greater
-- than than this value.
function fzy.getScoreFloor()
	return MATCH_MAX_LENGTH * SCORE_GAP_INNER
end

-- The maximum score for non-exact matches.
--
-- For matches that don't return `get_score_max`, their score will be less than
-- this value.
function fzy.getScoreCeiling()
	return MATCH_MAX_LENGTH * SCORE_MATCH_CONSECUTIVE
end

return fzy

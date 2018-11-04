---Open source string library that supplies additional LUA string functions
--@module StringLib
--@author myc
--@license myc
--@version 1.0.0
--@copyright boyaa.cy


-- local string = {};
---Allows the ability to index into a string using square-bracket notation
-- For example:
--		s = "hello"
--		s[1] = "h"
getmetatable('').__index = function(str, i)
	if (type(i) == 'number') then
		return string.sub(str, i, i)
	end
	
	return string[i]
end
 

--- Allows the ability to index into a string like above, but using normal brackes to
-- return the substring
-- For example:
--		s = "hello"
--		s(2,5) = "ello"
--
-- However, it also allows indexing into the string to return the byte (unicode) value
-- of the character found at the index. This only occurs if the second value is omitted
-- For example:
--      s = "hello"
--      s(2) = 101 (e)
--
-- Furthermore, it also allows for the ability to replace a character at the given index
-- with the given characters, iff the second value is a string
-- For example:
--		s = "hello"
--		s(2,'p') = "hpllo"
getmetatable('').__call = function(str, i, j)
	if (type(i) == 'number' and type(j) == 'number') then
		return string.sub(str, i, j)
	elseif (type(i) == 'number' and type(j) == 'string') then
		return table.concat{string.sub(str, 1, i - 1), j, string.sub(str, i + 1)}
	elseif (type(i) == 'number' and type(j) == 'nil') then
		return string.byte(str, i)
	end
	
	return string[i]
end



---Checks to see if the string starts with the given characters
function string.startsWith(str, chars)
	return chars == '' or string.sub(str, 1, string.len(chars)) == chars
end



---Checks to see if the string ends with the given characters
function string.endsWith(str, chars)
	return chars == '' or string.sub(str, -string.len(chars)) == chars
end



---Removes the length from the start of the string, returning the result
---Length can be a number or string
function string.removeFromStart(str, length)
	if (type(length) == 'number') then
		return string.sub(str, length + 1, string.len(str))
	elseif (type(length) == 'string') then
		return string.sub(str, string.len(length) + 1, string.len(str))
	else
		return str
	end
end



---Removes the length from the end of the string, returning the result
---Length can be a number or string
function string.removeFromEnd(str, length)
	if (type(length) == 'number') then
		return string.sub(str, 1, string.len(str) - length)
	elseif (type(length) == 'string') then
		return string.sub(str, 1, string.len(str) - string.len(length))
	else
		return str
	end
end



---Removes a number of occurrences of the pattern from the string
---If limit is blank, removes all occurrences
function string.remove(str, pattern, limit)
	if (pattern == '' or pattern == nil) then
		return str
	end

	if (limit == '' or limit == nil) then
		str = string.gsub(str, pattern, '')
	else
		str = string.gsub(str, pattern, '', limit)
	end
	return str
end


--拼接字符串
function string.concat(str1, str2, concatStr)
	local ret =  table.concat({str1, str2}, concatStr)
	return ret
end



---Removes all occurrences of the pattern from the string
function string.removeAll(str, pattern)
	if (pattern == '' or pattern == nil) then
		return str
	end

	str = string.gsub(str, pattern, '')
	return str
end





---Removes the first occurrence of the pattern from the string
function string.removeFirst(str, pattern)
	if (pattern == '' or pattern == nil) then
		return str
	end

	str = string.gsub(str, pattern, '', 1)
	return str
end



---Returns whether the string contains the pattern
function string.contains(str, pattern)
	if (pattern == '' or string.find(str, pattern, 1)) then
		return true
	end
	
	return false
end



---A case-insensitive string.find, returning start and end position of pattern in string
function string.findi(str, pattern)
	return string.find(string.lower(str), string.lower(pattern), 1)
end



---Returns the first substring which matches the pattern in the string from a start index
function string.findPattern(str, pattern, start)
	if (pattern == '' or pattern == nil) then
		return ''
	end
	
	if (start == '' or start == nil) then
		start = 1
	end

	return string.sub(str, string.find(str, pattern, start))
end



------Split the string by the given pattern, returning an array of the result
------If pattern is omitted or nil, then default is to split on spaces
------Array index starts at 1
---function string.split(str, pattern)
---	local split = {}
---	local index = 1
	
---	if (pattern == '' or pattern == nil) then
---		pattern = '%s'
---	end
	
---	local previousstart = 1
---	local startpos, endpos = string.find(str, pattern, 1)
	
---	while (startpos ~= nil) do
---		split[index] = string.sub(str, previousstart, startpos - 1)
---		previousstart = endpos + 1
---		index = index + 1
---		startpos, endpos = string.find(str, pattern, endpos + 1)
---	end
	
---	split[index] = string.sub(str, previousstart, string.len(str))
	
---	return split
---end

---分割字字符串
--@usage split[index] = string.sub(str, previousstart, string.len(str))

--[[--
分割字字符串
]]
function string.split(str, delimiter)
	if (delimiter == '') then return false end
	local pos, arr = 0, {}
	-- for each divider found
	for st, sp in function() return string.find(str, delimiter, pos, true) end do
		table.insert(arr, string.sub(str, pos, st - 1))
		pos = sp + 1
	end
	table.insert(arr, string.sub(str, pos))
	return arr
end



---Returns the array of word contained within the string
---Array index starts at 1
function string.toWordArray(str)
	local words = {}
	local index = 1
	
	for word in string.gmatch(str, '%w+') do
		words[index] = word
		index = index + 1
	end
	
	return words
end



---Returns the number of letters within the string
function string.letterCount(str)
	local _, count = string.gsub(str, '%a', '')
	return count
end



---Returns the number of spaces within the string
function string.spaceCount(str)
	local _, count = string.gsub(str, '%s', '')
	return count
end



---Returns the number of times the pattern occurs within the string
function string.patternCount(str, pattern)
	if (pattern == '' or pattern == nil) then
		return nil
	end

	local _, count = string.gsub(str, pattern, '')
	return count
end



---Returns a table of how many of each character appears in the string
---Table in the format: ["char"] = 2
function string.charTotals(str)
	local totals = {}
	local temp = ''
	
	for i = 1, string.len(str), 1 do
		temp = str[i]
		if (totals[temp]) then
			totals[temp] = totals[temp] + 1
		else
			totals[temp] = 1
		end
	end
	
	return totals
end

--模糊搜索，返回true、false,匹配单词中如果含有特殊字符串，返回false
function string.fuzzyMatch(sourceStr,  searchStr)
	if string.find(searchStr,"[().%+-*?[^$]")then
		return 
	end 
	sourceStr = string.upper(sourceStr)
	searchStr = string.upper(searchStr)
	searchStr = string.gsub(searchStr,"",".*")
	if string.find(sourceStr,searchStr) then 
		return true
	end 
end

---Returns the number of words within the string
function string.wordCount(str)
	local _, count = string.gsub(str, '%w+', '')
	return count
end



---Returns a string which contains the lengths of each each word found in the given string
function string.wordLengths(str)
	local lengths = string.gsub(str, '%w+', function(w) return string.len(w) end)
	return lengths
end



---Returns a table of how many of each word appears in the string
---Table in the format: ["word"] = 2
function string.wordTotals(str)
	local totals = {}
	
	for word in string.gmatch(str, '%w+') do
		if (totals[word]) then
			totals[word] = totals[word] + 1
		else
			totals[word] = 1
		end
	end
	
	return totals
end



---Returns byte (unicode) representation of each character within the string as an array
---Array index starts at 1
function string.toByteArray(str)
	local bytes = {}
	
	for i = 1, string.len(str), 1 do
		bytes[i] = string.byte(str, i)
	end
	
	return bytes
end



---Returns character representation of each character within the string as an array
---Array index starts at 1
function string.toCharArray(str)
	local chars = {}
	
	for i = 1, string.len(str), 1 do
		chars[i] = str[i]
	end
	
	return chars
end



---Returns a string where occurrences of the pattern are put into upper-case
function string.patternToUpper(str, pattern)
	if (pattern == '' or pattern == nil) then
		return str
	end

	local upper = string.gsub(str, pattern, string.upper)
	return upper
end



---Returns a string where occurrences of the pattern are put into lower-case
function string.patternToLower(str, pattern)
	if (pattern == '' or pattern == nil) then
		return str
	end

	local lower = string.gsub(str, pattern, string.lower)
	return lower
end



---Returns a string, where the given string's occurrences of the pattern is replaced by
---the given characters, restricted by the given limit
function string.replace(str, pattern, chars, limit)
	if (pattern == '' or pattern == nil) then
		return str
	end

	if (limit == '' or limit == nil) then
		str = string.gsub(str, pattern, chars)
	else
		str = string.gsub(str, pattern, chars, limit)
	end
	return str
end



---Replaces the character at the given index with the given characters
function string.replaceAt(str, index, chars)
	return table.concat{string.sub(str, 1, index - 1), chars, string.sub(str, index + 1)}
end



---Returns a string, where the given string's occurrences of the pattern is replaced by
---the given characters
function string.replaceAll(str, pattern, chars)
	if (pattern == '' or pattern == nil) then
		return str
	end

	str = string.gsub(str, pattern, chars)
	return str
end



---Returns a string, where the given string's first occurrence of the pattern is replaced
---by the given characters
function string.replaceFirst(str, pattern, chars)
	if (pattern == '' or pattern == nil) then
		return str
	end

	str = string.gsub(str, pattern, chars, 1)
	return str
end



---Returns the index within the string for the first occurrence of the pattern after the
---given starting index
function string.indexOf(str, pattern, start)
	if (pattern == '' or pattern == nil) then
		return nil
	end
	
	if (start == '' or start == nil) then
		start = 1
	end

	local position = string.find(str, pattern, start)
	return position
end



---Returns the index within the string for the first occurrence of the pattern
function string.firstIndexOf(str, pattern)
	if (pattern == '' or pattern == nil) then
		return nil
	end

	local position = string.find(str, pattern, 1)
	return position
end



---Returns the index within the string for the last occurrence of the pattern
function string.lastIndexOf(str, pattern)
	if (pattern == '' or pattern == nil) then
		return nil
	end
	
	local position = string.find(str, pattern, 1)
	local previous = nil
	
	while (position ~= nil) do
		previous = position
		position = string.find(str, pattern, previous + 1)
	end
	
	return previous
end



---Returns the character at the specified index in the string
function string.charAt(str, index)
	return str[index]
end



---Returns the byte (unicode) value of the character at given index in the string
---Basically the same as 'string.byte'
function string.byteAt(str, index)
	return string.byte(str, index)
end



---Returns the byte (unicode) value for the single given character
---nil is returned if not single character or otherwise
function string.byteValue(char)
	if (string.len(char) == 1) then
		return string.byte(char, 1)
	end
	
	return nil
end



---Compares two strings lexiographically. 1 is returned if str1 is greater than
---str2. -1 if str1 is less than str2. And 0 if they are equal
---This comparing is case-sensitive
function string.compare(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local smallestLen = 0;
	
	if (len1 <= len2) then
		smallestLen = len1
	else
		smallestLen = len2
	end
	
	for i = 1, smallestLen, 1 do
		if (str1(i) > str2(i)) then
			return 1
		elseif (str1(i) < str2(i)) then
			return -1
		end
	end
	
	local lengthDiff = len1 - len2
	if (lengthDiff < 0) then
		return -1
	elseif (lengthDiff > 0) then
		return 1
	else
		return 0
	end
end



---Compares two strings lexiographically. 1 is returned if str1 is greater than
---str2. -1 if str1 is less than str2. And 0 if they are equal
---This comparing is case-insensitive
function string.comparei(str1, str2)
	return string.compare(string.lower(str1), string.lower(str2))
end



---Returns whether the two strings are equal to one another. True of they are,
---false otherwise
---This equals function is case-sensitive
function string.equal(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	
	if (len1 ~= len2) then
		return false
	end
	
	for i = 1, len1, 1 do
		if (str1[i] ~= str2[i]) then
			return false
		end
	end
	
	return true
end



---Returns whether the two strings are equal to one another. True of they are,
---false otherwise
---This equals function is case-insensitive
function string.equali(str1, str2)
	return string.equal(string.lower(str1), string.lower(str1))
end



---Prints the elements of an array, optionally displaying each element's index
function printArray(array, showindex)
	for k,v in ipairs(array) do
		if (showindex) then
			print(k, v)
		else
			print(v)
		end
	end
end



---Prints the elements of a table in key-value pair style
function printTable(_table)
	for k,v in pairs(_table) do
		print(k, v)
	end
end



---Returns the string representation of the given value. Be it either a
---number, boolean, string or a table. nil is returned otherwise for functions,
---threads, userdata and nil.
function string.valueOf(value)
	local t = type(value)

	if (t == 'string') then
		return value
	elseif (t == 'number') then
		return '' .. value .. ''
	elseif (t == 'boolean') then
		if (value) then
			return "true"
		else
			return "false"
		end
	elseif (t == 'table') then
		local str = ""
		for k,v in pairs(value) do
			str = str .. "[" .. k .. "] = " .. v .. "\n"
		end
		str = string.sub(str, 1, string.len(str) - string.len("\n"))
		return str
	else
		return "nil"
	end
end



---Returns a string, where the given characters have been inserted into the
---string at the required index. An index of 0 specifies the front of the string
function string.insert(str, chars, index)
	if (index == 0) then
		return chars .. str
	elseif (index == string.len(str)) then
		return str .. chars
	else
		return string.sub(str, 1, index) .. chars .. string.sub(str, index + 1, string.len(str))
	end
end



---Returns a string, where the given characters have been inserted into the
---string rep times at the required index. An index of 0 specifies the front of
---the string
---For example:
--		string.insertRep("ello", "h", 4, 0) = "hhhhello"
function string.insertRep(str, chars, rep, index)
	local rep = string.rep(chars, rep)
	return string.insert(str, rep, index)
end



---Returns a string where all characters starting at the given index have
---been removed up to the end of the string (including the start index character)
function string.removeToEnd(str, index)
	if (index == 1) then
		return ""
	else
		return string.sub(str, 1, index - 1)
	end
end



---Returns a string where all charaters starting at the given index have
---been removed down to the start of the string (including the start index character)
function string.removeToStart(str, index)
	if (index == string.len(str)) then
		return ""
	else
		return string.sub(str, index + 1, string.len(str))
	end
end



---Returns a string where the given string has had any leading and
---trailing characters removed
---If char is left blank, then whitespaces are removed
--@usage
--string.trim("[[[word[[[", "%[") => "word"
--string.trim("   word   ") => "word"
function string.trim(str, char)
	if (char == '' or char == nil) then
		char = '%s'
	end

	local trimmed = string.gsub(str, '^' .. char .. '*(.-)' .. char .. '*$', '%1')
	return trimmed
end



---Returns a string where the given string has had any leading
---characters removed
---If char is left blank, then whitespaces are removed
function string.trimStart(str, char)
	if (char == '' or char == nil) then
		char = '%s'
	end

	local trimmed = string.gsub(str, '^' .. char .. '*', '')
	return trimmed
end



---Returns a string where the gievn string has had any trailing
---characters removed
---If char is left blank, then whitespaces are removed
function string.trimEnd(str, char)
	if (char == '' or char == nil) then
		char = '%s'
	end

	local length = string.len(str)
	
	while (length > 0 and string.find(str, '^' .. char .. '', length)) do
		length = length - 1
	end
	
	return string.sub(str, 1, length)
end



---Returns a string where the given string has had variables substituted into it
--@usage
--string.subvar("x=$(x), y=$(y)", {x=200, y=300}) => "x=200, y=300"
--string.subvar("x=$(x), y=$(y)", {['x']=200, ['y']=300}) => "x=200, y=300"
function string.subvar(str, _table)
	str = string.gsub(str, "%$%(([%w_]+)%)", function(key)
		local value = _table[key]
		return value ~= nil and tostring(value)
	end)
	
	return str
end



---Rotates the string about the given index, returning the result.
--@usage
--string.rotate("hello, 3) => "lohel"
function string.rotate(str, index)
	local str1 = string.sub(str, 1, index)
	local str2 = string.sub(str, index + 1, string.len(str))
	return str2 .. str1
end



---Averages the two strings together. This is done by adding the byte (unicode) values
---of parallel characters and dividing by 2.
function string.average(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local smallestLen = 0
	local newstr = ''
	
	if (len1 <= len2) then
		smallestLen = len1
	else
		smallestLen = len2
	end
	
	for i = 1, smallestLen, 1 do
		newstr = newstr .. string.char( (str1(i) + str2(i)) / 2 )
	end
	
	if (len1 <= len2) then
		newstr = newstr .. string.sub(str2, smallestLen + 1, string.len(str2))
	else
		newstr = newstr .. string.sub(str1, smallestLen + 1, string.len(str1))
	end
	
	return newstr
end



---Swaps the two characters at the given indices of the string
function string.swap(str, index1, index2)
	local temp = str[index1]
	str = str(index1, str[index2])
	return str(index2, temp)
end



---Sorts the string into ascending order according to their unicode values.
function string.sortAscending(str)
	local chars = str:toCharArray()
	table.sort(chars, function(a,b) return a(1) < b(1) end)
	return table.concat(chars)
end



---Sorts the string into descending order according to their unicode values.
function string.sortDescending(str)
	local chars = str:toCharArray()
	table.sort(chars, function(a,b) return a(1) > b(1) end)
	return table.concat(chars)
end



---Returns the character with the highest byte (unicode) value
function string.highest(str)
	local s = string.sortDescending(str)
	return s[1]
end



---Returns the character with the lowest byte (unicode) value
function string.lowest(str)
	local s = string.sortAscending(str)
	return s[1]
end



---Checks to see if the string is empty
function string.isEmpty(str)
	if (str == '' or str == nil) then
		return true
	end
	
	return false
end



---Returns a table for the percentage of how much the string is formed of
---each word.
--@usage
--string.wordPercents("hello, world!") = {"hello" = 38.46, "world" = 38.46}
function string.wordPercents(str)
	local t = string.wordTotals(str)
	local count = string.len(str)
	
	for k,v in pairs(t) do
		t[k] = ((string.len(k) * v) / count) * 100.0
	end
	
	return t
end



---Returns the percentage for how much of the string is formed by the given word
--@usage
--string.wordPercent("hello, world!", "hello") = 50
function string.wordPercent(str, word)
	local t = string.wordPercents(str)
	
	if (t[word]) then
		return t[word]
	end
	
	return 0
end



---Returns a table for the percentage of how much the string is formed of
---each character.
--@usage
--string.charPercents("hello") = {"h" = 20, "e" = 20, "l" = 40, "o" = 20}
function string.charPercents(str)
	local t = string.charTotals(str)
	local count = string.len(str)
	
	for k,v in pairs(t) do
		t[k] = (v/count) * 100.0
	end
	
	return t
end



---Returns the percentage for how much of the string is formed by the given character
--@usage
--string.charPercent("hello", "h") = 20
function string.charPercent(str, char)
	local t = string.charPercents(str)
	
	if (t[char]) then
		return t[char]
	end
	
	return 0
end



---Returns the percentage for how much of the string is formed by whitespace
function string.spacePercent(str)
	local count = string.spaceCount(str)
	return (count / string.len(str)) * 100.0
end



---Returns the number of uppercase characters in the string
function string.upperCount(str)
	local _, count = string.gsub(str, '%u', '')
	return count
end



---Returns the percentage for how much of the string is formed by uppercase
---characters
function string.upperPercent(str)
	local count = string.upperCount(str)
	return (count / string.len(str)) * 100.0
end



---Returns the number of lowercase characters in the string
function string.lowerCount(str)
	local _, count = string.gsub(str, '%l', '')
	return count
end



---Returns the percentage for how much of the string is formed by lowercase
---characters
function string.lowerPercent(str)
	local count = string.lowerCount(str)
	return (count / string.len(str)) * 100.0
end



---Returns the number of single digits in the string
function string.digitCount(str)
	local _, count = string.gsub(str, '%d', '')
	return count
end



---Returns a table of how many of each single digit appears in the string
function string.digitTotals(str)
	local totals = {}
	
	for digit in string.gmatch(str, '%d') do
		if (totals[digit]) then
			totals[digit] = totals[digit] + 1
		else
			totals[digit] = 1
		end
	end
	
	return totals
end



---Returns a table for the percentage of how much the string is formed of
---each single digit.
--@usage
--string.digitPercents("hello, 2world!") = {"2" = 7.14}
function string.digitPercents(str)
	local t = string.digitTotals(str)
	local count = string.len(str)
	
	for k,v in pairs(t) do
		t[k] = ((string.len(k) * v) / count) * 100.0
	end
	
	return t
end



---Returns the percentage for how much of the string is formed by the given single digit
--@usage
--string.digitPercent("hello2", "2") = 16.67
function string.digitPercent(str, digit)
	local t = string.digitPercents(str)
	
	if (t[digit]) then
		return t[digit]
	end
	
	return 0
end



---Returns the amount of punctuation in the string
function string.puncCount(str)
	local _, count = string.gsub(str, '%p', '')
	return count
end



---Returns a table of how many of each punctuation appears in the string
function string.puncTotals(str)
	local totals = {}
	
	for punc in string.gmatch(str, '%p') do
		if (totals[punc]) then
			totals[punc] = totals[punc] + 1
		else
			totals[punc] = 1
		end
	end
	
	return totals
end



---Returns a table for the percentage of how much the string is formed of
---each punctuation.
--@usage
--string.puncPercents("hello, world!") = {"," = 7.69, "!" = 7.69}
function string.puncPercents(str)
	local t = string.puncTotals(str)
	local count = string.len(str)
	
	for k,v in pairs(t) do
		t[k] = ((string.len(k) * v) / count) * 100.0
	end
	
	return t
end



---Returns the percentage for how much of the string is formed by the given punctuation
--@usage
--string.puncPercent("hello, world!", ",") = 7.69
function string.puncPercent(str, punc)
	local t = string.puncPercents(str)
	
	if (t[punc]) then
		return t[punc]
	end
	
	return 0
end



---Concatenates an array of strings together, with optional seperation characters
---This is basically the same as doing table.concat(table, sep)
function string.join(array, sep)
	return table.concat(array, sep)
end



---Returns the Levenshtein distance between the two given strings
function string.levenshtein(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local matrix = {}
	local cost = 0
	
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end
	
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end
	
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (str1[i] == str2[j]) then
				cost = 0
			else
				cost = 1
			end
			
			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end
	
	return matrix[len1][len2]
end



---Makes the string's first character lowercase
function string.lowerFirst(str)
	return str(1, string.lower(str[1]))
end



---Makes the string's first character uppercase
function string.upperFirst(str)
	return str(1, string.upper(str[1]))
end



---Randomly shuffles the given string
function string.shuffle(str)
	local temp = ''
	local length = string.len(str)
	local ran1, ran2 = 0, 0
	math.randomseed(os.time())
	
	for i = 1, length , 1 do
		ran1 = math.random(length)
		ran2 = math.random(length)
		temp = str[ran1]
		str = str(ran1, str[ran2])
		str = str(ran2, temp)
	end
	
	return str
end



---Converts the given integer value into a binary string of length limit
---If limit is omitted, then a binary string of length 8 is returned
function dectobin(dec, limit)
	if (limit == '' or limit == nil) then
		limit = 8
	end

	local bin = ''
	local rem = 0
	
	for i = 1, dec, 1 do
		rem = dec % 2
		dec = dec - rem
		bin = rem .. bin
		dec = dec / 2
		if (dec <= 0) then break end
	end
	
	local padding = limit - (string.len(bin) % limit)
	if (padding ~= limit) then
		bin = string.insertRep(bin, '0', padding, 0)
	end
	
	return bin
end



---Returns the uuencoded representation of the given string
function string.uuencode(str)
	local padding = 3 - (string.len(str) % 3)
	if (padding ~= 3) then
		str = string.insertRep(str, string.char(1), padding, string.len(str))
	end
	
	local uuenc = ''
	local bin1, bin2, bin3, binall = '', '', '', ''
	
	for i = 1, string.len(str) - 2, 3 do
		bin1 = dectobin(string.byte(str[i]), 8)
		bin2 = dectobin(string.byte(str[i+1]), 8)
		bin3 = dectobin(string.byte(str[i+2]), 8)
		
		binall = bin1 .. bin2 .. bin3

		uuenc = uuenc .. string.char(tonumber(binall(1,6), 2) + 32)
		uuenc = uuenc .. string.char(tonumber(binall(7,12), 2) + 32)
		uuenc = uuenc .. string.char(tonumber(binall(13,18), 2) + 32)
		uuenc = uuenc .. string.char(tonumber(binall(19,24), 2) + 32)
	end
	
	return uuenc
end



---Returns the actual string from a uuencoded string
function string.uudecode(str)	
	local padding = 4 - (string.len(str) % 4)
	if (padding ~= 4) then
		str = string.insertRep(str, string.char(1), padding, string.len(str))
	end
	
	local uudec = ''
	local bin1, bin2, bin3, bin4, binall = '', '', '', '', ''
	
	for i = 1, string.len(str) - 3, 4 do
		bin1 = dectobin(string.byte(str[i]) - 32, 6)
		bin2 = dectobin(string.byte(str[i+1]) - 32, 6)
		bin3 = dectobin(string.byte(str[i+2]) - 32, 6)
		bin4 = dectobin(string.byte(str[i+3]) - 32, 6)
		
		binall = bin1 .. bin2 .. bin3 .. bin4
		
		uudec = uudec .. string.char(tonumber(binall(1,8), 2))
		uudec = uudec .. string.char(tonumber(binall(9,16), 2))
		uudec = uudec .. string.char(tonumber(binall(17,24), 2))
	end
	
	return string.trim(uudec, string.char(1))
end



---Returns a simple hash key for a string. If the check value is ommited
---then the string is hashed by the prime value of 17
---Best results occur when the check value is prime
function string.hash(str, check)
	local sum = 0
	local checksum = 17
	local length = string.len(str)
	
	if (check ~= '' and check ~= nil) then checksum = check end
	
	sum = str(1) + 1
	sum = sum + str(length) + length
	sum = sum + str(length/2) + math.ceil(length/2)
	
	return sum % checksum
end

---url字符转换
function string.urlencodeChar(char)
	return "%" .. string.format("%02X", string.byte(char))
end

---url字符转换
function string.urlencode(str)
	---convert line endings
	str = string.gsub(tostring(str), "\n", "\r\n")
	---escape all characters but alphanumeric, '.' and '-'
	str = string.gsub(str, "([^%w%.%- ])", string.urlencodeChar)
	---convert spaces to "+" symbols
	return string.gsub(str, " ", "+")
end

function string.ltrim(str)
    return string.gsub(str, "^[ \t\n\r]+", "")
end

function string.rtrim(str)
    return string.gsub(str, "[ \t\n\r]+$", "")
end

function string.trim(str)
    str = string.gsub(str, "^[ \t\n\r]+", "")
    return string.gsub(str, "[ \t\n\r]+$", "")
end

---检测手机号码是否正确
function string.isPoneNum( PhoneNumText )
    local phoneNum = string.trim(PhoneNumText);
    local start, length = string.find(phoneNum, "^1[3|4|5|8|7][0-9]%d+$"); ---判断手机号码是否正确
    if start ~= nil and length == 11 then
        return true ;
    end
    return false;
end

---计算文字utf8的长度
function string.utf8len(str)
	local len = #str
	local left = len
	local cnt = 0
	local arr = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc }
	while left > 0 do
		local tmp = string.byte(str, -left)
		local i = #arr
		while arr[i] do
			if tmp >= arr[i] then
				left = left - i
				break
			end
			i = i - 1
		end
		cnt = cnt + 1
	end
	return cnt
end

--按照utf8格式取子串
function string.utf8SubStr(str,subLen)

	if subLen == 0 then return "" end 
	if str == nil then 
		debug.traceback()
	print(str, "str")
	end

	local len = #str
	local left = len
	local cnt = 0
	local arr = {0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc }
	while left > 0 do
		local tmp = string.byte(str, -left)
		local i = #arr
		while arr[i] do
			if tmp >= arr[i] then
				left = left - i
				break
			end
			i = i - 1
		end
		cnt = cnt + 1
		if cnt >= subLen then
			break;
		end
	end
	local temp = string.sub(str,0,len - left);
	return temp
end


function string.utf8CharStr( str, index )
 
	 local last = string.utf8SubStr(str, index - 1)

	 local tem = string.utf8SubStr(str, index) 
	 local utf8CharStr = string.sub(str, #last + 1, #tem)

	return utf8CharStr
end

-- local string = _G['string'];


-- for k,v in pairs(string) do
--     -- print_string(k)
--     -- print_string(v)
--     if string[k] then
--     	-- print("k---",k)
--     else
--     	string[k] = v;
--     	-- print("k2---",k)
--     end
-- end

return string;
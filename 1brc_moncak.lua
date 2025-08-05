-- vars and helpers
local file = io.open("measurements.txt", "r")
local separator = ";"
local parsed = {}
local results = {}

local function parse_line(line)
    local separator_pos = line:find(separator)
    local city = line:sub(1, separator_pos - 1)
    local value = line:sub(separator_pos + 1)
    return city, value
end

local function insert_value(city, value)
    if parsed[city] then
        table.insert(parsed[city], value)
    else
        parsed[city] = { value }
    end
end

local function array_sum(array)
    local sum = 0
    for _, value in ipairs(array) do
        sum = sum + value
    end
    return sum
end

-- read the file first
if not file then
    io.stderr:write("measurements.txt file not found\n")
    os.exit(1)
end
local measurements = file:read("*a")
file:close()

-- parse the measurements
for line in measurements:gmatch("[^\n]+") do
    insert_value(parse_line(line))
end

-- process the parsed data
for city, values in pairs(parsed) do
    table.sort(values)
    local count = #values
    table.insert(results, {
        city,                      -- name
        values[1],                 -- min
        array_sum(values) / count, -- avg
        values[count],             -- max
    })
end
table.sort(results, function(a, b) return a[1] < b[1] end)

-- output the results
for _, city in ipairs(results) do
    io.write(table.concat(city, separator), "\n")
end

-- timer inside
local socket = require "socket"
local last_time = socket.gettime()
local function write_time(name, elapsed)
    io.write(string.format("%s use time: %.6f seconds\n", name, elapsed))
end
local function show_time(name)
    local current_time = socket.gettime()
    local elapsed = current_time - last_time
    last_time = current_time
    write_time(name, elapsed)
end

local function read_file_in_chunk(file, page_size)
    local measurements = {}
    while true do
        local chunk = file:read(page_size)
        if not chunk then break end
        table.insert(measurements, chunk)
    end
    _ = table.concat(measurements)
end

local function test_avg(test, times)
    times = times or 5
    local total_time = 0
    for i = 1, times do
        collectgarbage("collect")
        local start_time = socket.gettime()
        test()
        total_time = total_time + (socket.gettime() - start_time)
    end
    return total_time / times
end

local function write_to_csv(chunk_size, buffer_size, use_time)
    local csv = io.open("output.csv", "a")
    if not csv then
        io.stderr:write("Could not open output.csv for writing\n")
        return
    end
    csv:write(string.format("%d,%d,%.6f\n", chunk_size, buffer_size, use_time))
    csv:close()
end

local file = io.open("measurements.txt", "rb")

if not file then
    io.stderr:write("measurements.txt file not found\n")
    os.exit(1)
end

local chunk_sizes = { 1, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536 }  --kb
local buffer_sizes = { 1, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536 } --kb

collectgarbage("stop")
show_time("init")


for _, chunk_size in ipairs(chunk_sizes) do
    for _, buffer_size in ipairs(buffer_sizes) do
        local time_avg = test_avg(function()
            file:setvbuf("full", buffer_size * 1024)
            read_file_in_chunk(file, chunk_size * 1024)
            file:seek("set", 0)
        end)
        write_time(
            string.format("read by chunk of %d kb, buffer of %d kb", chunk_size, buffer_size),
            time_avg
        )
        write_to_csv(chunk_size, buffer_size, time_avg)
    end
end

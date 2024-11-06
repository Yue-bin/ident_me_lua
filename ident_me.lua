#!/usr/bin/env lua5.4

local http_server = require "http.server"
local http_headers = require "http.headers"

local listen_port = 6000
local log_file = "/var/log/ident_me.log"

local log = io.open(log_file, "a")
if log == nil then
    io.stderr:write("Failed to open log file: " .. log_file)
    os.exit(1)
end

local server = http_server.listen {
    host = "0.0.0.0",
    port = listen_port,
    onstream = function(myserver, stream)
        local req_headers = assert(stream:get_headers())
        local method = req_headers:get(":method")
        local path = req_headers:get(":path")
        local family, client_ip, client_port = stream:peername()

        if method == "GET" and path == "/" then
            local headers = http_headers.new()
            headers:append(":status", "200")
            headers:append("content-type", "text/plain")
            log:write(os.date() .. " ")
            log:write("Client request: " .. client_ip .. ":" .. client_port .. "\n")
            assert(stream:write_headers(headers, false))
            assert(stream:write_chunk(client_ip, true))
        else
            local headers = http_headers.new()
            headers:append(":status", "404")
            headers:append("content-type", "text/plain")

            assert(stream:write_headers(headers, false))
            assert(stream:write_chunk("ah~ just... dont touch me there...\n", true))
        end
    end,
    onerror = function(myserver, context, op, err, errno)
        local msg = string.format("%s on %s failed: %s", op, context, err)
        print(msg)
    end,
}

assert(server:loop())

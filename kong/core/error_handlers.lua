local singletons = require "kong.singletons"
local error_messages = require "kong.error_messages"

local find = string.find
local format = string.format

local TYPE_PLAIN = "text/plain"
local TYPE_JSON = "application/json"
local TYPE_XML = "application/xml"
local TYPE_HTML = "text/html"

local text_template = "%s"
local json_template = '{"message":"%s"}'
local xml_template = '<?xml version="1.0" encoding="UTF-8"?>\n<error><message>%s</message></error>'
local html_template = '<html><head><title>Kong Error</title></head><body><h1>Kong Error</h1><p>%s.</p></body></html>'

local SERVER_HEADER = _KONG._NAME .. "/" .. _KONG._VERSION

return function(ngx)
  local accept_header = ngx.req.get_headers()["accept"]
  local template, message, content_type

  if accept_header == nil then
    accept_header = singletons.configuration.error_default_type
  end

  if find(accept_header, TYPE_HTML, nil, true) then
    template = html_template
    content_type = TYPE_HTML
  elseif find(accept_header, TYPE_JSON, nil, true) then
    template = json_template
    content_type = TYPE_JSON
  elseif find(accept_header, TYPE_XML, nil, true) then
    template = xml_template
    content_type = TYPE_XML
  else
    template = text_template
    content_type = TYPE_PLAIN
  end

  local status = ngx.status
  message = error_messages["s" .. status] and error_messages["s" .. status] or format(error_messages.default, status)

  if singletons.configuration.server_tokens then
    ngx.header["Server"] = SERVER_HEADER
  end

  ngx.header["Content-Type"] = content_type
  ngx.say(format(template, message))
end

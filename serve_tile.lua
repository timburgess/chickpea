local S = require "syscall"
local mapnik = require "mapnik"
local fs = require "fs"
local min = math.min
local max = math.max
local log = math.log
local pow = math.pow

-- modify this to validate the urls requested
-- ensure that an invalid url returns 404
local function validate_url(source, layertype, pathrow, date)

  if source == 'l8' or source == 's2a' or source == 'uav' then
    return ngx.var.xmlroot .. ngx.var.xmlpath
  end

  ngx.status = 404
  ngx.log(ngx.NOTICE, "Invalid tile request url")
  ngx.exit(ngx.OK)
end


--- GEOMETRY ---

-- new coords with zoom applied
local function zoomTo(zoom_factor, z, x, y)
  return x * pow(2, zoom_factor - z), y * pow(2, zoom_factor - z), zoom_factor
end

-- convert from Slippy Map coordinate to Web Mercator point
-- see https://en.wikipedia.org/wiki/Web_Mercator
local function coordinateProj(z, x, y)
  -- zoom for meters on the ground
  local diameter = 2 * math.pi * 6378137
  local zoom_factor = log(diameter) / log(2)
  local x, y, z = zoomTo(zoom_factor, z, x, y)

  -- global offsets
  x = x - diameter/2
  y = diameter/2 - y
  return x, y
end

-- projected rendering envelope (xmin, ymin, xmax, ymax) for Slippy map coord
local function envelope(z, x, y)
  -- get upper left coords
  local ul_x, ul_y = coordinateProj(z, x, y)
  -- lower right can be determined from upper left of diagonally adjacent tile
  local lr_x, lr_y = coordinateProj(z, x+1, y+1)

  return min(ul_x, lr_x), min(ul_y, lr_y), max(ul_x, lr_x), max(ul_y, lr_y)
end



---- MAIN ----

-- get request path variables
local source, pathrow, type, date, x, y, z =
  ngx.var.source, ngx.var.pathrow, ngx.var.type, ngx.var.date, ngx.var.x, ngx.var.y, ngx.var.z

-- validate the url according to custom logic
-- 404 redirect on invalid url
local xmlpath = validate_url(source, type, pathrow, date)

local result = mapnik:register_datasources(ngx.var.mapnik_datasource)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to register datasource")
end

local map = mapnik:map(256,256)

---- load xml and get map
if xmlpath == nil then
  xmlpath = ngx.var.xmlroot .. ngx.var.xmlpath
end
result = mapnik:map_load(map, xmlpath)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to load " .. xmlpath)
  local errstr = mapnik:last_error(map)
  ngx.log(ngx.ERR, errstr)
  ngx.exit(0)
end

-- derive web mercator bounds for slippy map tile
xmin, ymin, xmax, ymax = envelope(z, x, y)

local box = mapnik:bbox(xmin, ymin, xmax, ymax)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to create bounding box")
  local errstr = mapnik:last_error(map)
  ngx.log(ngx.ERR, errstr)
  ngx.exit(0)
end

mapnik:map_zoom_to_box(map, box)

-- match to trailing slash then remove slash
local dirpath = ngx.var.cachepath:match(".*/"):sub(1,-2)
if not S.stat(ngx.var.cacheroot .. dirpath) then
  fs:mkdir(dirpath)
else
  ngx.log(ngx.NOTICE, "filepath exists")
end

-- render image
local file_cache_path = ngx.var.cacheroot .. ngx.var.cachepath
result = mapnik:map_render_to_file(map, file_cache_path)
-- log where tile is being written to
ngx.log(ngx.NOTICE, "Writing to " .. file_cache_path)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to render image")
  local errstr = mapnik:last_error(map)
  ngx.log(ngx.ERR, errstr)
  ngx.exit(0)
end

-- free up resources
mapnik:bbox_free(box)
mapnik:map_free(map)

-- trigger new internal request
ngx.exec(ngx.var.request_uri)

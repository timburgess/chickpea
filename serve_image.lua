
--local function return_not_found(msg)
--  ngx.status = ngx.HTTP_NOT_FOUND
--  ngx.header["Content-type"] = "text/html"
--  ngx.say(msg or "not found")
--  ngx.exit(0)
--end

-- log error msg and last mapnik error
--local function report_error(msg)
--  ngx.log(ngx.ERR, "failed to load xml file")
--  local errstr = ffi.string(clib.mapnik_map_last_error(map))
--  ngx.log(ngx.ERR, errstr)
--end

-- get request path variables
local layer, pathrow, type, date, x, y, z =
  ngx.var.layer, ngx.var.pathrow, ngx.var.type, ngx.var.date, ngx.var.x, ngx.var.y, ngx.var.z
-- satamap only construction to layer
local layername = layer .. "/" .. pathrow .. "/" .. type .. "/" .. date .. "/"

local result = 0, library_path

-- ngx.say(ngx.var.scheme);
-- ngx.say(ngx.var.cachepath);

ngx.log(ngx.NOTICE, "Creating tile image")


local ffi = require("ffi")

ffi.cdef[[
int mapnik_register_datasources(const char* path, char** err);

//  Opaque class structure
typedef struct _mapnik_map_t mapnik_map_t;

// Bbox
typedef struct _mapnik_bbox_t mapnik_bbox_t;

mapnik_bbox_t * mapnik_bbox(double minx, double miny, double maxx, double maxy);


mapnik_map_t * mapnik_map( unsigned int width, unsigned int height );

void mapnik_map_free(mapnik_map_t * m);

const char * mapnik_map_last_error(mapnik_map_t * m);

const char * mapnik_map_get_srs(mapnik_map_t * m);

int mapnik_map_set_srs(mapnik_map_t * m, const char* srs);

int mapnik_map_load(mapnik_map_t * m, const char* stylesheet);

int mapnik_map_zoom_all(mapnik_map_t * m);

void mapnik_map_zoom_to_box(mapnik_map_t * m, mapnik_bbox_t * b);

int mapnik_map_render_to_file(mapnik_map_t * m, const char* filepath);
]]

-- check platform and load appropriate mapnik C lib
if ffi.os == "OSX" then
  library_path = "./lib/libmapnik_c.dylib"
else
  library_path = "./lib/libmapnik_c.so"
end
local clib = ffi.load(library_path)

result = clib.mapnik_register_datasources("/usr/local/lib/mapnik/input", nil)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to register datasource")
end

local map = clib.mapnik_map(256,256)
-- get map
result = clib.mapnik_map_load(map, "./sample/l8_rgb_09108020160924.xml")
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to load xml file")
  local errstr = ffi.string(clib.mapnik_map_last_error(map))
  ngx.log(ngx.ERR, errstr)
  ngx.exit(0)
end

local xmin = 16671833.113336448
local ymin = -3443946.7464169525
local xmax = 16750104.630300466
local ymax = -3365675.229452934
local box = clib.mapnik_bbox(xmin, ymin, xmax, ymax)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to create bounding box")
  local errstr = ffi.string(clib.mapnik_map_last_error(map))
  ngx.log(ngx.ERR, errstr)
  ngx.exit(0)
end

clib.mapnik_map_zoom_to_box(map, box)
local file_cache_path = "./cache/" .. layername .. "/" .. z .. "/" .. x .. "/" .. y .. ".jpg"
result = clib.mapnik_map_render_to_file(map, file_cache_path)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to render image")
  local errstr = ffi.string(clib.mapnik_map_last_error(map))
  ngx.log(ngx.ERR, errstr)
  ngx.exit(0)
end


clib.mapnik_map_free(map)

-- trigger new internal request
ngx.exec(ngx.var.request_uri)

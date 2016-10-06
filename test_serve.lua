-- code with all ngx usage removed for testing


local ffi = require("ffi")

ffi.cdef[[
int mapnik_register_datasources(const char* path, char** err);

//  Opaque class structure
typedef struct _mapnik_map_t mapnik_map_t;

// Bbox
typedef struct _mapnik_bbox_t mapnik_bbox_t;

mapnik_bbox_t * mapnik_bbox(double minx, double miny, double maxx, double maxy);

void mapnik_bbox_free(mapnik_bbox_t * b);

// Map
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


-- new coords with zoom applied
local function zoomTo(zoom_factor, z, x, y)
  return x * math.pow(2, zoom_factor - z), y * math.pow(2, zoom_factor - z), zoom_factor
end

-- convert from Slippy Map coordinate to Web Mercator point
-- see https://en.wikipedia.org/wiki/Web_Mercator
local function coordinateProj(z, x, y)

  -- zoom for meters on the ground
  diameter = 2 * math.pi * 6378137
  zoom_factor = math.log(diameter) / math.log(2)
  x, y, z = zoomTo(zoom_factor, z, x, y)

  -- global offsets
  x = x - diameter/2
  y = diameter/2 - y
  return x, y

end

-- projected rendering envelope (xmin, ymin, xmax, ymax) for Slippy map coord
local function envelope(z, x, y)
  -- get upper left coords
  ul_x, ul_y = coordinateProj(z, x, y)
  -- lower right can be determined from upper left of diagonally adjacent tile
  lr_x, lr_y = coordinateProj(z, x+1, y+1)

  return math.min(ul_x, lr_x), math.min(ul_y, lr_y), math.max(ul_x, lr_x), math.max(ul_y, lr_y)

end


-- get request path variables
local layer, pathrow, type, date, x, y, z =
  --ngx.var.layer, ngx.var.pathrow, ngx.var.type, ngx.var.date, ngx.var.x, ngx.var.y, ngx.var.z
  "l8", "091080", "rgb", "20160924", 10, 938, 597

local result = 0, library_path


print("Creating tile image")

result = clib.mapnik_register_datasources("/usr/local/lib/mapnik/input", nil)
if result ~= 0 then
  --ngx.log(ngx.ERR, "failed to register datasource")
  print("failed to register datasource")
end

local map = clib.mapnik_map(256,256)
-- get map
result = clib.mapnik_map_load(map, "./sample/l8_rgb_09108020160924.xml")
if result ~= 0 then
  --ngx.log(ngx.ERR, "failed to load xml file")
  print("failed to load xml file")
  local errstr = ffi.string(clib.mapnik_map_last_error(map))
  --ngx.log(ngx.ERR, errstr)
  print(errstr)
  os.exit(0)
end

-- derive web mercator bounds for slippy map tile
xmin, ymin, xmax, ymax = envelope(z, x, y)
--print(xmin)
--print(ymin)
--print(xmax)
--print(ymax)

local box = clib.mapnik_bbox(xmin, ymin, xmax, ymax)
if result ~= 0 then
  --ngx.log(ngx.ERR, "failed to create bounding box")
  print("failed to create bounding box")
  local errstr = ffi.string(clib.mapnik_map_last_error(map))
  --ngx.log(ngx.ERR, errstr)
  print(errstr)
  os.exit(0)
end

clib.mapnik_map_zoom_to_box(map, box)

--local file_cache_path = ngx.var.cacheroot .. ngx.var.cachepath
local file_cache_path = "/Users/tim/work/chickpea/cache/" .. "l8/091080/rgb/20160924/10/938/597.jpg"
-- check if cache dir exists. if not, create it
local newdir = file_cache_path:match("(.*/)")
os.execute("mkdir -p " .. newdir)

result = clib.mapnik_map_render_to_file(map, file_cache_path)
-- log where tile is being written to
--ngx.log(ngx.NOTICE, "Writing to " .. file_cache_path)
print("Writing to " .. file_cache_path)
if result ~= 0 then
  --ngx.log(ngx.ERR, "failed to render image")
  print("failed to render image")
  local errstr = ffi.string(clib.mapnik_map_last_error(map))
  --ngx.log(ngx.ERR, errstr)
  print(errstr)
  os.exit(0)
end

clib.mapnik_bbox_free(box)
clib.mapnik_map_free(map)

-- trigger new internal request
--ngx.exec(ngx.var.request_uri)

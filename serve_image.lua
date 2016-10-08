local require = require
local ffi = require "ffi"
local platform = require "platform"
local syscall = require "syscall"
local fs = require "fs"
local ffi_cdef = ffi.cdef
local ffi_errno = ffi.errno
local ffi_typeof = ffi.typeof
local ffi_load = ffi.load
local ffi_string = ffi.string
local C = ffi.C
local min = math.min
local max = math.max
local log = math.log
local pow = math.pow

ffi_cdef[[

// mkdir
int mkdir(const char *filename, unsigned int mode);

// Mapnik

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
local clib = ffi_load(library_path)


--- Read out file metadata with a given path
function stat(path, buf)
  local stat_t = ffi_typeof("struct stat")
  if not buf then buf = stat_t() end
  local ret = C.stat(path, buf)
  if ret == -1 then
    return -1, ffi_string(C.strerror(ffi_errno()))
  end
  return buf
end

--- Check whether a given path is directory
function is_dir(path)
  local buf, err = stat(path, nil)
  if buf == -1 then return false, err end
  -- TODO identify explicitly as directory
  --ngx.log(ngx.NOTICE, "Dir exists ")
  return true

--  if bit.band(buf.st_mode, syscall.S_IFMT) == syscall.S_IFDIR then
--    ngx.log(ngx.NOTICE, "Dir exists ")
--    return true
--  else
--    ngx.log(ngx.NOTICE, "Dir does not exist ")
--    return false
--  end
end


-- iterate through path to create required cache subdirs
-- we presume that the root cache dir exists
local function mkdir(fullpath)
  -- get cache root without trailing slash
  local newdir = ngx.var.cacheroot:sub(1, -2)
  for s in string.gmatch(fullpath, "(%w+)/") do
    newdir = newdir .. "/" .. s
    -- TODO report on errs other than existing dir
    local status = C.mkdir(newdir, 0x1ff)
  end
end

-- log error msg and last mapnik error
--local function report_error(msg)
--  ngx.log(ngx.ERR, "failed to load xml file")
--  local errstr = ffi.string(clib.mapnik_map_last_error(map))
--  ngx.log(ngx.ERR, errstr)
--end

-- new coords with zoom applied
local function zoomTo(zoom_factor, z, x, y)
  return x * pow(2, zoom_factor - z), y * pow(2, zoom_factor - z), zoom_factor
end

-- convert from Slippy Map coordinate to Web Mercator point
-- see https://en.wikipedia.org/wiki/Web_Mercator
local function coordinateProj(z, x, y)
  -- zoom for meters on the ground
  diameter = 2 * math.pi * 6378137
  zoom_factor = log(diameter) / log(2)
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

  return min(ul_x, lr_x), min(ul_y, lr_y), max(ul_x, lr_x), max(ul_y, lr_y)
end


-- get request path variables
local layer, pathrow, type, date, x, y, z =
  ngx.var.layer, ngx.var.pathrow, ngx.var.type, ngx.var.date, ngx.var.x, ngx.var.y, ngx.var.z

local result = 0, library_path


result = clib.mapnik_register_datasources("/usr/local/lib/mapnik/input", nil)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to register datasource")
end

local map = clib.mapnik_map(256,256)
-- load xml and get map
local xmlpath = ngx.var.xmlroot .. ngx.var.xmlpath
result = clib.mapnik_map_load(map, xmlpath)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to load " .. xmlpath)
  local errstr = ffi_string(clib.mapnik_map_last_error(map))
  ngx.log(ngx.ERR, errstr)
  ngx.exit(0)
end

-- derive web mercator bounds for slippy map tile
xmin, ymin, xmax, ymax = envelope(z, x, y)

local box = clib.mapnik_bbox(xmin, ymin, xmax, ymax)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to create bounding box")
  local errstr = ffi_string(clib.mapnik_map_last_error(map))
  ngx.log(ngx.ERR, errstr)
  ngx.exit(0)
end

clib.mapnik_map_zoom_to_box(map, box)

-- check if cache dir exists. if not, create it
local file_cache_path = ngx.var.cacheroot .. ngx.var.cachepath
local file_cache_dir = file_cache_path:match("(.*/)")
if not is_dir(file_cache_dir) then
  ngx.log(ngx.NOTICE, "Directory does not exist. Creating ...")
  local newdir = ngx.var.cachepath:match("(.*/)")
  mkdir(newdir)
end

-- render image
result = clib.mapnik_map_render_to_file(map, file_cache_path)
-- log where tile is being written to
ngx.log(ngx.NOTICE, "Writing to " .. file_cache_path)
if result ~= 0 then
  ngx.log(ngx.ERR, "failed to render image")
  local errstr = ffi_string(clib.mapnik_map_last_error(map))
  ngx.log(ngx.ERR, errstr)
  ngx.exit(0)
end

-- free up resources
clib.mapnik_bbox_free(box)
clib.mapnik_map_free(map)

-- trigger new internal request
ngx.exec(ngx.var.request_uri)

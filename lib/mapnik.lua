local ffi = require "ffi"
local ffi_cdef = ffi.cdef
local ffi_load = ffi.load
local ffi_string = ffi.string
local C = ffi.C

local _M = { _VERSION = '0.01' }


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
  library_path = "./clib/libmapnik_c.dylib"
else
  library_path = "./clib/libmapnik_c.so"
end
local clib = ffi_load(library_path)


-- iterate through path to create required cache subdirs
-- we presume that the root cache dir exists
function _M.mkdir(self, fullpath)
  -- get cache root without trailing slash
  local newdir = ngx.var.cacheroot:sub(1, -2)
  for s in string.gmatch(fullpath, "(%w+)/") do
    newdir = newdir .. "/" .. s
    -- TODO report on errs other than existing dir
    local status = C.mkdir(newdir, 0x1ff)
  end
end


function _M.register_datasources(self, path)
  return clib.mapnik_register_datasources("/usr/local/lib/mapnik/input", nil)
end

function _M.map(self, dim1, dim2)
  return clib.mapnik_map(dim1,dim2)
end

function _M.map_load(self, map, xmlpath)
  return clib.mapnik_map_load(map, xmlpath)
end

function _M.bbox(self, xmin, ymin, xmax, ymax)
  return clib.mapnik_bbox(xmin, ymin, xmax, ymax)
end

function _M.map_zoom_to_box(self, map, box)
  return clib.mapnik_map_zoom_to_box(map, box)
end

function _M.map_render_to_file(self, map, file_cache_path)
  return clib.mapnik_map_render_to_file(map, file_cache_path)
end

function _M.bbox_free(self, box)
  clib.mapnik_bbox_free(box)
end

function _M.map_free(self, map)
  clib.mapnik_map_free(map)
end

function _M.last_error(self, map)
  return ffi_string(clib.mapnik_map_last_error(map))
end


return _M


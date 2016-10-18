local ffi = require "ffi"
local ffi_cdef = ffi.cdef
local ffi_load = ffi.load
local ffi_string = ffi.string
local C = ffi.C

local _M = { _VERSION = '0.01' }


ffi_cdef[[

// mkdir
int mkdir(const char *filename, unsigned int mode);

]]


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


return _M


local S = require "syscall"


local fs = { _VERSION = '0.01' }


-- iterate through path to create required cache subdirs
-- we presume that the root cache dir exists
function fs.mkdir(self, fullpath)
  -- get cache root without trailing slash
  local newdir = ngx.var.cacheroot:sub(1, -2)
  for s in string.gmatch(fullpath, "%w+") do
    newdir = newdir .. "/" .. s
    ngx.log(ngx.NOTICE, "Making " .. newdir)
    local status = S.mkdir(newdir, "0755")
  end
end


return fs


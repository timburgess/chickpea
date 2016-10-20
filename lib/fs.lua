local ffi = require "ffi"
local platform = require "platform"

local ffi_cdef = ffi.cdef
local ffi_load = ffi.load
local ffi_string = ffi.string
local C = ffi.C

local fs = { _VERSION = '0.01' }


ffi_cdef[[

// mkdir
int mkdir(const char *filename, unsigned int mode);

// stat
int stat(const char *restrict path, struct stat *restrict buf);
int syscall(int number, ...);
char *strerror(int errnum);

]]

if platform.__X86__ then

    SYS_stat = 106  -- stat()
    ffi.cdef[[
      struct stat {
        unsigned long  st_dev;
        unsigned long  st_ino;
        unsigned short st_mode;
        unsigned short st_nlink;
        unsigned short st_uid;
        unsigned short st_gid;
        unsigned long  st_rdev;
        unsigned long  st_size;
        unsigned long  st_blksize;
        unsigned long  st_blocks;
        unsigned long  st_atime;
        unsigned long  st_atime_nsec;
        unsigned long  st_mtime;
        unsigned long  st_mtime_nsec;
        unsigned long  st_ctime;
        unsigned long  st_ctime_nsec;
        unsigned long  __unused4;
        unsigned long  __unused5;
      };
    ]]
elseif platform.__X64__ then

    SYS_stat = 4  -- stat()
    ffi.cdef [[
      struct stat {
        unsigned long   st_dev;
        unsigned long   st_ino;
        unsigned long   st_nlink;
        unsigned int    st_mode;
        unsigned int    st_uid;
        unsigned int    st_gid;
        unsigned int    __pad0;
        unsigned long   st_rdev;
        long            st_size;
        long            st_blksize;
        long            st_blocks;
        unsigned long   st_atime;
        unsigned long   st_atime_nsec;
        unsigned long   st_mtime;
        unsigned long   st_mtime_nsec;
        unsigned long   st_ctime;
        unsigned long   st_ctime_nsec;
        long            __unused[3];
      };
    ]]
  end

-- stat the path
function fs.stat(self, path, buf)
  local stat_t = ffi.typeof("struct stat")
  if not buf then buf = stat_t() end
  --local ret = ffi.C.syscall(SYS_stat, path, buf)
  --local ret = ffi.C.syscall(syscall.SYS_stat, path, buf)
  local ret = ffi.C.stat(path, buf)
  ngx.log(ngx.NOTICE, ret)
  if ret == -1 then
    return -1, ffi.string(ffi.C.strerror(ffi.errno()))
  end
  return buf
end


-- is the path a directory
function fs.is_dir(self, path)
  ngx.log(ngx.NOTICE, "Checking: " .. path)
  local buf, err = fs.stat(path, nil)
  if buf == -1 then
    ngx.log(ngx.NOTICE, "Dir does not exist")
    ngx.log(ngx.NOTICE, err)
    return false, err
  end

  -- check bit band
  return true
end


-- iterate through path to create required cache subdirs
-- we presume that the root cache dir exists
function fs.mkdir(self, fullpath)
  -- get cache root without trailing slash
  --ngx.log(ngx.NOTICE, "Received " .. fullpath)
  local newdir = ngx.var.cacheroot:sub(1, -2)
  for s in string.gmatch(fullpath, "%w+") do
    newdir = newdir .. "/" .. s
    ngx.log(ngx.NOTICE, "Making " .. newdir)
    -- TODO report on errs other than existing dir
    local status = C.mkdir(newdir, 0x1ff)
  end
end


return fs


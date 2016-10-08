--- Turbo.lua C function declarations
--
-- Copyright 2013, 2014 John Abrahamsen
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local ffi = require "ffi"
local platform = require "platform"

--- ******* File system *******
ffi.cdef[[
    typedef long int __ssize_t;
    typedef __ssize_t ssize_t;

    char *strerror(int errnum);

    ssize_t read(int fd, void *buf, size_t nbytes) ;
    int syscall(int number, ...);
    void *mmap(
        void *addr,
        size_t length,
        int prot,
        int flags,
        int fd,
        long offset);
    int munmap(void *addr, size_t length);
    int open(const char *pathname, int flags);
    int close(int fd);

    int stat(const char *pathname, struct stat *buf);
]]

-- stat structure is architecture dependent in Linux
if platform.__X86__ then
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
elseif platform.__PPC__ then
    ffi.cdef[[
      struct stat {
        unsigned int st_dev;
        unsigned int st_ino;
        unsigned int st_mode;
        unsigned int st_nlink;
        unsigned int st_uid;
        unsigned int st_gid;
        unsigned int st_rdev;
        unsigned int st_size;
        unsigned int st_blksize;
        unsigned int st_blocks;
        unsigned int st_atime;
        unsigned int st_atime_nsec;
        unsigned int st_mtime;
        unsigned int st_mtime_nsec;
        unsigned int st_ctime;
        unsigned int st_ctime_nsec;
        unsigned int __unused4;
        unsigned int __unused5;
      };
    ]]
elseif platform.__PPC64__ then
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
elseif platform.__ARM__ then
    ffi.cdef[[
      struct stat {
        unsigned short  st_dev;
        unsigned long   st_ino;
        unsigned short  st_mode;
        unsigned short  st_nlink;
        unsigned short  st_uid;
        unsigned short  st_gid;
        unsigned long   st_rdev;
        unsigned long   st_size;
        unsigned long   st_blksize;
        unsigned long   st_blocks;
        unsigned long   st_atime;
        unsigned long   st_atime_nsec;
        unsigned long   st_mtime;
        unsigned long   st_mtime_nsec;
        unsigned long   st_ctime;
        unsigned long   st_ctime_nsec;
        unsigned long   __unused4;
        unsigned long   __unused5;
      };
    ]]
elseif platform.__MIPSEL__ then
    ffi.cdef[[
      struct stat {
        unsigned long long  st_dev;
        long int            st_pad1[2];
        unsigned int        st_ino;
        unsigned int        st_mode;
        unsigned int        st_nlink;
        unsigned int        st_uid;
        unsigned int        st_gid;
        unsigned long long  st_rdev;
        long int            st_pad2[1];
        unsigned int        st_size;
        long int            st_pad3;
        unsigned int        st_atime;
        unsigned int        st_mtime;
        unsigned int        st_ctime;
        unsigned int        st_blksize;
        unsigned int        st_blocks;
        long int            st_pad5[14];
      };
    ]]
end

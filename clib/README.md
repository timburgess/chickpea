# C library requirements

Chickpea uses the C API to make Mapnik calls and it expects the Mapnik C library built for your system to be located here.
On Linux, this file will be `libmapnik_c.so` and on OS X it will be `libmapnik_c.dylib`.

To build the library, `git clone https://github.com/springmeyer/mapnik-c-api.git` to an appropriate location and simply type `make` to build the library.

The Mapnik C API has a dependency on the mapnik development library which in turn has dependencies on various other libraries.

On Ubuntu/Debian, this can be installed with '`sudo apt-get install libmapnik-dev` and this will pull in all dependencies.


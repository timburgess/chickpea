# chickpea

A small and fast tile server for nginx.

Chickpea is a small tileserver using Lua (Openresty) and nginx. Using features from both, it disects a Slippy (OSM) tile url request from a browser client such as Leaflet.js, transforms the tile coordinates to Web Mercator, and then uses Mapnik to extract the region from a TIF via a Mapnik xml definition. The tile is then served and also cached for any future requests. Once a tile is cached, nginx serves any further requests itself out of the cache.

Implemented in Lua and C, Chickpea is fast, and with a well-performing IO subsystem, can deliver tiles quickly. I've done no formal testing but usage has shown that delivering 100+ tiles to a client on a page load is a non-issue. Chickpea significantly outperforms tileservers such as TileStache.

Features yet to implement:
- C lib fstat usage for better cache directory checking
- A better cache system than just url request path

Contributions and feature requests are always welcome.

**Chickpea is sponsored by [Satamap Pty Ltd](http://www.satamap.com.au)** - providing global crop productivity analysis.

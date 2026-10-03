"""Validate/execute stock Lua 5.4 via its shared library; no RedM runtime implied."""
import ctypes
import ctypes.util
from pathlib import Path
import os
root = Path(__file__).resolve().parents[1]
os.chdir(root)
lua = ctypes.CDLL(ctypes.util.find_library('lua5.4'))
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lua.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_settop.argtypes = [ctypes.c_void_p, ctypes.c_int]
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
lua.luaL_openlibs(state)
try:
    files = sorted(root.glob('m-ac/**/*.lua'))
    for path in files:
        status = lua.luaL_loadfilex(state, str(path).encode(), None)
        if status:
            raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
        lua.lua_settop(state, 0)
    print(f'Lua 5.4 syntax: {len(files)} files passed')
    status = lua.luaL_loadfilex(state, b'tests/runtime.lua', None)
    if status == 0:
        status = lua.lua_pcallk(state, 0, 0, 0, 0, None)
    if status:
        raise RuntimeError(lua.lua_tolstring(state, -1, None).decode())
finally:
    lua.lua_close(state)

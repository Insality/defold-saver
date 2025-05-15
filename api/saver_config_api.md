# saver.config API

> at /saver/saver.lua

Configuration table for `saver.init` to setup all things you can in game.project file

## Fields

- [save_folder](#save_folder)
- [save_name](#save_name)
- [saver_key](#saver_key)
- [storage_key](#storage_key)
- [autosave_timer](#autosave_timer)
- [lua_require_as_string](#lua_require_as_string)




## Fields
<a name="save_folder"></a>
- **save_folder** (_string_): Save folder name. Default is project name without special characters

<a name="save_name"></a>
- **save_name** (_string_): Save file name, use ".json" or ".lua" extension to use these formats. Default is "game"

<a name="saver_key"></a>
- **saver_key** (_string_): Saver key, where saver internal data will be stored. Default is "saver"

<a name="storage_key"></a>
- **storage_key** (_string_): Storage key, where storage internal data will be stored. Deprecated. Default is "storage"

<a name="autosave_timer"></a>
- **autosave_timer** (_number_): Autosave timer in seconds. Default is 3 seconds

<a name="lua_require_as_string"></a>
- **lua_require_as_string** (_boolean_): If true, the `require()` function will load Lua files as strings instead of Lua tables. Default is false


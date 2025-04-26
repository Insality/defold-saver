# saver API

> at /saver/saver.lua

## Functions

- [set_logger](#set_logger)
- [init](#init)
- [save_game_state](#save_game_state)
- [load_game_state](#load_game_state)
- [delete_game_state](#delete_game_state)
- [get_game_state](#get_game_state)
- [set_game_state](#set_game_state)
- [bind_save_state](#bind_save_state)
- [save_file_by_path](#save_file_by_path)
- [save_binary_by_path](#save_binary_by_path)
- [load_file_by_path](#load_file_by_path)
- [load_binary_by_path](#load_binary_by_path)
- [delete_file_by_path](#delete_file_by_path)
- [is_file_exists_by_path](#is_file_exists_by_path)
- [save_file_by_name](#save_file_by_name)
- [save_binary_by_name](#save_binary_by_name)
- [load_file_by_name](#load_file_by_name)
- [load_binary_by_name](#load_binary_by_name)
- [delete_file_by_name](#delete_file_by_name)
- [is_file_exists_by_name](#is_file_exists_by_name)
- [get_save_path](#get_save_path)
- [get_save_version](#get_save_version)
- [set_autosave_timer](#set_autosave_timer)
- [get_current_game_project_folder](#get_current_game_project_folder)
- [set_migrations](#set_migrations)
- [apply_migrations](#apply_migrations)
- [get_value](#get_value)
- [set_value](#set_value)
- [is_value_exists](#is_value_exists)

## Fields

- [autosave_timer_id](#autosave_timer_id)
- [autosave_timer_counter](#autosave_timer_counter)
- [last_autosave_time](#last_autosave_time)
- [FORMAT](#FORMAT)
- [before_save_callback](#before_save_callback)



### set_logger

---
```lua
saver.set_logger([logger_instance])
```

Customize the logging mechanism used by Defold Saver.
You can use Defold Log library or provide a custom logger.

- **Parameters:**
	- `[logger_instance]` *(table|saver.logger|nil)*: A logger object that follows the specified logging interface, including methods for trace, debug, info, warn, error. Pass nil to remove the default logger.

- **Example Usage:**

```lua
local log = require("log.log")
local saver = require("saver.saver")
saver.set_logger(log.get_logger("saver"))
```
### init

---
```lua
saver.init()
```

Initialize the Saver module. Should be called at the start of your game to set up the module.
Call it after saver.set_migrations if you are using migrations.
This function loads the game state from a file and starts the autosave timer.
If the game state file does not exist, a new game state is created.

- **Example Usage:**

```lua
saver.init()
```
### save_game_state

---
```lua
saver.save_game_state([save_name])
```

Save the current game state to a file. If no file name is provided, the default file name specified in the game.project file is used.

- **Parameters:**
	- `[save_name]` *(string|nil)*: The name of the file to save the game state to. Default is the file name specified in the game.project file under the saver.save_file key.

- **Returns:**
	- `is_saved` *(boolean)*: true if the game state was saved successfully, false otherwise.

- **Example Usage:**

```lua
-- Save the game with default name
saver.save_game_state()
-- Save the game with custom name
saver.save_game_state("custom_save")
```
### load_game_state

---
```lua
saver.load_game_state([save_name])
```

Load the game state from a file. If no file name is provided, the default file name specified in the game.project file is used.

- **Parameters:**
	- `[save_name]` *(string|nil)*: The name of the file to load the game state from. Default is the file name specified in the game.project file.

- **Returns:**
	- `is_loaded` *(boolean)*: true if the game state was loaded successfully, false if the new game state is created

- **Example Usage:**

```lua
local is_loaded = saver.load_game_state() -- Load the game state with default name
local is_loaded = saver.load_game_state("custom_save") -- Load the game state with custom name
```
### delete_game_state

---
```lua
saver.delete_game_state([save_name])
```

Delete the game state file. Doesn't affect the current game state.
If autosave is enabled, it will be rescheduled, so probably you want to immediately restart the game.

- **Parameters:**
	- `[save_name]` *(string|nil)*: The name of the file to delete the game state from. Default is the file name specified in the game.project file.

- **Returns:**
	- `is_deleted` *(boolean)*: true if the game state was deleted successfully, false otherwise.

- **Example Usage:**

```lua
-- Delete the game state with default name
saver.delete_game_state()
-- Delete the game state with custom name
saver.delete_game_state("custom_save")
```
### get_game_state

---
```lua
saver.get_game_state()
```

Returns the current game state.

- **Returns:**
	- `The` *(saver.game_state)*: current game state.

- **Example Usage:**

```lua
local game_state = saver.get_game_state()
pprint(game_state)
```
### set_game_state

---
```lua
saver.set_game_state(data)
```

Sets the current game state to the specified state.

- **Parameters:**
	- `data` *(table)*: The state to set the game state to.

- **Returns:**
	- `is_set` *(boolean)*: true if the game state was set successfully, false otherwise.

- **Example Usage:**

```lua
local game_state = saver.get_game_state()
game_state.game.level = 5
saver.set_game_state(game_state)
```
### bind_save_state

---
```lua
saver.bind_save_state(table_key_id, table_reference)
```

Binds a table reference as a part of the game state. When the game state is saved, all table references will be saved.
This is a main function to use to save your game state. You can bind multiple tables to different parts of the game state.
After binding, the table_reference will be updated with the saved data if it exists.

- **Parameters:**
	- `table_key_id` *(string)*: The table key to set the value for.
	- `table_reference` *(table)*: The table reference to bind to the game state.

- **Returns:**
	- `table_reference` *(table)*: The table_reference

- **Example Usage:**

```lua
local game_state = {
	level = 1,
	money = 100
}
saver.bind_save_state("game", game_state)
-- If we have previously saved game state, the game_state will be changed to the saved data
print(game_state.level) -- 5 (if it was saved before)
```
### save_file_by_path

---
```lua
saver.save_file_by_path(data, path, [format])
```

Saves the specified data to a file at the specified path. The data format is chosen by file path extension.

- **Parameters:**
	- `data` *(table)*: The lua table to save to the file.
	- `path` *(string)*: The absolute path to save the file to. Contains the file name and extension. Extension can be empty, .json or .lua
	- `[format]` *(string|nil)*: Optional format override (json, lua, serialized, binary). If not specified, format will be detected from paths extension or data type.

- **Returns:**
	- `is_saved` *(boolean)*: true if the file was saved successfully, false otherwise.

- **Example Usage:**

```lua
local data = {
	score = 100,
	level = 1
}
-- Get project path works on build from the Defold Editor only
local project_path = saver.get_current_game_project_folder()
-- Use path to the resources folder
local file_path = saver.get_save_path(project_path .. "/resources/data.json")
saver.save_file_by_path(data, file_path)
```
### save_binary_by_path

---
```lua
saver.save_binary_by_path(data, path)
```

Saves the specified data to a file at the specified path. The data format is binary.

- **Parameters:**
	- `data` *(string)*: The binary data to save to the file.
	- `path` *(string)*: The absolute path to save the file to. Contains the file name and extension.

- **Returns:**
	- `is_saved` *(boolean)*: true if the file was saved successfully, false otherwise.

### load_file_by_path

---
```lua
saver.load_file_by_path(path, [format])
```

Loads the data from a file at the specified path.
  NOTE: For binary data like images, use `saver.load_binary_by_path` instead.

- **Parameters:**
	- `path` *(string)*: The absolute path to load the file from. Contains the file name and extension.
	- `[format]` *(string|nil)*: Optional format override (json, lua, serialized). If not specified, format will be detected from paths extension.

- **Returns:**
	- `data` *(table|nil)*: The data loaded from the file. If the file does not exist, returns nil.

- **Example Usage:**

```lua
-- Get project path works on build from the Defold Editor only
local project_path = saver.get_current_game_project_folder()
-- Use path to the resources folder
local file_path = saver.get_save_path(project_path .. "/resources/data.json")
local data = saver.load_file_by_path(file_path)
pprint(data)
```
### load_binary_by_path

---
```lua
saver.load_binary_by_path(path)
```

Loads the binary data from a file at the specified path.

- **Parameters:**
	- `path` *(string)*: The absolute path to the file to load. Contains the file name and extension.

- **Returns:**
	- `data` *(string|nil)*: The binary data loaded from the file. If the file does not exist, returns nil.

### delete_file_by_path

---
```lua
saver.delete_file_by_path(path)
```

Deletes the file at the specified path.

- **Parameters:**
	- `path` *(string)*: The absolute path to the file to delete. Contains the file name and extension.

- **Returns:**
	- `is_deleted` *(boolean)*: true if the file was deleted successfully, false otherwise.

### is_file_exists_by_path

---
```lua
saver.is_file_exists_by_path(path)
```

Checks if the file exists at the specified path.

- **Parameters:**
	- `path` *(string)*: The absolute path to the file to check. Contains the file name and extension.

- **Returns:**
	- `is_exists` *(boolean)*: true if the file exists, false otherwise.

- **Example Usage:**

```lua
local is_project_file_exists = saver.is_file_exists_by_path(absolute_path_to_file)
```
### save_file_by_name

---
```lua
saver.save_file_by_name(data, filename, [format])
```

Saves the specified data to a file with the specified name. The file is saved in the game save folder. Filename supports subfolders.

- **Parameters:**
	- `data` *(table)*: The lua table to save to the file.
	- `filename` *(string)*: The name of the file to save the data to. Can contain subfolders.
	- `[format]` *(string|nil)*: Optional format override (json, lua, serialized, binary)

- **Returns:**
	- `is_saved` *(boolean)*: true if the file was saved successfully, false otherwise.

- **Example Usage:**

```lua
local data = {
	score = 100,
	level = 1
}
-- Save the data to the game save folder
saver.save_file_by_name(data, "data.json")
```
### save_binary_by_name

---
```lua
saver.save_binary_by_name(data, filename)
```

Saves the specified data to a file with the specified name. The data format is binary.

- **Parameters:**
	- `data` *(string)*: The binary data to save to the file.
	- `filename` *(string)*: The name of the file to save the data to. Can contain subfolders.

- **Returns:**
	- `is_saved` *(boolean)*: true if the file was saved successfully, false otherwise.

### load_file_by_name

---
```lua
saver.load_file_by_name(filename, [format])
```

Loads the data from a file with the specified name. The file is loaded from the game save folder. Filename supports subfolders.
---
  NOTE: For binary data like images, always specify FORMAT.BINARY explicitly to avoid potential crashes.

- **Parameters:**
	- `filename` *(string)*: The name of the file to load the data from. Can contain subfolders.
	- `[format]` *(string|nil)*: Optional format override (json, lua, serialized, binary)

- **Returns:**
	- `data` *(table|nil)*: The data loaded from the file. If the file does not exist, returns nil.

- **Example Usage:**

```lua
local data = saver.load_file_by_name("data.json")
pprint(data)
```
### load_binary_by_name

---
```lua
saver.load_binary_by_name(filename)
```

Loads the binary data from a file with the specified name. The file is loaded from the game save folder. Filename supports subfolders.

- **Parameters:**
	- `filename` *(string)*: The name of the file to load the binary data from. Can contain subfolders.

- **Returns:**
	- `data` *(string|nil)*: The binary data loaded from the file. If the file does not exist, returns nil.

### delete_file_by_name

---
```lua
saver.delete_file_by_name(filename)
```

Deletes the file with the specified name. The file is deleted from the game save folder. Filename supports subfolders.

- **Parameters:**
	- `filename` *(string)*: The name of the file to delete. Can contain subfolders.

- **Returns:**
	- `is_deleted` *(boolean)*: true if the file was deleted successfully, false otherwise.

- **Example Usage:**

```lua
saver.delete_file_by_name("data.json")
```
### is_file_exists_by_name

---
```lua
saver.is_file_exists_by_name(filename)
```

Checks if the file exists with the specified name. The file is checked in the game save folder. Filename supports subfolders.

- **Parameters:**
	- `filename` *(string)*: The name of the file to check. Can contain subfolders.

- **Returns:**
	- `is_exists` *(boolean)*: true if the file exists, false otherwise.

- **Example Usage:**

```lua
local is_header_downloaded = saver.is_file_exists_by_name("/cache/header.png")
```
### get_save_path

---
```lua
saver.get_save_path(filename)
```

Returns the absolute path to the game save folder. If a file name is provided, the path to the file in the game save folder is returned. Filename supports subfolders.

- **Parameters:**
	- `filename` *(string)*: The name of the file to get the path for. Can contain subfolders.

- **Returns:**
	- `path` *(string)*: The absolute path to the game save folder, or the path to the file in the game save folder if a file name is provided.

- **Example Usage:**

```lua
local file_path = saver.get_save_path("data.json")
print(file_path) -- "/Users/user/Library/Application Support/Defold Saver/data.json"
local file_path_2 = saver.get_save_path("profiles/profile1.json")
print(file_path_2) -- "/Users/user/Library/Application Support/Defold Saver/profiles/profile1.json"
```
### get_save_version

---
```lua
saver.get_save_version()
```

Returns the current save version of the game state. The save version is used to check if the game state is older than the current version. The save version increments when the game state is saved.

- **Returns:**
	- `version` *(number)*: The current save version of the game state.

- **Example Usage:**

```lua
local save_version = saver.get_save_version()
print(save_version)
```
### set_autosave_timer

---
```lua
saver.set_autosave_timer(timer)
```

Sets the autosave timer to the specified number of seconds. The autosave timer is used to automatically save the game state at regular intervals.
Use 0 to disable autosave.

- **Parameters:**
	- `timer` *(number)*: The number of seconds between autosaves. Use 0 to disable autosave.

- **Example Usage:**

```lua
saver.set_autosave_timer(5) -- Autosave every 5 seconds
saver.set_autosave_timer(0) -- Disable autosave
```
### get_current_game_project_folder

---
```lua
saver.get_current_game_project_folder()
```

Returns the absolute path to the current game project folder. It is useful when you need to save or load files from the game project folder at development.
Returns nil if the game project folder is not found. Used only at desktop platforms and if game started from the Defold Editor.

- **Returns:**
	- `The` *(string|nil)*: absolute path to the current game project folder. Nil if the game.project folder is not found.

- **Example Usage:**

```lua
local project_folder = saver.get_current_game_project_folder()
print(project_folder) -- "/Users/user/projects/my_game"
```
### set_migrations

---
```lua
saver.set_migrations([migrations_table])
```

Sets the list of migrations to apply after loading the game state manually with saver.apply_migrations() function.
Migrations are used to update the game state in case of changes to the game state structure.
Migrations are applied in order. Each migration should be a function that takes the game state as a parameter and returns the updated game state.

- **Parameters:**
	- `[migrations_table]` *((fun(game_state: saver.game_state, logger: saver.logger):nil)[])*: Array of migration functions

- **Example Usage:**

```lua
local migrations = {
	-- Migration 1
	function(game_state, logger)
		-- Assume we have new level_data field in the game state and we need to move level and score to it
		game_state.game.level_data = {
			level = game_state.game.level,
			score = game_state.game.score
		}
		game_state.game.level = nil
		game_state.game.score = nil
		return game_state
	},
	-- Migration 2
	function(game_state, logger)
		-- Just an example, multiply the score by 1000. For example we changed our score system
		game_state.game.level_data.score = game_state.game.level_data.score * 1000
		return game_state
	}
}
saver.set_migrations(migrations)
saver.init()
saver.bind_save_state("game", game_state)
saver.apply_migrations()
```
### apply_migrations

---
```lua
saver.apply_migrations()
```

Applies the migrations set by saver.set_migrations function. It should be called after loading the game state manually with saver.init() function.

- **Example Usage:**

```lua
saver.apply_migrations()
```
### get_value

---
```lua
saver.get_value(key_id, [default_value])
```

Gets the value from the saver storage. If the value does not exist, it will return the default value.

- **Parameters:**
	- `key_id` *(string)*: The storage field name
	- `[default_value]` *(<T>?)*: The default value

- **Returns:**
	- `value` *(<T>)*: The value from the saver storage

### set_value

---
```lua
saver.set_value(key_id, [value])
```

Sets the value in the saver storage.

- **Parameters:**
	- `key_id` *(string)*: The storage field name
	- `[value]` *(any)*: value

### is_value_exists

---
```lua
saver.is_value_exists(key_id)
```

Checks if the value exists in the saver storage.

- **Parameters:**
	- `key_id` *(string)*: The storage field name

- **Returns:**
	- `is_exists` *(boolean)*: true if the value exists, false otherwise


## Fields
<a name="autosave_timer_id"></a>
- **autosave_timer_id** (_nil_)

<a name="autosave_timer_counter"></a>
- **autosave_timer_counter** (_integer_)

<a name="last_autosave_time"></a>
- **last_autosave_time** (_nil_)

<a name="FORMAT"></a>
- **FORMAT** (_enum saver.FORMAT_)

<a name="before_save_callback"></a>
- **before_save_callback** (_nil_): A callback that is called before the saver saves the game state.


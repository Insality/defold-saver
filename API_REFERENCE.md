# API Reference

## Table of Contents

- [Saver Functions](#saver-functions)
  - [saver.init](#saverinit)
  - [saver.bind_save_part](#saverbind_save_part)
  - [saver.save_game_state](#saversave_game_state)
  - [saver.load_game_state](#saverload_game_state)
  - [saver.get_game_state](#saverget_game_state)
  - [saver.set_game_state](#saverset_game_state)
  - [saver.save_file_by_path](#saversave_file_by_path)
  - [saver.load_file_by_path](#saverload_file_by_path)
  - [saver.save_file_by_name](#saversave_file_by_name)
  - [saver.load_file_by_name](#saverload_file_by_name)
  - [saver.set_autosave_timer](#saverset_autosave_timer)
  - [saver.get_save_path](#saverget_save_path)
  - [saver.get_save_version](#saverget_save_version)
  - [saver.set_migrations](#saverset_migrations)
  - [saver.apply_migrations](#saverapply_migrations)
  - [saver.set_logger](#saverset_logger)
  - [saver.get_current_game_project_folder](#saverget_current_game_project_folder)
- [Storage Functions](#storage-functions)
  - [storage.set](#storageset)
  - [storage.get](#storageget)
  - [storage.get_number](#storageget_number)
  - [storage.get_string](#storageget_string)
  - [storage.get_boolean](#storageget_boolean)

## Saver

To start using the module in your project, you first need to import it. This can be done with the following line of code:

```lua
local saver = require("saver.saver")
```

## Saver Functions

The Saver module provides several functions to work with saving and loading game state:

**saver.init**
---
```lua
saver.init()
```

This function initializes the Saver module. It should be called at the start of your game to set up the module. Call it after `saver.set_migrations` if you are using migrations.

This function loads the game state from a file and starts the autosave timer. If the game state file does not exist, a new game state is created.

- **Usage Example:**

```lua
saver.init()
```

**saver.bind_save_part**
---
```lua
saver.bind_save_part(key_id, table_reference)
```

This function binds a table reference to a part of the game state. When the game state is saved, the table reference will be saved as part of the game state.

This is a main function to use to save your game state. You can bind multiple tables to different parts of the game state. After binding, the `table_reference` will be changed by the saved data.

- **Parameters:**
  - `key_id`: The table key to set the value for.
  - `table_reference`: The table reference to bind to the game state.

- **Usage Example:**

```lua
local game_state = {
  level = 1,
  money = 100
}

saver.bind_save_part("game", game_state)

-- If we have previously saved game state, the game_state will be changed to the saved data
print(game_state.level) -- 5 (if it was saved as before)
```


**saver.save_game_state**
---
```lua
saver.save_game_state([file_name])
```

This function saves the current game state to a file. If no file name is provided, the default file name specified in the `game.project` file is used.

- **Parameters:**
  - `file_name`: The name of the file to save the game state to. Default is the file name specified in the `game.project` file under the `saver.save_file` key.

- **Return Value:**
  - `true` if the game state was saved successfully, `false` otherwise.

- **Usage Example:**

```lua
-- Save the game state using the default file name
saver.save_game_state()

-- Save the game state to a file named "save.json"
saver.save_game_state("save.json")

-- Save the game state to a file named "profiles/profile1.json"
-- The nested folders will be created automatically
saver.save_game_state("profiles/profile1.json")
```


**saver.load_game_state**
---
```lua
saver.load_game_state([file_name])
```

This function loads the game state from a file. If no file name is provided, the default file name specified in the `game.project` file is used.

It used by `saver.init()` function to load the game state at the start of the game. It will load the game state from the save file.

- **Parameters:**
  - `file_name`: The name of the file to load the game state from. Default is the file name specified in the `game.project` file.

- **Return Value:**
  - `true` if the game state was loaded successfully, `false` otherwise.

- **Usage Example:**

```lua
-- Load the game state using the default file name
saver.load_game_state()

-- Load the game state from a file named "save.json"
saver.load_game_state("save.json")
```

**saver.get_game_state**
---
```lua
saver.get_game_state()
```

This function returns the current game state.

- **Return Value:**
  - The current game state.

- **Usage Example:**

```lua
local game_state = saver.get_game_state()
pprint(game_state)
```


**saver.set_game_state**
---
```lua
saver.set_game_state(state)
```

This function sets the current game state to the specified state.

It used by `saver.load_game_state()` function to set the game state after loading the game state from the save file.

- **Parameters:**
  - `state`: The state to set the game state to.

- **Return Value:**
  - `true` if the game state was set successfully, `false` otherwise.

- **Usage Example:**

```lua
local game_state = saver.get_game_state()
game_state.game.level = 5

saver.set_game_state(state)
```


**saver.save_file_by_path**
---
```lua
saver.save_file_by_path(data, file_path)
```

This function saves the specified data to a file at the specified path. The data format is choosen by file path extension.

- **Parameters:**
  - `data`: The lua table to save to the file.
  - `file_path`: The absolute path to save the file to. Contains the file name and extension. Extension can be empty, `.json` or `.lua`

- **Return Value:**
  - `true` if the file was saved successfully, `false` otherwise.

- **Usage Example:**

```lua
local data = {
  score = 100,
  level = 1
}

--- Save the path to the game save folder
local file_path = saver.get_save_path("data.json")
saver.save_file_by_path(data, file_path)
```

**saver.load_file_by_path**
---
```lua
saver.load_file_by_path(path)
```

This function loads the data from a file at the specified path.

- **Parameters:**
  - `path`: The absolute path to load the file from. Contains the file name and extension.

- **Return Value:**
  - The data loaded from the file. If the file does not exist, returns `nil`.

- **Usage Example:**

```lua
local file_path = saver.get_save_path("data.json")
local data = saver.load_file_by_path(file_path)
pprint(data)
```

**saver.save_file_by_name**
---
```lua
saver.save_file_by_name(data, file_name)
```

This function saves the specified data to a file with the specified name. The file is saved in the game save folder. Filename supports subfolders.

- **Parameters:**
  - `data`: The lua table to save to the file.
  - `file_name`: The name of the file to save the data to. Can contain subfolders.

- **Return Value:**
  - `true` if the file was saved successfully, `false` otherwise.

- **Usage Example:**

```lua
local data = {
  score = 100,
  level = 1
}

--- Save the data to the game save folder
saver.save_file_by_name(data, "data.json")
```

**saver.load_file_by_name**
---
```lua
saver.load_file_by_name(file_name)
```

This function loads the data from a file with the specified name. The file is loaded from the game save folder. Filename supports subfolders.

- **Parameters:**
  - `file_name`: The name of the file to load the data from. Can contain subfolders.

- **Return Value:**
  - The data loaded from the file. If the file does not exist, returns `nil`.

- **Usage Example:**

```lua
local data = saver.load_file_by_name("data.json")
pprint(data)
```

**saver.set_autosave_timer**
---
```lua
saver.set_autosave_timer(seconds)
```

This function sets the autosave timer to the specified number of seconds. The autosave timer is used to automatically save the game state at regular intervals.
Use `0` to disable autosave.

Autosave use the `timer.delay` function to run autosave.

- **Parameters:**
  - `seconds`: The number of seconds between autosaves. Use `0` to disable autosave.

- **Usage Example:**

```lua
saver.set_autosave_timer(5) -- Autosave every 5 seconds
```

**saver.get_save_path**
---
```lua
saver.get_save_path(file_name)
```

This function returns the absolute path to the game save folder. If a file name is provided, the path to the file in the game save folder is returned. Filename supports subfolders.

- **Parameters:**
  - `file_name`: The name of the file to get the path for. Can contain subfolders.

- **Return Value:**
  - The absolute path to the game save folder, or the path to the file in the game save folder if a file name is provided.

- **Usage Example:**

```lua
local file_path = saver.get_save_path("data.json")
print(file_path) -- "/Users/user/Library/Application Support/Defold Saver/data.json"

local file_path_2 = saver.get_save_path("profiles/profile1.json")
print(file_path_2) -- "/Users/user/Library/Application Support/Defold Saver/profiles/profile1.json"
```

**saver.get_save_version**
---
```lua
saver.get_save_version()
```

This function returns the current save version of the game state. The save version is used to check if the game state is older than the current version. The save version increments when the game state is saved.

- **Return Value:**
  - The current save version of the game state.

- **Usage Example:**

```lua
local save_version = saver.get_save_version()
print(save_version)
```

**saver.set_migrations**
---
```lua
saver.set_migrations(migration_list)
```

This function sets the list of migrations to apply after loading the game state manually with `saver.apply_migrations()` function. Migrations are used to update the game state in case of changes to the game state structure. Migrations are applied in order. Each migration should be a function that takes the game state as a parameter and returns the updated game state.

- **Parameters:**
  - `migration_list`: The list of migrations to apply.

- **Usage Example:**

```lua
local migrations = {
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
  function(game_state, logger)
	-- Just an example, multiply the score by 1000. For example we changed our score system
	game_state.game.level_data.score = game_state.game.level_data.score * 1000
	return game_state
  }
}

saver.set_migrations(migrations)
saver.init()
saver.bind_save_part("game", game_state)
saver.apply_migrations()
```

**saver.apply_migrations**
---
```lua
saver.apply_migrations()
```

This function applies the migrations set by `saver.set_migrations` function. It should be called after loading the game state manually with `saver.init()` function.

- **Usage Example:**

```lua
saver.apply_migrations()
```


**saver.set_logger**
---
```lua
saver.set_logger(logger)
```

Customize the logging mechanism used by **Defold Saver**. You can use **Defold Log** library or provide a custom logger.

```lua
saver.set_logger(logger_instance)
```

- **Parameters:**
  - `logger_instance`: A logger object that follows the specified logging interface, including methods for `trace`, `debug`, `info`, `warn`, `error`. Pass `nil` to remove the default logger.

- **Usage Example:**

Using the [Defold Log](https://github.com/Insality/defold-log) module:

```lua
local log = require("log.log")
local saver = require("saver.saver")

saver.set_logger(log.get_logger("saver"))
```

Creating a custom user logger:
```lua
local logger = {
    trace = function(_, message, context) end,
    debug = function(_, message, context) end,
    info = function(_, message, context) end,
    warn = function(_, message, context) end,
    error = function(_, message, context) end
}
saver.set_logger(logger)
```

Remove the default logger:
```lua
saver.set_logger(nil)
```

**saver.get_current_game_project_folder**
---
```lua
saver.get_current_game_project_folder()
```

This function returns the absolute path to the current game project folder. It is useful when you need to save or load files from the game project folder at development.
Returns `nil` if the game project folder is not found. Used only at desktop platforms and if game started from the Defold Editor.

- **Return Value:**
  - The absolute path to the current game project folder. Nil if the `game.project` folder is not found.

- **Usage Example:**

```lua
local project_folder = saver.get_current_game_project_folder()
print(project_folder)
```

## Storage Functions

The Storage module provides several functions to work with key-value storage:

**storage.set**
---
```lua
storage.set(id, value)
```

This function sets the value of the specified key in the storage. Type of value is auto-detected and should be one of the following: `number`, `string`, `boolean`.

- **Parameters:**
  - `id`: The key to set the value for.
  - `value`: The value to set for the key.

- **Return Value:**
  - `true` if the value was set successfully, `false` otherwise.

- **Usage Example:**

```lua
storage.set("score", 100)
storage.set("level", "level_1")
storage.set("is_paused", true)
```

**storage.get**
---
```lua
storage.get(id, [default_value])
```

This function gets the value of the specified key from the storage. If the key does not exist, the default value is returned.

- **Parameters:**
  - `id`: The key to get the value for.
  - `default_value`: The default value to return if the key does not exist. Default is `nil`.

- **Return Value:**
  - The value of the key, or the default value if the key does not exist.

- **Usage Example:**

```lua
local score = storage.get("score", 0) -- 100
local level = storage.get("level", "level_1") -- "level_1"
local is_paused = storage.get("is_paused", false) -- true
```

**storage.get_number**
---
```lua
storage.get_number(id, [default_value])
```

This function gets the value of the specified key from the storage as a number. If the key does not exist or its value is not a number, the default value is returned.

- **Parameters:**
  - `id`: The key to get the value for.
  - `default_value`: The default value to return if the key does not exist or its value is not a number. Default is `0`.

- **Return Value:**
  - The value of the key as a number, or the default value if the key does not exist or its value is not a number.

- **Usage Example:**

```lua
local score = storage.get_number("score", 0) -- 100
```

**storage.get_string**
---
```lua
storage.get_string(id, [default_value])
```

This function gets the value of the specified key from the storage as a string. If the key does not exist or its value is not a string, the default value is returned.

- **Parameters:**
  - `id`: The key to get the value for.
  - `default_value`: The default value to return if the key does not exist or its value is not a string. Default is an empty string.

- **Return Value:**
  - The value of the key as a string, or the default value if the key does not exist or its value is not a string.

- **Usage Example:**

```lua
local level = storage.get_string("level", "level_1") -- "level_1"
```

**storage.get_boolean**
---
```lua
storage.get_boolean(id, [default_value])
```

This function gets the value of the specified key from the storage as a boolean. If the key does not exist or its value is not a boolean, the default value is returned.

- **Parameters:**
  - `id`: The key to get the value for.
  - `default_value`: The default value to return if the key does not exist or its value is not a boolean. Default is `false`.

- **Return Value:**
  - The value of the key as a boolean, or the default value if the key does not exist or its value is not a boolean.

- **Usage Example:**

```lua
local is_paused = storage.get_boolean("is_paused", false) -- true
```

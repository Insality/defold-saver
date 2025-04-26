# Use Cases

This section provides examples of how to use the `saver` module.


## Add your game profile data

Saver module allows you to bind lua table references. After that, this table will be saved and loaded automatically. You should not re-create the table after loading the game state.

```lua
local saver = require("saver.saver")

local game_data = {
	score = 0,
	level = 1,
}

function init(self)
	saver.init()
	saver.bind_save_state("game", game_data)
end
```


## Add annotations to your game profile data

The default annotation class for game state is `saver.game_state`. You can add your own fields to it right before your place with `saver.bind_save_state`.

```lua
function init(self)
	---Add save states to annotations
	---@class saver.game_state
	---@field profile profile.state @The `profile.state` is your persistent data annotation class
	---@field settings settings.state @The `settings.state` is your persistent data annotation class

	saver.init()
	saver.bind_game_state("profile", profile.state)
	saver.bind_game_state("settings", settings.state)
end
```


## Debug your game profile data

You can use `saver.get_game_state()` to get the current game state. It will return the table with all bound states.

```lua
function init(self)
	saver.init()
	saver.bind_save_state("game", game_data)

	-- Inspect the game state
	pprint(saver.get_game_state())
end
```


## Make your library works with Defold Saver module

If you wish to make a easy-to-use integration with the **Defold Saver** module, you can use the following approach:

```lua
-- my_library.lua
local M = {}

-- Make an persistent state for your library, which should be saved/loaded
M.state = {
	value = 0,
	other_value = 0,
}

-- Other functions of your library
```

```lua
-- Integration in the game
local saver = require("saver.saver")
local my_library = require("my_library")

function init(self)
	saver.init()
	saver.bind_save_state("my_library", my_library.state)

	-- After bind save state, you can use your library functions
	-- The state will be loaded from the save file and will be saved automatically
	my_library.init()
end
```

## Use Migrations

Migration is a way to update your save data when you change the structure of the save data. You can use the `saver.set_migrations` function to set the list of migrations. The migration is a function that receives the save data and returns the updated save data.

The migrations can be useful if the game has been released and you need to update the save data structure.

```lua
local saver = require("saver.saver")

local migrations = {
	-- First migration
	function(data, logger)
		-- Make some changes in the data
		data.game.level = 10
		data.game.score = nil
	end,
	-- Second migration
	function(data, logger)
		data.settings.ui_params = {
			scale = 1,
			theme = "dark",
		}
	end,
}

function init(data)
	saver.set_migrations(migrations)
	saver.init()
	saver.bind_save_state("game", game_data)
	saver.bind_save_state("settings", settings_data)

	-- We need to call `set_migrations` before `init` to correct
	-- tracking of current migration version
	saver.apply_migrations()
end
```


## Use Storage

Storage is a simple key-value storage. It allows you to save and load values by key. It supports string, number, and boolean values. The functions `get_string`, `get_number`, and `get_boolean` will be useful if you are using lua annotations and want to get the value in the correct type.

```lua
local storage = require("saver.storage")

function init(self)
	storage.set("key", "value")
	local value = storage.get("key") -- Returns "value"
	local value_str = storage.get_string("key", "default_value") -- Returns "value"
	local value_num = storage.get_number("key", 0) -- Returns 0
	local value_bool = storage.get_boolean("key", false) -- Returns false
end

```

## Use several game states

While using **Defold Saver**, you can make and use a few game states. It can be useful if you have a few game modes or profiles. Or if you want to make an snapshot of the game state to debug some issues.

```lua

---@param game_state_name string @Example game_state.json
local function save_game_state(game_state_name)
	-- Save the specific game state
	saver.save_game_state(game_state_name)
end

---@param game_state_name string @Example game_state.json
local function load_game_state(game_state_name)
	-- Reboot and load the specific game state
	-- Also disable autosave to prevent overwriting the game state
	sys.reboot("--config=saver.save_name=" .. game_state_name, "--config=saver.autosave_timer=0")
end

--- Usage

-- When you want to save the game state
save_game_state("game_state_1.json")

-- When you want to load the game state
load_game_state("game_state_1.json")
```

## How to save file at folder

With **Defold Saver** module you also can save and load files. You able to use next functions:

```lua
-- This function will save the data inside you game save folder. You can use subfolders in the path
-- file name should contain the file name and extension
saver.save_file_by_name(data, file_name)
saver.load_file_by_name(file_name)

-- This function will save the data to the absolute path
-- file path should contain the file name and extension
saver.save_file_by_path(data, file_path)
saver.load_file_by_path(path)
```

## How I initialize the Saver module

I use set of `init_*` function at bootstrap loader script. This is how I initialize the saver module.

```lua
---@param self scene.loader
local function init_saver(self)
	---@class saver.game_state
	---@field lang lang.state
	---@field token token.state
	---@field quest quest.state
	---@field sound sound.state

	saver.init()
	saver.bind_save_state("lang", lang.state)
	saver.bind_save_state("token", token.state)
	saver.bind_save_state("quest", quest.state)
	saver.bind_save_state("sound", sound.state)
end

function init_lang(self)
	lang.init()
end

function init_token(self)
	token.init()
end

function init_quest(self)
	quest.init()
end

local function init(self)
	init_saver(self)
	init_lang(self)
	init_token(self)
	init_quest(self)
end

```

## Use Custom json.encode function

In case you want to use your own json.encode function, you can set it to the saver module.

Currently you should override it in `saver.saver_internal` module.

```lua
local json = require("json")
local saver_internal = require("saver.saver_internal")

saver_internal.json_encode = json.sorted_encode
```

## The Saver and Defold userdata

In case your data contains a Defold userdata, like `vmath.vector3`, `hash` etc, you should not use the `json` or `lua` file format, due the userdata will be lost. Use `serialized` format instead.

Serialized format can be selected by not specifying the format (`.json` or `.lua` extension) in `saver.save_name` game.project setting. Example:

```
saver.save_name = "game"
```


## Saving and Loading Raw Binary Data

You can use the Saver library to save and load raw binary data, such as images, audio files, or any other binary file format:

```lua
local saver = require("saver.saver")

-- Save a PNG image to the save directory
local function save_image(file_url, file_name)
    -- Load image from url
    local file_url = "https://raw.githubusercontent.com/Insality/defold-saver/refs/heads/main/media/logo.png"
    http.request(file_url, "GET", function(_, id, response)
        if response.status == 200 or response.status == 304 then
            local image_data = response.response
            local success = saver.save_binary_by_name(image_data, file_name)
            return success
        end
    end)
end

-- Load a saved PNG image from the save directory
local function load_image(save_name, node_id)
    -- Load the binary data
    local image_data = saver.load_binary_by_name(save_name)
    local img = image.load(image_data)
    if not image_data then
        print("Failed to load saved image:", save_name)
        return nil
    end

    -- Create an image from the binary data
    if not img then
        print("Unable to load image data")
        return nil
    end

    -- Create a texture ID based on the save name
    local texture_id = save_name .. "_texture"

    -- Create a new texture from the image and set it to the GUI node
    if gui.new_texture(texture_id, img.width, img.height, img.type, img.buffer) then
        gui.set_texture(node_id, texture_id)
        return texture_id
    else
        print("Failed to create texture from image data")
        return nil
    end
end

-- Usage
save_image("assets/my_image.png", "saved_image.png")
load_image("saved_image.png", gui.get_node("image_node"))
```

## Saving and Loading Lua Tables with Defold Userdata

When working with Lua tables that contain Defold userdata like `vmath.vector3`, `hash`, or other Defold-specific types, you need to use binary or serialized format to preserve these values:

```lua
local saver = require("saver.saver")

-- Save player data including position (vector3) and object ID (hash)
local function save_player_data(player)
    local player_data = {
        position = player.position,       -- vmath.vector3
        rotation = player.rotation,       -- vmath.quat
        id = player.id,                  -- hash
        velocity = player.velocity,      -- vmath.vector3
        game_objects = player.game_objects -- might contain go.* references
    }

    local success = saver.save_binary_by_name(player_data, "player_data")
    return success
end

-- Load player data
local function load_player_data()
    local player_data = saver.load_binary_by_name("player_data")
    if not player_data then
        print("Failed to load player data")
        return nil
    end

    -- Now you can safely use the Defold userdata
    local position = player_data.position -- This is a valid vmath.vector3
    local id = player_data.id            -- This is a valid hash

    return player_data
end

-- Usage example
local player = {
    position = vmath.vector3(100, 200, 0),
    rotation = vmath.quat_rotation_z(math.rad(45)),
    id = hash("player"),
    velocity = vmath.vector3(5, 0, 0),
}

save_player_data(player)
local loaded_player = load_player_data()

-- You can now use the loaded data with all userdata intact
print("Player position:", loaded_player.position)
```

## Explicitly Selecting Format

If you need more control over the format, you can explicitly specify it when saving or loading files:

```lua
local saver = require("saver.saver")

-- Available formats
local JSON_FORMAT = saver.FORMAT.JSON     -- For human-readable JSON files
local LUA_FORMAT = saver.FORMAT.LUA       -- For Lua files (more flexible than JSON)
local SERIALIZED_FORMAT = saver.FORMAT.SERIALIZED -- For Lua tables with userdata using sys.save/sys.load

-- Save game settings in JSON format for human readability
local settings = {
    music_volume = 0.8,
    sfx_volume = 1.0,
    difficulty = "normal",
    controls = {
        up = "w",
        down = "s",
        left = "a",
        right = "d"
    }
}

-- Save as JSON for human-readability
saver.save_file_by_name(settings, "settings.json", JSON_FORMAT)

-- Save the same data in Lua format
saver.save_file_by_name(settings, "settings.lua", LUA_FORMAT)

-- Save the same data in binary format
saver.save_binary_by_name(settings, "settings")

-- Load from any format
local json_settings = saver.load_file_by_name("settings.json", JSON_FORMAT)
local lua_settings = saver.load_file_by_name("settings.lua", LUA_FORMAT)
local binary_settings = saver.load_binary_by_name("settings")

-- You can also let the library auto-detect the format based on file extension
local auto_json_settings = saver.load_file_by_name("settings.json")
local auto_lua_settings = saver.load_file_by_name("settings.lua")
```

## Download file by URL and save it inside project data

You can use the `saver.save_file_by_name` to save binary data to the project folder, like images, audio files, etc.

```lua
local saver = require("saver.saver")

local file_url = "https://raw.githubusercontent.com/Insality/defold-saver/refs/heads/main/media/logo.png"
http.request(file_url, "GET", function(_, id, response)
	if response.status == 200 then
		saver.save_binary_by_name(response.response, "cache/logo.png")
	end
end)
```


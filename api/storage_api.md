# saver.storage API

> at /saver/storage.lua

## Functions

- [reset_state](#reset_state)
- [get](#get)
- [get_number](#get_number)
- [get_string](#get_string)
- [get_boolean](#get_boolean)
- [set](#set)

## Fields

- [state](#state)



### reset_state

---
```lua
storage.reset_state()
```

### get

---
```lua
storage.get(name, [default_value])
```

Get the value from the storage.

- **Parameters:**
	- `name` *(string)*: The storage field name
	- `[default_value]` *(boolean|string|number|nil)*: The default value

- **Returns:**
	- `` *(boolean|string|number|nil)*:

### get_number

---
```lua
storage.get_number(name, [default_value])
```

Get the number from the storage.

- **Parameters:**
	- `name` *(string)*: The storage field name
	- `[default_value]` *(number|nil)*: The default value. If not set, then it will be 0.

- **Returns:**
	- `` *(number)*:

### get_string

---
```lua
storage.get_string(name, [default_value])
```

Get the string from the storage.

- **Parameters:**
	- `name` *(string)*: The storage field name
	- `[default_value]` *(string|nil)*: The default value. If not set, then it will be an empty string.

- **Returns:**
	- `` *(string)*:

### get_boolean

---
```lua
storage.get_boolean(name, [default_value])
```

Get the boolean from the storage.

- **Parameters:**
	- `name` *(string)*: The storage field name
	- `[default_value]` *(boolean|nil)*: The default value. If not set, then it will be `false`.

- **Returns:**
	- `` *(boolean)*:

### set

---
```lua
storage.set(id, value)
```

Set the value to storage

- **Parameters:**
	- `id` *(string)*: The record id
	- `value` *(boolean|string|number)*: value

- **Returns:**
	- `` *(boolean)*: true if the value was set, nil otherwise


## Fields
<a name="state"></a>
- **state** (_nil_):  Persistent storage


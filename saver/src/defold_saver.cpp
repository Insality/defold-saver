#define LIB_NAME "DefoldSaver"
#define MODULE_NAME "defold_saver"

#include <dmsdk/sdk.h>
#include <dmsdk/dlib/crypt.h>

// Source: https://github.com/defold/extension-crypt/blob/master/crypt/src/crypt.cpp
// Inline this two functions to avoid linking with the extension-crypt library

static int Crypt_Base64Encode(lua_State* L) {
	DM_LUA_STACK_CHECK(L, 1);

	size_t srclen;
	const char* src = luaL_checklstring(L, 1, &srclen);

	// 4 characters to represent every 3 bytes with padding applied
	// for binary data which isn't an exact multiple of 3 bytes.
	// https://stackoverflow.com/a/7609180/1266551
	uint32_t dstlen = srclen * 4 / 3 + 4;
	uint8_t* dst = (uint8_t*)malloc(dstlen);

	if (dmCrypt::Base64Encode((const uint8_t*)src, srclen, dst, &dstlen)) {
		lua_pushlstring(L, (char*)dst, dstlen);
	} else {
		lua_pushnil(L);
	}

	free(dst);
	return 1;
}

static int Crypt_Base64Decode(lua_State* L) {
	DM_LUA_STACK_CHECK(L, 1);

	size_t srclen;
	const char* src = luaL_checklstring(L, 1, &srclen);

	uint32_t dstlen = srclen * 3 / 4;
	uint8_t* dst = (uint8_t*)malloc(dstlen);

	if (dmCrypt::Base64Decode((const uint8_t*)src, srclen, dst, &dstlen)) {
		lua_pushlstring(L, (char*)dst, dstlen);
	} else {
		lua_pushnil(L);
	}

	free(dst);
	return 1;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] = {
	{"encode_base64", Crypt_Base64Encode},
	{"decode_base64", Crypt_Base64Decode},
	{0, 0}
};

static void LuaInit(lua_State* L) {
	int top = lua_gettop(L);

	luaL_register(L, MODULE_NAME, Module_methods);
	lua_pop(L, 1);

	assert(top == lua_gettop(L));
}

static dmExtension::Result Initialize(dmExtension::Params* params) {
	LuaInit(params->m_L);
	return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(DefoldSaver, LIB_NAME, 0, 0, Initialize, 0, 0, 0)

-- A tiny stand-in for Roblox, so the game's real modules can run in Lune without Studio.
-- It loads the real files from src/ and gives them fake `game`, `script` and `require`.
-- Only what the tested modules need is faked. It is not a Roblox emulator.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local luneTask = require("@lune/task")

local harness = {}

-- Lune's file calls cannot run inside a metamethod, so list every file under src/ up front.
local files: { [string]: boolean } = {}
local dirs: { [string]: boolean } = {}
local function scan(path: string)
	dirs[path] = true
	for _, name in fs.readDir(path) do
		local child = `{path}/{name}`
		if fs.isDir(child) then
			scan(child)
		else
			files[child] = true
		end
	end
end
scan("src")

-- A fake instance tree that mirrors the Rojo mapping: a folder node finds `name.luau` files and
-- sub-folders on disk.
local function makeNodes(world)
	local function folder(path: string, parent: any)
		local node = { Name = path, Parent = parent }
		return setmetatable(node, {
			__index = function(self, key)
				if key == "WaitForChild" or key == "FindFirstChild" then
					return function(_, name)
						return self[name]
					end
				end
				local file = `{path}/{key}.luau`
				if files[file] then
					local child = { Name = key, Parent = self, __file = file }
					rawset(self, key, child)
					return child
				end
				if dirs[`{path}/{key}`] then
					local child = folder(`{path}/{key}`, self)
					rawset(self, key, child)
					return child
				end
				return nil
			end,
		})
	end
	return folder
end

local function fakeEnum()
	return setmetatable({}, {
		__index = function(self, key)
			local child = fakeEnum()
			rawset(self, key, child)
			return child
		end,
	})
end

-- Builds a fresh fake world. `options.services` can replace or add fake Roblox services
-- ("Players", "DataStoreService", ...).
function harness.newWorld(options: { services: { [string]: any }? }?)
	local world = { cache = {}, services = {} }
	local folder = makeNodes(world)

	local shared = folder("src/shared", nil)
	local server = folder("src/server", nil)
	world.services.ReplicatedStorage = {
		Shared = shared,
		WaitForChild = function(self, name)
			return self[name]
		end,
	}
	world.services.ServerScriptService = { Server = server }
	world.services.RunService = {
		IsServer = function()
			return true
		end,
		Heartbeat = {
			Wait = function()
				return 1 / 60
			end,
		},
	}
	for name, service in (options and options.services) or {} do
		world.services[name] = service
	end

	local game = {
		GetService = function(_, name)
			return world.services[name]
		end,
		BindToClose = function() end,
	}

	-- Just enough of Instance for Remotes: instances with a name, children found by name, and
	-- RemoteEvents whose handlers a test can fire with `remote.__fireServer(player, ...)`.
	local Instance = {
		new = function(class: string)
			local children: { [string]: any } = {}
			local handlers: { (...any) -> () } = {}
			local inst: { [string]: any } = {
				ClassName = class,
				__children = children,
				OnServerEvent = {
					Connect = function(_, handler)
						table.insert(handlers, handler)
					end,
				},
				FireClient = function() end,
				WaitForChild = function(_, name)
					return children[name]
				end,
			}
			inst.__fireServer = function(...)
				for _, handler in handlers do
					handler(...)
				end
			end
			return setmetatable(inst, {
				__newindex = function(self, key, value)
					rawset(self, key, value)
					if key == "Parent" and type(value) == "table" and value.__children then
						value.__children[self.Name] = self
					end
				end,
			})
		end,
	}

	local env: { [string]: any } = {
		game = game,
		Instance = Instance,
		task = luneTask,
		Enum = fakeEnum(),
		Vector3 = {
			new = function(x, y, z)
				return { X = x, Y = y, Z = z }
			end,
		},
		Color3 = {
			fromRGB = function(r, g, b)
				return { R = r / 255, G = g / 255, B = b / 255 }
			end,
		},
	}

	local function load(node: any): any
		local file = node.__file
		if world.cache[file] ~= nil then
			return world.cache[file]
		end
		local fileEnv = table.clone(env)
		fileEnv.script = node
		fileEnv.require = function(target)
			return load(target)
		end
		local chunk = luau.load(fs.readFile(file), { debugName = file, environment = fileEnv })
		local result = chunk()
		world.cache[file] = result
		return result
	end

	-- Loads a module by its path under src/, for example "server/Services/DataService".
	function world.load(path: string): any
		local node: any = if path:sub(1, 7) == "shared/" then shared else server
		for part in path:gsub("^%a+/", ""):gmatch("[^/]+") do
			node = node[part]
			assert(node, `no such module: {path}`)
		end
		return load(node)
	end

	return world
end

return harness

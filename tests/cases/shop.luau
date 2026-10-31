-- M4: items, equipment rules and the shop service.
-- A test case file: `return function(t)` and use t.check, t.section and t.harness.

return function(t)
	local check, section, harness, task = t.check, t.section, t.harness, t.task

	-- M4: items, equipment rules and the shop ----------------------------------------------------
	section("Items and equipment")
	do
		local world = harness.newWorld()
		local Items = world.load("shared/Config/Items")
		local count = 0
		for key, item in Items do
			count += 1
			check(`{key}: id matches its key and it has a price`, item.id == key and item.price > 0)
			if item.slot == "weapon" then
				check(`{key}: a weapon raises damage`, (item.damageMultiplier or 0) > 1)
			else
				check(
					`{key}: armour adds health`,
					item.slot == "armor" and (item.healthBonus or 0) > 0
				)
			end
		end
		check("the shop has items", count >= 4, count)

		local Equipment = world.load("shared/Equipment")
		local function dataWith(fields: any)
			local data = { gold = 0, path = "Yodha", inventory = {}, equipped = {} }
			for key, value in fields do
				data[key] = value
			end
			return data
		end

		check(
			"buying checks the item exists",
			select(2, Equipment.checkBuy(dataWith({ gold = 999 }), "Nope")) == "unknown item"
		)
		check(
			"buying needs enough gold",
			select(2, Equipment.checkBuy(dataWith({ gold = 5 }), "IronSword")) == "not enough gold"
		)
		check(
			"buying works with enough gold",
			Equipment.checkBuy(dataWith({ gold = 40 }), "IronSword")
		)
		check(
			"you cannot buy something twice",
			select(
				2,
				Equipment.checkBuy(
					dataWith({ gold = 999, inventory = { IronSword = 1 } }),
					"IronSword"
				)
			) == "already owned"
		)
		check(
			"you cannot equip what you do not own",
			select(2, Equipment.checkEquip(dataWith({}), "IronSword")) == "not owned"
		)
		check(
			"you cannot equip a weapon for the wrong path",
			select(
				2,
				Equipment.checkEquip(
					dataWith({ path = "Rishi", inventory = { IronSword = 1 } }),
					"IronSword"
				)
			) == "wrong path"
		)

		local armed =
			dataWith({ inventory = { IronSword = 1 }, equipped = { weapon = "IronSword" } })
		check("an equipped weapon raises damage", Equipment.damageMultiplier(armed) == 1.15)
		armed.path = "Rishi"
		check("a weapon for another path does nothing", Equipment.damageMultiplier(armed) == 1)
		check(
			"an equipped item you no longer own does nothing",
			Equipment.damageMultiplier(dataWith({ equipped = { weapon = "IronSword" } })) == 1
		)
		check(
			"an item in the wrong slot does nothing",
			Equipment.healthBonus(
				dataWith({ inventory = { IronSword = 1 }, equipped = { armor = "IronSword" } })
			) == 0
		)
		check(
			"armour adds health",
			Equipment.healthBonus(
				dataWith({ inventory = { LeatherVest = 1 }, equipped = { armor = "LeatherVest" } })
			) == 30
		)
	end

	section("Shop service")
	do
		-- Starts the real DataService and ShopService against a fake DataStore with one player.
		local function startShop(record: any)
			local store = { saved = { Player_1 = record } }
			function store.GetAsync(_, key)
				return store.saved[key]
			end
			function store.UpdateAsync(_, key, transform)
				store.saved[key] = transform(store.saved[key])
			end
			local player = { Name = "Shopper", UserId = 1, Parent = true }
			local world = harness.newWorld({
				services = {
					Players = {
						GetPlayers = function()
							return { player }
						end,
						PlayerAdded = { Connect = function() end },
						PlayerRemoving = { Connect = function() end },
					},
					DataStoreService = {
						GetDataStore = function()
							return store
						end,
					},
				},
			})
			local DataService = world.load("server/Services/DataService")
			local ShopService = world.load("server/Services/ShopService")
			local Remotes = world.load("shared/Remotes")
			DataService.start()
			ShopService.start()
			task.wait(0.2)
			return {
				player = player,
				data = DataService.get(player),
				shop = ShopService,
				remote = function(name: string)
					return Remotes.get(name)
				end,
			}
		end

		local game1 = startShop({ version = 2, level = 1, gold = 100 })
		local data = game1.data
		check("the shopper has 100 gold to start", data.gold == 100)

		local ok = game1.shop.buy(game1.player, "IronSword")
		check("buying an item works", ok and data.inventory.IronSword == 1)
		check("buying takes the gold", data.gold == 60, data.gold)

		local again, reason = game1.shop.buy(game1.player, "IronSword")
		check("buying twice is refused", not again and reason == "already owned")
		check("a refused purchase takes no gold", data.gold == 60)

		local poor, poorReason = game1.shop.buy(game1.player, "SteelSword")
		check("buying without enough gold is refused", not poor and poorReason == "not enough gold")
		check("a refused purchase keeps the gold", data.gold == 60)

		local unknown = game1.shop.buy(game1.player, "FreeMoney")
		check("buying an unknown item is refused", not unknown)

		local equipped = game1.shop.equip(game1.player, "IronSword")
		check("equipping an owned weapon works", equipped and data.equipped.weapon == "IronSword")
		check(
			"equipping something you do not own is refused",
			not game1.shop.equip(game1.player, "SteelSword")
		)

		local dropped = game1.shop.unequip(game1.player, "weapon")
		check("unequipping works", dropped and data.equipped.weapon == nil)
		check(
			"unequipping an empty slot is refused",
			not game1.shop.unequip(game1.player, "weapon")
		)
		check(
			"unequipping an unknown slot is refused",
			not game1.shop.unequip(game1.player, "helmet")
		)

		-- The remote handlers must survive anything a client sends.
		local before = data.gold
		for _, junk in { 123, true, {}, "", "x" } do
			game1.remote("BuyItem").__fireServer(game1.player, junk)
			game1.remote("EquipItem").__fireServer(game1.player, junk)
			game1.remote("UnequipSlot").__fireServer(game1.player, junk)
		end
		game1.remote("BuyItem").__fireServer(game1.player)
		check(
			"junk remote arguments change nothing",
			data.gold == before and data.equipped.weapon == nil
		)

		game1.remote("BuyItem").__fireServer(game1.player, "LeatherVest")
		check(
			"a valid remote purchase works",
			data.inventory.LeatherVest == 1 and data.gold == before - 50
		)
		game1.remote("EquipItem").__fireServer(game1.player, "LeatherVest")
		check("a valid remote equip works", data.equipped.armor == "LeatherVest")
		game1.remote("UnequipSlot").__fireServer(game1.player, "armor")
		check("a valid remote unequip works", data.equipped.armor == nil)
	end
end

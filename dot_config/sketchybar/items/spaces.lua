local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.icon_map")

-- AeroSpace カスタムイベントを登録
sbar.add("event", "aerospace_workspace_change")

-- ワークスペースの色設定（アルファベット順にグラデーション）
local function get_workspace_color(ws)
	local color_map = {
		W = colors.cmap_8,  -- Web
		T = colors.cmap_5,  -- Terminal
		I = colors.cmap_6,  -- IDE
		M = colors.cmap_9,  -- Meeting
		C = colors.cmap_2,  -- Communication
		A = colors.cmap_1,  -- AI
		D = colors.cmap_3,  -- Docs
		G = colors.cmap_4,  -- DB/API
	}
	return color_map[ws] or colors.grey
end

-- 表示するワークスペースの順序
local workspace_order = { "W", "T", "I", "M", "C", "A", "D", "G" }

-- ワークスペースアイテムを格納
local spaces = {}
local space_names = {}

-- 各ワークスペースのアイテムを作成
for idx, ws in ipairs(workspace_order) do
	local space = sbar.add("item", "space." .. ws, {
		icon = {
			font = {
				family = settings.font.text,
				style = settings.font.style_map["Bold"],
				size = 14,
			},
			string = ws,
			padding_left = 6,
			padding_right = 0,
			color = get_workspace_color(ws),
			highlight_color = colors.tn_black3,
		},
		label = {
			padding_right = 8,
			padding_left = 4,
			color = get_workspace_color(ws),
			highlight_color = colors.tn_black3,
			font = "sketchybar-app-font-bg:Regular:14.0",
			y_offset = -1,
		},
		padding_right = 2,
		padding_left = 2,
		background = {
			color = colors.transparent,
			height = 22,
			border_width = 0,
			border_color = colors.transparent,
		},
		drawing = false, -- 初期状態は非表示
	})

	spaces[ws] = space
	space_names[#space_names + 1] = space.name

	-- パディング用スペーサー
	sbar.add("item", "space.padding." .. ws, {
		width = settings.group_paddings,
		drawing = false,
	})

	-- クリックでワークスペース切り替え
	space:subscribe("mouse.clicked", function(env)
		sbar.exec("aerospace workspace " .. ws)
	end)
end

-- ワークスペースをブラケットでまとめる
local spaces_bracket = sbar.add("bracket", space_names, {
	background = {
		color = colors.background,
		border_color = colors.accent3,
		border_width = 2,
	},
})

-- 特定ワークスペースのアプリアイコンを更新
local function update_space_icons(ws)
	sbar.exec("aerospace list-windows --workspace " .. ws .. " --format '%{app-name}'", function(result)
		local icon_line = ""
		local has_apps = false

		for app in result:gmatch("[^\r\n]+") do
			has_apps = true
			local lookup = app_icons[app]
			local icon = lookup or app_icons["default"]
			icon_line = icon_line .. icon
		end

		if spaces[ws] then
			spaces[ws]:set({ label = icon_line })
		end
	end)
end

-- ワークスペース状態を更新する関数
local function update_spaces()
	-- 全ワークスペース（ウィンドウがあるもの）を取得
	sbar.exec("aerospace list-workspaces --all", function(all_ws)
		-- 現在のワークスペースを取得
		sbar.exec("aerospace list-workspaces --focused", function(focused)
			local current = focused:match("%S+") or ""

			-- ウィンドウがあるワークスペースをセットに変換
			local active_workspaces = {}
			for ws in all_ws:gmatch("%S+") do
				active_workspaces[ws] = true
			end

			-- 各ワークスペースの表示を更新
			for _, ws in ipairs(workspace_order) do
				local is_active = active_workspaces[ws]
				local is_current = (ws == current)

				if spaces[ws] then
					-- アクティブなワークスペースのみ表示
					spaces[ws]:set({ drawing = is_active })
					sbar.set("space.padding." .. ws, { drawing = is_active })

					if is_current then
						spaces[ws]:set({
							icon = { highlight = true },
							label = { highlight = true },
							background = {
								height = 25,
								border_color = get_workspace_color(ws),
								color = get_workspace_color(ws),
								corner_radius = 6,
							},
						})
					elseif is_active then
						spaces[ws]:set({
							icon = { highlight = false },
							label = { highlight = false },
							background = {
								height = 22,
								border_color = colors.transparent,
								color = colors.transparent,
								corner_radius = 0,
							},
						})
					end

					-- アプリアイコンを更新
					if is_active then
						update_space_icons(ws)
					end
				end
			end
		end)
	end)
end

-- 専用オブザーバーでイベントを購読
local space_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

space_observer:subscribe("aerospace_workspace_change", function(env)
	update_spaces()
end)

space_observer:subscribe("front_app_switched", function(env)
	update_spaces()
end)

-- スリープ復帰時にも更新
space_observer:subscribe("system_woke", function(env)
	update_spaces()
end)

-- 定期的に更新（routine イベント: 約5秒ごと）
space_observer:subscribe("routine", function(env)
	update_spaces()
end)

-- 初回ロード時に遅延して更新（aerospace の準備を待つ）
sbar.exec("sleep 0.5 && echo done", function()
	update_spaces()
end)

sbar.add("item", { width = 6 })

local spaces_indicator = sbar.add("item", {
	background = {
		color = colors.with_alpha(colors.grey, 0.0),
		border_color = colors.with_alpha(colors.bg1, 0.0),
		border_width = 0,
		corner_radius = 6,
		height = 24,
		padding_left = 6,
		padding_right = 6,
	},
	icon = {
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14.0,
		},
		padding_left = 6,
		padding_right = 9,
		color = colors.accent1,
		string = icons.switch.on,
	},
	label = {
		drawing = "off",
		padding_left = 0,
		padding_right = 0,
	},
})

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
	spaces_indicator:set({
		icon = currently_on and icons.switch.off or icons.switch.on,
	})
end)

spaces_indicator:subscribe("mouse.entered", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = colors.tn_black1,
				border_color = { alpha = 1.0 },
				padding_left = 6,
				padding_right = 6,
			},
			icon = {
				color = colors.accent1,
				padding_left = 6,
				padding_right = 9,
			},
			label = { drawing = "off" },
			padding_left = 6,
			padding_right = 6,
		})
	end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 0.0 },
				border_color = { alpha = 0.0 },
			},
			icon = { color = colors.accent1 },
			label = { width = 0 },
		})
	end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
	sbar.trigger("swap_menus_and_spaces")
end)

local front_app_icon = sbar.add("item", "front_app_icon", {
	display = "active",
	icon = { drawing = false },
	label = {
		font = "sketchybar-app-font-bg:Regular:21.0",
	},
	updates = true,
	padding_right = 0,
	padding_left = -10,
})

front_app_icon:subscribe("front_app_switched", function(env)
	local icon_name = env.INFO
	local lookup = app_icons[icon_name]
	local icon = ((lookup == nil) and app_icons["default"] or lookup)
	front_app_icon:set({ label = { string = icon, color = colors.accent1 } })
end)

sbar.add("bracket", {
	spaces_indicator.name,
	front_app_icon.name,
}, {
	background = {
		color = colors.tn_black3,
		border_color = colors.accent1,
		border_width = 2,
	},
})

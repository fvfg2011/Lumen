# Lumen

A frosted-glass UI library for Roblox script executors, built with phones in mind.

- Tab panel that starts as icons and slides its names out; can dock **left, right, top or bottom**
- Tabs with sub-tabs, animated page switching
- Toggle, Slider, Button, Input, Dropdown (single / multi / search), Colorpicker, Keybind, Section, Paragraph, Divider
- 13 built-in themes (Dark, Light, Glass and ten accent colours) that switch live, plus your own themes
- Notifications, an open button that appears when the window is hidden, drag to move
- Icon sets: Lucide, Solar, Gravity, Craft (one optional bundle file)
- One file, no dependencies

> Made by Nick. Works in executors that provide `loadstring`, `readfile` and `writefile` (tested on Delta, mobile).

## Quick start

```lua
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/fvfg2011/Lumen/main/Lumen.lua"))()
-- optional icons (one file, all sets are read only when first used):
UI.Icons:SetBundle("Lumen_Icons.lua")   -- a file in the executor workspace

local window = UI:CreateWindow({
    Title = "My Hub",
    Author = "me",
    ToggleKey = Enum.KeyCode.RightShift,
})

local main = window:Tab({ Title = "Main", Icon = "house" })
main:Section({ Title = "Combat" })
main:Toggle({ Title = "Auto farm", Value = false, Callback = function (on) print("auto farm", on) end })
main:Slider({ Title = "Speed", Step = 1, Value = { Min = 0, Max = 100, Default = 50 }, Callback = function (n) print(n) end })
main:Button({ Title = "Hello", Icon = "bell", Callback = function () UI:Notify({ Title = "Lumen", Content = "Hello!" }) end })
```

If you keep `Lumen.lua` in your workspace instead: `loadstring(readfile("Lumen.lua"))()`.

## Window

```lua
local window = UI:CreateWindow({
    Title = "My Hub",              -- shown in the window header
    Author = "me",                 -- optional, shown after the title
    Size = UDim2.fromOffset(620, 480),
    ToggleKey = Enum.KeyCode.RightShift,
    OpenButton = { Title = "Open", Draggable = true, Enabled = true },
    Dock = "Left",                 -- "Left" | "Right" | "Top" | "Bottom"
    BarLabels = false,             -- Top / Bottom: show names under the icons
    RailExpandDelay = 3,           -- seconds before the names slide out at start
    RailCollapseAfter = 10,        -- seconds without activity before the panel folds back to icons
    DockChanged = function (side) end,
    Language = "en",               -- default language; the choice made in Settings is remembered
    Settings = true,               -- false: the settings page keeps ONLY the language choice. { BarLabels = false, Timing = false } hides single groups
    ConfirmClose = true,           -- the "×" button asks "Close the window?" first (ConfirmTitle / ConfirmText / ConfirmYes / ConfirmNo change the texts)
    SaveDock = true,               -- remembers the chosen side in a small file in the workspace (DockFile = "name.txt" to rename it)
    MinimizeIcon = "solar:minimize-square-3-linear",   -- icons of the header buttons (these are the defaults; without the bundle Lucide / a text symbol is used)
    CloseIcon = "solar:close-square-linear",
    Blur = false,                  -- off by default; BlurMode = "Screen" blurs the whole view
})
```

| Method | What it does |
| --- | --- |
| `window:Tab({ Title, Icon })` | New tab. Returns a tab |
| `tab:Tab({ Title, Icon })` | Sub-tab of a tab |
| `window:SelectTab(tab)` | Opens a tab |
| `window:SetDock("Right")` | Moves the tab panel (animated) |
| `window:SetVisible(bool)` / `window:Toggle()` | Shows / hides the window |
| `window:OnDestroy(fn)` / `window:Destroy()` | Cleanup |

The four dock buttons in the window header are always there, so every hub built on Lumen can move its panel.

### Tab panel behaviour

- Starts as icons only; after `RailExpandDelay` seconds the names slide out.
- On PC it also opens on hover; on a phone it opens when you tap it.
- Folds back after `RailCollapseAfter` seconds without activity.
- Width follows the longest tab name (measured in pixels). A sub-tab widens the panel only if its name plus indent is longer.
- Left / Right: sub-tabs sit under their parent with a tree line, and stay visible as small icons when the panel is folded. A dot marks tabs that have sub-tabs. A tab without an icon shows its first letter.
- Top / Bottom: icons only, sub-tabs appear to the right of the parent. With names switched on (`BarLabels` or the settings page), tab names sit on the outer side of the icons (above them at the top, below them at the bottom), and the names of the open tab's sub-tabs on the inner side. A sub-tab cell grows to fit its name, so neighbours never overlap.

## Languages and the settings button

Every window has a settings button: the last button of the side panel (the rightmost one in the top / bottom bar). It has no name; a hint appears next to it for a couple of seconds after the names slide out. The page contains:

- **Language** (12 built-in languages: English, Русский, Українська, Español, Deutsch, Français, Português, Polski, Türkçe, Italiano, 中文, 日本語)
- Names under the icons (only for the top / bottom panel)
- Seconds of inactivity before the panel folds (not used when the panel is on the top or bottom)
- Seconds after the script starts before the panel expands

Time values can be set with the slider, or by tapping the number next to it and typing a value (it may be larger than the slider end). The choices are saved to `Lumen_<Title>_settings.json` in the executor workspace.

The button sits below the list of tabs and never covers them: the tabs scroll above it, the button stays in place.

The settings button cannot be removed, because the language choice must always be available. `Settings = false` only removes the other options and leaves the language choice on the page.

### Making your own script multilingual

Lumen translates **its own** texts (settings page, close confirmation, hints) by itself. The texts of **your** script are translated only if you write them as a **table** with one entry per language code instead of a plain string. A plain string is shown as it is in every language.

```lua
-- the key is the language code: en, ru, uk, es, de, fr, pt, pl, tr, it, zh, ja
window:Tab({ Title = { en = "Main", ru = "Главное", de = "Start" }, Icon = "house" })
tab:Section({ Title = { en = "Combat", ru = "Бой" } })
tab:Button({ Title = { en = "Run", ru = "Запустить" }, Desc = { en = "Starts it", ru = "Запускает" }, Callback = function () end })
UI:Notify({ Title = { en = "Saved", ru = "Сохранено" }, Content = { en = "Done", ru = "Готово" } })
```

What follows the language automatically: the `Title` and `Desc` of tabs, sub-tabs and every element (also after `:SetTitle` / `:SetDesc` with a table), and `Title` / `Content` of notifications.

What does **not**: the window `Title` (it is also used for file names), the values of a dropdown, and plain strings. For those use `UI:T` and `UI:OnLanguageChanged` below.

Rules: if the current language is missing in a table, English (`en`) is used, then the first entry. Write at least `en` in every table.

```lua
UI:AddLanguage("de", "Deutsch", { my_key = "..." })   -- add a language or your own texts
UI:AddStrings("en", { my_key = "Hello" })             -- texts of your own script
UI:T("my_key")                                        -- text in the current language (for dropdown values and anything else you set yourself)
UI:SetLanguage("ru")
UI:OnLanguageChanged(function (code) end)
```

## Elements

All elements are created on a tab and take a `Title` and an optional `Desc`.

```lua
tab:Section({ Title = "Group" })
tab:Paragraph({ Title = "Text", Desc = "Some description" })      -- tab:Label is the same
tab:Divider()

tab:Button({ Title = "Run", Icon = "play", Callback = function () end })

local toggle = tab:Toggle({ Title = "Option", Value = true, Callback = function (v) end })
toggle:Set(false)            -- runs the callback; toggle:Set(false, true) does not
toggle:Get()

tab:Slider({ Title = "Value", Step = 1, Value = { Min = 0, Max = 100, Default = 20 }, Live = false, Callback = function (n) end })
-- by default the callback runs when you release the slider; Live = true runs it while dragging.
-- tap the number to type a value; TypedMax = 600 lets the typed value go above the slider end

tab:Input({ Title = "Name", Placeholder = "type here", Type = "Input", Callback = function (text) end })   -- Type = "Textarea" for several lines

local list = tab:Dropdown({ Title = "Map", Values = { "A", "B", "C" }, Value = "A", Callback = function (v) end })
-- Multi = true (Value and the callback use lists), AllowNone = true, SearchBarEnabled = true (shown automatically above 10 items)
list:Refresh({ "X", "Y" })   -- replaces the options, no callback
list:Select("X")             -- list:Get()

tab:Colorpicker({ Title = "Colour", Default = Color3.fromRGB(0, 145, 255), Live = false, Callback = function (color) end })

tab:Keybind({ Title = "Key", Default = Enum.KeyCode.F, Callback = function (key) end, Changed = function (key) end })
```

Every element also has `:SetTitle`, `:SetDesc`, `:SetVisible`, `:Destroy`, and `:SetCallback` where it makes sense.
Callbacks run in a protected call, so an error in your callback prints a warning and does not break the UI.

Scrolling: pressing a card and dragging scrolls the page. A click is counted only if the pointer moved less than 10 px.

## Notifications

```lua
UI:Notify({ Title = "Saved", Content = "Config saved", Duration = 4 })
```

## Themes

```lua
UI:GetThemeNames()          -- { "Dark", "Light", "Glass", "Rose", ... }
UI:SetTheme("Glass")        -- all windows change live with a smooth fade

UI:AddTheme({
    Name = "Mine",
    Background = Color3.fromRGB(14, 15, 21), Panel = Color3.fromRGB(23, 24, 32),
    Element = Color3.fromRGB(32, 34, 44),    Popup = Color3.fromRGB(27, 28, 38),
    Text = Color3.new(1, 1, 1), SubText = Color3.fromRGB(170, 175, 190),
    Primary = Color3.fromRGB(0, 145, 255),   Outline = Color3.fromRGB(60, 64, 80),
    Alpha = { Background = 0.1, Panel = 0.2, Element = 0.2, Popup = 0.05 },   -- 0 solid .. 1 invisible
    StrokeAlpha = 0.5, Gloss = 0.8,
})
```

Missing fields fall back to the Dark theme.

## Icons

Use an icon by name in `Icon = "..."`. Names without a prefix come from Lucide; other sets use a prefix: `"solar:bell-bold"`, `"gravity:camera"`.

```lua
UI.Icons:SetBundle("Lumen_Icons.lua")                  -- one file with all sets
UI.Icons:Register("my-icon", "rbxassetid://123456")    -- your own image or a text glyph
UI.Icons:AddPack("mypack", { home = 123456 }, false)   -- your own set
```

Solar names have a style at the end (`-bold`, `-linear`, `-outline`, `-broken`, `-line-duotone`, `-bold-duotone`). A name without a style, such as `"solar:bell"`, takes the first style that exists. If an icon is not found, the console shows a line starting with `[Lumen] icon`: it says whether the set could not be loaded (check that the newest `Lumen_Icons.lua` is in the workspace and `UI.Icons:SetBundle("Lumen_Icons.lua")` is called before the window is created).

Old Lucide names such as `home`, `alert-triangle`, `check-circle` are understood and mapped to the current names.

## Files

| File | What it is |
| --- | --- |
| `Lumen.lua` | The library |
| `Lumen_Icons.lua` | Optional bundle of icon sets (about 0.6 MB) |
| `Lumen_Test.lua` | Test script, one tab per feature |

## Credits and licenses

Lumen itself is licensed under **MIT**.

The icon bundle is generated from the icon sets below. Check each license before you redistribute the bundle:

- Lucide: ISC License
- lucide-roblox sprite sheets: MIT License
- Icon packaging (asset IDs and name tables): MIT License, Footagesus/Icons. See `THIRD_PARTY_LICENSES.md`
- Solar icons by 480 Design, CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/); Craft Icons by eusha, CC BY 4.0. Both were converted to Roblox image assets and renamed. Please keep this credit if you ship the bundle
- The artwork itself keeps the license of each original set (Gravity UI icons are MIT). Check the sets you ship

I am also waiting for your suggestions for changes/additions to the library

I also have my own hub for [Cameraman TD](https://github.com/fvfg2011/REPLACE_WITH_HUB_LINK), which already uses Lumen library. I'm sure it will be useful for you to see how it looks in game, not just in code.

I hope that my library will be useful to you.
Created by Nick(Fvfg2O11) in 2026

local env = getgenv()
if env.LumenTest then
    pcall(function () env.LumenTest:Destroy() end)
end
-- Lumen test script for the repository. Loads the library straight from GitHub.
-- The repository must be public for this to work. Leave BASE empty to use the files from the workspace.
local BASE = "https://raw.githubusercontent.com/fvfg2011/Lumen/main/"

local function fetch(name)
    if BASE ~= "" and true then
        local ok, body = pcall(game.HttpGet, game, BASE .. name)
        if ok and type(body) == "string" and #body > 0 then
            return body
        end
        warn("[Lumen test] could not download " .. name .. ", trying the workspace file")
    end
    return readfile(name)
end

local UI = loadstring(fetch("Lumen.lua"))()
-- the icon bundle is saved to the workspace once, so it is not downloaded every time
local okIcons, icons = pcall(fetch, "Lumen_Icons.lua")
if okIcons and type(icons) == "string" then
    pcall(writefile, "Lumen_Icons.lua", icons)
end
UI.Icons:SetBundle("Lumen_Icons.lua")

local w = UI:CreateWindow({
    Title = "Lumen", Author = "тест", ToggleKey = Enum.KeyCode.RightShift, OpenButton = { Title = "Lumen" },
    Dock = "Left", RailExpandDelay = 3, RailCollapseAfter = 10, BarLabels = false,
    DockChanged = function (side) print("dock:", side) end,
})
env.LumenTest = w

-- 1. rail: icons first, names after 3 s, fold after 10 s
local t1 = w:Tab({ Title = "Панель: значки и названия", Icon = "panel-left" })
t1:Tab({ Title = "Пусто", Icon = "circle" })
t1:Section({ Title = "Что проверять" })
t1:Paragraph({ Title = "Старт", Desc = "Сразу после запуска видны только значки. Через 3 секунды названия плавно выезжают." })
t1:Paragraph({ Title = "Сворачивание", Desc = "10 секунд без касаний и без наведения — панель сворачивается обратно до значков." })
t1:Paragraph({ Title = "ПК / телефон", Desc = "На ПК названия выезжают и при наведении. На телефоне — по таймеру или по нажатию на панель." })
t1:Paragraph({ Title = "Подвкладки", Desc = "Открой эту вкладку: подвкладка остаётся маленьким значком (14 px), у вкладки с подвкладками есть точка." })

-- 2. width by text
local t2 = w:Tab({ Title = "Ширина по тексту", Icon = "ruler" })
t2:Tab({ Title = "Подвкладка длиннее чем вкладка", Icon = "arrow-right" })
t2:Section({ Title = "Ширина панели" })
t2:Paragraph({ Title = "Правило", Desc = "Ширина = самое длинное название вкладки. Откройте эту вкладку: подвкладка длиннее — панель расширяется. Откройте другую — снова сужается." })

-- 3. letter instead of icon
local t3 = w:Tab({ Title = "Буква вместо значка" })
t3:Tab({ Title = "Тоже без значка" })
t3:Paragraph({ Title = "Проверка", Desc = "У этой вкладки и подвкладки нет значка — вместо него первая буква названия." })

-- 4. dock buttons
local t4 = w:Tab({ Title = "Кнопки сторон окна", Icon = "layout-dashboard" })
t4:Tab({ Title = "Пусто", Icon = "circle" })
t4:Section({ Title = "Четыре кнопки в шапке окна" })
t4:Paragraph({ Title = "Слева / сверху / снизу / справа", Desc = "Нажимай значки в правом верхнем углу окна. Справа панель зеркальная, но текст читается нормально. Сверху и снизу — только значки, подвкладки появляются справа от родителя." })
t4:Toggle({ Title = "Подписи под значками (Top / Bottom)", Desc = "Название под значком, нажимается только значок", Value = false, Callback = function (v)
    w.BarLabels = v
    w:SetDock(w.Dock, true)
end })
for _, side in ipairs({ "Left", "Right", "Top", "Bottom" }) do
    t4:Button({ Title = "Переместить: " .. side, Callback = function () w:SetDock(side) end })
end

-- 5. dropdown field
local t5 = w:Tab({ Title = "Поле списка справа", Icon = "list" })
t5:Tab({ Title = "Пусто", Icon = "circle" })
t5:Section({ Title = "Поле на одной строке с названием, список того же размера" })
local map = t5:Dropdown({ Title = "Map", Values = { "Toilet City", "Forest", "Desert" }, Value = "Forest", Callback = function (v) print("map", v) end })
t5:Dropdown({ Title = "Modifiers", Multi = true, Values = { "A", "B", "C", "D" }, Value = { "A" }, Callback = function (v) print("mods", table.concat(v, ",")) end })
t5:Dropdown({ Title = "Search (с описанием)", Desc = "Карточка с описанием — поле всё равно по центру справа", SearchBarEnabled = true, AllowNone = true, Values = { "alpha", "beta", "gamma", "delta" } })
t5:Button({ Title = "Refresh Map", Callback = function () map:Refresh({ "City A", "City B", "City C" }) end })
t5:Toggle({ Title = "Переключатель для сравнения положения", Value = true })

-- 6. scroll from a button
local t6 = w:Tab({ Title = "Прокрутка за кнопку", Icon = "mouse-pointer-click" })
t6:Tab({ Title = "Пусто", Icon = "circle" })
t6:Section({ Title = "Тяни страницу, начиная движение прямо с кнопки или переключателя" })
for i = 1, 8 do
    t6:Button({ Title = "Кнопка " .. i, Callback = function () UI:Notify({ Title = "Нажато", Content = "Кнопка " .. i, Duration = 2 }) end })
    t6:Toggle({ Title = "Переключатель " .. i, Callback = function (v) print("toggle", i, v) end })
end

-- 7. sliders
local t7 = w:Tab({ Title = "Ползунки", Icon = "sliders-horizontal" })
t7:Tab({ Title = "Пусто", Icon = "circle" })
t7:Section({ Title = "Двигается только тот, которого касаешься" })
for i = 1, 4 do
    t7:Slider({ Title = "Slider " .. i, Step = 1, Value = { Min = 0, Max = 100, Default = 20 * i }, Callback = function (n) print("slider", i, n) end })
end

-- 8. icon sets
local t8 = w:Tab({ Title = "Наборы иконок", Icon = "image" })
t8:Tab({ Title = "Пусто", Icon = "circle" })
t8:Section({ Title = "У каждой кнопки значок из своего набора" })
t8:Button({ Title = "Lucide: house", Icon = "house" })
t8:Button({ Title = "Solar: solar:bell-bold", Icon = "solar:bell-bold" })
t8:Button({ Title = "Gravity: gravity:camera", Icon = "gravity:camera" })
t8:Button({ Title = "Craft: craft:2d-axis-stroke", Icon = "craft:2d-axis-stroke" })
t8:Paragraph({ Title = "Нет значка", Desc = "Если у какой-то кнопки значка нет, набор не загрузился: проверь, что Lumen_Icons.lua лежит рядом с Lumen.lua." })

-- 9. dock memory
local t9 = w:Tab({ Title = "Запоминание стороны", Icon = "save" })
t9:Tab({ Title = "Пусто", Icon = "circle" })
t9:Paragraph({ Title = "Проверка", Desc = "Передвинь панель кнопками в шапке, закрой и снова запусти тест: панель должна появиться на выбранной стороне, названия сразу открыты через 3 секунды." })

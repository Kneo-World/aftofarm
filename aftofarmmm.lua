-- ============================================================
-- MM2 ULTIMATE AUTO-FARM V2.5 (DEBUG & DIRECT FIX)
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local autoFarmActive = false
local collectedCoinsCount = 0
local maxCoinsPerRound = 40
local safePointCFrame = CFrame.new(0, 100, 0)

local function getCharacter()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
        return char, char.Humanoid, char.HumanoidRootPart
    end
    return nil, nil, nil
end

-- ==================== ИНТЕРФЕЙС ====================
local Window = Rayfield:CreateWindow({
   Name = "💰 MM2 Auto-Farm (Debug V2.5)",
   LoadingTitle = "Загрузка...",
   LoadingSubtitle = "by Kneo World",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local FarmTab = Window:CreateTab("🚀 Фарм", 4483362458)

FarmTab:CreateToggle({
   Name = "💰 Включить Авто-Фарм",
   CurrentValue = false,
   Callback = function(Value)
      autoFarmActive = Value
      print("[AUTO-FARM] Статус изменен на:", Value)
      if Value then
          collectedCoinsCount = 0
      end
   end,
})

FarmTab:CreateButton({
   Name = "📌 Сохранить Safe-Точку",
   Callback = function()
      local _, _, root = getCharacter()
      if root then
          safePointCFrame = root.CFrame
          Rayfield:Notify({Title = "Успешно", Content = "Точка сохранена!", Duration = 2})
      end
   end,
})

-- ==================== ГЛАВНЫЙ ПОТОК ФАРМА ====================
task.spawn(function()
    print("[AUTO-FARM] Поток фарма успешно запущен!")
    while true do
        task.wait(0.5) -- Чуть реже проверяем, чтобы не нагружать
        
        if not autoFarmActive then
            continue
        end

        local char, hum, root = getCharacter()
        if not char or not root or not hum then
            print("[AUTO-FARM] Персонаж не найден или мертв, ждем респавна...")
            task.wait(1)
            continue
        end

        -- Ищем папку CoinContainer
        local coinContainer = Workspace:FindFirstChild("CoinContainer")
        if not coinContainer then
            print("[AUTO-FARM] Папка CoinContainer не найдена в Workspace! (Раунд еще не начался?)")
            task.wait(1)
            continue
        end

        -- Собираем список всех монет
        local coins = {}
        for _, obj in ipairs(coinContainer:GetChildren()) do
            if obj.Name == "Coin_Server" and obj:IsA("BasePart") then
                table.insert(coins, obj)
            end
        end

        print("[AUTO-FARM] Найдено монет в контейнере:", #coins)

        if #coins == 0 then
            task.wait(1)
            continue
        end

        -- Сбрасываем лимит если монет снова много
        if #coins > 5 and collectedCoinsCount >= maxCoinsPerRound then
            collectedCoinsCount = 0
        end

        if collectedCoinsCount >= maxCoinsPerRound then
            print("[AUTO-FARM] Лимит монет за раунд собран, летим в сейф.")
            root.CFrame = safePointCFrame
            task.wait(2)
            continue
        end

        -- Ищем самую близкую монету
        local nearestCoin = nil
        local shortestDist = math.huge

        for _, coin in ipairs(coins) do
            local dist = (root.Position - coin.Position).Magnitude
            if dist < shortestDist then
                shortestDist = dist
                nearestCoin = coin
            end
        end

        -- Летим к монете
        if nearestCoin and nearestCoin.Parent then
            print("[AUTO-FARM] Летим к монете на дистанции:", shortestDist)
            
            while autoFarmActive and nearestCoin and nearestCoin.Parent do
                local _, _, currentRoot = getCharacter()
                if not currentRoot then break end
                
                local targetPos = nearestCoin.Position
                local currentPos = currentRoot.Position
                local dist = (currentPos - targetPos).Magnitude
                
                if dist < 3 then
                    currentRoot.CFrame = nearestCoin.CFrame
                    break
                end
                
                -- Плавное движение к позиции монеты
                local dir = (targetPos - currentPos).Unit
                currentRoot.CFrame = CFrame.new(currentPos + dir * math.min(dist, 40 * 0.1), targetPos)
                currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                
                task.wait(0.1)
            end
            
            collectedCoinsCount = collectedCoinsCount + 1
            task.wait(0.2)
        end
    end
end)

Rayfield:Notify({Title = "Скрипт V2.5 загружен", Content = "Отладка включена, чекни F9!", Duration = 4})

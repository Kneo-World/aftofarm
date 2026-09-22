-- ============================================================
-- MM2 ULTIMATE AUTO-FARM V2.9 (UNDERMAP STEALTH FARM + 1.5S DELAY)
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
   Name = "💰 MM2 Undermap Farm (Stealth V2.9)",
   LoadingTitle = "Загрузка стелс-режима...",
   LoadingSubtitle = "by Kneo World",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local FarmTab = Window:CreateTab("🚀 Стелс-Фарм", 4483362458)

FarmTab:CreateToggle({
   Name = "💰 Включить Подземный Авто-Фарм",
   CurrentValue = false,
   Callback = function(Value)
      autoFarmActive = Value
      print("[AUTO-FARM] Статус:", Value)
      if Value then collectedCoinsCount = 0 end
   end,
})

FarmTab:CreateButton({
   Name = "📌 Сохранить Safe-Точку (на всякий случай)",
   Callback = function()
      local _, _, root = getCharacter()
      if root then
          safePointCFrame = root.CFrame
          Rayfield:Notify({Title = "Успешно", Content = "Точка сохранена!", Duration = 2})
      end
   end,
})

-- Глубокий поиск Coin_Server
local function getAllCoins()
    local coins = {}
    local function scan(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "Coin_Server" and child:IsA("BasePart") then
                table.insert(coins, child)
            end
            if #child:GetChildren() > 0 then
                scan(child)
            end
        end
    end
    scan(Workspace)
    return coins
end

-- ==================== ГЛАВНЫЙ ПОТОК ПОДЗЕМНОГО ФАРМА ====================
task.spawn(function()
    print("[AUTO-FARM] Стелс-поток под землей запущен!")
    while true do
        task.wait(0.2)
        
        if not autoFarmActive then
            continue
        end

        local char, hum, root = getCharacter()
        if not char or not root or not hum then
            task.wait(1)
            continue
        end

        local coins = getAllCoins()
        if #coins == 0 then
            task.wait(0.5)
            continue
        end

        if #coins > 5 and collectedCoinsCount >= maxCoinsPerRound then
            collectedCoinsCount = 0
        end

        if collectedCoinsCount >= maxCoinsPerRound then
            root.CFrame = safePointCFrame
            task.wait(1)
            continue
        end

        -- Ищем ближайшую монету
        local nearestCoin = nil
        local shortestDist = math.huge

        for _, coin in ipairs(coins) do
            if coin and coin.Parent then
                local dist = (root.Position - coin.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearestCoin = coin
                end
            end
        end

        -- Полет под картой к монете
        if nearestCoin and nearestCoin.Parent then
            while autoFarmActive and nearestCoin and nearestCoin.Parent do
                local _, _, currentRoot = getCharacter()
                if not currentRoot then break end
                
                -- Целевая позиция монеты, но СМЕЩЕННАЯ ВНИЗ (под карту / под пол)
                -- Монета находится в точке coin.Position. 
                -- Мы ставим персонажа на 3.5 блока ниже монеты, чтобы пол защищал тебя от убийцы, 
                -- а верхняя часть хитбокса/головы доставала до монеты.
                local targetPos = nearestCoin.Position - Vector3.new(0, 3.5, 0)
                local currentPos = currentRoot.Position
                local dist = (currentPos - targetPos).Magnitude
                
                if dist < 2 then
                    currentRoot.CFrame = CFrame.new(targetPos)
                    break
                end
                
                local dir = (targetPos - currentPos).Unit
                currentRoot.CFrame = CFrame.new(currentPos + dir * math.min(dist, 40 * 0.05), targetPos)
                currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                
                task.wait(0.05)
            end
            
            collectedCoinsCount = collectedCoinsCount + 1
            
            -- Твоя задержка 1.5 секунды на монете (находясь под картой)
            local waitTimer = 0
            while waitTimer < 1.5 and autoFarmActive do
                task.wait(0.1)
                waitTimer = waitTimer + 0.1
            end
        end
    end
end)

Rayfield:Notify({Title = "Скрипт V2.9 загружен", Content = "Стелс-фарм под картой активирован!", Duration = 4})

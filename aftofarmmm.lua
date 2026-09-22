-- ============================================================
-- MM2 ULTIMATE AUTO-FARM V2.6 (COIN CONTAINER MODEL FIX)
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
   Name = "💰 MM2 Auto-Farm (Fixed V2.6)",
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
        task.wait(0.3)
        
        if not autoFarmActive then
            continue
        end

        local char, hum, root = getCharacter()
        if not char or not root or not hum then
            task.wait(1)
            continue
        end

        -- Ищем CoinContainer как модель или объект в Workspace
        local coinContainer = Workspace:FindFirstChild("CoinContainer")
        if not coinContainer then
            -- Не спамим в консоль каждую секунду, просто ждем раунд
            task.wait(1)
            continue
        end

        -- Собираем все монеты-парты из модели CoinContainer
        local coins = {}
        for _, obj in ipairs(coinContainer:GetChildren()) do
            if obj.Name == "Coin_Server" and (obj:IsA("BasePart") or obj:IsA("Part") or obj:IsA("MeshPart")) then
                table.insert(coins, obj)
            end
        end

        if #coins == 0 then
            task.wait(0.5)
            continue
        end

        -- Сбрасываем лимит если начался новый раунд
        if #coins > 5 and collectedCoinsCount >= maxCoinsPerRound then
            collectedCoinsCount = 0
        end

        if collectedCoinsCount >= maxCoinsPerRound then
            root.CFrame = safePointCFrame
            task.wait(1)
            continue
        end

        -- Ищем самую близкую монету
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

        -- Летим к монете
        if nearestCoin and nearestCoin.Parent then
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
                
                local dir = (targetPos - currentPos).Unit
                currentRoot.CFrame = CFrame.new(currentPos + dir * math.min(dist, 45 * 0.05), targetPos)
                currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                
                task.wait(0.05)
            end
            
            collectedCoinsCount = collectedCoinsCount + 1
            task.wait(0.2)
        end
    end
end)

Rayfield:Notify({Title = "Скрипт V2.6 загружен", Content = "Контейнер-модель теперь поддерживается!", Duration = 4})

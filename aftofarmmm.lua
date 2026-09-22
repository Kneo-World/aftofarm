-- ============================================================
-- MM2 ULTIMATE AUTO-FARM V3.3 (DEBUG CONSOLE LOGS)
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local autoFarmActive = false
local collectedCoinsCount = 0
local maxCoinsPerRound = 40
local safePointCFrame = CFrame.new(0, 50, 0)

local function getCharacter()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
        return char, char.Humanoid, char.HumanoidRootPart
    end
    return nil, nil, nil
end

-- ==================== ИНТЕРФЕЙС ====================
local Window = Rayfield:CreateWindow({
   Name = "💰 MM2 Auto-Farm (Debug V3.3)",
   LoadingTitle = "Загрузка дебага...",
   LoadingSubtitle = "by Kneo World",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local FarmTab = Window:CreateTab("🚀 Отладка", 4483362458)

FarmTab:CreateToggle({
   Name = "💰 Включить Авто-Фарм (Debug)",
   CurrentValue = false,
   Callback = function(Value)
      autoFarmActive = Value
      print("[DEBUG] Статус автофарма изменен на:", Value)
      if Value then collectedCoinsCount = 0 end
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

-- Рекурсивный поиск с отладкой
local function getAllCoins()
    local coins = {}
    local totalChecked = 0
    
    local function scan(parent)
        for _, child in ipairs(parent:GetChildren()) do
            totalChecked = totalChecked + 1
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

-- Noclip
RunService.Stepped:Connect(function()
    if not autoFarmActive then return end
    local char, _, _ = getCharacter()
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ==================== ГЛАВНЫЙ ПОТОК ФАРМА ====================
task.spawn(function()
    print("[DEBUG] Поток фарма запущен и готов к работе!")
    while true do
        task.wait(0.5)
        
        if not autoFarmActive then
            continue
        end

        local char, hum, root = getCharacter()
        if not char or not root or not hum then
            print("[DEBUG] Персонаж не найден (умер или грузится)...")
            task.wait(1)
            continue
        end

        if root.Position.Y < -50 then
            print("[DEBUG] Упали в войд! Телепорт на сейф-точку.")
            root.CFrame = safePointCFrame
            task.wait(1)
            continue
        end

        local coins = getAllCoins()
        print("[DEBUG] Найдено Coin_Server партов на карте:", #coins)

        if #coins == 0 then
            print("[DEBUG] Монет нет! Ждем начала раунда...")
            task.wait(1)
            continue
        end

        if #coins > 5 and collectedCoinsCount >= maxCoinsPerRound then
            collectedCoinsCount = 0
        end

        if collectedCoinsCount >= maxCoinsPerRound then
            print("[DEBUG] Лимит монет на раунд исчерпан. Идем на сейф-точку.")
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

        if nearestCoin and nearestCoin.Parent then
            print("[DEBUG] Летим к монете на дистанции:", shortestDist)
            while autoFarmActive and nearestCoin and nearestCoin.Parent do
                local _, _, currentRoot = getCharacter()
                if not currentRoot then break end
                
                local targetPos = nearestCoin.Position
                local currentPos = currentRoot.Position
                local dist = (currentPos - targetPos).Magnitude
                
                if dist < 2 then
                    currentRoot.CFrame = CFrame.new(targetPos)
                    currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    currentRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    break
                end
                
                local dir = (targetPos - currentPos).Unit
                currentRoot.CFrame = CFrame.new(currentPos + dir * math.min(dist, 45 * 0.05), targetPos)
                currentRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                currentRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                
                task.wait(0.05)
            end
            
            collectedCoinsCount = collectedCoinsCount + 1
            print("[DEBUG] Монета собрана! Всего собрано:", collectedCoinsCount)
            
            -- Пауза 1.5 секунды
            local waitTimer = 0
            while waitTimer < 1.5 and autoFarmActive do
                local _, _, curRoot = getCharacter()
                if curRoot then
                    curRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    curRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                else
                    break
                end
                task.wait(0.1)
                waitTimer = waitTimer + 0.1
            end
        end
    end
end)

Rayfield:Notify({Title = "Скрипт V3.3 загружен", Content = "Дебаг-логи активированы в консоли!", Duration = 4})

-- Note: writefile, readfile, and getcustomasset are external functions
-- that need to be provided by the execution environment (e.g., Synapse X, KRNL, etc.)
local isasveon = false 
local isreadon = false 
local iscustomasseton = false 
local isdownloadon = false
local _isHttpGeton = false
local _uiReady = false
local _ismeowon = false

local data = {
    "localtest loading..."
}

local function _checkHttpGet()
    local _url = "https://raw.githubusercontent.com/displaynameroblox/displayoptiy/refs/heads/main/README.md"
    local _working = pcall(function()
        game:HttpGet(_url)
    end)
    if _working then
        _isHttpGeton = true
    end
end

local function checksave()
    if isasveon == false then
        local working = pcall(function()
            writefile("Displayoptiy/testdata.txt", table.concat(data, "\n"))
        end)
        if working then
            isasveon = true
        end
    end
end

local function checkread()
    if isreadon == false then
        local succeeds = pcall(function()
            local data = readfile("Displayoptiy/testdata.txt")
            if data then
                print(data)
            end
        end)
        if succeeds then
            isreadon = true
        end
    end
end

local function checkcustomasset()
    if iscustomasseton == false then
        local folder, song
        local succeeds = pcall(function()
            folder = Instance.new("Folder")
            song = Instance.new("Sound")
            song.Name = "testsong"
            song.SoundId = getcustomasset("untitledtaggameOST-BloxiadebyO9ocopy.mp3") or getcustomasset("soundfolder/untitledtaggameOST-BloxiadebyO9o.wav")
            song.Parent = folder
            song.Volume = 0
            song:Play()
        end)
        if succeeds then
            iscustomasseton = true
            if song then
                song:Stop()
                song:Destroy()
            end
            if folder then
                folder:Destroy()
            end
        end
    end
end

local function checkdownload()
    local working = pcall(function()
        local data = game:HttpGet('https://raw.githubusercontent.com/displaynameroblox/displayoptiy/refs/heads/main/README.md')
        writefile('Displayoptiy/testdownload.txt', data)
        local _localdata = readfile('Displayoptiy/testdownload.txt')
    end)
    if working then 
        isdownloadon = true 
    else 
        isdownloadon = false
    end
end
-- meow check, very very very important, if this fails, the script will not work and you cant meow at all
local function checkmeow()
    local oneinamillion = math.random(1,1000000)
    if oneinamillion == 69420 then
        _ismeowon = false
    else
        _ismeowon = true
    end
end

local function _song(songname, Name)
    if iscustomasseton == true and isreadon == true and isasveon == true then
        local loaded = pcall(function()
            local folder = Instance.new("Folder", workspace)
            folder.Name = "soundfolder"
            local sound = Instance.new("Sound", folder)
            sound.SoundId = getcustomasset(Name)
            sound.Name = songname
        end)
        if loaded then
            print("--- loaded " .. songname)
        else 
            print("error while loading " .. songname)
        end
    end
end

local function _listsoundfolder()
    local _listed = pcall(function()
        local folder = workspace:FindFirstChild("soundfolder")
        if folder then
            for _, sounds in pairs(folder:GetChildren()) do 
                print("--- " .. sounds)
            end
        end
    end)
    if not _listed then
        print("error while listing folder")
    end
end

local function _listlocalfiles()
    if not isfolder("soundsfolder") then
        print("sounds folder not found, making one..")
        makefolder("soundsfolder")
    else
        if isfolder("soundsfolder") then
            local _folder = listfiles("soundsfolder")
            for _, file in pairs(_folder) do
                print("--- " .. file)
            end
        end
    end
end

local function _preloadLocalFiles()
    print("--- preloading local files")
    -- Ensure soundsfolder exists
    if not isfolder("soundsfolder") then
        print("--- no soundsfolder found; skipping preload")
        return
    end

    local files = listfiles("soundsfolder")
    if not files or #files == 0 then
        print("--- no files to preload")
        return
    end

    -- Ensure workspace soundfolder exists
    local folder = workspace:FindFirstChild("soundfolder")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "soundfolder"
        folder.Parent = workspace
    end

    for _, filePath in pairs(files) do
        local filename = filePath:match("([^/\\]+)$")
        local ok = pcall(function()
            local sid = getcustomasset("soundsfolder/" .. filename)

            -- Reuse existing Sound with same SoundId if present
            local sound
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Sound") and child.SoundId == sid then
                    sound = child
                    break
                end
            end

            if not sound then
                sound = Instance.new("Sound")
                sound.Name = filename
                sound.SoundId = sid
                sound.Parent = folder
            end

            -- Test playback silently
            local previousVolume = sound.Volume
            sound.Volume = 0
            sound:Play()
            task.wait(0.05)
            sound:Stop()
            sound.Volume = previousVolume

            -- mark local asset
            if sound:GetAttribute("islocal") ~= true then
                sound:SetAttribute("islocal", true)
            end
        end)

        if ok then
            print("--- preload ok: " .. tostring(filename))
        else
            print("--- preload error: " .. tostring(filename))
        end
    end
end

-- GUI Variables
local gui, mainFrame, soundFrame, controlFrame, fileFrame
local soundIdBox, playButton, stopButton, volumeSlider, volumeLabel
local fileList, refreshButton, loadFileButton
local currentSound = nil
local currentVolume = 0.5
-- Settings
local settingsFrame, tabBar, playerTabButton, settingsTabButton
local toggleHotkeyButton, playHotkeyButton, pauseHotkeyButton
local themeNextButton, themeLabel
local _hotkeyConn
local toggleGuiKey = Enum.KeyCode.RightShift
local playKey = Enum.KeyCode.L
local pauseKey = Enum.KeyCode.K
local currentTheme = "Dark"
local themes = {
    Dark = {
        Main = Color3.fromRGB(30,30,30),
        Panel = Color3.fromRGB(40,40,40),
        Accent = Color3.fromRGB(50,50,50),
        Text = Color3.fromRGB(255,255,255),
        Button = Color3.fromRGB(80,80,80),
        Hover = Color3.fromRGB(100,100,100),
    },
    Light = {
        Main = Color3.fromRGB(235,235,235),
        Panel = Color3.fromRGB(245,245,245),
        Accent = Color3.fromRGB(210,210,210),
        Text = Color3.fromRGB(20,20,20),
        Button = Color3.fromRGB(220,220,220),
        Hover = Color3.fromRGB(200,200,200),
    }
}

local function _applyTheme(name)
    currentTheme = themes[name] and name or currentTheme
    local t = themes[currentTheme]
    if not t then return end
    if mainFrame then mainFrame.BackgroundColor3 = t.Main end
    local title = mainFrame and mainFrame:FindFirstChild("Title")
    if title then title.BackgroundColor3 = t.Accent; title.TextColor3 = t.Text end
    if soundFrame then soundFrame.BackgroundColor3 = t.Panel end
    if controlFrame then controlFrame.BackgroundColor3 = t.Panel end
    if fileFrame then fileFrame.BackgroundColor3 = t.Panel end
    if settingsFrame then settingsFrame.BackgroundColor3 = t.Panel end
    if fileList then fileList.BackgroundColor3 = t.Button end
    if volumeLabel then volumeLabel.TextColor3 = t.Text end
    if themeLabel then themeLabel.TextColor3 = t.Text end
end

local function _keyCodeToText(code)
    return code and code.Name or "None"
end

local function _bindHotkeys()
    if _hotkeyConn then _hotkeyConn:Disconnect() end
    local UIS = game:GetService("UserInputService")
    _hotkeyConn = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == toggleGuiKey then
            if gui then gui.Enabled = not gui.Enabled end
        elseif input.KeyCode == playKey then
            if currentSound then
                if currentSound.IsPaused then
                    currentSound:Resume()
                else
                    currentSound:Play()
                end
            end
        elseif input.KeyCode == pauseKey then
            if currentSound then
                currentSound:Pause()
            end
        end
    end)
end

local function _buildGUI()
    -- Main ScreenGui
    gui = Instance.new("ScreenGui")
    gui.Name = "DisPlayoptify"
    gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    
    -- Main Frame
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = gui
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = mainFrame
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    title.BorderSizePixel = 0
    title.Text = "DisPlayoptify v0.1 (OPEN BETA)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Parent = title
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0.5, -15)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 4)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- Tabs Bar
    tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Parent = mainFrame
    tabBar.Size = UDim2.new(1, -20, 0, 30)
    tabBar.Position = UDim2.new(0, 10, 0, 45)
    tabBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    tabBar.BorderSizePixel = 0

    playerTabButton = Instance.new("TextButton")
    playerTabButton.Name = "PlayerTab"
    playerTabButton.Parent = tabBar
    playerTabButton.Size = UDim2.new(0, 100, 0, 30)
    playerTabButton.Position = UDim2.new(0, 0, 0, 0)
    playerTabButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    playerTabButton.BorderSizePixel = 0
    playerTabButton.Text = "Player"
    playerTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playerTabButton.Font = Enum.Font.GothamBold
    playerTabButton.TextSize = 14

    settingsTabButton = Instance.new("TextButton")
    settingsTabButton.Name = "SettingsTab"
    settingsTabButton.Parent = tabBar
    settingsTabButton.Size = UDim2.new(0, 100, 0, 30)
    settingsTabButton.Position = UDim2.new(0, 110, 0, 0)
    settingsTabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    settingsTabButton.BorderSizePixel = 0
    settingsTabButton.Text = "Settings"
    settingsTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingsTabButton.Font = Enum.Font.GothamBold
    settingsTabButton.TextSize = 14

    -- Settings Frame (hidden by default)
    settingsFrame = Instance.new("Frame")
    settingsFrame.Name = "SettingsFrame"
    settingsFrame.Parent = mainFrame
    settingsFrame.Size = UDim2.new(1, -20, 0, 200)
    settingsFrame.Position = UDim2.new(0, 10, 0, 250)
    settingsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Visible = false

    local settingsCorner = Instance.new("UICorner")
    settingsCorner.CornerRadius = UDim.new(0, 6)
    settingsCorner.Parent = settingsFrame

    -- Hotkey Buttons Labels
    local hkLabel = Instance.new("TextLabel")
    hkLabel.Parent = settingsFrame
    hkLabel.Size = UDim2.new(1, -20, 0, 20)
    hkLabel.Position = UDim2.new(0, 10, 0, 5)
    hkLabel.BackgroundTransparency = 1
    hkLabel.Text = "Hotkeys"
    hkLabel.TextColor3 = Color3.fromRGB(255,255,255)
    hkLabel.Font = Enum.Font.GothamBold
    hkLabel.TextSize = 14

    toggleHotkeyButton = Instance.new("TextButton")
    toggleHotkeyButton.Parent = settingsFrame
    toggleHotkeyButton.Size = UDim2.new(0, 180, 0, 28)
    toggleHotkeyButton.Position = UDim2.new(0, 10, 0, 30)
    toggleHotkeyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    toggleHotkeyButton.BorderSizePixel = 0
    toggleHotkeyButton.Text = "Toggle GUI: " .. (toggleGuiKey and toggleGuiKey.Name or "None")
    toggleHotkeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleHotkeyButton.Font = Enum.Font.Gotham
    toggleHotkeyButton.TextSize = 12

    playHotkeyButton = Instance.new("TextButton")
    playHotkeyButton.Parent = settingsFrame
    playHotkeyButton.Size = UDim2.new(0, 180, 0, 28)
    playHotkeyButton.Position = UDim2.new(0, 10, 0, 65)
    playHotkeyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    playHotkeyButton.BorderSizePixel = 0
    playHotkeyButton.Text = "Play: " .. (playKey and playKey.Name or "None")
    playHotkeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playHotkeyButton.Font = Enum.Font.Gotham
    playHotkeyButton.TextSize = 12

    pauseHotkeyButton = Instance.new("TextButton")
    pauseHotkeyButton.Parent = settingsFrame
    pauseHotkeyButton.Size = UDim2.new(0, 180, 0, 28)
    pauseHotkeyButton.Position = UDim2.new(0, 10, 0, 100)
    pauseHotkeyButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    pauseHotkeyButton.BorderSizePixel = 0
    pauseHotkeyButton.Text = "Pause: " .. (pauseKey and pauseKey.Name or "None")
    pauseHotkeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    pauseHotkeyButton.Font = Enum.Font.Gotham
    pauseHotkeyButton.TextSize = 12

    local themeHdr = Instance.new("TextLabel")
    themeHdr.Parent = settingsFrame
    themeHdr.Size = UDim2.new(1, -20, 0, 20)
    themeHdr.Position = UDim2.new(0, 10, 0, 135)
    themeHdr.BackgroundTransparency = 1
    themeHdr.Text = "Theme"
    themeHdr.TextColor3 = Color3.fromRGB(255,255,255)
    themeHdr.Font = Enum.Font.GothamBold
    themeHdr.TextSize = 14

    themeLabel = Instance.new("TextLabel")
    themeLabel.Parent = settingsFrame
    themeLabel.Size = UDim2.new(0, 120, 0, 28)
    themeLabel.Position = UDim2.new(0, 10, 0, 160)
    themeLabel.BackgroundTransparency = 1
    themeLabel.Text = currentTheme
    themeLabel.TextColor3 = Color3.fromRGB(255,255,255)
    themeLabel.Font = Enum.Font.Gotham
    themeLabel.TextSize = 12

    themeNextButton = Instance.new("TextButton")
    themeNextButton.Parent = settingsFrame
    themeNextButton.Size = UDim2.new(0, 80, 0, 28)
    themeNextButton.Position = UDim2.new(0, 140, 0, 160)
    themeNextButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
    themeNextButton.BorderSizePixel = 0
    themeNextButton.Text = "Next"
    themeNextButton.TextColor3 = Color3.fromRGB(255,255,255)
    themeNextButton.Font = Enum.Font.Gotham
    themeNextButton.TextSize = 12

    -- Sound ID Input Section
    soundFrame = Instance.new("Frame")
    soundFrame.Name = "SoundFrame"
    soundFrame.Parent = mainFrame
    soundFrame.Size = UDim2.new(1, -20, 0, 120)
    soundFrame.Position = UDim2.new(0, 10, 0, 85)
    soundFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    soundFrame.BorderSizePixel = 0
    
    local soundCorner = Instance.new("UICorner")
    soundCorner.CornerRadius = UDim.new(0, 6)
    soundCorner.Parent = soundFrame
    
    -- Sound ID Label
    local soundIdLabel = Instance.new("TextLabel")
    soundIdLabel.Name = "SoundIdLabel"
    soundIdLabel.Parent = soundFrame
    soundIdLabel.Size = UDim2.new(1, 0, 0, 25)
    soundIdLabel.Position = UDim2.new(0, 10, 0, 5)
    soundIdLabel.BackgroundTransparency = 1
    soundIdLabel.Text = "Sound ID:"
    soundIdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    soundIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    soundIdLabel.Font = Enum.Font.Gotham
    soundIdLabel.TextSize = 16
    
    -- Sound ID Input Box
    soundIdBox = Instance.new("TextBox")
    soundIdBox.Name = "SoundIdBox"
    soundIdBox.Parent = soundFrame
    soundIdBox.Size = UDim2.new(1, -20, 0, 30)
    soundIdBox.Position = UDim2.new(0, 10, 0, 30)
    soundIdBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    soundIdBox.BorderSizePixel = 0
    soundIdBox.Text = ""
    soundIdBox.PlaceholderText = "Enter Sound ID (e.g., rbxassetid://123456789)"
    soundIdBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    soundIdBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    soundIdBox.Font = Enum.Font.Gotham
    soundIdBox.TextSize = 14
    soundIdBox.TextXAlignment = Enum.TextXAlignment.Left
    
    local soundIdCorner = Instance.new("UICorner")
    soundIdCorner.CornerRadius = UDim.new(0, 4)
    soundIdCorner.Parent = soundIdBox
    
    -- Play/Stop Buttons
    playButton = Instance.new("TextButton")
    playButton.Name = "PlayButton"
    playButton.Parent = soundFrame
    playButton.Size = UDim2.new(0, 80, 0, 30)
    playButton.Position = UDim2.new(0, 10, 0, 70)
    playButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    playButton.BorderSizePixel = 0
    playButton.Text = "Play"
    playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playButton.Font = Enum.Font.GothamBold
    playButton.TextSize = 14
    
    local playCorner = Instance.new("UICorner")
    playCorner.CornerRadius = UDim.new(0, 4)
    playCorner.Parent = playButton
    
    stopButton = Instance.new("TextButton")
    stopButton.Name = "StopButton"
    stopButton.Parent = soundFrame
    stopButton.Size = UDim2.new(0, 80, 0, 30)
    stopButton.Position = UDim2.new(0, 100, 0, 70)
    stopButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    stopButton.BorderSizePixel = 0
    stopButton.Text = "Pause"
    stopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    stopButton.Font = Enum.Font.GothamBold
    stopButton.TextSize = 14
    
    local stopCorner = Instance.new("UICorner")
    stopCorner.CornerRadius = UDim.new(0, 4)
    stopCorner.Parent = stopButton
    
    -- Volume Control Section
    controlFrame = Instance.new("Frame")
    controlFrame.Name = "ControlFrame"
    controlFrame.Parent = mainFrame
    controlFrame.Size = UDim2.new(1, -20, 0, 60)
    controlFrame.Position = UDim2.new(0, 10, 0, 180)
    controlFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    controlFrame.BorderSizePixel = 0
    
    local controlCorner = Instance.new("UICorner")
    controlCorner.CornerRadius = UDim.new(0, 6)
    controlCorner.Parent = controlFrame
    
    -- Volume Label
    volumeLabel = Instance.new("TextLabel")
    volumeLabel.Name = "VolumeLabel"
    volumeLabel.Parent = controlFrame
    volumeLabel.Size = UDim2.new(1, 0, 0, 25)
    volumeLabel.Position = UDim2.new(0, 10, 0, 5)
    volumeLabel.BackgroundTransparency = 1
    volumeLabel.Text = "Volume: 50%"
    volumeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    volumeLabel.TextXAlignment = Enum.TextXAlignment.Left
    volumeLabel.Font = Enum.Font.Gotham
    volumeLabel.TextSize = 16
    
    -- Volume Slider
    volumeSlider = Instance.new("TextButton")
    volumeSlider.Name = "VolumeSlider"
    volumeSlider.Parent = controlFrame
    volumeSlider.Size = UDim2.new(1, -20, 0, 20)
    volumeSlider.Position = UDim2.new(0, 10, 0, 30)
    volumeSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    volumeSlider.BorderSizePixel = 0
    volumeSlider.Text = ""
    
    local volumeCorner = Instance.new("UICorner")
    volumeCorner.CornerRadius = UDim.new(0, 10)
    volumeCorner.Parent = volumeSlider
    
    -- File Selection Section
    fileFrame = Instance.new("Frame")
    fileFrame.Name = "FileFrame"
    fileFrame.Parent = mainFrame
    fileFrame.Size = UDim2.new(1, -20, 0, 200)
    fileFrame.Position = UDim2.new(0, 10, 0, 250)
    fileFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    fileFrame.BorderSizePixel = 0
    
    local fileCorner = Instance.new("UICorner")
    fileCorner.CornerRadius = UDim.new(0, 6)
    fileCorner.Parent = fileFrame
    
    -- File List Label
    local fileLabel = Instance.new("TextLabel")
    fileLabel.Name = "FileLabel"
    fileLabel.Parent = fileFrame
    fileLabel.Size = UDim2.new(1, 0, 0, 25)
    fileLabel.Position = UDim2.new(0, 10, 0, 5)
    fileLabel.BackgroundTransparency = 1
    fileLabel.Text = "Local Files:"
    fileLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fileLabel.TextXAlignment = Enum.TextXAlignment.Left
    fileLabel.Font = Enum.Font.Gotham
    fileLabel.TextSize = 16
    
    -- File List
    fileList = Instance.new("ScrollingFrame")
    fileList.Name = "FileList"
    fileList.Parent = fileFrame
    fileList.Size = UDim2.new(1, -20, 0, 120)
    fileList.Position = UDim2.new(0, 10, 0, 30)
    fileList.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    fileList.BorderSizePixel = 0
    fileList.ScrollBarThickness = 6
    fileList.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local fileListCorner = Instance.new("UICorner")
    fileListCorner.CornerRadius = UDim.new(0, 4)
    fileListCorner.Parent = fileList
    
    -- Refresh and Load Buttons
    refreshButton = Instance.new("TextButton")
    refreshButton.Name = "RefreshButton"
    refreshButton.Parent = fileFrame
    refreshButton.Size = UDim2.new(0, 80, 0, 30)
    refreshButton.Position = UDim2.new(0, 10, 0, 160)
    refreshButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
    refreshButton.BorderSizePixel = 0
    refreshButton.Text = "Refresh"
    refreshButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshButton.Font = Enum.Font.GothamBold
    refreshButton.TextSize = 14
    
    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 4)
    refreshCorner.Parent = refreshButton
    
    loadFileButton = Instance.new("TextButton")
    loadFileButton.Name = "LoadFileButton"
    loadFileButton.Parent = fileFrame
    loadFileButton.Size = UDim2.new(0, 80, 0, 30)
    loadFileButton.Position = UDim2.new(0, 100, 0, 160)
    loadFileButton.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
    loadFileButton.BorderSizePixel = 0
    loadFileButton.Text = "Load File"
    loadFileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    loadFileButton.Font = Enum.Font.GothamBold
    loadFileButton.TextSize = 14
    
    local loadCorner = Instance.new("UICorner")
    loadCorner.CornerRadius = UDim.new(0, 4)
    loadCorner.Parent = loadFileButton
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Parent = mainFrame
    statusLabel.Size = UDim2.new(1, -20, 0, 30)
    statusLabel.Position = UDim2.new(0, 10, 0, 460)
    statusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    statusLabel.BorderSizePixel = 0
    statusLabel.Text = "Ready"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 4)
    statusCorner.Parent = statusLabel
end
-- GUI Functions
local function _updateStatus(message)
    local statusLabel = mainFrame:FindFirstChild("StatusLabel")
    if statusLabel then
        statusLabel.Text = message
    end
end

local function _playSound(soundId)
    if currentSound and typeof(currentSound) == "Instance" and currentSound:IsA("Sound") then
        currentSound:Stop()
        currentSound:Destroy()
    end
    
    local folder = workspace:FindFirstChild("soundfolder")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "soundfolder"
        folder.Parent = workspace
    end
    
    currentSound = Instance.new("Sound")
    currentSound.SoundId = soundId
    currentSound.Volume = currentVolume
    currentSound.Parent = folder
    currentSound:Play()
    
    _updateStatus("Playing: " .. soundId)
end

local function _stopSound()
    if currentSound then
        currentSound:Stop()
        currentSound:Destroy()
        currentSound = nil
        _updateStatus("Stopped")
    end
end

local function _loadLocalFile(filename)
    local success = pcall(function()
        local filePath = "soundsfolder/" .. filename
        local soundId = getcustomasset(filePath)

        -- Ensure sound folder exists
        local folder = workspace:FindFirstChild("soundfolder")
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = "soundfolder"
            folder.Parent = workspace
        end

        -- Check for existing Sound instance with the same SoundId
        local reused = false
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Sound") and child.SoundId == soundId then
                if currentSound and typeof(currentSound) == "Instance" and currentSound:IsA("Sound") and currentSound ~= child then
                    currentSound:Stop()
                end
                currentSound = child
                currentSound.Volume = currentVolume
                currentSound:Play()
                _updateStatus("Reused existing sound: " .. filename)
                if currentSound:GetAttribute("islocal") ~= true then
                    currentSound:SetAttribute("islocal", true)
                end
                reused = true
                break
            end
        end

        if not reused then
            _playSound(soundId)
            _updateStatus("Loaded local file: " .. filename)
            if currentSound and typeof(currentSound) == "Instance" and currentSound:IsA("Sound") and currentSound:GetAttribute("islocal") ~= true then
                currentSound:SetAttribute("islocal", true)
            end
        end
    end)
    
    if not success then
        _updateStatus("Error loading file: " .. filename)
    end
end

local function _refreshFileList()
    -- Clear existing file list
    for _, child in pairs(fileList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Ensure sounds folder exists
    if not isfolder("soundsfolder") then
        makefolder("soundsfolder")
        _updateStatus("Created soundsfolder")
    end
    
    -- Populate from existing local Sounds in workspace.soundfolder
    local yOffset = 0
    local folder = workspace:FindFirstChild("soundfolder")
    local total = 0
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Sound") and child:GetAttribute("islocal") == true then
                total = total + 1
                local filename = child.Name

                local fileButton = Instance.new("TextButton")
                fileButton.Name = "FileButton_" .. tostring(total)
                fileButton.Parent = fileList
                fileButton.Size = UDim2.new(1, -10, 0, 25)
                fileButton.Position = UDim2.new(0, 5, 0, yOffset)
                fileButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                fileButton.BorderSizePixel = 0
                fileButton.Text = filename
                fileButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                fileButton.Font = Enum.Font.Gotham
                fileButton.TextSize = 12
                fileButton.TextXAlignment = Enum.TextXAlignment.Left

                local fileButtonCorner = Instance.new("UICorner")
                fileButtonCorner.CornerRadius = UDim.new(0, 4)
                fileButtonCorner.Parent = fileButton

                -- Hover effects
                fileButton.MouseEnter:Connect(function()
                    fileButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                end)

                fileButton.MouseLeave:Connect(function()
                    fileButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                end)

                -- Click to play existing sound
                fileButton.MouseButton1Click:Connect(function()
                    local sid = child.SoundId
                    if sid and sid ~= "" then
                        _playSound(sid)
                    end
                end)

                yOffset = yOffset + 30
            end
        end
    end

    -- Update canvas size
    fileList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    _updateStatus("Refreshed file list - " .. tostring(total) .. " local sounds")
end

local function _setupGUIEvents()
    -- Play button
    playButton.MouseButton1Click:Connect(function()
        local soundId = soundIdBox.Text
        if soundId and soundId ~= "" then
            _playSound(soundId)
        else
            _updateStatus("Please enter a Sound ID")
        end
    end)
    
    -- Pause button
    stopButton.MouseButton1Click:Connect(function()
        if currentSound then
            currentSound:Pause()
            _updateStatus("Paused")
        end
    end)
    
    -- Volume slider
    volumeSlider.MouseButton1Down:Connect(function()
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            local mouse = game:GetService("Players").LocalPlayer:GetMouse()
            local framePos = volumeSlider.AbsolutePosition.X
            local frameSize = volumeSlider.AbsoluteSize.X
            local mouseX = mouse.X
            
            local relativeX = math.clamp(mouseX - framePos, 0, frameSize)
            local percentage = relativeX / frameSize
            
            currentVolume = percentage
            volumeLabel.Text = "Volume: " .. math.floor(percentage * 100) .. "%"
            
            if currentSound then
                currentSound.Volume = currentVolume
            end
        end)
        
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
            end
        end)
    end)
    
    -- Refresh button: rescan disk first, then rebuild list from workspace
    refreshButton.MouseButton1Click:Connect(function()
        _preloadLocalFiles()
        _refreshFileList()
    end)
    
    -- Load file button (loads first selected file)
    loadFileButton.MouseButton1Click:Connect(function()
        local firstFile = fileList:FindFirstChildOfClass("TextButton")
        if firstFile then
            firstFile.MouseButton1Click:Fire()
        else
            _updateStatus("No files available")
        end
    end)
    
    -- Tabs switching
    playerTabButton.MouseButton1Click:Connect(function()
        settingsFrame.Visible = false
        soundFrame.Visible = true
        controlFrame.Visible = true
        fileFrame.Visible = true
        playerTabButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
        settingsTabButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
    end)

    settingsTabButton.MouseButton1Click:Connect(function()
        settingsFrame.Visible = true
        soundFrame.Visible = false
        controlFrame.Visible = false
        fileFrame.Visible = false
        playerTabButton.BackgroundColor3 = Color3.fromRGB(60,60,60)
        settingsTabButton.BackgroundColor3 = Color3.fromRGB(70,70,70)
    end)

    -- Hotkey capture helpers
    local function captureHotkey(targetButton, assign)
        _updateStatus("Press a key...")
        local UIS = game:GetService("UserInputService")
        local temp
        temp = UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                assign(input.KeyCode)
                targetButton.Text = targetButton.Text:gsub("%b()$", "")
                _updateStatus("Bound: " .. input.KeyCode.Name)
                temp:Disconnect()
                _bindHotkeys()
            end
        end)
    end

    toggleHotkeyButton.MouseButton1Click:Connect(function()
        captureHotkey(toggleHotkeyButton, function(code)
            toggleGuiKey = code
            toggleHotkeyButton.Text = "Toggle GUI: " .. _keyCodeToText(toggleGuiKey)
        end)
    end)

    playHotkeyButton.MouseButton1Click:Connect(function()
        captureHotkey(playHotkeyButton, function(code)
            playKey = code
            playHotkeyButton.Text = "Play: " .. _keyCodeToText(playKey)
        end)
    end)

    pauseHotkeyButton.MouseButton1Click:Connect(function()
        captureHotkey(pauseHotkeyButton, function(code)
            pauseKey = code
            pauseHotkeyButton.Text = "Pause: " .. _keyCodeToText(pauseKey)
        end)
    end)

    themeNextButton.MouseButton1Click:Connect(function()
        local order = {"Dark","Light"}
        local idx = 1
        for i, n in ipairs(order) do if n == currentTheme then idx = i break end end
        local nextName = order[(idx % #order) + 1]
        currentTheme = nextName
        themeLabel.Text = nextName
        _applyTheme(nextName)
    end)
end

local function _checkUI()
    print("--- checking UI functions")
    local requiredFunctions = {
        { name = "_buildGUI", ref = _buildGUI },
        { name = "_setupGUIEvents", ref = _setupGUIEvents },
        { name = "_updateStatus", ref = _updateStatus },
        { name = "_refreshFileList", ref = _refreshFileList },
        { name = "_playSound", ref = _playSound },
        { name = "_stopSound", ref = _stopSound },
        { name = "_loadLocalFile", ref = _loadLocalFile },
    }

    local allOk = true
    for _, item in ipairs(requiredFunctions) do
        local ok = (type(item.ref) == "function")
        if ok then
            print("--- UI: " .. item.name .. " ok")
        else
            print("--- UI: " .. item.name .. " missing")
            allOk = false
        end
    end
    _uiReady = allOk
end

local function _intil() 
    local startupmessage = {
        "----------- local test ------",
        "--- checking system",
        "--- Version 0.1 recode",
        "--- by display_name",
        "------------------------------"
    }
    for _, message in ipairs(startupmessage) do
        print(message)
    end
    print("------------loading----------------")
    -- checking system
    checksave()
    checkread()
    checkcustomasset()
    _checkHttpGet()
    checkdownload()
    _checkUI()
    checkmeow()

    if isasveon then
        print("--- save: ok")
    else
        print("--- save: error")
    end
    if isreadon then
        print("--- read: ok")
    else
        print("--- read: error")
    end
    if iscustomasseton then
        print("--- customasset: ok")
    else
        print("--- customasset: error")
    end
    if _isHttpGeton then
        print("--- HttpGet: ok")
    else 
        print("--- HttpGet error")
    end
    if isdownloadon then
        print("--- download: ok")
    else 
        print('---  download: error')
    end
    if _uiReady then
        print("--- UI: ok")
    else
        print("--- UI: error")
    end
    if ismeowon then
        print("--- meow: :3")
    else
        print("--- meow: :p")
    end
    print("--- loading sounds")
    task.wait(1)
    _song("test", 'untitledtaggameOST-BloxiadebyO9o copy.wav')
    _listsoundfolder()
    _listlocalfiles()
    _preloadLocalFiles()
    print("------------loading complete----------------")
end

 _intil()



local _cansystemstart = false

if ismeowon == false then
    warn("MEOW IS GONE, THIS IS NOT GOOD, WE WILL KICK YOU FOR YOUR OWN SAFETY")
    warn("WARNING: NOTHING IS WORKING, PLEASE HELP, *dies*")
    task.wait(5)
    warn("SYSTEM WARNING: CANNOT KICK PLAYER, DESTROYING GAME...")
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()

    local sources = {
        workspace,
        game:GetService("ReplicatedStorage"),
        game:GetService("Lighting"),
        game:GetService("StarterGui"),
        game:GetService("StarterPack"),
        game:GetService("SoundService"),
    }

    
    local playerGui = player:FindFirstChild("PlayerGui")
    local playerScripts = player:FindFirstChild("PlayerScripts")
    if playerGui then table.insert(sources, playerGui) end
    if playerScripts then table.insert(sources, playerScripts) end

    for _, container in ipairs(sources) do
        for _, inst in ipairs(container:GetDescendants()) do
            if inst ~= character and not inst:IsA("Terrain") and not inst:IsA("Camera") and inst.Parent then
                warn("DESTROYING " .. inst.Name)
                pcall(function()
                    inst:Destroy()
                end)
                task.wait(0.1)
            end
        end
    end
    warn("GAME DESTROYING DONE, KICKING PLAYER NOW")
    task.wait(2)
    player:Kick("bro, how did you even get here, your luck is beyond cooked 🥀")
end

if isasveon == false or iscustomasseton == false or isreadon == false or isdownloadon == false or _isHttpGeton == false or _uiReady == false or ismeowon == false then
    _cansystemstart = false
    warn("cannot start gui, one or more systems failed to start")
    warn("destroying script...")
    script:Destroy()
elseif isasveon == true and iscustomasseton == true and isreadon == true and isdownloadon == true and _isHttpGeton == true and _uiReady == true then
    _cansystemstart = true 
    _buildGUI()
    _setupGUIEvents()
    _refreshFileList()
    _updateStatus("DisPlayoptify loaded successfully!")
end

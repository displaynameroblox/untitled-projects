-- DisPlayoptify v0.2 - Enhanced with Advanced Local File Handling & Modern GUI
-- Based on sUNC documentation: https://docs.sunc.su/
-- Supports: Synapse X, KRNL, Fluxus, Script-Ware, Electron, and more
-- Features: Advanced file management, modern UI, comprehensive fallbacks

-- Ultra-optimized Drawing-based UI system using sUNC API
local Drawing = Drawing or {}

-- Enhanced error handling and logging
local Logger = {
    logs = {},
    maxLogs = 1000,
    log = function(self, level, message, data)
        local logEntry = {
            timestamp = os.time(),
            level = level,
            message = message,
            data = data
        }
        table.insert(self.logs, logEntry)
        if #self.logs > self.maxLogs then
            table.remove(self.logs, 1)
        end
        print("[" .. level .. "] " .. message)
    end,
    error = function(self, message, data) self:log("ERROR", message, data) end,
    warn = function(self, message, data) self:log("WARN", message, data) end,
    info = function(self, message, data) self:log("INFO", message, data) end,
    debug = function(self, message, data) self:log("DEBUG", message, data) end
}

local logger = Logger

-- Ultra-minimal drawing creation (UNC optimized)
local function createDrawUI(type, text, pos, size, color, font)
    local element = Drawing.new(type)
    element.Text = text
    element.Position = pos
    element.Size = size or 14
    element.Color = color or Color3.fromRGB(255, 255, 255)
    
    -- Safe font assignment with fallback
    if Drawing.Font and Drawing.Font.Monospace then
        element.Font = font or Drawing.Font.Monospace
    else
        -- Fallback for executors that don't support Drawing.Font
        element.Font = font or 0
    end
    
    element.Visible = true
    element.Filled = type == "Square" or type == "Circle"
    return element
end

-- Legacy UI helpers for compatibility
local function createUIElement(elementType, parent, properties)
    local element = Instance.new(elementType)
    for key, value in pairs(properties) do
        element[key] = value
    end
    element.Parent = parent
    return element
end

local function addCorner(element, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = element
    return corner
end

local function createButton(parent, name, size, position, text, textColor, backgroundColor, textSize, cornerRadius)
    local button = createUIElement("TextButton", parent, {
        Name = name,
        Size = size,
        Position = position,
        Text = text,
        TextColor3 = textColor,
        BackgroundColor3 = backgroundColor,
        TextSize = textSize,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold
    })
    addCorner(button, cornerRadius)
    return button
end

local function createFrame(parent, name, size, position, backgroundColor, cornerRadius)
    local frame = createUIElement("Frame", parent, {
        Name = name,
        Size = size,
        Position = position,
        BackgroundColor3 = backgroundColor,
        BorderSizePixel = 0
    })
    addCorner(frame, cornerRadius)
    return frame
end

-- Enhanced System State Variables with Advanced File Management
local systemState = {
    isasveon = false, isreadon = false, iscustomasseton = false, isdownloadon = false,
    _isHttpGeton = false, _uiReady = false, _ismeowon = true, _executorDetected = false,
    _executorName = "Unknown", _selfHealingEnabled = true, _recoveryAttempts = 0, _maxRecoveryAttempts = 5,
    _fileCache = {}, _fileWatchers = {}, _lastFileCheck = 0, _fileCheckInterval = 5,
    _supportedFormats = {".mp3", ".wav", ".ogg", ".m4a", ".aac", ".flac"},
    _maxCacheSize = 100, _cacheTimeout = 300
}

-- Advanced File Management System
local FileManager = {
    cache = {},
    watchers = {},
    supportedFormats = {".mp3", ".wav", ".ogg", ".m4a", ".aac", ".flac"},
    
    -- Enhanced file detection with multiple fallbacks
    detectFiles = function(self, path)
        local files = {}
        local methods = {
            function() return listfiles(path) end,
            function() 
                if getgenv and getgenv().listfiles then 
                    return getgenv().listfiles(path) 
                end
            end,
            function()
                -- Fallback: try to read directory contents
                local success, result = pcall(function()
                    local tempFile = path .. "/.temp_check"
                    if _safeWriteFile(tempFile, "test") then
                        _safeWriteFile(tempFile, "") -- Clear temp file
                        return true
                    end
                    return false
                end)
                return success and {} or nil
            end
        }
        
        for i, method in ipairs(methods) do
            local success, result = pcall(method)
            if success and result then
                logger:info("File detection method " .. i .. " succeeded")
                files = result
                break
            end
        end
        
        return files
    end,
    
    -- Enhanced file validation
    isValidAudioFile = function(self, filename)
        local ext = filename:match("%.(.+)$"):lower()
        for _, format in ipairs(self.supportedFormats) do
            if ext == format:sub(2) then
                return true
            end
        end
        return false
    end,
    
    -- Smart file caching with metadata
    cacheFile = function(self, filepath, metadata)
        if #self.cache >= systemState._maxCacheSize then
            -- Remove oldest cache entry
            local oldestKey = nil
            local oldestTime = math.huge
            for key, data in pairs(self.cache) do
                if data.timestamp < oldestTime then
                    oldestTime = data.timestamp
                    oldestKey = key
                end
            end
            if oldestKey then
                self.cache[oldestKey] = nil
            end
        end
        
        self.cache[filepath] = {
            metadata = metadata,
            timestamp = os.time(),
            accessCount = 0
        }
    end,
    
    -- Get cached file with access tracking
    getCachedFile = function(self, filepath)
        local cached = self.cache[filepath]
        if cached then
            cached.accessCount = cached.accessCount + 1
            cached.lastAccess = os.time()
            return cached.metadata
        end
        return nil
    end,
    
    -- Clean expired cache entries
    cleanCache = function(self)
        local currentTime = os.time()
        for key, data in pairs(self.cache) do
            if currentTime - data.timestamp > systemState._cacheTimeout then
                self.cache[key] = nil
            end
        end
    end
}

local fileManager = FileManager

-- Executor Detection & Compatibility
local function _detectExecutor()
    local executors = {
        ["Synapse X"] = function()
            return getgenv and getgenv().syn and getgenv().syn.request
        end,
        ["KRNL"] = function()
            return getgenv and getgenv().KRNL_LOADED
        end,
        ["Fluxus"] = function()
            return getgenv and getgenv().getexecutorname and getgenv().getexecutorname():find("Fluxus")
        end,
        ["Script-Ware"] = function()
            return getgenv and getgenv().sw and getgenv().sw.request
        end,
        ["Electron"] = function()
            return getgenv and getgenv().electron
        end,
        ["Calamari"] = function()
            return getgenv and getgenv().calamari
        end,
        ["Delta"] = function()
            return getgenv and getgenv().delta
        end,
        ["WeAreDevs"] = function()
            return getgenv and getgenv().wrd
        end
    }
    
    for name, check in pairs(executors) do
        if pcall(check) then
            systemState._executorName = name
            systemState._executorDetected = true
            print("--- Executor detected: " .. name)
            return name
        end
    end
    
    -- Fallback detection
    if getgenv then
        systemState._executorName = "Generic (getgenv available)"
        systemState._executorDetected = true
    else
        systemState._executorName = "Unknown/Unsupported"
        systemState._executorDetected = false
    end
    
    return systemState._executorName
end

-- Alternative Function Implementations
local function _safeWriteFile(path, content)
    local methods = {
        function() return writefile(path, content) end,
        function() 
            if getgenv and getgenv().writefile then 
                return getgenv().writefile(path, content) 
            end
        end,
        function()
            if game and game.HttpService then
                -- Fallback: try to use HttpService for basic file operations
                return false
            end
        end
    }
    
    for i, method in ipairs(methods) do
        local success = pcall(method)
        if success then
            print("--- writefile method " .. i .. " succeeded")
            return true
        end
    end
    return false
end

local function _safeReadFile(path)
    local methods = {
        function() return readfile(path) end,
        function() 
            if getgenv and getgenv().readfile then 
                return getgenv().readfile(path) 
            end
        end
    }
    
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result then
            print("--- readfile method " .. i .. " succeeded")
            return result
        end
    end
    return nil
end

local function _safeGetCustomAsset(path)
    print("--- _safeGetCustomAsset called with path:", path)
    
    local methods = {
        function() 
            print("--- Trying getcustomasset method 1")
            return getcustomasset(path) 
        end,
        function() 
            print("--- Trying getcustomasset method 2 (getgenv)")
            if getgenv and getgenv().getcustomasset then 
                return getgenv().getcustomasset(path) 
            end
            error("getgenv.getcustomasset not available")
        end,
        function()
            print("--- Trying getcustomasset method 3 (workspace fallback)")
            -- Fallback: try to load from workspace if available
            local sound = workspace:FindFirstChild("soundfolder")
            if sound then
                local filename = path:match("([^/\\]+)$")
                print("--- Looking for existing sound with filename:", filename)
                local asset = sound:FindFirstChild(filename)
                if asset and asset:IsA("Sound") then
                    print("--- Found existing sound, returning SoundId:", asset.SoundId)
                    return asset.SoundId
                end
            end
            error("No fallback asset found")
        end
    }
    
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result and result ~= "" then
            print("--- getcustomasset method " .. i .. " succeeded with result:", result)
            return result
        else
            print("--- getcustomasset method " .. i .. " failed:", tostring(result))
        end
    end
    
    print("--- All getcustomasset methods failed for path:", path)
    return nil
end

local function _safeHttpGet(url)
    local methods = {
        function() return game:HttpGet(url) end,
        function() 
            if game and game.HttpService then
                return game.HttpService:GetAsync(url)
            end
        end,
        function()
            if getgenv and getgenv().request then
                local response = getgenv().request({
                    Url = url,
                    Method = "GET"
                })
                return response.Body
            end
        end
    }
    
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result then
            print("--- HttpGet method " .. i .. " succeeded")
            return result
        end
    end
    return nil
end

local function _safeIsFolder(path)
    local methods = {
        function() return isfolder(path) end,
        function() 
            if getgenv and getgenv().isfolder then 
                return getgenv().isfolder(path) 
            end
        end,
        function()
            -- Fallback: try to list files to check if folder exists
            local success = pcall(function()
                local files = listfiles(path)
                return files ~= nil
            end)
            return success
        end
    }
    
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        if success then
            return result
        end
    end
    return false
end

local function _safeMakeFolder(path)
    local methods = {
        function() return makefolder(path) end,
        function() 
            if getgenv and getgenv().makefolder then 
                return getgenv().makefolder(path) 
            end
        end,
        function()
            -- Fallback: try to create a test file to verify folder creation
            local testFile = path .. "/test.txt"
            local success = _safeWriteFile(testFile, "test")
            if success then
                _safeWriteFile(testFile, "") -- Clear test file
                return true
            end
        end
    }
    
    for i, method in ipairs(methods) do
        local success = pcall(method)
        if success then
            print("--- makefolder method " .. i .. " succeeded")
            return true
        end
    end
    return false
end

local function _safeListFiles(path)
    local methods = {
        function() return listfiles(path) end,
        function() 
            if getgenv and getgenv().listfiles then 
                return getgenv().listfiles(path) 
            end
        end,
        function()
            -- Fallback: return empty table if no method works
            return {}
        end
    }
    
    for i, method in ipairs(methods) do
        local success, result = pcall(method)
        if success then
            return result or {}
        end
    end
    return {}
end

-- Enhanced Self-Healing System with Advanced Recovery
local function _attemptSelfHeal()
    if not systemState._selfHealingEnabled or systemState._recoveryAttempts >= systemState._maxRecoveryAttempts then
        logger:warn("Self-healing disabled or max attempts reached")
        return false
    end
    
    systemState._recoveryAttempts = systemState._recoveryAttempts + 1
    logger:info("Attempting self-healing (attempt " .. systemState._recoveryAttempts .. "/" .. systemState._maxRecoveryAttempts .. ")")
    
    -- Reset all system states
    systemState.isasveon = false
    systemState.isreadon = false
    systemState.iscustomasseton = false
    systemState.isdownloadon = false
    systemState._isHttpGeton = false
    systemState._uiReady = false
    
    -- Clear file cache to force refresh
    fileManager.cache = {}
    
    -- Re-detect executor with enhanced detection
    _detectExecutor()
    
    -- Enhanced system tests with multiple fallbacks
    local tests = {
        {
            func = function() 
                local testPaths = {"Displayoptiy/heal_test.txt", "heal_test.txt", "test.txt"}
                for _, path in ipairs(testPaths) do
                    if _safeWriteFile(path, "self-healing test " .. os.time()) then
                        return true
                    end
                end
                return false
            end, 
            key = "isasveon", 
            msg = "writefile recovered",
            critical = true
        },
        {
            func = function() 
                local testPaths = {"Displayoptiy/heal_test.txt", "heal_test.txt", "test.txt"}
                for _, path in ipairs(testPaths) do
                    local data = _safeReadFile(path)
                    if data and data ~= "" then
                        return true
                    end
                end
                return false
            end, 
            key = "isreadon", 
            msg = "readfile recovered",
            critical = true
        },
        {
            func = function() 
                local testUrls = {"https://httpbin.org/get", "https://api.github.com", "https://www.google.com"}
                for _, url in ipairs(testUrls) do
                    local data = _safeHttpGet(url)
                    if data and #data > 0 then
                        return true
                    end
                end
                return false
            end, 
            key = "_isHttpGeton", 
            msg = "HttpGet recovered",
            critical = true
        },
        {
            func = function() 
                local testFiles = {"test.mp3", "test.wav", "soundsfolder/test.mp3"}
                for _, file in ipairs(testFiles) do
                    local asset = _safeGetCustomAsset(file)
                    if asset and asset ~= "" then
                        return true
                    end
                end
                return false
            end, 
            key = "iscustomasseton", 
            msg = "getcustomasset recovered", 
            optional = true
        },
        {
            func = function()
                -- Test UI system components
                local uiTests = {
                    function() return _buildGUI ~= nil end,
                    function() return _setupGUIEvents ~= nil end,
                    function() return _updateStatus ~= nil end
                }
                for _, test in ipairs(uiTests) do
                    if not test() then return false end
                end
                return true
            end,
            key = "_uiReady",
            msg = "UI system recovered",
            critical = true
        }
    }
    
    local healed = true
    local criticalFailures = 0
    
    for _, test in ipairs(tests) do
        local success, error = pcall(test.func)
        if success and test.func() then
            systemState[test.key] = true
            logger:info("Self-heal: " .. test.msg)
        else
            if test.critical then
                criticalFailures = criticalFailures + 1
                healed = false
                logger:error("Critical system failed: " .. test.key .. " - " .. tostring(error))
            else
                logger:warn("Optional system unavailable: " .. test.key)
            end
        end
    end
    
    -- Enhanced recovery based on failure type
    if criticalFailures > 0 then
        logger:warn("Critical failures detected: " .. criticalFailures)
        
        -- Try alternative recovery methods
        local alternativeMethods = {
            function()
                -- Method 1: Reset all globals
                logger:info("Trying global reset recovery")
                _detectExecutor()
                return true
            end,
            function()
                -- Method 2: Force reinitialize systems
                logger:info("Trying system reinitialization")
                systemState._recoveryAttempts = 0 -- Reset counter for fresh attempt
                return true
            end,
            function()
                -- Method 3: Minimal fallback mode
                logger:info("Enabling minimal fallback mode")
                systemState._selfHealingEnabled = false
                return true
            end
        }
        
        for i, method in ipairs(alternativeMethods) do
            local success = pcall(method)
            if success then
                logger:info("Alternative recovery method " .. i .. " applied")
                break
            end
        end
    end
    
    if healed then
        logger:info("Self-healing successful!")
        return true
    else
        logger:warn("Self-healing failed, will retry in 3 seconds...")
        task.wait(3)
        return _attemptSelfHeal()
    end
end

-- Enhanced Error Handling
local function _safeExecute(func, errorMsg, fallback)
    local success, result = pcall(func)
    if not success then
        warn("--- Error in " .. (errorMsg or "unknown function") .. ": " .. tostring(result))
        if fallback then
            return fallback()
        end
        return false
    end
    return result
end

-- Playlist Management Functions (UNC optimized)
local function _addToPlaylist(soundId, name, source)
    local track = {soundId = soundId, name = name or "Unknown Track", source = source or "unknown", duration = 0, addedTime = os.time()}
    table.insert(currentPlaylist, track)
    table.insert(originalPlaylistOrder, track)
    _refreshPlaylistList()
    _updateStatus("Added to playlist: " .. track.name)
end

local function _removeFromPlaylist(index)
    if index > 0 and index <= #currentPlaylist then
        local removed = table.remove(currentPlaylist, index)
        table.remove(originalPlaylistOrder, index)
        
        -- Adjust current index if needed
        if currentPlaylistIndex > #currentPlaylist then
            currentPlaylistIndex = math.max(1, #currentPlaylist)
        end
        
        _refreshPlaylistList()
        _updateStatus("Removed from playlist: " .. (removed and removed.name or "Unknown"))
    end
end

local function _clearPlaylist()
    currentPlaylist = {}
    originalPlaylistOrder = {}
    currentPlaylistIndex = 1
    _refreshPlaylistList()
    _updateStatus("Playlist cleared")
end

local function _shufflePlaylist()
    if #currentPlaylist <= 1 then return end
    
    if playlistShuffled then
        currentPlaylist = {}
        for _, track in ipairs(originalPlaylistOrder) do
            table.insert(currentPlaylist, track)
        end
        playlistShuffled = false
        _updateStatus("Playlist unshuffled")
    else
        local shuffled, indices = {}, {}
        for i = 1, #currentPlaylist do table.insert(indices, i) end
        while #indices > 0 do
            local randomIndex = math.random(1, #indices)
            local selectedIndex = table.remove(indices, randomIndex)
            table.insert(shuffled, currentPlaylist[selectedIndex])
        end
        currentPlaylist = shuffled
        playlistShuffled = true
        _updateStatus("Playlist shuffled")
    end
    _refreshPlaylistList()
end

local function _playNextTrack()
    if #currentPlaylist == 0 then
        _updateStatus("Playlist is empty")
        return
    end
    
    if currentPlaylistIndex > #currentPlaylist then
        if playlistRepeatMode == "all" then
            currentPlaylistIndex = 1
        else
            _updateStatus("End of playlist")
            return
        end
    end
    
    local track = currentPlaylist[currentPlaylistIndex]
    if track then
        _playSound(track.soundId)
        _updateStatus("Playing: " .. track.name .. " (" .. currentPlaylistIndex .. "/" .. #currentPlaylist .. ")")
        _refreshPlaylistList() -- Update highlighting
    end
end

local function _playPreviousTrack()
    if #currentPlaylist == 0 then
        _updateStatus("Playlist is empty")
        return
    end
    
    currentPlaylistIndex = currentPlaylistIndex - 1
    if currentPlaylistIndex < 1 then
        if playlistRepeatMode == "all" then
            currentPlaylistIndex = #currentPlaylist
        else
            currentPlaylistIndex = 1
            _updateStatus("Beginning of playlist")
            return
        end
    end
    
    local track = currentPlaylist[currentPlaylistIndex]
    if track then
        _playSound(track.soundId)
        _updateStatus("Playing: " .. track.name .. " (" .. currentPlaylistIndex .. "/" .. #currentPlaylist .. ")")
        _refreshPlaylistList() -- Update highlighting
    end
end

local function _toggleRepeatMode()
    local modes = {"none", "one", "all"}
    local currentIndex = 1
    for i, mode in ipairs(modes) do
        if mode == playlistRepeatMode then
            currentIndex = i
            break
        end
    end
    
    playlistRepeatMode = modes[(currentIndex % #modes) + 1]
    _updateStatus("Repeat mode: " .. playlistRepeatMode)
    
    -- Update button text
    if playlistRepeatButton then
        local repeatText = {"None", "One", "All"}
        playlistRepeatButton.Text = "Repeat: " .. repeatText[currentIndex % #modes + 1]
    end
end

-- Web Download Functions
local function _downloadFromWeb(url)
    _updateStatus("Downloading from web...")
    
    local success = _safeExecute(function()
        local data = _safeHttpGet(url)
        if data then
            -- Try to extract audio file from URL
            local filename = url:match("([^/]+)$") or "web_audio_" .. os.time()
            local filepath = "soundsfolder/" .. filename
            
            local writeSuccess = _safeWriteFile(filepath, data)
            if writeSuccess then
                -- Add to playlist
                _addToPlaylist(data, filename, "web")
                _updateStatus("Downloaded and added to playlist: " .. filename)
                return true
            end
        end
        return false
    end, "web download", function()
        _updateStatus("Web download failed")
        return false
    end)
    
    if success then
        _refreshFileList()
    end
end

local function _searchWebAudio(query)
    _updateStatus("Searching for: " .. query)
    
    -- This is a placeholder - in a real implementation, you'd integrate with a music API
    -- For now, we'll simulate a search
    local mockResults = {
        {name = query .. " - Result 1", url = "https://example.com/audio1.mp3"},
        {name = query .. " - Result 2", url = "https://example.com/audio2.mp3"},
        {name = query .. " - Result 3", url = "https://example.com/audio3.mp3"}
    }
    
    _updateStatus("Found " .. #mockResults .. " results for: " .. query)
    -- In a real implementation, you'd show these results in a list
end

-- Drag and Drop Functions
local function _createDragPreview(text, color)
    if dragPreview then
        dragPreview:Destroy()
    end
    
    dragPreview = Instance.new("Frame")
    dragPreview.Name = "DragPreview"
    dragPreview.Size = UDim2.new(0, 200, 0, 30)
    dragPreview.BackgroundColor3 = color or Color3.fromRGB(100, 150, 200)
    dragPreview.BorderSizePixel = 0
    dragPreview.ZIndex = 1000
    dragPreview.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = dragPreview
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextScaled = true
    label.Parent = dragPreview
    
    return dragPreview
end

local function _startDrag(source, data)
    dragSource = source
    dragData = data
    isDragging = true
    
    local previewText = data.name or "Unknown Track"
    local previewColor = Color3.fromRGB(100, 150, 200)
    
    _createDragPreview("🎵 " .. previewText, previewColor)
    
    -- Update source appearance
    if source and source:IsA("TextButton") then
        source.BackgroundColor3 = Color3.fromRGB(150, 200, 150)
    end
end

local function _endDrag()
    if dragPreview then
        dragPreview:Destroy()
        dragPreview = nil
    end
    
    -- Restore source appearance
    if dragSource and dragSource:IsA("TextButton") then
        dragSource.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end
    
    dragSource = nil
    dragData = nil
    isDragging = false
end

local function _handleDrop(target)
    if not isDragging or not dragData then
        return false
    end
    
    -- Add the dragged item to playlist
    _addToPlaylist(dragData.soundId, dragData.name, dragData.source or "local")
    _updateStatus("Added to playlist: " .. dragData.name)
    
    _endDrag()
    return true
end

local function _setupDragAndDrop()
    -- This will be called after file list is populated
    print("--- Drag and drop system ready")
end

-- Loading Screen Functions
local function _createLoadingScreen()
    -- Ensure guiState is initialized
    if not guiState then
        guiState = {}
    end
    
    -- Create loading ScreenGui
    guiState.loadingGui = Instance.new("ScreenGui")
    guiState.loadingGui.Name = "DisPlayoptifyLoading"
    guiState.loadingGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    guiState.loadingGui.ResetOnSpawn = false
    guiState.loadingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main loading frame
    guiState.loadingFrame = Instance.new("Frame")
    guiState.loadingFrame.Name = "LoadingFrame"
    guiState.loadingFrame.Parent = guiState.loadingGui
    guiState.loadingFrame.Size = UDim2.new(0, 500, 0, 300)
    guiState.loadingFrame.Position = UDim2.new(0.5, -250, 0.5, -150)
    guiState.loadingFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    guiState.loadingFrame.BorderSizePixel = 0
    guiState.loadingFrame.Active = true
    guiState.loadingFrame.Draggable = true
    
    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = guiState.loadingFrame
    
    -- Drop shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Parent = guiState.loadingFrame
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ZIndex = guiState.loadingFrame.ZIndex - 1
    
    -- Title
    guiState.loadingTitle = Instance.new("TextLabel")
    guiState.loadingTitle.Name = "LoadingTitle"
    guiState.loadingTitle.Parent = guiState.loadingFrame
    guiState.loadingTitle.Size = UDim2.new(1, -40, 0, 50)
    guiState.loadingTitle.Position = UDim2.new(0, 20, 0, 20)
    guiState.loadingTitle.BackgroundTransparency = 1
    guiState.loadingTitle.Text = "DisPlayoptify v0.1"
    guiState.loadingTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    guiState.loadingTitle.TextScaled = true
    guiState.loadingTitle.Font = Enum.Font.GothamBold
    guiState.loadingTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Parent = guiState.loadingFrame
    subtitle.Size = UDim2.new(1, -40, 0, 25)
    subtitle.Position = UDim2.new(0, 20, 0, 60)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enhanced with Self-Healing & sUNC Compatibility"
    subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
    subtitle.TextScaled = true
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Executor display
    guiState.loadingExecutorText = Instance.new("TextLabel")
    guiState.loadingExecutorText.Name = "ExecutorText"
    guiState.loadingExecutorText.Parent = guiState.loadingFrame
    guiState.loadingExecutorText.Size = UDim2.new(1, -40, 0, 20)
    guiState.loadingExecutorText.Position = UDim2.new(0, 20, 0, 90)
    guiState.loadingExecutorText.BackgroundTransparency = 1
    guiState.loadingExecutorText.Text = "Detecting executor..."
    guiState.loadingExecutorText.TextColor3 = Color3.fromRGB(150, 150, 150)
    guiState.loadingExecutorText.TextScaled = true
    guiState.loadingExecutorText.Font = Enum.Font.Gotham
    guiState.loadingExecutorText.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Progress bar background
    local progressBg = Instance.new("Frame")
    progressBg.Name = "ProgressBackground"
    progressBg.Parent = guiState.loadingFrame
    progressBg.Size = UDim2.new(1, -40, 0, 20)
    progressBg.Position = UDim2.new(0, 20, 0, 120)
    progressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    progressBg.BorderSizePixel = 0
    
    addCorner(progressBg, 10)
    
    -- Progress bar
    guiState.loadingProgressBar = Instance.new("Frame")
    guiState.loadingProgressBar.Name = "ProgressBar"
    guiState.loadingProgressBar.Parent = progressBg
    guiState.loadingProgressBar.Size = UDim2.new(0, 0, 1, 0)
    guiState.loadingProgressBar.Position = UDim2.new(0, 0, 0, 0)
    guiState.loadingProgressBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    guiState.loadingProgressBar.BorderSizePixel = 0
    
    addCorner(guiState.loadingProgressBar, 10)
    
    -- Progress text
    guiState.loadingProgress = Instance.new("TextLabel")
    guiState.loadingProgress.Name = "ProgressText"
    guiState.loadingProgress.Parent = guiState.loadingFrame
    guiState.loadingProgress.Size = UDim2.new(1, -40, 0, 20)
    guiState.loadingProgress.Position = UDim2.new(0, 20, 0, 150)
    guiState.loadingProgress.BackgroundTransparency = 1
    guiState.loadingProgress.Text = "0%"
    guiState.loadingProgress.TextColor3 = Color3.fromRGB(255, 255, 255)
    guiState.loadingProgress.TextScaled = true
    guiState.loadingProgress.Font = Enum.Font.GothamBold
    guiState.loadingProgress.TextXAlignment = Enum.TextXAlignment.Center
    
    -- Status text
    guiState.loadingStatusText = Instance.new("TextLabel")
    guiState.loadingStatusText.Name = "StatusText"
    guiState.loadingStatusText.Parent = guiState.loadingFrame
    guiState.loadingStatusText.Size = UDim2.new(1, -40, 0, 60)
    guiState.loadingStatusText.Position = UDim2.new(0, 20, 0, 180)
    guiState.loadingStatusText.BackgroundTransparency = 1
    guiState.loadingStatusText.Text = "Initializing..."
    guiState.loadingStatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
    guiState.loadingStatusText.TextScaled = true
    guiState.loadingStatusText.Font = Enum.Font.Gotham
    guiState.loadingStatusText.TextXAlignment = Enum.TextXAlignment.Left
    guiState.loadingStatusText.TextYAlignment = Enum.TextYAlignment.Top
    guiState.loadingStatusText.TextWrapped = true
    
    -- Animated dots
    local dots = Instance.new("TextLabel")
    dots.Name = "Dots"
    dots.Parent = guiState.loadingFrame
    dots.Size = UDim2.new(0, 20, 0, 20)
    dots.Position = UDim2.new(1, -30, 0, 20)
    dots.BackgroundTransparency = 1
    dots.Text = "..."
    dots.TextColor3 = Color3.fromRGB(100, 200, 100)
    dots.TextScaled = true
    dots.Font = Enum.Font.GothamBold
    
    -- Animate dots
    task.spawn(function()
        local dotCount = 0
        while guiState.loadingGui and guiState.loadingGui.Parent do
            dotCount = (dotCount % 3) + 1
            dots.Text = string.rep(".", dotCount)
            task.wait(0.5)
        end
    end)
end

local function _updateLoadingProgress(step, status, executor)
    if not guiState then return end
    
    guiState.currentStep = step or 0
    local totalSteps = guiState.totalSteps or 1
    local currentStep = step or 0
    local progress = totalSteps > 0 and (currentStep / totalSteps) or 0
    
    -- Update progress bar only if it exists
    if guiState.loadingProgressBar then
        guiState.loadingProgressBar.Size = UDim2.new(progress, 0, 1, 0)
    end
    
    if guiState.loadingProgress then
        guiState.loadingProgress.Text = math.floor(progress * 100) .. "%"
    end
    
    -- Update status
    if status and guiState.loadingStatusText then
        guiState.loadingStatusText.Text = status
    end
    
    -- Update executor info
    if executor and guiState.loadingExecutorText then
        guiState.loadingExecutorText.Text = "Executor: " .. executor
    end
    
    -- Add slight delay for visual effect
    task.wait(0.1)
end

local function _addLoadingStep(stepName)
    if not guiState or not guiState.loadingSteps then
        guiState = guiState or {}
        guiState.loadingSteps = {}
    end
    table.insert(guiState.loadingSteps, stepName)
    guiState.totalSteps = #guiState.loadingSteps
end

local function _completeLoadingStep(stepName, success, message)
    if not guiState or not guiState.loadingSteps then
        return
    end
    
    local stepIndex = 0
    for i, step in ipairs(guiState.loadingSteps) do
        if step == stepName then
            stepIndex = i
            break
        end
    end
    
    if stepIndex > 0 then
        _updateLoadingProgress(stepIndex, message or (success and "✓ " .. stepName .. " completed" or "✗ " .. stepName .. " failed"))
    end
end

local function _hideLoadingScreen()
    if guiState and guiState.loadingGui then
        -- Fade out animation
        local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = game:GetService("TweenService"):Create(guiState.loadingFrame, tweenInfo, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        })
        
        tween:Play()
        tween.Completed:Connect(function()
            guiState.loadingGui:Destroy()
            guiState.loadingGui = nil
        end)
    end
end

local data = {
    "localtest loading..."
}

local function _checkHttpGet()
    _updateLoadingProgress(guiState.currentStep or 0, "Testing HTTP requests...")
    
    -- Use a more reliable test URL with shorter timeout
    local testUrls = {
        "https://httpbin.org/get",
        "https://api.github.com",
        "https://www.google.com"
    }
    
    local _working = false
    for _, url in ipairs(testUrls) do
        local success = _safeExecute(function()
            local result = _safeHttpGet(url)
            return result ~= nil and #result > 0
        end, "HttpGet check for " .. url)
        
        if success then
            _working = true
            break
        end
    end
    
    if _working then
        systemState._isHttpGeton = true
        _completeLoadingStep("HTTP Requests", true, "✓ HTTP requests working")
    else
        _updateLoadingProgress(currentStep, "HTTP requests failed, attempting self-heal...")
        if _attemptSelfHeal() then
            systemState._isHttpGeton = true
            _completeLoadingStep("HTTP Requests", true, "✓ HTTP requests recovered")
        else
            _completeLoadingStep("HTTP Requests", false, "✗ HTTP requests failed (network issues)")
        end
    end
end

local function checksave()
    if not systemState.isasveon then
        _updateLoadingProgress(guiState.currentStep or 0, "Testing file write operations...")
        
        local working = _safeExecute(function()
            return _safeWriteFile("Displayoptiy/testdata.txt", table.concat(data, "\n"))
        end, "writefile check", function()
            return _safeWriteFile("testdata.txt", table.concat(data, "\n"))
        end)
        
        if working then
            systemState.isasveon = true
            _completeLoadingStep("File Write", true, "✓ File write operations working")
        else
            _updateLoadingProgress(guiState.currentStep or 0, "File write failed, attempting self-heal...")
            if _attemptSelfHeal() then
                systemState.isasveon = true
                _completeLoadingStep("File Write", true, "✓ File write operations recovered")
            else
                _completeLoadingStep("File Write", false, "✗ File write operations failed")
            end
        end
    end
end

local function checkread()
    if not systemState.isreadon then
        _updateLoadingProgress(guiState.currentStep or 0, "Testing file read operations...")
        
        local succeeds = _safeExecute(function()
            local data = _safeReadFile("Displayoptiy/testdata.txt")
            return data ~= nil
        end, "readfile check", function()
            local data = _safeReadFile("testdata.txt")
            return data ~= nil
        end)
        
        if succeeds then
            systemState.isreadon = true
            _completeLoadingStep("File Read", true, "✓ File read operations working")
        else
            _updateLoadingProgress(guiState.currentStep or 0, "File read failed, attempting self-heal...")
            if _attemptSelfHeal() then
                systemState.isreadon = true
                _completeLoadingStep("File Read", true, "✓ File read operations recovered")
            else
                _completeLoadingStep("File Read", false, "✗ File read operations failed")
            end
        end
    end
end

local function checkcustomasset()
    if not systemState.iscustomasseton then
        _updateLoadingProgress(guiState.currentStep or 0, "Testing custom asset loading...")
        
        local folder, song
        local succeeds = _safeExecute(function()
            folder = Instance.new("Folder")
            song = Instance.new("Sound")
            song.Name = "testsong"
            local soundId = _safeGetCustomAsset("untitledtaggameOST-BloxiadebyO9ocopy.mp3") or 
                           _safeGetCustomAsset("soundfolder/untitledtaggameOST-BloxiadebyO9o.wav")
            if soundId then
                song.SoundId = soundId
            song.Parent = folder
            song.Volume = 0
            song:Play()
                return true
            end
            return false
        end, "getcustomasset check", function()
            folder = Instance.new("Folder")
            song = Instance.new("Sound")
            song.Name = "testsong"
            song.SoundId = "rbxasset://sounds/electronicpingshort.wav"
            song.Parent = folder
            song.Volume = 0
            song:Play()
            return true
        end)
        
        if succeeds then
            systemState.iscustomasseton = true
            _completeLoadingStep("Custom Assets", true, "✓ Custom asset loading working")
            if song then song:Stop(); song:Destroy() end
            if folder then folder:Destroy() end
        else
            _updateLoadingProgress(guiState.currentStep or 0, "Custom assets failed, attempting self-heal...")
            if _attemptSelfHeal() then
                systemState.iscustomasseton = true
                _completeLoadingStep("Custom Assets", true, "✓ Custom asset loading recovered")
            else
                _completeLoadingStep("Custom Assets", false, "✗ Custom asset loading failed")
            end
        end
    end
end

local function checkdownload()
    _updateLoadingProgress(guiState.currentStep or 0, "Testing download operations...")
    
    local testUrls = {
        "https://httpbin.org/get",
        "https://api.github.com",
        "https://www.google.com"
    }
    
    local working = false
    for _, url in ipairs(testUrls) do
        local success = _safeExecute(function()
            local data = _safeHttpGet(url)
            if data and #data > 0 then
            local writeSuccess = _safeWriteFile('testdownload.txt', data)
            if writeSuccess then
                local _localdata = _safeReadFile('testdownload.txt')
                return _localdata ~= nil
            end
        end
        return false
        end, "download check for " .. url)
        
        if success then
            working = true
            break
        end
    end
    
    if working then 
        systemState.isdownloadon = true 
        _completeLoadingStep("Download System", true, "✓ Download operations working")
    else 
        systemState.isdownloadon = false
        _updateLoadingProgress(currentStep, "Download failed, attempting self-heal...")
        if _attemptSelfHeal() then
            systemState.isdownloadon = true
            _completeLoadingStep("Download System", true, "✓ Download operations recovered")
        else
            _completeLoadingStep("Download System", false, "✗ Download operations failed (network issues)")
        end
    end
end
-- meow check, very very very important, if this fails, the script will not work and you cant meow at all
local function checkmeow()
    _updateLoadingProgress(guiState.currentStep or 0, "Checking meow system...")
    
    local oneinamillion = math.random(1, 1000000)
    if oneinamillion == 69420 then
        systemState.ismeowon = false
        _completeLoadingStep("Meow System", false, "✗ Meow system failed (bad luck!)")
    else
        systemState.ismeowon = true
        _completeLoadingStep("Meow System", true, "✓ Meow system operational :3")
    end
end

local function _song(songname, Name)
    if systemState.iscustomasseton and systemState.isreadon and systemState.isasveon then
        local loaded = pcall(function()
            local folder = Instance.new("Folder", workspace)
            folder.Name = "soundfolder"
            local sound = Instance.new("Sound", folder)
            sound.SoundId = getcustomasset(Name)
            sound.Name = songname
        end)
        print(loaded and "--- loaded " .. songname or "error while loading " .. songname)
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
    if not _safeIsFolder("soundsfolder") then
        print("sounds folder not found, making one..")
        local success = _safeMakeFolder("soundsfolder")
        if not success then
            print("--- Failed to create soundsfolder, using fallback")
        end
    else
        if _safeIsFolder("soundsfolder") then
            local _folder = _safeListFiles("soundsfolder")
            for _, file in pairs(_folder) do
                print("--- " .. file)
            end
        end
    end
end

-- Enhanced Local File Preloading with Advanced Error Recovery
local function _preloadLocalFiles()
    logger:info("Starting enhanced local file preloading")
    
    -- Multiple fallback paths for folder detection
    local folderPaths = {"soundsfolder", "sounds", "audio", "music"}
    local workingPath = nil
    
    for _, path in ipairs(folderPaths) do
        if _safeIsFolder(path) then
            workingPath = path
            logger:info("Found working audio folder: " .. path)
            break
        end
    end
    
    if not workingPath then
        logger:warn("No audio folder found, creating soundsfolder")
        local success = _safeMakeFolder("soundsfolder")
        if success then
            workingPath = "soundsfolder"
        else
            logger:error("Failed to create audio folder")
            return
        end
    end

    local files = fileManager:detectFiles(workingPath)
    if not files or #files == 0 then
        logger:info("No audio files found in " .. workingPath)
        return
    end

    -- Ensure workspace soundfolder exists with fallbacks
    local folder = workspace:FindFirstChild("soundfolder")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "soundfolder"
        folder.Parent = workspace
        logger:info("Created workspace soundfolder")
    end

    local successCount = 0
    local errorCount = 0
    
    for _, filePath in pairs(files) do
        local filename = filePath:match("([^/\\]+)$")
        
        -- Enhanced file validation
        if not fileManager:isValidAudioFile(filename) then
            logger:debug("Skipping non-audio file: " .. filename)
            continue
        end
        
        local success, error = pcall(function()
            -- Try multiple methods to get the sound ID
            local sid = nil
            local methods = {
                function() return _safeGetCustomAsset(workingPath .. "/" .. filename) end,
                function() return _safeGetCustomAsset(filename) end,
                function() 
                    -- Fallback: try to read file and convert to base64
                    local fileData = _safeReadFile(workingPath .. "/" .. filename)
                    if fileData then
                        return "data:audio/mp3;base64," .. fileData
                    end
                end
            }
            
            for i, method in ipairs(methods) do
                local methodSuccess, result = pcall(method)
                if methodSuccess and result and result ~= "" then
                    sid = result
                    logger:debug("Got sound ID using method " .. i .. " for " .. filename)
                    break
                end
            end
            
            if not sid then
                error("Could not get sound ID for " .. filename)
            end

            -- Check cache first
            local cached = fileManager:getCachedFile(filename)
            if cached then
                logger:debug("Using cached data for " .. filename)
                return cached
            end

            -- Reuse existing Sound with same SoundId if present
            local sound = nil
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
                logger:debug("Created new sound instance for " .. filename)
            end

            -- Enhanced validation with multiple checks
            local validationPassed = false
            local validationMethods = {
                function()
                    -- Method 1: Silent playback test
                    local previousVolume = sound.Volume
                    sound.Volume = 0
                    sound:Play()
                    task.wait(0.1)
                    local isPlaying = sound.IsPlaying
                    sound:Stop()
                    sound.Volume = previousVolume
                    return isPlaying
                end,
                function()
                    -- Method 2: Check if sound is loaded
                    return sound.IsLoaded
                end,
                function()
                    -- Method 3: Check sound properties
                    return sound.SoundId ~= "" and sound.SoundId ~= "rbxasset://sounds/"
                end
            }
            
            for i, validationMethod in ipairs(validationMethods) do
                local validationSuccess, result = pcall(validationMethod)
                if validationSuccess and result then
                    validationPassed = true
                    logger:debug("Validation passed using method " .. i .. " for " .. filename)
                    break
                end
            end
            
            if not validationPassed then
                error("Sound validation failed for " .. filename)
            end

            -- Cache file metadata
            local metadata = {
                filename = filename,
                soundId = sid,
                sound = sound,
                filepath = filePath,
                preloadTime = os.time(),
                validationPassed = true
            }
            
            fileManager:cacheFile(filename, metadata)
            
            -- Mark as local asset
            if sound:GetAttribute("islocal") ~= true then
                sound:SetAttribute("islocal", true)
            end
            
            return metadata
        end)

        if success then
            successCount = successCount + 1
            logger:info("Successfully preloaded: " .. filename)
        else
            errorCount = errorCount + 1
            logger:error("Failed to preload " .. filename .. ": " .. tostring(error))
        end
    end
    
    logger:info("Preload complete: " .. successCount .. " successful, " .. errorCount .. " failed")
    
    -- Clean up cache
    fileManager:cleanCache()
end

-- ========================================
-- 🎵 DISPLAYOPTIFY -  MUSIC PLAYER
-- ========================================

-- Core GUI Variables (UNC optimized - consolidated)
local guiState = {
    gui = nil, mainWindow = nil, titleBar = nil, contentArea = nil, sidebar = nil, playerBar = nil,
    currentSound = nil, currentVolume = 0.5, isPlaying = false, isPaused = false, currentTime = 0, totalTime = 0,
    playPauseButton = nil, stopButton = nil, prevButton = nil, nextButton = nil, shuffleButton = nil, repeatButton = nil,
    volumeSlider = nil, volumeLabel = nil, progressBar = nil, timeLabel = nil, titleLabel = nil, artistLabel = nil,
    waveformDisplay = nil, equalizerDisplay = nil, visualizerDisplay = nil, albumArtDisplay = nil,
    libraryFrame = nil, searchBox = nil, filterButtons = nil, sortButtons = nil, libraryList = nil,
    libraryTabs = nil, allSongsTab = nil, playlistsTab = nil, favoritesTab = nil, recentTab = nil,
    songCountLabel = nil, totalDurationLabel = nil, libraryStats = nil,
    playlistFrame = nil, playlistList = nil, playlistControls = nil, playlistInfo = nil,
    currentPlaylist = {}, currentPlaylistIndex = 1, playlistRepeatMode = "none", playlistShuffled = false,
    originalPlaylistOrder = {}, playlists = {},
    webFrame = nil, webSearchBox = nil, webResults = nil, webDownloadButton = nil,
    webTabs = nil, searchTab = nil, trendingTab = nil, newReleasesTab = nil,
    settingsFrame = nil, themeSelector = nil, layoutSelector = nil, hotkeySettings = nil,
    visualSettings = nil, audioSettings = nil, advancedSettings = nil, customThemes = {},
    backgroundBlur = nil, particleEffects = nil, glowEffects = nil, animations = nil,
    dragData = nil, dragSource = nil, isDragging = false, dragPreview = nil,
    lyricsDisplay = nil, albumArt = nil, socialFeatures = nil, statistics = nil,
    autoPlay = nil, crossfade = nil, gaplessPlayback = nil, smartPlaylists = nil,
    loadingGui = nil, loadingFrame = nil, loadingTitle = nil, loadingProgress = nil, loadingStatus = nil,
    loadingProgressBar = nil, loadingStatusText = nil, loadingExecutorText = nil,
    loadingSteps = {}, currentStep = 0, totalSteps = 0
}

-- Initialize guiState with proper structure
guiState = {
    gui = nil, mainWindow = nil, titleBar = nil, contentArea = nil, sidebar = nil, playerBar = nil,
    currentSound = nil, currentVolume = 0.5, isPlaying = false, isPaused = false, currentTime = 0, totalTime = 0,
    playPauseButton = nil, stopButton = nil, prevButton = nil, nextButton = nil, shuffleButton = nil, repeatButton = nil,
    volumeSlider = nil, volumeLabel = nil, progressBar = nil, timeLabel = nil, titleLabel = nil, artistLabel = nil,
    waveformDisplay = nil, equalizerDisplay = nil, visualizerDisplay = nil, albumArtDisplay = nil,
    libraryFrame = nil, searchBox = nil, filterButtons = nil, sortButtons = nil, libraryList = nil,
    libraryTabs = nil, allSongsTab = nil, playlistsTab = nil, favoritesTab = nil, recentTab = nil,
    songCountLabel = nil, totalDurationLabel = nil, libraryStats = nil,
    playlistFrame = nil, playlistList = nil, playlistControls = nil, playlistInfo = nil,
    currentPlaylist = {}, currentPlaylistIndex = 1, playlistRepeatMode = "none", playlistShuffled = false,
    originalPlaylistOrder = {}, playlists = {},
    webFrame = nil, webSearchBox = nil, webResults = nil, webDownloadButton = nil,
    webTabs = nil, searchTab = nil, trendingTab = nil, newReleasesTab = nil,
    settingsFrame = nil, themeSelector = nil, layoutSelector = nil, hotkeySettings = nil,
    visualSettings = nil, audioSettings = nil, advancedSettings = nil, customThemes = {},
    backgroundBlur = nil, particleEffects = nil, glowEffects = nil, animations = nil,
    dragData = nil, dragSource = nil, isDragging = false, dragPreview = nil,
    lyricsDisplay = nil, albumArt = nil, socialFeatures = nil, statistics = nil,
    autoPlay = nil, crossfade = nil, gaplessPlayback = nil, smartPlaylists = nil,
    loadingGui = nil, loadingFrame = nil, loadingTitle = nil, loadingProgress = nil, loadingStatus = nil,
    loadingProgressBar = nil, loadingStatusText = nil, loadingExecutorText = nil,
    loadingSteps = {}, currentStep = 0, totalSteps = 0
}

-- Forward declarations for functions
local _refreshPlaylistList, _updateStatus, _playSound, _refreshFileList, _refreshPlaylistSoundList
local _setupModernEvents, _setupGlobalDragTracking, _createMainContent, _buildGUI, _setupGUIEvents
local _createEnhancedFileButton, _createFileButtonFromPath, _checkSystemStatus

-- Placeholder implementations for forward declarations
_refreshPlaylistList = function() end
_updateStatus = function(msg) print("Status: " .. tostring(msg)) end
_playSound = function(soundId) print("Playing: " .. tostring(soundId)) end
_refreshFileList = function() end
_refreshPlaylistSoundList = function() end
_setupModernEvents = function() end
_setupGlobalDragTracking = function() end
_createMainContent = function() end
_buildGUI = function() end
_setupGUIEvents = function() end
_createEnhancedFileButton = function() end
_createFileButtonFromPath = function() end
_checkSystemStatus = function() return true end

-- Global references for GUI elements
local mainFrame, gui, contentArea
-- Settings
local settingsFrame, tabBar, playerTabButton, settingsTabButton, webTabButton, playlistTabButton
-- Frame references
local soundFrame, controlFrame, fileFrame, webFrame, playlistFrame
-- UI element references
local volumeLabel, playlistSoundTitle, playlistRepeatButton
local toggleHotkeyButton, playHotkeyButton, pauseHotkeyButton
local themeNextButton, themeLabel
local _hotkeyConn
local toggleGuiKey = Enum.KeyCode.RightShift
local playKey = Enum.KeyCode.L
local pauseKey = Enum.KeyCode.K
local currentTheme = "Spotify"

-- Global variables for compatibility
local currentPlaylist = {}
local originalPlaylistOrder = {}
local currentPlaylistIndex = 1
local playlistRepeatMode = "none"
local playlistShuffled = false
local currentSound = nil
local currentVolume = 0.5
local isPlaying = false
local isPaused = false
local dragPreview = nil
local currentStep = 0
local totalSteps = 0
local guiState = {}
-- Enhanced Modern Theme System with Advanced Visual Effects
local themes = {
    ["Spotify"] = {
        primary = Color3.fromRGB(30, 215, 96), secondary = Color3.fromRGB(25, 20, 20), tertiary = Color3.fromRGB(40, 40, 40),
        surface = Color3.fromRGB(24, 24, 24), background = Color3.fromRGB(18, 18, 18), textPrimary = Color3.fromRGB(255, 255, 255),
        textSecondary = Color3.fromRGB(179, 179, 179), textTertiary = Color3.fromRGB(115, 115, 115), accent = Color3.fromRGB(30, 215, 96),
        accentHover = Color3.fromRGB(26, 185, 82), warning = Color3.fromRGB(255, 193, 7), error = Color3.fromRGB(220, 53, 69),
        success = Color3.fromRGB(40, 167, 69), border = Color3.fromRGB(40, 40, 40), shadow = Color3.fromRGB(0, 0, 0),
        glow = Color3.fromRGB(30, 215, 96), gradient1 = Color3.fromRGB(30, 215, 96), gradient2 = Color3.fromRGB(25, 20, 20),
        -- Enhanced visual properties
        borderRadius = 12, shadowBlur = 20, animationSpeed = 0.3, hoverScale = 1.05,
        glassEffect = true, particleEffects = true, smoothAnimations = true
    },
    ["Apple Music"] = {
        primary = Color3.fromRGB(250, 45, 108), secondary = Color3.fromRGB(20, 20, 20), tertiary = Color3.fromRGB(40, 40, 40),
        surface = Color3.fromRGB(24, 24, 24), background = Color3.fromRGB(18, 18, 18), textPrimary = Color3.fromRGB(255, 255, 255),
        textSecondary = Color3.fromRGB(179, 179, 179), textTertiary = Color3.fromRGB(115, 115, 115), accent = Color3.fromRGB(250, 45, 108),
        accentHover = Color3.fromRGB(220, 40, 95), warning = Color3.fromRGB(255, 193, 7), error = Color3.fromRGB(220, 53, 69),
        success = Color3.fromRGB(40, 167, 69), border = Color3.fromRGB(40, 40, 40), shadow = Color3.fromRGB(0, 0, 0),
        glow = Color3.fromRGB(250, 45, 108), gradient1 = Color3.fromRGB(250, 45, 108), gradient2 = Color3.fromRGB(20, 20, 20)
    },
    ["YouTube Music"] = {
        primary = Color3.fromRGB(255, 0, 0), secondary = Color3.fromRGB(15, 15, 15), tertiary = Color3.fromRGB(40, 40, 40),
        surface = Color3.fromRGB(24, 24, 24), background = Color3.fromRGB(15, 15, 15), textPrimary = Color3.fromRGB(255, 255, 255),
        textSecondary = Color3.fromRGB(170, 170, 170), textTertiary = Color3.fromRGB(115, 115, 115), accent = Color3.fromRGB(255, 0, 0),
        accentHover = Color3.fromRGB(220, 0, 0), warning = Color3.fromRGB(255, 193, 7), error = Color3.fromRGB(220, 53, 69),
        success = Color3.fromRGB(40, 167, 69), border = Color3.fromRGB(40, 40, 40), shadow = Color3.fromRGB(0, 0, 0),
        glow = Color3.fromRGB(255, 0, 0), gradient1 = Color3.fromRGB(255, 0, 0), gradient2 = Color3.fromRGB(15, 15, 15)
    },
    ["Glassmorphism"] = {
        primary = Color3.fromRGB(0, 150, 255), secondary = Color3.fromRGB(255, 255, 255), tertiary = Color3.fromRGB(255, 255, 255),
        surface = Color3.fromRGB(255, 255, 255), background = Color3.fromRGB(240, 248, 255), textPrimary = Color3.fromRGB(20, 20, 20),
        textSecondary = Color3.fromRGB(100, 100, 100), textTertiary = Color3.fromRGB(150, 150, 150), accent = Color3.fromRGB(0, 150, 255),
        accentHover = Color3.fromRGB(0, 130, 220), warning = Color3.fromRGB(255, 193, 7), error = Color3.fromRGB(220, 53, 69),
        success = Color3.fromRGB(40, 167, 69), border = Color3.fromRGB(200, 200, 200), shadow = Color3.fromRGB(0, 0, 0),
        glow = Color3.fromRGB(0, 150, 255), gradient1 = Color3.fromRGB(0, 150, 255), gradient2 = Color3.fromRGB(255, 255, 255)
    }
}

local function _applyTheme(name)
    currentTheme = themes[name] and name or currentTheme
    local t = themes[currentTheme]
    if not t then return end
    
    -- Apply theme colors to main elements
    if mainFrame then mainFrame.BackgroundColor3 = t.background end
    if soundFrame then soundFrame.BackgroundColor3 = t.surface end
    if controlFrame then controlFrame.BackgroundColor3 = t.surface end
    if fileFrame then fileFrame.BackgroundColor3 = t.surface end
    if webFrame then webFrame.BackgroundColor3 = t.surface end
    if playlistFrame then playlistFrame.BackgroundColor3 = t.surface end
    if settingsFrame then settingsFrame.BackgroundColor3 = t.surface end
    
    -- Apply text colors
    if volumeLabel then volumeLabel.TextColor3 = t.textPrimary end
    if themeLabel then themeLabel.TextColor3 = t.textPrimary end
    if playlistSoundTitle then playlistSoundTitle.TextColor3 = t.textPrimary end
    
    _updateStatus("Theme changed to: " .. currentTheme)
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

-- Enhanced Modern GUI Creation with Advanced Visual Effects
local function _createMainGUI()
    logger:info("Creating enhanced modern GUI")
    
    -- Create main ScreenGui with enhanced properties
    gui = Instance.new("ScreenGui")
    gui.Name = "DisPlayoptify"
    gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true
    
    -- Create main frame with modern design
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Parent = gui
    mainFrame.Size = UDim2.new(0, 900, 0, 650) -- Slightly larger for better content
    mainFrame.Position = UDim2.new(0.5, -450, 0.5, -325)
    mainFrame.BackgroundColor3 = themes[currentTheme].background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    
    -- Enhanced corner radius with theme support
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, themes[currentTheme].borderRadius or 12)
    corner.Parent = mainFrame
    
    -- Add drop shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Parent = mainFrame
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = themes[currentTheme].shadow
    shadow.ImageTransparency = 0.5
    shadow.ZIndex = mainFrame.ZIndex - 1
    
    -- Add glass effect if supported
    if themes[currentTheme].glassEffect then
        local glassEffect = Instance.new("Frame")
        glassEffect.Name = "GlassEffect"
        glassEffect.Parent = mainFrame
        glassEffect.Size = UDim2.new(1, 0, 1, 0)
        glassEffect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        glassEffect.BackgroundTransparency = 0.9
        glassEffect.BorderSizePixel = 0
        glassEffect.ZIndex = mainFrame.ZIndex + 1
        
        local glassCorner = Instance.new("UICorner")
        glassCorner.CornerRadius = UDim.new(0, themes[currentTheme].borderRadius or 12)
        glassCorner.Parent = glassEffect
    end
    
    -- Create title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Parent = mainFrame
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    titleBar.BorderSizePixel = 0
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Parent = titleBar
    titleText.Size = UDim2.new(1, -100, 1, 0)
    titleText.Position = UDim2.new(0, 20, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "🎵 DisPlayoptify v0.1"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Parent = titleBar
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -40, 0, 10)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "×"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 16
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- Create tab bar
    tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Parent = mainFrame
    tabBar.Size = UDim2.new(1, -20, 0, 40)
    tabBar.Position = UDim2.new(0, 10, 0, 60)
    tabBar.BackgroundTransparency = 1
    
    -- Create tab buttons
    playerTabButton = createButton(tabBar, "PlayerTab", UDim2.new(0, 100, 1, 0), UDim2.new(0, 0, 0, 0), "🎵 Player", Color3.fromRGB(255, 255, 255), Color3.fromRGB(70, 70, 70), 14, 6)
    webTabButton = createButton(tabBar, "WebTab", UDim2.new(0, 100, 1, 0), UDim2.new(0, 110, 0, 0), "🌐 Web", Color3.fromRGB(255, 255, 255), Color3.fromRGB(60, 60, 60), 14, 6)
    playlistTabButton = createButton(tabBar, "PlaylistTab", UDim2.new(0, 100, 1, 0), UDim2.new(0, 220, 0, 0), "📁 Playlist", Color3.fromRGB(255, 255, 255), Color3.fromRGB(60, 60, 60), 14, 6)
    settingsTabButton = createButton(tabBar, "SettingsTab", UDim2.new(0, 100, 1, 0), UDim2.new(0, 330, 0, 0), "⚙️ Settings", Color3.fromRGB(255, 255, 255), Color3.fromRGB(60, 60, 60), 14, 6)
    
    -- Create content area
    contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Parent = mainFrame
    contentArea.Size = UDim2.new(1, -20, 1, -110)
    contentArea.Position = UDim2.new(0, 10, 0, 110)
    contentArea.BackgroundTransparency = 1
    
    print("--- Main GUI created successfully!")
end

local function _createTitleBar(centerX, centerY, theme)
    titleBar = createDrawUI("Square", nil, Vector2.new(centerX - 400, centerY - 300), Vector2.new(800, 50), theme.surface)
    titleBar.ZIndex = 1002
    
    local title = createDrawUI("Text", "🎵 DisPlayoptify", Vector2.new(centerX - 380, centerY - 280), 18, theme.textPrimary)
    title.ZIndex = 1003
    
    local minimizeButton = createDrawUI("Square", nil, Vector2.new(centerX + 350, centerY - 280), Vector2.new(25, 25), theme.warning)
    minimizeButton.ZIndex = 1003
    
    local minimizeText = createDrawUI("Text", "−", Vector2.new(centerX + 360, centerY - 275), 16, Color3.fromRGB(255, 255, 255))
    minimizeText.ZIndex = 1004
    
    local closeButton = createDrawUI("Square", nil, Vector2.new(centerX + 380, centerY - 280), Vector2.new(25, 25), theme.error)
    closeButton.ZIndex = 1003
    
    local closeText = createDrawUI("Text", "×", Vector2.new(centerX + 390, centerY - 275), 16, Color3.fromRGB(255, 255, 255))
    closeText.ZIndex = 1004
    
    return {title, minimizeButton, minimizeText, closeButton, closeText}
end

local function _createContentArea(centerX, centerY, theme)
    local contentArea = createDrawUI("Square", nil, Vector2.new(centerX - 400, centerY - 250), Vector2.new(800, 500), theme.tertiary)
    contentArea.ZIndex = 1001
    
    sidebar = createDrawUI("Square", nil, Vector2.new(centerX - 400, centerY - 250), Vector2.new(200, 500), theme.surface)
    sidebar.ZIndex = 1002
    
    local mainContent = createDrawUI("Square", nil, Vector2.new(centerX - 180, centerY - 250), Vector2.new(580, 500), theme.tertiary)
    mainContent.ZIndex = 1002
    
    return {contentArea, sidebar, mainContent}
end

local function _createPlayerBar(centerX, centerY, theme)
    playerBar = createDrawUI("Square", nil, Vector2.new(centerX - 400, centerY + 250), Vector2.new(800, 100), theme.surface)
    playerBar.ZIndex = 1002
    
    local nowPlaying = createDrawUI("Square", nil, Vector2.new(centerX - 380, centerY + 270), Vector2.new(200, 60), theme.tertiary)
    nowPlaying.ZIndex = 1003
    
    albumArtDisplay = createDrawUI("Square", nil, Vector2.new(centerX - 380, centerY + 270), Vector2.new(60, 60), theme.tertiary)
    albumArtDisplay.ZIndex = 1004
    
    titleLabel = createDrawUI("Text", "No song selected", Vector2.new(centerX - 310, centerY + 280), 14, theme.textPrimary)
    titleLabel.ZIndex = 1004
    
    artistLabel = createDrawUI("Text", "Unknown Artist", Vector2.new(centerX - 310, centerY + 300), 12, theme.textSecondary)
    artistLabel.ZIndex = 1004
    
    return {nowPlaying, albumArtDisplay, titleLabel, artistLabel}
end

local function _createPlayerControls(centerX, centerY, theme)
    local controls = createDrawUI("Square", nil, Vector2.new(centerX - 150, centerY + 270), Vector2.new(300, 60), theme.tertiary)
    controls.ZIndex = 1003
    
    progressBar = createDrawUI("Square", nil, Vector2.new(centerX - 140, centerY + 280), Vector2.new(280, 4), theme.border)
    progressBar.ZIndex = 1004
    
    local progressFill = createDrawUI("Square", nil, Vector2.new(centerX - 140, centerY + 280), Vector2.new(0, 4), theme.accent)
    progressFill.ZIndex = 1005
    
    timeLabel = createDrawUI("Text", "0:00 / 0:00", Vector2.new(centerX - 140, centerY + 290), 12, theme.textSecondary)
    timeLabel.ZIndex = 1004
    
    prevButton = createDrawUI("Square", nil, Vector2.new(centerX - 50, centerY + 320), Vector2.new(40, 40), theme.tertiary)
    prevButton.ZIndex = 1004
    
    local prevText = createDrawUI("Text", "⏮", Vector2.new(centerX - 35, centerY + 335), 16, theme.textPrimary)
    prevText.ZIndex = 1005
    
    playPauseButton = createDrawUI("Square", nil, Vector2.new(centerX - 25, centerY + 315), Vector2.new(50, 50), theme.accent)
    playPauseButton.ZIndex = 1004
    
    local playText = createDrawUI("Text", "▶", Vector2.new(centerX - 10, centerY + 330), 20, Color3.fromRGB(255, 255, 255))
    playText.ZIndex = 1005
    
    nextButton = createDrawUI("Square", nil, Vector2.new(centerX + 10, centerY + 320), Vector2.new(40, 40), theme.tertiary)
    nextButton.ZIndex = 1004
    
    local nextText = createDrawUI("Text", "⏭", Vector2.new(centerX + 25, centerY + 335), 16, theme.textPrimary)
    nextText.ZIndex = 1005
    
    return {controls, progressBar, progressFill, timeLabel, prevButton, prevText, playPauseButton, playText, nextButton, nextText}
end

local function _createVolumeControls(centerX, centerY, theme)
    local volumeContainer = createDrawUI("Square", nil, Vector2.new(centerX + 200, centerY + 270), Vector2.new(150, 60), theme.tertiary)
    volumeContainer.ZIndex = 1003
    
    local volumeIcon = createDrawUI("Text", "🔊", Vector2.new(centerX + 210, centerY + 285), 16, theme.textSecondary)
    volumeIcon.ZIndex = 1004
    
    volumeSlider = createDrawUI("Square", nil, Vector2.new(centerX + 240, centerY + 288), Vector2.new(100, 4), theme.border)
    volumeSlider.ZIndex = 1004
    
    local volumeFill = createDrawUI("Square", nil, Vector2.new(centerX + 240, centerY + 288), Vector2.new(currentVolume * 100, 4), theme.accent)
    volumeFill.ZIndex = 1005
    
    volumeLabel = createDrawUI("Text", math.floor(currentVolume * 100) .. "%", Vector2.new(centerX + 320, centerY + 285), 12, theme.textSecondary)
    volumeLabel.ZIndex = 1004
    
    return {volumeContainer, volumeIcon, volumeSlider, volumeFill, volumeLabel}
end

local function _createNavigation(centerX, centerY, theme)
    local navItems = {"🏠 Home", "🎵 Library", "📁 Playlists", "❤️ Favorites", "🔍 Search", "⚙️ Settings"}
    local navButtons = {}
    local navTexts = {}
    
    for i, item in ipairs(navItems) do
        navButtons[i] = createDrawUI("Square", nil, Vector2.new(centerX - 390, centerY - 240 + (i-1) * 50), Vector2.new(180, 40), theme.tertiary)
        navButtons[i].ZIndex = 1003
        navTexts[i] = createDrawUI("Text", item, Vector2.new(centerX - 380, centerY - 230 + (i-1) * 50), 14, theme.textPrimary)
        navTexts[i].ZIndex = 1004
    end
    
    return {navButtons, navTexts}
end

local function _createWelcomeContent(centerX, centerY, theme)
    local welcomeText = createDrawUI("Text", "Welcome to DisPlayoptify!", Vector2.new(centerX - 160, centerY - 200), 24, theme.textPrimary)
    welcomeText.ZIndex = 1003
    
    local subtitleText = createDrawUI("Text", "The best Roblox music player under the sun!", Vector2.new(centerX - 160, centerY - 170), 16, theme.textSecondary)
    subtitleText.ZIndex = 1003
    
    local featuresText = createDrawUI("Text", "Features: • Modern UI • Playlist Management • Web Downloads • Drag & Drop", Vector2.new(centerX - 160, centerY - 140), 12, theme.textSecondary)
    featuresText.ZIndex = 1003
    
    return {welcomeText, subtitleText, featuresText}
end

-- _buildGUI function will be defined after all frame creation functions

-- Create main content area
local function _createMainContent()
    if not contentArea then return end
    
    -- Clear existing content
    for _, child in pairs(contentArea:GetChildren()) do
        if child.Name ~= "Sidebar" then
            child:Destroy()
        end
    end
    
    -- Create content frame
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "ContentFrame"
    contentFrame.Parent = contentArea
    contentFrame.Size = UDim2.new(1, -220, 1, 0)
    contentFrame.Position = UDim2.new(0, 220, 0, 0)
    contentFrame.BackgroundColor3 = themes[currentTheme].tertiary
    contentFrame.BorderSizePixel = 0
    
    addCorner(contentFrame, 12)
    
    -- Content header
    local contentHeader = Instance.new("Frame")
    contentHeader.Name = "ContentHeader"
    contentHeader.Parent = contentFrame
    contentHeader.Size = UDim2.new(1, -20, 0, 50)
    contentHeader.Position = UDim2.new(0, 10, 0, 10)
    contentHeader.BackgroundTransparency = 1
    
    local contentTitle = Instance.new("TextLabel")
    contentTitle.Name = "ContentTitle"
    contentTitle.Parent = contentHeader
    contentTitle.Size = UDim2.new(1, 0, 1, 0)
    contentTitle.BackgroundTransparency = 1
    contentTitle.Text = "🎵 Welcome to DisPlayoptify"
    contentTitle.TextColor3 = themes[currentTheme].textPrimary
    contentTitle.Font = Enum.Font.GothamBold
    contentTitle.TextSize = 20
    contentTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Content body
    local contentBody = Instance.new("ScrollingFrame")
    contentBody.Name = "ContentBody"
    contentBody.Parent = contentFrame
    contentBody.Size = UDim2.new(1, -20, 1, -70)
    contentBody.Position = UDim2.new(0, 10, 0, 70)
    contentBody.BackgroundTransparency = 1
    contentBody.ScrollBarThickness = 6
    contentBody.CanvasSize = UDim2.new(0, 0, 0, 500)
    
    -- Welcome message
    local welcomeMessage = Instance.new("TextLabel")
    welcomeMessage.Name = "WelcomeMessage"
    welcomeMessage.Parent = contentBody
    welcomeMessage.Size = UDim2.new(1, 0, 0, 100)
    welcomeMessage.Position = UDim2.new(0, 0, 0, 0)
    welcomeMessage.BackgroundTransparency = 1
    welcomeMessage.Text = "🎵 The Ultimate Roblox Music Player\n\n✨ Modern Interface\n🎧 High Quality Audio\n📱 Responsive Design\n🎨 Beautiful Themes\n⚡ Lightning Fast\n\nClick on Library to get started!"
    welcomeMessage.TextColor3 = themes[currentTheme].textSecondary
    welcomeMessage.Font = Enum.Font.Gotham
    welcomeMessage.TextSize = 16
    welcomeMessage.TextXAlignment = Enum.TextXAlignment.Center
    welcomeMessage.TextYAlignment = Enum.TextYAlignment.Center
    welcomeMessage.TextWrapped = true
end

-- Set up modern event handlers
local function _setupModernEvents()
    -- Play/Pause button
    if playPauseButton then
        playPauseButton.MouseButton1Click:Connect(function()
            if currentSound then
                if isPlaying then
                    currentSound:Pause()
                    isPlaying = false
                    isPaused = true
                    playPauseButton.Text = "▶"
                else
                    currentSound:Resume()
                    isPlaying = true
                    isPaused = false
                    playPauseButton.Text = "⏸"
                end
            end
        end)
    end
    
    -- Volume slider
    if volumeSlider then
        volumeSlider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mouse = game:GetService("Players").LocalPlayer:GetMouse()
                local sliderPos = (mouse.X - volumeSlider.AbsolutePosition.X) / volumeSlider.AbsoluteSize.X
                sliderPos = math.clamp(sliderPos, 0, 1)
                currentVolume = sliderPos
                
                -- Update volume fill
                local volumeFill = volumeSlider:FindFirstChild("VolumeFill")
                if volumeFill then
                    volumeFill.Size = UDim2.new(currentVolume, 0, 1, 0)
                end
                
                -- Update volume label
                if volumeLabel then
                    volumeLabel.Text = math.floor(currentVolume * 100) .. "%"
                end
                
                -- Apply volume to current sound
                if currentSound then
                    currentSound.Volume = currentVolume
                end
            end
        end)
    end
end

-- Frame creation functions
local function _createSoundFrame()
    -- Sound ID Input Section
    soundFrame = Instance.new("Frame")
    soundFrame.Name = "SoundFrame"
    soundFrame.Parent = contentArea
    soundFrame.Size = UDim2.new(1, 0, 0, 120)
    soundFrame.Position = UDim2.new(0, 0, 0, 0)
    soundFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    soundFrame.BorderSizePixel = 0
    soundFrame.Visible = true
    
    addCorner(soundFrame, 6)
    
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
    
    addCorner(soundIdBox, 4)
    
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
    
    addCorner(playButton, 4)
    
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
    
    addCorner(stopButton, 4)
end
    
local function _createControlFrame()
    -- Volume Control Section
    controlFrame = Instance.new("Frame")
    controlFrame.Name = "ControlFrame"
    controlFrame.Parent = contentArea
    controlFrame.Size = UDim2.new(1, 0, 0, 60)
    controlFrame.Position = UDim2.new(0, 0, 0, 130)
    controlFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    controlFrame.BorderSizePixel = 0
    controlFrame.Visible = true
    
    addCorner(controlFrame, 6)
    
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
    
    addCorner(volumeSlider, 10)
end
    
local function _createFileFrame()
    -- File Selection Section
    fileFrame = Instance.new("Frame")
    fileFrame.Name = "FileFrame"
    fileFrame.Parent = contentArea
    fileFrame.Size = UDim2.new(1, 0, 0, 200)
    fileFrame.Position = UDim2.new(0, 0, 0, 200)
    fileFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    fileFrame.BorderSizePixel = 0
    fileFrame.Visible = true
    
    addCorner(fileFrame, 6)
    
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
    
    addCorner(fileList, 4)
    
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
    
    addCorner(refreshButton, 4)
    
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
    
    addCorner(loadFileButton, 4)
end

local function _createWebFrame()
    -- Web Download Frame
    webFrame = Instance.new("Frame")
    webFrame.Name = "WebFrame"
    webFrame.Parent = contentArea
    webFrame.Size = UDim2.new(1, 0, 1, 0)
    webFrame.Position = UDim2.new(0, 0, 0, 0)
    webFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    webFrame.BorderSizePixel = 0
    webFrame.Visible = false
    
    addCorner(webFrame, 6)
    
    -- Web URL Input
    local webUrlLabel = Instance.new("TextLabel")
    webUrlLabel.Name = "WebUrlLabel"
    webUrlLabel.Parent = webFrame
    webUrlLabel.Size = UDim2.new(1, -20, 0, 25)
    webUrlLabel.Position = UDim2.new(0, 10, 0, 10)
    webUrlLabel.BackgroundTransparency = 1
    webUrlLabel.Text = "Download URL:"
    webUrlLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    webUrlLabel.TextXAlignment = Enum.TextXAlignment.Left
    webUrlLabel.Font = Enum.Font.Gotham
    webUrlLabel.TextSize = 16
    
    webUrlBox = Instance.new("TextBox")
    webUrlBox.Name = "WebUrlBox"
    webUrlBox.Parent = webFrame
    webUrlBox.Size = UDim2.new(1, -20, 0, 30)
    webUrlBox.Position = UDim2.new(0, 10, 0, 35)
    webUrlBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    webUrlBox.BorderSizePixel = 0
    webUrlBox.Text = ""
    webUrlBox.PlaceholderText = "Enter audio URL (e.g., https://example.com/audio.mp3)"
    webUrlBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    webUrlBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    webUrlBox.Font = Enum.Font.Gotham
    webUrlBox.TextSize = 14
    webUrlBox.TextXAlignment = Enum.TextXAlignment.Left
    
    addCorner(webUrlBox, 4)
    
    -- Download Button
    webDownloadButton = Instance.new("TextButton")
    webDownloadButton.Name = "WebDownloadButton"
    webDownloadButton.Parent = webFrame
    webDownloadButton.Size = UDim2.new(0, 120, 0, 30)
    webDownloadButton.Position = UDim2.new(0, 10, 0, 75)
    webDownloadButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
    webDownloadButton.BorderSizePixel = 0
    webDownloadButton.Text = "Download"
    webDownloadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    webDownloadButton.Font = Enum.Font.GothamBold
    webDownloadButton.TextSize = 14
    
    addCorner(webDownloadButton, 4)
    
    -- Search Section
    local webSearchLabel = Instance.new("TextLabel")
    webSearchLabel.Name = "WebSearchLabel"
    webSearchLabel.Parent = webFrame
    webSearchLabel.Size = UDim2.new(1, -20, 0, 25)
    webSearchLabel.Position = UDim2.new(0, 10, 0, 115)
    webSearchLabel.BackgroundTransparency = 1
    webSearchLabel.Text = "Search Audio:"
    webSearchLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    webSearchLabel.TextXAlignment = Enum.TextXAlignment.Left
    webSearchLabel.Font = Enum.Font.Gotham
    webSearchLabel.TextSize = 16
    
    webSearchBox = Instance.new("TextBox")
    webSearchBox.Name = "WebSearchBox"
    webSearchBox.Parent = webFrame
    webSearchBox.Size = UDim2.new(1, -140, 0, 30)
    webSearchBox.Position = UDim2.new(0, 10, 0, 140)
    webSearchBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    webSearchBox.BorderSizePixel = 0
    webSearchBox.Text = ""
    webSearchBox.PlaceholderText = "Search for audio..."
    webSearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    webSearchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    webSearchBox.Font = Enum.Font.Gotham
    webSearchBox.TextSize = 14
    webSearchBox.TextXAlignment = Enum.TextXAlignment.Left
    
    addCorner(webSearchBox, 4)
    
    webSearchButton = Instance.new("TextButton")
    webSearchButton.Name = "WebSearchButton"
    webSearchButton.Parent = webFrame
    webSearchButton.Size = UDim2.new(0, 100, 0, 30)
    webSearchButton.Position = UDim2.new(1, -110, 0, 140)
    webSearchButton.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
    webSearchButton.BorderSizePixel = 0
    webSearchButton.Text = "Search"
    webSearchButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    webSearchButton.Font = Enum.Font.GothamBold
    webSearchButton.TextSize = 14
    
    addCorner(webSearchButton, 4)
end
    
local function _createPlaylistFrame()
    -- Playlist Frame
    playlistFrame = Instance.new("Frame")
    playlistFrame.Name = "PlaylistFrame"
    playlistFrame.Parent = contentArea
    playlistFrame.Size = UDim2.new(1, 0, 1, 0)
    playlistFrame.Position = UDim2.new(0, 0, 0, 0)
    playlistFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    playlistFrame.BorderSizePixel = 0
    playlistFrame.Visible = false
    
    addCorner(playlistFrame, 6)
    
    -- Playlist Controls
    local playlistControls = Instance.new("Frame")
    playlistControls.Name = "PlaylistControls"
    playlistControls.Parent = playlistFrame
    playlistControls.Size = UDim2.new(1, -20, 0, 30)
    playlistControls.Position = UDim2.new(0, 10, 0, 10)
    playlistControls.BackgroundTransparency = 1
    
    playlistAddButton = Instance.new("TextButton")
    playlistAddButton.Name = "PlaylistAddButton"
    playlistAddButton.Parent = playlistControls
    playlistAddButton.Size = UDim2.new(0, 60, 0, 25)
    playlistAddButton.Position = UDim2.new(0, 0, 0, 0)
    playlistAddButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    playlistAddButton.BorderSizePixel = 0
    playlistAddButton.Text = "Add"
    playlistAddButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playlistAddButton.Font = Enum.Font.GothamBold
    playlistAddButton.TextSize = 12
    
    addCorner(playlistAddButton, 4)
    
    playlistRemoveButton = Instance.new("TextButton")
    playlistRemoveButton.Name = "PlaylistRemoveButton"
    playlistRemoveButton.Parent = playlistControls
    playlistRemoveButton.Size = UDim2.new(0, 60, 0, 25)
    playlistRemoveButton.Position = UDim2.new(0, 70, 0, 0)
    playlistRemoveButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    playlistRemoveButton.BorderSizePixel = 0
    playlistRemoveButton.Text = "Remove"
    playlistRemoveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playlistRemoveButton.Font = Enum.Font.GothamBold
    playlistRemoveButton.TextSize = 12
    
    addCorner(playlistRemoveButton, 4)
    
    playlistShuffleButton = Instance.new("TextButton")
    playlistShuffleButton.Name = "PlaylistShuffleButton"
    playlistShuffleButton.Parent = playlistControls
    playlistShuffleButton.Size = UDim2.new(0, 60, 0, 25)
    playlistShuffleButton.Position = UDim2.new(0, 140, 0, 0)
    playlistShuffleButton.BackgroundColor3 = Color3.fromRGB(150, 100, 200)
    playlistShuffleButton.BorderSizePixel = 0
    playlistShuffleButton.Text = "Shuffle"
    playlistShuffleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playlistShuffleButton.Font = Enum.Font.GothamBold
    playlistShuffleButton.TextSize = 12
    
    addCorner(playlistShuffleButton, 4)
    
    playlistRepeatButton = Instance.new("TextButton")
    playlistRepeatButton.Name = "PlaylistRepeatButton"
    playlistRepeatButton.Parent = playlistControls
    playlistRepeatButton.Size = UDim2.new(0, 60, 0, 25)
    playlistRepeatButton.Position = UDim2.new(0, 210, 0, 0)
    playlistRepeatButton.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
    playlistRepeatButton.BorderSizePixel = 0
    playlistRepeatButton.Text = "Repeat: None"
    playlistRepeatButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playlistRepeatButton.Font = Enum.Font.GothamBold
    playlistRepeatButton.TextSize = 10
    
    addCorner(playlistRepeatButton, 4)
    
    playlistClearButton = Instance.new("TextButton")
    playlistClearButton.Name = "PlaylistClearButton"
    playlistClearButton.Parent = playlistControls
    playlistClearButton.Size = UDim2.new(0, 60, 0, 25)
    playlistClearButton.Position = UDim2.new(0, 280, 0, 0)
    playlistClearButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100)
    playlistClearButton.BorderSizePixel = 0
    playlistClearButton.Text = "Clear"
    playlistClearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playlistClearButton.Font = Enum.Font.GothamBold
    playlistClearButton.TextSize = 12
    
    addCorner(playlistClearButton, 4)
    
    -- Playlist List
    playlistList = Instance.new("ScrollingFrame")
    playlistList.Name = "PlaylistList"
    playlistList.Parent = playlistFrame
    playlistList.Size = UDim2.new(1, -20, 0, 120)
    playlistList.Position = UDim2.new(0, 10, 0, 50)
    playlistList.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    playlistList.BorderSizePixel = 0
    playlistList.ScrollBarThickness = 6
    playlistList.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    addCorner(playlistList, 4)
    
    -- Drag and Drop Hint
    local dragHint = Instance.new("TextLabel")
    dragHint.Name = "DragHint"
    dragHint.Parent = playlistList
    dragHint.Size = UDim2.new(1, -10, 0, 20)
    dragHint.Position = UDim2.new(0, 5, 0, 5)
    dragHint.BackgroundTransparency = 1
    dragHint.Text = "💡 Drag sounds from Player tab to add to playlist"
    dragHint.TextColor3 = Color3.fromRGB(150, 150, 150)
    dragHint.Font = Enum.Font.Gotham
    dragHint.TextSize = 10
    dragHint.TextXAlignment = Enum.TextXAlignment.Center
    dragHint.TextWrapped = true
    
    -- Available Sounds Section
    playlistSoundTitle = Instance.new("TextLabel")
    playlistSoundTitle.Name = "PlaylistSoundTitle"
    playlistSoundTitle.Parent = playlistFrame
    playlistSoundTitle.Size = UDim2.new(1, -20, 0, 20)
    playlistSoundTitle.Position = UDim2.new(0, 10, 0, 180)
    playlistSoundTitle.BackgroundTransparency = 1
    playlistSoundTitle.Text = "🎵 Available Sounds (Drag to Playlist)"
    playlistSoundTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    playlistSoundTitle.Font = Enum.Font.GothamBold
    playlistSoundTitle.TextSize = 12
    playlistSoundTitle.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Playlist Sound List
    playlistSoundList = Instance.new("ScrollingFrame")
    playlistSoundList.Name = "PlaylistSoundList"
    playlistSoundList.Parent = playlistFrame
    playlistSoundList.Size = UDim2.new(1, -20, 0, 100)
    playlistSoundList.Position = UDim2.new(0, 10, 0, 200)
    playlistSoundList.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    playlistSoundList.BorderSizePixel = 0
    playlistSoundList.ScrollBarThickness = 6
    playlistSoundList.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    addCorner(playlistSoundList, 4)
    
    -- Playlist Navigation
    local playlistNav = Instance.new("Frame")
    playlistNav.Name = "PlaylistNav"
    playlistNav.Parent = playlistFrame
    playlistNav.Size = UDim2.new(1, -20, 0, 30)
    playlistNav.Position = UDim2.new(0, 10, 0, 310)
    playlistNav.BackgroundTransparency = 1
    
    local prevButton = Instance.new("TextButton")
    prevButton.Name = "PrevButton"
    prevButton.Parent = playlistNav
    prevButton.Size = UDim2.new(0, 60, 0, 25)
    prevButton.Position = UDim2.new(0, 0, 0, 0)
    prevButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
    prevButton.BorderSizePixel = 0
    prevButton.Text = "◀ Prev"
    prevButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    prevButton.Font = Enum.Font.GothamBold
    prevButton.TextSize = 12
    
    addCorner(prevButton, 4)
    
    playlistPlayButton = Instance.new("TextButton")
    playlistPlayButton.Name = "PlaylistPlayButton"
    playlistPlayButton.Parent = playlistNav
    playlistPlayButton.Size = UDim2.new(0, 60, 0, 25)
    playlistPlayButton.Position = UDim2.new(0, 70, 0, 0)
    playlistPlayButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    playlistPlayButton.BorderSizePixel = 0
    playlistPlayButton.Text = "Play"
    playlistPlayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    playlistPlayButton.Font = Enum.Font.GothamBold
    playlistPlayButton.TextSize = 12
    
    addCorner(playlistPlayButton, 4)
    
    local nextButton = Instance.new("TextButton")
    nextButton.Name = "NextButton"
    nextButton.Parent = playlistNav
    nextButton.Size = UDim2.new(0, 60, 0, 25)
    nextButton.Position = UDim2.new(0, 140, 0, 0)
    nextButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
    nextButton.BorderSizePixel = 0
    nextButton.Text = "Next ▶"
    nextButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    nextButton.Font = Enum.Font.GothamBold
    nextButton.TextSize = 12
    
    addCorner(nextButton, 4)
end

local function _createSettingsFrame()
    -- Settings Frame (hidden by default)
    settingsFrame = Instance.new("Frame")
    settingsFrame.Name = "SettingsFrame"
    settingsFrame.Parent = contentArea
    settingsFrame.Size = UDim2.new(1, 0, 1, 0)
    settingsFrame.Position = UDim2.new(0, 0, 0, 0)
    settingsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.Visible = false

    addCorner(settingsFrame, 6)

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
    
    addCorner(toggleHotkeyButton, 4)
    addCorner(playHotkeyButton, 4)
    addCorner(pauseHotkeyButton, 4)
    addCorner(themeNextButton, 4)
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Parent = contentArea
    statusLabel.Size = UDim2.new(1, -20, 0, 30)
    statusLabel.Position = UDim2.new(0, 10, 1, -40)
    statusLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    statusLabel.BorderSizePixel = 0
    statusLabel.Text = "Ready"
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 14
    
    addCorner(statusLabel, 4)
end

-- _buildGUI function will be defined after _setupGUIEvents

-- GUI Functions
local function _updateStatus(message)
    local statusLabel = contentArea and contentArea:FindFirstChild("StatusLabel")
    if statusLabel then
        statusLabel.Text = message
    else
        print("Status: " .. message)
    end
end

local function _playSound(soundId)
    print("--- _playSound called with SoundId:", soundId)
    
    if currentSound and typeof(currentSound) == "Instance" and currentSound:IsA("Sound") then
        print("--- Stopping previous sound")
        currentSound:Stop()
        currentSound:Destroy()
    end
    
    if not soundId or soundId == "" then
        print("--- Error: Invalid SoundId provided")
        _updateStatus("Error: Invalid Sound ID")
        return
    end
    
    local folder = workspace:FindFirstChild("soundfolder")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "soundfolder"
        folder.Parent = workspace
        print("--- Created soundfolder in workspace")
    end
    
    currentSound = Instance.new("Sound")
    currentSound.SoundId = soundId
    currentSound.Volume = currentVolume
    currentSound.Parent = folder
    
    print("--- Created sound instance, attempting to play...")
    print("--- SoundId:", currentSound.SoundId)
    print("--- Volume:", currentSound.Volume)
    
    currentSound:Play()
    
    -- Check if sound is actually playing
    task.wait(0.1)
    print("--- Sound playing status:", currentSound.IsPlaying)
    print("--- Sound loaded status:", currentSound.IsLoaded)
    
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
    print("--- _loadLocalFile called with filename:", filename)
    
    local success, error = pcall(function()
        local filePath = "soundsfolder/" .. filename
        print("--- Looking for file at path:", filePath)
        
        local soundId = _safeGetCustomAsset(filePath)
        print("--- Retrieved SoundId:", soundId)

        if not soundId or soundId == "" then
            print("--- Error: Could not get custom asset for", filePath)
            _updateStatus("Error: Could not load " .. filename)
            return
        end

        -- Ensure sound folder exists
        local folder = workspace:FindFirstChild("soundfolder")
        if not folder then
            folder = Instance.new("Folder")
            folder.Name = "soundfolder"
            folder.Parent = workspace
            print("--- Created new soundfolder in workspace")
        end

        -- Check for existing Sound instance with the same SoundId
        local reused = false
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Sound") and child.SoundId == soundId then
                print("--- Reusing existing sound instance:", child.Name)
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
            print("--- Creating new sound instance with SoundId:", soundId)
            _playSound(soundId)
            _updateStatus("Loaded local file: " .. filename)
            if currentSound and typeof(currentSound) == "Instance" and currentSound:IsA("Sound") and currentSound:GetAttribute("islocal") ~= true then
                currentSound:SetAttribute("islocal", true)
            end
        end
    end)
    
    if not success then
        print("--- Error in _loadLocalFile:", error)
        _updateStatus("Error loading file: " .. filename .. " - " .. tostring(error))
    end
end

-- Enhanced File List Refresh with Advanced Error Recovery
local function _refreshFileList()
    logger:info("Refreshing file list with enhanced error recovery")
    
    -- Clear existing file list with error handling
    local clearSuccess, clearError = pcall(function()
        for _, child in pairs(fileList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end)
    
    if not clearSuccess then
        logger:error("Failed to clear file list: " .. tostring(clearError))
    end
    
    -- Enhanced folder detection with multiple fallbacks
    local folderPaths = {"soundsfolder", "sounds", "audio", "music"}
    local workingPath = nil
    
    for _, path in ipairs(folderPaths) do
        if _safeIsFolder(path) then
            workingPath = path
            logger:info("Using audio folder: " .. path)
            break
        end
    end
    
    if not workingPath then
        logger:warn("No audio folder found, creating soundsfolder")
        local success = _safeMakeFolder("soundsfolder")
        if success then
            workingPath = "soundsfolder"
            _updateStatus("Created soundsfolder")
        else
            _updateStatus("Failed to create soundsfolder")
            return
        end
    end
    
    -- Get files using enhanced file manager
    local files = fileManager:detectFiles(workingPath)
    if not files then
        logger:error("Failed to detect files in " .. workingPath)
        _updateStatus("Failed to detect files")
        return
    end
    
    -- Filter and validate audio files
    local audioFiles = {}
    for _, filePath in ipairs(files) do
        local filename = filePath:match("([^/\\]+)$")
        if fileManager:isValidAudioFile(filename) then
            table.insert(audioFiles, {path = filePath, name = filename})
        end
    end
    
    logger:info("Found " .. #audioFiles .. " valid audio files")
    
    -- Populate from workspace sounds first (for existing loaded sounds)
    local yOffset = 0
    local folder = workspace:FindFirstChild("soundfolder")
    local total = 0
    local processedFiles = {}
    
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("Sound") and child:GetAttribute("islocal") == true then
                total = total + 1
                local filename = child.Name
                processedFiles[filename] = true

                local fileButton = _createEnhancedFileButton(fileList, filename, yOffset, child)
                yOffset = yOffset + 30
            end
        end
    end
    
    -- Add remaining files from file system
    for _, fileData in ipairs(audioFiles) do
        if not processedFiles[fileData.name] then
            total = total + 1
            local fileButton = _createFileButtonFromPath(fileList, fileData, yOffset)
            yOffset = yOffset + 30
        end
    end

    -- Update canvas size with smooth animation
    local targetSize = UDim2.new(0, 0, 0, yOffset)
    if themes[currentTheme].smoothAnimations then
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = game:GetService("TweenService"):Create(fileList, tweenInfo, {CanvasSize = targetSize})
        tween:Play()
    else
        fileList.CanvasSize = targetSize
    end
    
    _updateStatus("Refreshed file list - " .. tostring(total) .. " local sounds")
    
    -- Also refresh playlist sound list
    _refreshPlaylistSoundList()
    
    logger:info("File list refresh complete: " .. total .. " files")
end

-- Enhanced file button creation for workspace sounds
local function _createEnhancedFileButton(parent, filename, yOffset, sound)
    local fileButton = Instance.new("TextButton")
    fileButton.Name = "FileButton_" .. filename
    fileButton.Parent = parent
    fileButton.Size = UDim2.new(1, -10, 0, 30) -- Slightly taller for better touch
    fileButton.Position = UDim2.new(0, 5, 0, yOffset)
    fileButton.BackgroundColor3 = themes[currentTheme].tertiary
    fileButton.BorderSizePixel = 0
    fileButton.Text = "🎵 " .. filename
    fileButton.TextColor3 = themes[currentTheme].textPrimary
    fileButton.Font = Enum.Font.Gotham
    fileButton.TextSize = 14
    fileButton.TextXAlignment = Enum.TextXAlignment.Left

    addCorner(fileButton, themes[currentTheme].borderRadius or 6)

    -- Enhanced hover effects with theme support
    fileButton.MouseEnter:Connect(function()
        if not isDragging then
            fileButton.BackgroundColor3 = themes[currentTheme].accentHover
            if themes[currentTheme].hoverScale then
                fileButton.Size = UDim2.new(1, -5, 0, 32)
            end
        end
    end)

    fileButton.MouseLeave:Connect(function()
        if not isDragging then
            fileButton.BackgroundColor3 = themes[currentTheme].tertiary
            if themes[currentTheme].hoverScale then
                fileButton.Size = UDim2.new(1, -10, 0, 30)
            end
        end
    end)

    -- Enhanced click handling with error recovery
    fileButton.MouseButton1Click:Connect(function()
        if not isDragging then
            local success, error = pcall(function()
                local sid = sound.SoundId
                logger:info("Playing local file: " .. filename .. " (SoundId: " .. tostring(sid) .. ")")
                
                if sid and sid ~= "" and sid ~= "rbxasset://sounds/" then
                    _playSound(sid)
                else
                    _loadLocalFile(filename)
                end
            end)
            
            if not success then
                logger:error("Failed to play " .. filename .. ": " .. tostring(error))
                _updateStatus("Error playing " .. filename)
            end
        end
    end)
    
    -- Enhanced drag and drop functionality
    fileButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local soundId = sound.SoundId or filename
            local trackData = {
                soundId = soundId,
                name = filename,
                source = "local",
                sound = sound
            }
            _startDrag(fileButton, trackData)
        end
    end)
    
    fileButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
            _endDrag()
        end
    end)

    return fileButton
end

-- Create file button from file system path
local function _createFileButtonFromPath(parent, fileData, yOffset)
    local fileButton = Instance.new("TextButton")
    fileButton.Name = "FileButton_" .. fileData.name
    fileButton.Parent = parent
    fileButton.Size = UDim2.new(1, -10, 0, 30)
    fileButton.Position = UDim2.new(0, 5, 0, yOffset)
    fileButton.BackgroundColor3 = themes[currentTheme].tertiary
    fileButton.BorderSizePixel = 0
    fileButton.Text = "📁 " .. fileData.name
    fileButton.TextColor3 = themes[currentTheme].textSecondary
    fileButton.Font = Enum.Font.Gotham
    fileButton.TextSize = 14
    fileButton.TextXAlignment = Enum.TextXAlignment.Left

    addCorner(fileButton, themes[currentTheme].borderRadius or 6)

    -- Hover effects
    fileButton.MouseEnter:Connect(function()
        if not isDragging then
            fileButton.BackgroundColor3 = themes[currentTheme].accentHover
        end
    end)

    fileButton.MouseLeave:Connect(function()
        if not isDragging then
            fileButton.BackgroundColor3 = themes[currentTheme].tertiary
        end
    end)

    -- Click to load and play
    fileButton.MouseButton1Click:Connect(function()
        if not isDragging then
            _loadLocalFile(fileData.name)
        end
    end)
    
    -- Drag and drop functionality
    fileButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local trackData = {
                soundId = fileData.name,
                name = fileData.name,
                source = "filesystem",
                filepath = fileData.path
            }
            _startDrag(fileButton, trackData)
        end
    end)
    
    fileButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
            _endDrag()
        end
    end)

    return fileButton
end

local function _refreshPlaylistSoundList()
    if not playlistSoundList then return end
    
    -- Clear existing sound list
    for _, child in pairs(playlistSoundList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    local yOffset = 0
    local total = 0
    
    -- Get sounds from the main file list
    if fileList then
        for _, child in pairs(fileList:GetChildren()) do
            if child:IsA("TextButton") and child.Text ~= "" then
                total = total + 1
                
                local soundButton = Instance.new("TextButton")
                soundButton.Name = "PlaylistSoundButton_" .. total
                soundButton.Parent = playlistSoundList
                soundButton.Size = UDim2.new(1, -10, 0, 25)
                soundButton.Position = UDim2.new(0, 5, 0, yOffset)
                soundButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                soundButton.BorderSizePixel = 0
                soundButton.Text = "🎵 " .. child.Text
                soundButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                soundButton.Font = Enum.Font.Gotham
                soundButton.TextSize = 10
                soundButton.TextXAlignment = Enum.TextXAlignment.Left
                soundButton.TextWrapped = true
                
                addCorner(soundButton, 4)
                
                -- Hover effects
                soundButton.MouseEnter:Connect(function()
                    if not isDragging then
                        soundButton.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
                    end
                end)
                
                soundButton.MouseLeave:Connect(function()
                    if not isDragging then
                        soundButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
                    end
                end)
                
                -- Click to play
                soundButton.MouseButton1Click:Connect(function()
                    if not isDragging then
                        local soundId = child.Text:match("rbxasset://[%w%-]+") or child.Text
                        if soundId and soundId ~= "" then
                            _playSound(soundId)
                        end
                    end
                end)
                
                -- Drag and drop functionality
                soundButton.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local soundId = child.Text:match("rbxasset://[%w%-]+") or child.Text
                        local trackData = {
                            soundId = soundId,
                            name = child.Text,
                            source = "local"
                        }
                        
                        _startDrag(soundButton, trackData)
                    end
                end)
                
                soundButton.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
                        _endDrag()
                    end
                end)
                
                yOffset = yOffset + 27
            end
        end
    end
    
    -- Update canvas size
    playlistSoundList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    
    -- Update title with count
    if playlistSoundTitle then
        playlistSoundTitle.Text = "🎵 Available Sounds (" .. total .. ") - Drag to Playlist"
    end
end

local function _refreshPlaylistList()
    -- Clear existing playlist list
    for _, child in pairs(playlistList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Show/hide drag hint based on playlist content
    local dragHint = playlistList:FindFirstChild("DragHint")
    if dragHint then
        dragHint.Visible = #currentPlaylist == 0
    end
    
    local yOffset = 0
    for i, track in ipairs(currentPlaylist) do
        local trackButton = Instance.new("TextButton")
        trackButton.Name = "TrackButton_" .. i
        trackButton.Parent = playlistList
        trackButton.Size = UDim2.new(1, -10, 0, 25)
        trackButton.Position = UDim2.new(0, 5, 0, yOffset)
        
        -- Highlight current track
        if i == currentPlaylistIndex then
            trackButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200)
        else
            trackButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
        
        trackButton.BorderSizePixel = 0
        trackButton.Text = i .. ". " .. track.name .. " (" .. track.source .. ")"
        trackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        trackButton.Font = Enum.Font.Gotham
        trackButton.TextSize = 12
        trackButton.TextXAlignment = Enum.TextXAlignment.Left
        
        addCorner(trackButton, 4)
        
        -- Hover effects
        trackButton.MouseEnter:Connect(function()
            if i ~= currentPlaylistIndex then
                trackButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            end
        end)
        
        trackButton.MouseLeave:Connect(function()
            if i ~= currentPlaylistIndex then
                trackButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            end
        end)
        
        -- Click to play track
        trackButton.MouseButton1Click:Connect(function()
            if not isDragging then
                currentPlaylistIndex = i
                _playSound(track.soundId)
                _updateStatus("Playing: " .. track.name .. " (" .. i .. "/" .. #currentPlaylist .. ")")
                _refreshPlaylistList() -- Update highlighting
            end
        end)
        
        yOffset = yOffset + 30
    end
    
    -- Update canvas size
    playlistList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    
    -- Set up drop target for playlist list
    if not playlistList:GetAttribute("DropTargetSetup") then
        playlistList:SetAttribute("DropTargetSetup", true)
        
        playlistList.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and isDragging then
                _handleDrop(playlistList)
            end
        end)
        
        -- Visual feedback for drop target
        playlistList.MouseEnter:Connect(function()
            if isDragging then
                playlistList.BackgroundColor3 = Color3.fromRGB(120, 180, 120)
            end
        end)
        
        playlistList.MouseLeave:Connect(function()
            if isDragging then
                playlistList.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            end
        end)
    end
end

-- Break down GUI events into smaller functions
local function _setupPlayerEvents()
    -- Play button
    if playButton then
    playButton.MouseButton1Click:Connect(function()
        local soundId = soundIdBox.Text
        if soundId and soundId ~= "" then
            _playSound(soundId)
        else
            _updateStatus("Please enter a Sound ID")
        end
    end)
    end
    
    -- Pause button
    if stopButton then
    stopButton.MouseButton1Click:Connect(function()
        if currentSound then
            currentSound:Pause()
            _updateStatus("Paused")
        end
    end)
    end
    
    -- Volume slider
    if volumeSlider then
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
                if volumeLabel then
            volumeLabel.Text = "Volume: " .. math.floor(percentage * 100) .. "%"
                end
            
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
    end
end
    
local function _setupFileEvents()
    -- Refresh button
    if refreshButton then
    refreshButton.MouseButton1Click:Connect(function()
        _preloadLocalFiles()
        _refreshFileList()
    end)
    end
    
    -- Load file button
    if loadFileButton then
    loadFileButton.MouseButton1Click:Connect(function()
        local firstFile = fileList:FindFirstChildOfClass("TextButton")
        if firstFile then
            firstFile.MouseButton1Click:Fire()
        else
            _updateStatus("No files available")
        end
    end)
    end
end

local function _setupTabEvents()
    -- Tab switching helper
    local function switchTab(activeTab)
        local tabs = {settingsFrame, webFrame, playlistFrame, soundFrame, controlFrame, fileFrame}
        for _, tab in ipairs(tabs) do
            if tab then tab.Visible = false end
        end
        
        local buttons = {playerTabButton, webTabButton, playlistTabButton, settingsTabButton}
        for _, btn in ipairs(buttons) do
            if btn then btn.BackgroundColor3 = Color3.fromRGB(60,60,60) end
        end
        
        if activeTab then
            activeTab.Visible = true
        end
    end
    
    -- Player tab
    if playerTabButton then
    playerTabButton.MouseButton1Click:Connect(function()
            switchTab()
            if soundFrame then soundFrame.Visible = true end
            if controlFrame then controlFrame.Visible = true end
            if fileFrame then fileFrame.Visible = true end
            if playerTabButton then playerTabButton.BackgroundColor3 = Color3.fromRGB(70,70,70) end
        end)
    end

    -- Web tab
    if webTabButton then
    webTabButton.MouseButton1Click:Connect(function()
            switchTab(webFrame)
            if webTabButton then webTabButton.BackgroundColor3 = Color3.fromRGB(70,70,70) end
        end)
    end

    -- Playlist tab
    if playlistTabButton then
    playlistTabButton.MouseButton1Click:Connect(function()
            switchTab(playlistFrame)
            if playlistTabButton then playlistTabButton.BackgroundColor3 = Color3.fromRGB(70,70,70) end
        end)
    end

    -- Settings tab
    if settingsTabButton then
    settingsTabButton.MouseButton1Click:Connect(function()
            switchTab(settingsFrame)
            if settingsTabButton then settingsTabButton.BackgroundColor3 = Color3.fromRGB(70,70,70) end
        end)
    end
end

local function _setupHotkeyEvents()
    -- Hotkey capture helper
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

    if toggleHotkeyButton then
    toggleHotkeyButton.MouseButton1Click:Connect(function()
        captureHotkey(toggleHotkeyButton, function(code)
            toggleGuiKey = code
            toggleHotkeyButton.Text = "Toggle GUI: " .. _keyCodeToText(toggleGuiKey)
        end)
    end)
    end

    if playHotkeyButton then
    playHotkeyButton.MouseButton1Click:Connect(function()
        captureHotkey(playHotkeyButton, function(code)
            playKey = code
            playHotkeyButton.Text = "Play: " .. _keyCodeToText(playKey)
        end)
    end)
    end

    if pauseHotkeyButton then
    pauseHotkeyButton.MouseButton1Click:Connect(function()
        captureHotkey(pauseHotkeyButton, function(code)
            pauseKey = code
            pauseHotkeyButton.Text = "Pause: " .. _keyCodeToText(pauseKey)
        end)
    end)
    end

    if themeNextButton then
    themeNextButton.MouseButton1Click:Connect(function()
            local order = {"Spotify", "Apple Music", "YouTube Music", "Glassmorphism"}
        local idx = 1
            for i, n in ipairs(order) do 
                if n == currentTheme then 
                    idx = i 
                    break 
                end 
            end
        local nextName = order[(idx % #order) + 1]
        currentTheme = nextName
            if themeLabel then themeLabel.Text = nextName end
        _applyTheme(nextName)
    end)
    end
end
    
local function _setupWebEvents()
    if webDownloadButton then
    webDownloadButton.MouseButton1Click:Connect(function()
        local url = webUrlBox.Text
        if url and url ~= "" then
            _downloadFromWeb(url)
        else
            _updateStatus("Please enter a URL")
        end
    end)
    end
    
    if webSearchButton then
    webSearchButton.MouseButton1Click:Connect(function()
        local query = webSearchBox.Text
        if query and query ~= "" then
            _searchWebAudio(query)
        else
            _updateStatus("Please enter a search query")
        end
    end)
    end
end
    
local function _setupPlaylistEvents()
    if playlistAddButton then
    playlistAddButton.MouseButton1Click:Connect(function()
        local soundId = soundIdBox.Text
        if soundId and soundId ~= "" then
            _addToPlaylist(soundId, "Custom Track", "custom")
        else
            _updateStatus("Please enter a Sound ID first")
        end
    end)
    end
    
    if playlistRemoveButton then
    playlistRemoveButton.MouseButton1Click:Connect(function()
        if currentPlaylistIndex > 0 and currentPlaylistIndex <= #currentPlaylist then
            _removeFromPlaylist(currentPlaylistIndex)
        else
            _updateStatus("No track selected to remove")
        end
    end)
    end
    
    if playlistShuffleButton then
    playlistShuffleButton.MouseButton1Click:Connect(function()
        _shufflePlaylist()
    end)
    end
    
    if playlistRepeatButton then
    playlistRepeatButton.MouseButton1Click:Connect(function()
        _toggleRepeatMode()
    end)
    end
    
    if playlistClearButton then
    playlistClearButton.MouseButton1Click:Connect(function()
        _clearPlaylist()
    end)
    end
    
    if playlistPlayButton then
    playlistPlayButton.MouseButton1Click:Connect(function()
        _playNextTrack()
    end)
    end
    
    -- Playlist Navigation Events
    if playlistFrame then
        local playlistNav = playlistFrame:FindFirstChild("PlaylistNav")
        if playlistNav then
            local prevButton = playlistNav:FindFirstChild("PrevButton")
            local nextButton = playlistNav:FindFirstChild("NextButton")
    
    if prevButton then
        prevButton.MouseButton1Click:Connect(function()
            _playPreviousTrack()
        end)
    end
    
    if nextButton then
        nextButton.MouseButton1Click:Connect(function()
            _playNextTrack()
        end)
            end
        end
    end
end

local function _setupGUIEvents()
    _setupPlayerEvents()
    _setupFileEvents()
    _setupTabEvents()
    _setupHotkeyEvents()
    _setupWebEvents()
    _setupPlaylistEvents()
    _setupGlobalDragTracking()
end

local function _setupGlobalDragTracking()
    -- Global mouse tracking for drag preview
    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        if isDragging and dragPreview then
            dragPreview.Position = UDim2.new(0, mouse.X - 100, 0, mouse.Y - 15)
        end
    end)
    
    print("--- Global drag tracking enabled")
end

local function _buildGUI()
    -- Create main GUI structure
    _createMainGUI()
    
    -- Create all the content frames
    _createSoundFrame()
    _createControlFrame()
    _createFileFrame()
    _createWebFrame()
    _createPlaylistFrame()
    _createSettingsFrame()
    
    print("--- GUI built successfully!")
end

local function _checkUI()
    _updateLoadingProgress(currentStep, "Checking UI system...")
    
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
        if type(item.ref) ~= "function" then
            allOk = false
        end
    end
    
    systemState._uiReady = allOk
    
    if allOk then
        _completeLoadingStep("UI System", true, "✓ UI system ready")
    else
        _completeLoadingStep("UI System", false, "✗ UI system failed")
    end
end

-- Break down initialization into smaller functions
local function _initLoadingSteps()
    -- Ensure guiState is initialized
    if not guiState then
        guiState = {}
    end
    guiState.loadingSteps = {}
    local steps = {
        "Executor Detection", "File Write", "File Read", "Custom Assets",
        "HTTP Requests", "Download System", "UI System", "Meow System", "Finalization"
    }
    for _, step in ipairs(steps) do
        _addLoadingStep(step)
    end
end

local function _runSystemChecks()
    local checks = {
        {func = checksave, name = "checksave"},
        {func = checkread, name = "checkread"},
        {func = checkcustomasset, name = "checkcustomasset"},
        {func = _checkHttpGet, name = "_checkHttpGet"},
        {func = checkdownload, name = "checkdownload"},
        {func = _checkUI, name = "_checkUI"},
        {func = checkmeow, name = "checkmeow"}
    }
    
    for _, check in ipairs(checks) do
        _safeExecute(check.func, check.name, function()
            _updateLoadingProgress(currentStep, check.name .. " failed, attempting recovery...")
            _attemptSelfHeal()
        end)
    end
end

local function _reportSystemStatus()
    local statuses = {"isasveon", "isreadon", "iscustomasseton", "_isHttpGeton", "isdownloadon", "_uiReady", "ismeowon"}
    local names = {"save", "read", "customasset", "HttpGet", "download", "UI", "meow"}
    for i, status in ipairs(statuses) do
        print("--- " .. names[i] .. ": " .. (systemState[status] and "ok" or "error"))
        end
    end
    
local function _loadInitialSounds()
    print("--- loading sounds")
    task.wait(1)
    _song("test", 'untitledtaggameOST-BloxiadebyO9o copy.wav')
    _listsoundfolder()
    _listlocalfiles()
    _preloadLocalFiles()
    print("------------loading complete----------------")
end

local function _intil() 
    -- Initialize guiState first
    if not guiState then
        guiState = {}
    end
    
    _initLoadingSteps()
    _createLoadingScreen()
    _updateLoadingProgress(0, "Detecting executor...")
    _detectExecutor()
    _completeLoadingStep("Executor Detection", true, "✓ Executor detected: " .. systemState._executorName)
    _runSystemChecks()
    _updateLoadingProgress(guiState.totalSteps, "Finalizing system...")
    _completeLoadingStep("Finalization", true, "✓ System initialization complete")
    _reportSystemStatus()
    _loadInitialSounds()
end

 _intil()

local _cansystemstart = false

-- if not systemState.ismeowon then
--     warn("MEOW IS GONE, THIS IS NOT GOOD, WE WILL KICK YOU FOR YOUR OWN SAFETY")
--     warn("WARNING: NOTHING IS WORKING, PLEASE HELP, *dies*")
--     task.wait(5)
--     warn("SYSTEM WARNING: CANNOT KICK PLAYER, DESTROYING GAME...")
    
--     local player = game:GetService("Players").LocalPlayer
--     local character = player.Character or player.CharacterAdded:Wait()
    
--     -- Optimized destruction loop
--     local services = {
--         workspace, game:GetService("ReplicatedStorage"), game:GetService("Lighting"),
--         game:GetService("StarterGui"), game:GetService("StarterPack"), game:GetService("SoundService")
--     }
    
--     -- Add player services if they exist
--     local playerGui = player:FindFirstChild("PlayerGui")
--     local playerScripts = player:FindFirstChild("PlayerScripts")
--     if playerGui then table.insert(services, playerGui) end
--     if playerScripts then table.insert(services, playerScripts) end

--     for _, container in ipairs(services) do
--         for _, inst in ipairs(container:GetDescendants()) do
--             if inst ~= character and not inst:IsA("Terrain") and not inst:IsA("Camera") and inst.Parent then
--                 warn("DESTROYING " .. inst.Name)
--                 pcall(function() inst:Destroy() end)
--                 task.wait(0.1)
--             end
--         end
--     end
    
--     warn("GAME DESTROYING DONE, KICKING PLAYER NOW")
--     task.wait(2)
--     player:Kick("bro, how did you even get here, your luck is beyond cooked 🥀")
-- end

-- Break down system status check into smaller functions
local function _checkCriticalSystems()
    local criticalFailed = {}
    local systems = {"isasveon", "isreadon", "isdownloadon", "_isHttpGeton", "_uiReady", "ismeowon"}
    for _, system in ipairs(systems) do
        if not systemState[system] then
            table.insert(criticalFailed, system)
        end
    end
    return criticalFailed
end

local function _checkOptionalSystems()
    local optionalFailed = {}
    if not systemState.iscustomasseton then
        table.insert(optionalFailed, "customasset")
    end
    return optionalFailed
end

-- Forward declaration to avoid nil reference
local _checkSystemStatus

local function _handleSystemFailure(criticalFailed)
        print("--- Critical systems failed: " .. table.concat(criticalFailed, ", "))
    print("--- Executor: " .. systemState._executorName)
        print("--- Attempting final self-healing...")
        
        if _attemptSelfHeal() then
            print("--- Self-healing successful, retrying system check...")
        return _checkSystemStatus()
        else
        print("--- Self-healing failed after " .. systemState._maxRecoveryAttempts .. " attempts")
            print("--- Script will continue in limited mode")
    _cansystemstart = false
            
            _safeExecute(function()
                _buildGUI()
                _setupGUIEvents()
                _refreshFileList()
                _refreshPlaylistList()
                _refreshPlaylistSoundList()
                _updateStatus("DisPlayoptify loaded in limited mode - some features unavailable")
            end, "minimal GUI creation")
            
            task.wait(1)
            _hideLoadingScreen()
            return false
        end
end

local function _handleSystemSuccess(optionalFailed)
        print("--- All critical systems operational!")
        if #optionalFailed > 0 then
            print("--- Optional systems unavailable: " .. table.concat(optionalFailed, ", "))
        end
        
    _cansystemstart = true 
        _safeExecute(function()
    _buildGUI()
    _setupGUIEvents()
    _refreshFileList()
            _refreshPlaylistList()
            _refreshPlaylistSoundList()
        _updateStatus("DisPlayoptify loaded successfully! Executor: " .. systemState._executorName)
        end, "full GUI creation")
        
    task.wait(1)
        _hideLoadingScreen()
        return true
end

-- Enhanced System Status Check with Self-Healing
local function _checkSystemStatus()
    local criticalFailed = _checkCriticalSystems()
    local optionalFailed = _checkOptionalSystems()
    
    if #criticalFailed > 0 then
        return _handleSystemFailure(criticalFailed)
    else
        return _handleSystemSuccess(optionalFailed)
    end
end

-- Enhanced Error Recovery and Status Display (UNC optimized)
local function _displaySystemStatus()
    print("==========================================")
    print("DisPlayoptify v0.1 - System Status Report")
    print("==========================================")
    print("Executor: " .. systemState._executorName)
    print("Self-Healing: " .. (systemState._selfHealingEnabled and "Enabled" or "Disabled"))
    print("Recovery Attempts: " .. systemState._recoveryAttempts .. "/" .. systemState._maxRecoveryAttempts)
    print("------------------------------------------")
    print("System Status:")
    print("  Save System: " .. (systemState.isasveon and "✓ OK" or "✗ FAILED"))
    print("  Read System: " .. (systemState.isreadon and "✓ OK" or "✗ FAILED"))
    print("  Custom Assets: " .. (systemState.iscustomasseton and "✓ OK" or "✗ FAILED"))
    print("  Download System: " .. (systemState.isdownloadon and "✓ OK" or "✗ FAILED"))
    print("  HttpGet System: " .. (systemState._isHttpGeton and "✓ OK" or "✗ FAILED"))
    print("  UI System: " .. (systemState._uiReady and "✓ OK" or "✗ FAILED"))
    print("  Meow System: " .. (systemState.ismeowon and "✓ OK" or "✗ FAILED"))
    print("------------------------------------------")
    print("Compatibility: " .. (systemState._executorDetected and "Detected" or "Unknown"))
    print("Script Status: " .. (_cansystemstart and "FULLY OPERATIONAL" or "LIMITED MODE"))
    print("==========================================")
end

-- Run system status check
_checkSystemStatus()

-- Display final status (only if loading screen is hidden)
if not guiState or not guiState.loadingGui then
    _displaySystemStatus()
end

-- Add periodic health check
task.spawn(function()
    while true do
        task.wait(30) -- Check every 30 seconds
        if not _cansystemstart then
            print("--- Periodic health check: Attempting recovery...")
            if _attemptSelfHeal() then
                print("--- Periodic recovery successful!")
                _displaySystemStatus()
            end
        end
    end
end)

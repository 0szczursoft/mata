print("Test branch loaded.")

local DATABASE = {}
-- Demo
if next(DATABASE) == nil then
    DATABASE["Demo"] = {}
    local function g(s) local t={}; for i=1,s do local r={}; for j=1,s do table.insert(r,{200,100,100}) end; table.insert(t,r) end; return t end
    table.insert(DATABASE["Demo"], { ["Low"]=g(20), ["Mid"]=g(40), ["High"]=g(80) })
end

-- Cfg
local toggleKey = 0xA1 -- Right Shift
local keyName = "RShift"
local overlayKey = 0x4B -- K
local overlayKeyName = "K"

local rebindingAction = nil 
local currentOpacity = 0.90
local windowWidthTarget = 350
local currentMode = "High"
local menuWidth = 170 
local version = "1.1u"

-- theme
local theme = {
    bg = Color3.fromRGB(25, 25, 30),
    header = Color3.fromRGB(35, 35, 40),
    outline = Color3.fromRGB(60, 60, 65),
    separator = Color3.fromRGB(100, 140, 200),
    
    text = Color3.fromRGB(225, 225, 230),
    text_dim = Color3.fromRGB(120, 120, 130),
    
    accent = Color3.fromRGB(100, 140, 200),
    resize = Color3.fromRGB(100, 140, 200),
    menu_bg = Color3.fromRGB(30, 30, 35),
    q_active = Color3.fromRGB(80, 160, 120),
    q_idle = Color3.fromRGB(50, 50, 55),
    
    ghost = Color3.fromRGB(100, 140, 200)
}

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

if not Drawing then return print("Executor does not support Drawing API") end

-- State management
if not _G.MatchaState then
    _G.MatchaState = {
        visible = true,
        overlay = false
    }
end

-- State
local ui = {}       -- main ui
local btns = {}     -- buttons
local isVisible = _G.MatchaState.visible
local isOverlayMode = _G.MatchaState.overlay
local activeMenu = nil 
local curCat = nil
local curData = nil
local draggingSlider = false 

-- Pool
local pool = {} 
local poolUsed = 0

-- Init
if DATABASE["Women"] and #DATABASE["Women"] > 0 then
    curData = DATABASE["Women"][1]
else
    local k, v = next(DATABASE)
    curData = v[1]
end

-- dimensions
local winW, winH, totalH = 0, 0, 0

-- helper
local function getPixels() return curData[currentMode] end

local function calcDims()
    local p = getPixels()
    local rawH = #p
    local rawW = 0
    if rawH > 0 then rawW = #p[1] end
    if rawW == 0 then rawW=50; rawH=50 end

    winW = windowWidthTarget
    winH = winW * (rawH / rawW)
    totalH = winH + 35
    return (winW / rawW)
end

-- UI
-- Main bg
local Window = Drawing.new("Square"); Window.Filled=true; Window.Color=theme.bg; Window.Visible=true; table.insert(ui, Window)
local WinOutline = Drawing.new("Square"); WinOutline.Thickness=1; WinOutline.Color=theme.outline; WinOutline.Filled=false; WinOutline.Visible=true; table.insert(ui, WinOutline)

-- header
local Header = Drawing.new("Square"); Header.Filled=true; Header.Color=theme.header; Header.Visible=true; table.insert(ui, Header)
local AccentLine = Drawing.new("Square"); AccentLine.Filled=true; AccentLine.Color=theme.separator; AccentLine.Visible=true; table.insert(ui, AccentLine)

-- title
local TitleText = Drawing.new("Text"); 
TitleText.Text="Matcha Viewer " .. version; 
TitleText.Size=16; 
TitleText.Color=theme.text; 
TitleText.Visible=true; 
TitleText.Font=2; 
TitleText.Outline=false; 
table.insert(ui, TitleText)

-- top Buttons
local BtnGallery = Drawing.new("Text"); BtnGallery.Text="[ GALLERY ]"; BtnGallery.Size=16; BtnGallery.Color=theme.accent; BtnGallery.Visible=true; BtnGallery.Font=3; BtnGallery.Outline=false; table.insert(ui, BtnGallery)
local BtnSettings = Drawing.new("Text"); BtnSettings.Text="[ SETTINGS ]"; BtnSettings.Size=16; BtnSettings.Color=theme.text_dim; BtnSettings.Visible=true; BtnSettings.Font=3; BtnSettings.Outline=false; table.insert(ui, BtnSettings)

-- indicators
local QualInd = Drawing.new("Text"); QualInd.Text=currentMode; QualInd.Size=16; QualInd.Color=theme.text_dim; QualInd.Transparency=0.6; QualInd.Visible=true; QualInd.Font=3; QualInd.Outline=false; table.insert(ui, QualInd)

local ResizeGrip = Drawing.new("Square"); ResizeGrip.Filled=true; ResizeGrip.Color=theme.resize; ResizeGrip.Size=Vector2.new(8,8); ResizeGrip.Visible=true; table.insert(ui, ResizeGrip)
local GhostFrame = Drawing.new("Square"); GhostFrame.Thickness=1; GhostFrame.Color=theme.ghost; GhostFrame.Filled=false; GhostFrame.Visible=false

-- Menu P
local PanelBg = Drawing.new("Square"); PanelBg.Filled=true; PanelBg.Color=theme.menu_bg; PanelBg.Visible=false; PanelBg.Transparency=0.95
local PanelOutline = Drawing.new("Square"); PanelOutline.Thickness=1; PanelOutline.Color=theme.outline; PanelOutline.Filled=false; PanelOutline.Visible=false

-- Hidden label
local HiddenLabel = Drawing.new("Text"); HiddenLabel.Text="Menu hidden ("..keyName..")"; HiddenLabel.Size=20; HiddenLabel.Color=Color3.fromRGB(255,255,255); HiddenLabel.Transparency=0.5; HiddenLabel.Visible=false; HiddenLabel.Center=true; HiddenLabel.Font=3; HiddenLabel.Outline=true

-- Men Cleanup
local function clearPanel()
    for _, b in pairs(btns) do b.obj:Remove() end
    btns = {}; PanelBg.Visible = false; PanelOutline.Visible = false
    draggingSlider = false
end

-- visibility
local function updateVisibility()
    if not isVisible then
        for _, v in pairs(ui) do v.Visible = false end
        for i = 1, poolUsed do pool[i].obj.Visible = false end
        clearPanel()
        HiddenLabel.Visible = true
        HiddenLabel.Text = "Hidden ("..keyName..")"
    elseif isOverlayMode then
        for _, v in pairs(ui) do v.Visible = false end
        clearPanel()
        ResizeGrip.Visible = false
        GhostFrame.Visible = false
        HiddenLabel.Visible = false
        for i = 1, poolUsed do pool[i].obj.Visible = true end
    else
        for _, v in pairs(ui) do v.Visible = true end
        for i = 1, poolUsed do pool[i].obj.Visible = true end
        HiddenLabel.Visible = false
    end
    _G.MatchaState.visible = isVisible
    _G.MatchaState.overlay = isOverlayMode
end

-- render
local function renderPixels()
    local pxData = getPixels()
    local pSize = calcDims() 

    -- layout update
    Window.Size = Vector2.new(winW, totalH)
    WinOutline.Size = Vector2.new(winW, totalH)
    
    Header.Size = Vector2.new(winW, 30)
    AccentLine.Size = Vector2.new(winW, 1)
    
    GhostFrame.Size = Vector2.new(winW, totalH)
    QualInd.Text = currentMode

    if pSize < 0.5 then return end

    local startP = Window.Position
    local startX, startY = startP.X, startP.Y
    
    local poolIndex = 1
    for y, row in ipairs(pxData) do
        local oy = 35 + (y-1)*pSize
        local drawY = startY + oy
        for x, col in ipairs(row) do
            if col[1] ~= -1 then
                local p = pool[poolIndex]
                if not p then
                    p = { obj = Drawing.new("Square"), ox = 0, oy = 0 }
                    p.obj.Filled = true; p.obj.ZIndex = 2
                    table.insert(pool, p)
                end
                
                p.obj.Color = Color3.fromRGB(col[1], col[2], col[3])
                p.obj.Size = Vector2.new(pSize, pSize)
                p.obj.Transparency = currentOpacity
                p.obj.Position = Vector2.new(startX + (x-1)*pSize, drawY)
                p.ox = (x-1)*pSize; p.oy = oy
                
                poolIndex = poolIndex + 1
            end
        end
    end
    
    poolUsed = poolIndex - 1
    for i = poolIndex, #pool do pool[i].obj.Visible = false end
    
    -- initial opacity
    Window.Transparency = currentOpacity
    Header.Transparency = currentOpacity * 0.8
    for _, v in pairs(ui) do if v.Transparency then v.Transparency = currentOpacity end end
    
    updateVisibility()
end

-- positioning
local function updatePositions(x, y)
    Window.Position = Vector2.new(x, y)
    WinOutline.Position = Vector2.new(x, y)
    
    Header.Position = Vector2.new(x, y)
    AccentLine.Position = Vector2.new(x, y + 30)
    
    TitleText.Position = Vector2.new(x + 10, y + 7) 
    
    BtnSettings.Position = Vector2.new(x + winW - 85, y + 5) 
    BtnGallery.Position = Vector2.new(x + winW - 160, y + 5) 
    
    QualInd.Position = Vector2.new(x + winW - 200, y + 5)
    
    ResizeGrip.Position = Vector2.new(x + winW - 10, y + totalH - 10)

    -- menu L
    local panelX, panelY = x + winW + 5, y
    if (panelX + menuWidth) > Camera.ViewportSize.X then panelX = x - menuWidth - 5 end

    PanelBg.Position = Vector2.new(panelX, panelY); PanelOutline.Position = Vector2.new(panelX, panelY)
    
    for _, item in ipairs(btns) do item.obj.Position = Vector2.new(panelX + item.relX, panelY + item.relY) end
    for i = 1, poolUsed do
        local p = pool[i]; p.obj.Position = Vector2.new(x + p.ox, y + p.oy)
    end
end

-- menu build
local function createMenuBtn(text, color, y, type, val, w)
    w = w or 130
    local btnText = Drawing.new("Text")
    btnText.Text = text; btnText.Size = 16; btnText.Color = color; btnText.Visible = isVisible; btnText.ZIndex = 22
    btnText.Font = 3; btnText.Outline = false 
    table.insert(btns, {obj=btnText, type=type, val=val, relX=10, relY=y})
    return y + 24
end

local function buildGallery()
    clearPanel(); PanelBg.Visible = isVisible; PanelOutline.Visible = isVisible
    local yOff = 10
    local head = Drawing.new("Text"); head.Text="GALLERY"; head.Size=17; head.Color=theme.text_dim; head.Visible=isVisible; head.ZIndex=22; head.Font=3; head.Outline=false
    table.insert(btns, {obj=head, type="deco", relX=10, relY=yOff}); yOff=yOff+30

    if curCat == nil then
        local keys={}; for k in pairs(DATABASE) do table.insert(keys,k) end
        table.sort(keys, function(a,b) 
            if a == "Women" then return true end; if b == "Women" then return false end
            if a == "Men" then return true end; return a < b 
        end)
        
        for _, k in ipairs(keys) do
            local cnt = #DATABASE[k]
            yOff = createMenuBtn("> " .. k .. " ["..cnt.."]", theme.accent, yOff, "cat", k)
            yOff = yOff + 4
        end
    else
        yOff = createMenuBtn("< BACK", Color3.fromRGB(200, 80, 80), yOff, "back", nil)
        yOff = yOff + 10
        local imgs = DATABASE[curCat]
        for i, _ in ipairs(imgs) do yOff = createMenuBtn("   Image " .. i, theme.text, yOff, "img", i) end
    end
    PanelBg.Size = Vector2.new(menuWidth, yOff+10); PanelOutline.Size = Vector2.new(menuWidth, yOff+10)
    
    for _, b in pairs(btns) do b.obj.Transparency = currentOpacity end
end

local function buildSettings()
    clearPanel(); PanelBg.Visible = isVisible; PanelOutline.Visible = isVisible
    local yOff = 10
    local head = Drawing.new("Text"); head.Text="SETTINGS"; head.Size=17; head.Color=theme.text_dim; head.Visible=isVisible; head.ZIndex=22; head.Font=3; head.Outline=false
    table.insert(btns, {obj=head, type="deco", relX=10, relY=yOff}); yOff=yOff+30

    local kLbl = Drawing.new("Text"); kLbl.Text="Toggle:"; kLbl.Size=16; kLbl.Color=theme.text; kLbl.Visible=isVisible; kLbl.ZIndex=22; kLbl.Font=3; kLbl.Outline=false
    table.insert(btns, {obj=kLbl, type="deco", relX=10, relY=yOff}); 
    local kVal = Drawing.new("Text"); kVal.Text="[" .. keyName .. "]"; kVal.Size=16; kVal.Color=theme.accent; kVal.Visible=isVisible; kVal.ZIndex=22; kVal.Font=3; kVal.Outline=false
    table.insert(btns, {obj=kVal, type="bind_menu", relX=90, relY=yOff}); yOff=yOff+24

    local oLbl = Drawing.new("Text"); oLbl.Text="Overlay:"; oLbl.Size=16; oLbl.Color=theme.text; oLbl.Visible=isVisible; oLbl.ZIndex=22; oLbl.Font=3; oLbl.Outline=false
    table.insert(btns, {obj=oLbl, type="deco", relX=10, relY=yOff}); 
    local oVal = Drawing.new("Text"); oVal.Text="[" .. overlayKeyName .. "]"; oVal.Size=16; oVal.Color=theme.accent; oVal.Visible=isVisible; oVal.ZIndex=22; oVal.Font=3; oVal.Outline=false
    table.insert(btns, {obj=oVal, type="bind_overlay", relX=90, relY=yOff}); yOff=yOff+34

    local qLbl = Drawing.new("Text"); qLbl.Text="Quality:"; qLbl.Size=16; qLbl.Color=theme.text; qLbl.Visible=isVisible; qLbl.ZIndex=22; qLbl.Font=3; qLbl.Outline=false
    table.insert(btns, {obj=qLbl, type="deco", relX=10, relY=yOff}); yOff=yOff+24

    local btnW, btnH, startX = 42, 24, 10
    local modes = {"Low", "Mid", "High"}
    for i, mode in ipairs(modes) do
        local isActive = (currentMode == mode)
        local bg = Drawing.new("Square"); bg.Size = Vector2.new(btnW, btnH); bg.Color = isActive and theme.q_active or theme.q_idle; bg.Filled = true; bg.Visible = isVisible; bg.ZIndex = 21
        table.insert(btns, {obj=bg, type="q_"..string.lower(mode), relX=startX, relY=yOff})
        
        local txt = Drawing.new("Text"); txt.Text = mode; txt.Size = 14; txt.Color = isActive and Color3.new(0,0,0) or Color3.new(1,1,1); txt.Visible = isVisible; txt.ZIndex = 22; txt.Font=3; txt.Outline=false; txt.Center=true
        table.insert(btns, {obj=txt, type="deco", relX=startX+(btnW/2), relY=yOff+7}) 
        
        startX = startX + btnW + 5
    end
    yOff = yOff + 36

    local opLbl = Drawing.new("Text"); opLbl.Text="Opacity: " .. math.floor(currentOpacity*100) .. "%"; opLbl.Size=16; opLbl.Color=theme.text; opLbl.Visible=isVisible; opLbl.ZIndex=22; opLbl.Font=3; opLbl.Outline=false
    table.insert(btns, {obj=opLbl, type="op_lbl", relX=10, relY=yOff}); yOff=yOff+24
    local barBg = Drawing.new("Square"); barBg.Size=Vector2.new(140, 8); barBg.Color=Color3.fromRGB(50,50,50); barBg.Filled=true; barBg.Visible=isVisible; barBg.ZIndex=21
    table.insert(btns, {obj=barBg, type="op_bar", relX=10, relY=yOff})
    local barFill = Drawing.new("Square"); barFill.Size=Vector2.new(140 * currentOpacity, 8); barFill.Color=theme.accent; barFill.Filled=true; barFill.Visible=isVisible; barFill.ZIndex=22
    table.insert(btns, {obj=barFill, type="op_fill", relX=10, relY=yOff})
    yOff = yOff + 20
    PanelBg.Size = Vector2.new(menuWidth, yOff+10); PanelOutline.Size = Vector2.new(menuWidth, yOff+10)
    
    for _, b in pairs(btns) do b.obj.Transparency = currentOpacity end
end

-- init
renderPixels()
local vp = Camera.ViewportSize
local windowPosX, windowPosY = (vp.X/2)-(winW/2), (vp.Y/2)-(totalH/2)
updatePositions(windowPosX, windowPosY)

local function pointInRect(px, py, rx, ry, rw, rh) return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh end

-- input
local dragging, resizing = false, false
local dragOffsetX, dragOffsetY, resizeStartX, initialWinW = 0, 0, 0, 0
local mouse1Down, f3Down, overlayDown = false, false, false
local keyMap = { [0x4B]="K", [0x4C]="L", [0x50]="P", [0x58]="X", [0x4D]="M", [0xA1]="RShift" }

spawn(function()
    local tickCheck = 0
    while true do
        local mx, my = Mouse.X, Mouse.Y
        
        -- state watch
        tickCheck = tickCheck + 1
        if tickCheck > 50 then
            tickCheck = 0
            if isVisible and not isOverlayMode then
                if Window.Visible == false then
                    updateVisibility()
                end
            end
        end
        
        if not isVisible then
            HiddenLabel.Visible = true; HiddenLabel.Position = Vector2.new(Camera.ViewportSize.X-250, Camera.ViewportSize.Y-50)
            HiddenLabel.Text = "Menu hidden ("..keyName..")"
        else HiddenLabel.Visible = false end

        if not rebindingAction then
            local k = iskeypressed(toggleKey)
            if k and not f3Down then
                isVisible = not isVisible
                updateVisibility()
            end
            f3Down = k

            local o = iskeypressed(overlayKey)
            if o and not overlayDown then
                if isVisible then
                    isOverlayMode = not isOverlayMode
                    updateVisibility()
                end
            end
            overlayDown = o

        else
            for k = 8, 255 do
                if iskeypressed(k) and k ~= 0 then
                    local nm = keyMap[k] or string.char(k)
                    if rebindingAction == "menu" then
                        toggleKey = k; keyName = nm
                    elseif rebindingAction == "overlay" then
                        overlayKey = k; overlayKeyName = nm
                    end
                    rebindingAction = nil
                    buildSettings(); updatePositions(windowPosX, windowPosY); wait(0.2); break
                end
            end
        end

        if isVisible and not isOverlayMode then
            local m1Now = ismouse1pressed()

            if m1Now and not mouse1Down then
                local clickedUI = false
                
                if activeMenu then
                    for _, b in ipairs(btns) do
                        if b.type ~= "deco" then
                            local w, h = 100, 15
                            if b.type:sub(1,2) == "q_" then w = 42; h = 24 end
                            
                            if b.type == "op_bar" or b.type == "op_fill" then 
                                w = 140 
                                if pointInRect(mx, my, b.obj.Position.X, b.obj.Position.Y, w, h) then
                                    draggingSlider = true
                                    clickedUI = true
                                end
                            end
    
                            if pointInRect(mx, my, b.obj.Position.X, b.obj.Position.Y, w, h) then
                                clickedUI = true
                                if b.type == "cat" then curCat=b.val; buildGallery(); updatePositions(windowPosX, windowPosY)
                                elseif b.type == "back" then curCat=nil; buildGallery(); updatePositions(windowPosX, windowPosY)
                                elseif b.type == "img" then 
                                    curData=DATABASE[curCat][b.val]; renderPixels(); updatePositions(windowPosX, windowPosY)
                                elseif b.type == "bind_menu" then rebindingAction="menu"; b.obj.Text="[...]"; b.obj.Color=Color3.new(1,1,0)
                                elseif b.type == "bind_overlay" then rebindingAction="overlay"; b.obj.Text="[...]"; b.obj.Color=Color3.new(1,1,0)
                                elseif b.type == "q_low" then if currentMode~="Low" then currentMode="Low"; renderPixels(); buildSettings(); updatePositions(windowPosX, windowPosY) end
                                elseif b.type == "q_mid" then if currentMode~="Mid" then currentMode="Mid"; renderPixels(); buildSettings(); updatePositions(windowPosX, windowPosY) end
                                elseif b.type == "q_high" then if currentMode~="High" then currentMode="High"; renderPixels(); buildSettings(); updatePositions(windowPosX, windowPosY) end
                                end
                                
                                if not draggingSlider then
                                    repeat task.wait() until not ismouse1pressed()
                                end
                                break
                            end
                        end
                    end
                end

                if not clickedUI then
                    if pointInRect(mx, my, BtnGallery.Position.X, BtnGallery.Position.Y, 80, 20) then 
                        clickedUI = true; 
                        if activeMenu == "gallery" then activeMenu=nil; clearPanel() else activeMenu="gallery"; buildGallery(); updatePositions(windowPosX, windowPosY) end
                        repeat task.wait() until not ismouse1pressed()
                    
                    elseif pointInRect(mx, my, BtnSettings.Position.X, BtnSettings.Position.Y, 80, 20) then 
                        clickedUI = true; 
                        if activeMenu == "settings" then activeMenu=nil; clearPanel() else activeMenu="settings"; buildSettings(); updatePositions(windowPosX, windowPosY) end
                        repeat task.wait() until not ismouse1pressed()
                    end
                end

                if not clickedUI then
                    if pointInRect(mx, my, ResizeGrip.Position.X, ResizeGrip.Position.Y, 15, 15) then resizing=true; resizeStartX=mx; initialWinW=winW; GhostFrame.Position=Window.Position; GhostFrame.Size=Window.Size; GhostFrame.Visible=true
                    elseif pointInRect(mx, my, windowPosX, windowPosY, winW, totalH) then dragging=true; dragOffsetX=mx-windowPosX; dragOffsetY=my-windowPosY; GhostFrame.Position=Window.Position; GhostFrame.Size=Window.Size; GhostFrame.Visible=true
                    end
                end

            elseif m1Now then
                if draggingSlider then
                    local barBase = nil
                    for _, b in ipairs(btns) do if b.type == "op_bar" then barBase = b.obj break end end
                    
                    if barBase then
                        local pct = (mx - barBase.Position.X) / 140
                        if pct < 0.1 then pct = 0.1 end
                        if pct > 1 then pct = 1 end
                        
                        if math.abs(currentOpacity - pct) > 0.01 then
                            currentOpacity = pct

                            for _, b in ipairs(btns) do
                                if b.type == "op_fill" then b.obj.Size = Vector2.new(140 * pct, 8) end
                                if b.type == "op_lbl" then b.obj.Text = "Opacity: " .. math.floor(pct*100) .. "%" end
                                b.obj.Transparency = pct 
                            end
                            Window.Transparency = pct
                            Header.Transparency = pct * 0.8
                            for _, v in pairs(ui) do if v.Transparency then v.Transparency = pct end end


                            for i = 1, poolUsed do
                                if pool[i].obj.Visible then
                                    pool[i].obj.Transparency = pct
                                end
                            end
                        end
                    end
                end

            elseif not m1Now then
                if dragging then dragging=false; GhostFrame.Visible=false; windowPosX, windowPosY=mx-dragOffsetX, my-dragOffsetY; updatePositions(windowPosX, windowPosY)
                elseif resizing then
                    resizing=false; GhostFrame.Visible=false; renderPixels(); updatePositions(windowPosX, windowPosY)
                    if activeMenu then if activeMenu=="gallery" then buildGallery() else buildSettings() end end; updatePositions(windowPosX, windowPosY)
                elseif draggingSlider then
                    draggingSlider = false
                end
            end

            if dragging then GhostFrame.Position = Vector2.new(mx-dragOffsetX, my-dragOffsetY)
            elseif resizing then
                local dX = mx - resizeStartX; local newW = initialWinW + dX; if newW < 250 then newW = 250 end
                windowWidthTarget = newW; local rH = winH/winW
                GhostFrame.Size = Vector2.new(newW, (newW * rH) + 30)
            end
            
            mouse1Down = m1Now
        end
        wait(0.01)
    end
end)

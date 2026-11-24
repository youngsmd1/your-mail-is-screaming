-- StarterPlayerScripts > Mailroom. These effects follow confirmed server state.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local depot = workspace:WaitForChild("NightPost")
local counter = depot:WaitForChild("DispatchCounter")
local mailbox = depot:WaitForChild("RedMailbox")
local scenery = depot:WaitForChild("StreetScenery")
local works = depot:WaitForChild("NightShift")

local function soundAt(part, file, speed, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/" .. file
	sound.PlaybackSpeed = speed
	sound.Volume = volume
	sound.RollOffMaxDistance = 42
	sound.Parent = part
	sound:Play()
	Debris:AddItem(sound, 3)
end

local function slip(part, words)
	local paper = Instance.new("Part")
	paper.Name = "PostalReceipt"
	paper.Anchored = true
	paper.CanCollide = false
	paper.CanTouch = false
	paper.CanQuery = false
	paper.Size = Vector3.new(2.7, 1.45, 0.06)
	paper.Color = Color3.fromRGB(255, 230, 166)
	local origin = part.CFrame * CFrame.new(0, 0.55, part.Size.Z/2+0.2)
	paper.CFrame = origin
	paper.Parent = works

	local face = Instance.new("SurfaceGui")
	face.Face = Enum.NormalId.Back
	face.LightInfluence = 0
	face.Parent = paper
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(50,47,52)
	label.TextScaled = true
	label.Font = Enum.Font.Code
	label.Text = words
	label.Parent = face

	local feed = TweenService:Create(paper, TweenInfo.new(.38,Enum.EasingStyle.Back), {
		CFrame = origin*CFrame.new(0,2.3,.5)*CFrame.Angles(0,0,.1)
	})
	feed:Play()
	task.delay(1.1,function()
		if not paper.Parent then return end
		TweenService:Create(paper,TweenInfo.new(.65),{
			CFrame = origin*CFrame.new(1,.5,1.7)*CFrame.Angles(.3,0,-.4), Transparency=1
		}):Play()
		TweenService:Create(label,TweenInfo.new(.65),{TextTransparency=1}):Play()
	end)
	Debris:AddItem(paper,2)
end

local function watch(player)
	player:GetAttributeChangedSignal("DeliveryStatus"):Connect(function()
		local status = player:GetAttribute("DeliveryStatus")
		if status == "Carrying" then
			soundAt(counter,"action_jump_land.mp3",1.65,.28)
		elseif status == "Paid" then
			local final = depot:GetAttribute("Job")=="LastLetter"
			local desk = final and works:FindFirstChild("ReturnedMail") or mailbox
			if desk then
				soundAt(desk,"volume_slider.ogg",1.6,.4)
				slip(desk,final and "ROUTE CLOSED" or ("PAID\n"..tostring(player:GetAttribute("LastPay") or 0).." COINS"))
			end
		end
	end)
	player:GetAttributeChangedSignal("Sorted"):Connect(function()
		if not player:GetAttribute("Sorted") then return end
		local hall=works:FindFirstChild("SortingHall")
		local bin=hall and hall:FindFirstChild(player:GetAttribute("Address") or "")
		if bin then soundAt(bin,"action_jump_land.mp3",1.9,.5); slip(bin,"STAMPED") end
	end)
end
Players.PlayerAdded:Connect(watch)
for _,player in Players:GetPlayers() do watch(player) end

-- The dispatch parcels get a different consignment with each shift.
local consignments = {
	{"LIVE SOCKS","LEFT FEET"}, {"WARM ICE","KEEP FROZEN"}, {"SPARE YAWNS","DO NOT WAKE"},
	{"NIGHT MILK","MOTH FOOD"}, {"CANNED ECHO","DO NOT HUM"}, {"ONE TUESDAY","PAST DUE"},
}
local labels = {}
for _,box in scenery:GetChildren() do
	if box.Name=="CounterParcel" then
		local label=box:FindFirstChildWhichIsA("TextLabel",true)
		if label then table.insert(labels,{x=box.Position.X,label=label}) end
	end
end
table.sort(labels,function(a,b) return a.x<b.x end)
local index = 0
local function reloadCounter()
	if depot:GetAttribute("Phase")~="Ready" then return end
	index=index%#consignments+1
	for i,entry in labels do entry.label.Text=consignments[index][i] or "NIGHT POST" end
end
depot:GetAttributeChangedSignal("Phase"):Connect(reloadCounter)
reloadCounter()

-- Overhead parcel carriers and the concourse clock run locally for each visitor.
task.spawn(function()
	local station=workspace:WaitForChild("Midnight Terminal")
	local clock=station:WaitForChild("DepartureClock")
	local center=clock:WaitForChild("Case").CFrame
	local minute,hour=clock:WaitForChild("Minute"),clock:WaitForChild("HourHand")
	local carriers={}
	for i=1,3 do carriers[i]=station:WaitForChild("CablePost"..i) end
	while station.Parent do
		if Players.LocalPlayer:GetAttribute("Area")=="Lobby" then
			local t=workspace:GetServerTimeNow()
			local function hand(piece,angle,length,z)
				piece.CFrame=center*CFrame.new(0,0,z)*CFrame.Angles(0,0,-angle)*CFrame.new(0,length*.5,0)
			end
			hand(minute,t/3600*math.pi*2,3.6,.95)
			hand(hour,t/43200*math.pi*2,2.45,1.1)
			for i,car in carriers do
				car:PivotTo(CFrame.new(60*math.sin(t*.06+i*math.pi*2/3),36.8,421))
			end
			task.wait(.06)
		else task.wait(1) end
	end
end)

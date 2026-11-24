local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local Social=game:GetService("SocialService")
local Market=game:GetService("MarketplaceService")
local p=Players.LocalPlayer
local ev=RS:WaitForChild("TerminalEvent")
local catalog=require(RS:WaitForChild("TerminalCatalog"))
local studio=game:GetService("RunService"):IsStudio()
local gui=Instance.new("ScreenGui");gui.Name="PostalTerminal";gui.ResetOnSpawn=false;gui.DisplayOrder=6;gui.Parent=p:WaitForChild("PlayerGui")
local rgb=Color3.fromRGB
local navy,cream,gold,green=rgb(22,40,55),rgb(255,244,208),rgb(255,190,73),rgb(38,126,116)
local colors={Invite=rgb(93,207,191),Shop=rgb(255,150,85),Daily=rgb(255,203,78),Spin=rgb(117,189,248),Troll=rgb(185,144,240)}
local function round(obj,r)
	local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,r);c.Parent=obj
end
local function edge(obj,color,w)
	local s=Instance.new("UIStroke");s.Color=color;s.Thickness=w;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;s.Parent=obj
end
local function rect(parent,name,x,y,w,h,color,r)
	local f=Instance.new("Frame");f.Name=name;f.Position=UDim2.fromOffset(x,y);f.Size=UDim2.fromOffset(w,h)
	f.BorderSizePixel=0;f.BackgroundColor3=color;f.Parent=parent;if r then round(f,r) end;return f
end
local function words(parent,str,x,y,w,h,pt,color,bold)
	local l=Instance.new("TextLabel");l.BackgroundTransparency=1;l.Position=UDim2.fromOffset(x,y);l.Size=UDim2.fromOffset(w,h)
	l.Font=bold and Enum.Font.GothamBold or Enum.Font.GothamMedium;l.TextSize=pt;l.TextColor3=color or cream
	l.TextWrapped=true;l.Text=str;l.Parent=parent;return l
end
local function button(parent,name,caption,x,y,w,h,action,color)
	local b=Instance.new("TextButton");b.Name=name;b.Text=caption;b.Font=Enum.Font.GothamBold;b.TextSize=16;b.TextColor3=cream
	b.Position=UDim2.fromOffset(x,y);b.Size=UDim2.fromOffset(w,h);b.BackgroundColor3=color or green;b.BorderSizePixel=0
	round(b,10);b.Parent=parent;b.Activated:Connect(action);return b
end
local function icon(parent,key,accent)
	local f=rect(parent,"PostageMark",10,5,54,42,accent,10)
	local view=Instance.new("ViewportFrame")
	view.Name="Countertop miniature"
	view.Size=UDim2.fromScale(1,1)
	view.BackgroundTransparency=1
	view.Ambient=rgb(172,179,215)
	view.LightColor=rgb(255,240,194)
	view.LightDirection=Vector3.new(-.6,-1,-.8)
	view.Parent=f
	local camera=Instance.new("Camera")
	camera.FieldOfView=31
	camera.CFrame=CFrame.lookAt(Vector3.new(2.6,2.1,8),Vector3.zero)
	camera.Parent=view;view.CurrentCamera=camera
	local function piece(name,size,x,y,z,color,shape,angle)
		local part=Instance.new("Part")
		part.Name=name;part.Anchored=true;part.Size=size
		part.Color=color;part.Shape=shape or Enum.PartType.Block
		part.CFrame=CFrame.new(x,y,z)*CFrame.Angles(0,0,math.rad(angle or 0))
		part.Parent=view
		return part
	end
	local v=Vector3.new
	local ball=Enum.PartType.Ball
	if key=="Daily" then
		piece("Surprise parcel",v(2.15,1.6,1.65),0,-.32,0,rgb(183,66,188))
		piece("Golden lid",v(2.38,.45,1.9),0,.59,0,rgb(255,176,41))
		piece("Silk ribbon",v(.39,2.1,1.94),0,-.15,0,rgb(255,91,101))
		for _,side in {-1,1} do piece("Ribbon loop",v(1.15,.62,.68),side*.45,1,0,rgb(255,99,90),ball,side*24) end
	elseif key=="Invite" then
		piece("Courier badge",v(2.1,2.1,1.55),-.38,.08,0,gold,ball)
		for _,x in {-.8,-.15} do piece("Eye",v(.26,.44,.22),x,.23,.67,navy,ball) end
		piece("Hat brim",v(1.95,.22,1.3),-.38,.87,.2,rgb(74,100,211),nil,-9)
		piece("Invite plus",v(1.35,.40,.42),.86,-.55,.74,rgb(83,255,116))
		piece("Invite plus",v(.4,1.35,.42),.86,-.55,.74,rgb(83,255,116))
	elseif key=="Shop" then
		piece("Shop counter",v(2.3,1.4,1.35),0,-.45,0,rgb(233,99,75))
		for _,side in {-1,1} do piece("Pole",v(.17,1.6,.17),side, .6,0,navy) end
		for i=-2,2 do piece("Striped canopy",v(.5,.44,1.8),i*.49,1.1,0,i%2==0 and cream or rgb(255,75,94)) end
		piece("Counter lip",v(2.55,.24,1.65),0,.2,0,gold)
	elseif key=="Spin" then
		piece("Wheel",v(2.75,2.75,.5),0,0,0,navy,ball)
		for i=1,8 do
			local a=i*math.pi/4
			piece("Prize wedge",v(.64,.78,.28),math.sin(a)*.9,math.cos(a)*.9,.28,({gold,colors.Invite,colors.Troll,colors.Shop})[i%4+1],ball,-i*45)
		end
		piece("Axle",v(.67,.67,.45),0,0,.4,cream,ball)
		piece("Pointer",v(.36,.61,.4),0,1.2,.42,rgb(255,78,85),nil,14)
	else
		piece("Telegram imp",v(2.1,2.1,1.45),0,-.17,0,rgb(153,72,237),ball)
		for _,side in {-1,1} do
			piece("Little horn",v(.43,.9,.53),side*.84,.8,0,gold,nil,-side*23)
			piece("Socket",v(.59,.43,.29),side*.47,.09,.63,navy,ball,-side*19)
			piece("Eye glint",v(.22,.19,.16),side*.43,.12,.79,cream,ball)
		end
		piece("Fang",v(.2,.34,.18),.28,-.5,.67,cream,nil,-10)
	end
end
local rail=rect(gui,"LobbyActions",9,0,74,213,navy);rail.BackgroundTransparency=1;rail.AnchorPoint=Vector2.new(0,.5);rail.Position=UDim2.new(0,10,.5,0)
local railScale=Instance.new("UIScale");railScale.Parent=rail
local right=rail:Clone()
right.Name="LobbyActionsRight"
right.Size=UDim2.fromOffset(74,140)
right.AnchorPoint=Vector2.new(1,.5)
right.Position=UDim2.new(1,-10,.5,0)
right.Parent=gui
local rightScale=right:FindFirstChildOfClass("UIScale")
local modal=rect(gui,"DeskPanel",0,0,470,420,navy,16);modal.AnchorPoint=Vector2.new(.5,.5);modal.Position=UDim2.fromScale(.5,.5);edge(modal,gold,2)
local ms=Instance.new("UIScale");ms.Parent=modal
local content=rect(modal,"Contents",0,52,470,365,navy,15)
local title=words(modal,"",18,6,365,42,24,gold,true);title.TextXAlignment=Enum.TextXAlignment.Left
local active=nil
local function close() active=nil;modal.Visible=false end
local closeButton=button(modal,"Close","×",420,8,38,34,close)
local function clear()
	for _,v in content:GetChildren() do if not v:IsA("UICorner") then v:Destroy() end end
end
local toast=words(gui,"",0,0,420,42,16,cream,true);toast.BackgroundTransparency=.08;toast.BackgroundColor3=navy;round(toast,10)
toast.AnchorPoint=Vector2.new(.5,1);toast.Position=UDim2.new(.5,0,1,-16);toast.Visible=false
local serial=0
local function say(str)
	serial+=1;local id=serial;toast.Text=str;toast.Visible=true
	task.delay(3.5,function() if id==serial then toast.Visible=false end end)
end
local info={}
local function price(k)
	if studio then return "R$ "..catalog.products[k].price.." • free demo" end
	if catalog.products[k].id==0 then return "Coming soon" end
	return info[k] and ("R$ "..info[k]) or "Price unavailable"
end
local wheel,spinning,spinUntil=nil,false,0
local function buy(k)
	if studio or (catalog.products[k].id>0 and info[k]) then ev:FireServer("Buy",k) else say("This item is not available for sale yet.") end
end
local function action(name,str,x,y,w,h,fn) return button(content,name,str,x,y,w,h,fn) end
local function show(key)
	active=key;clear();modal.Visible=true;closeButton.Visible=key~="Tutorial"
	title.Text=({Daily="Seven-day mailbag",Spin="Postmark wheel",Shop="Station shop",Troll="Scare telegram",Tutorial="Your first departure"})[key] or key
	local day=math.floor(workspace:GetServerTimeNow()/86400)
	if key=="Tutorial" then
		words(content,"ROUTE HANDBOOK",25,4,418,28,15,gold,true)
		words(content,"A letter was returned without its address. Three rooms hold the witness statements.\n\nReader: open the ivory ledger. Both couriers will see the clue.\n\nKeyholder: match the clue to a brass seal. You swap roles in the next room. A wrong turn wakes the keeper and costs five seconds. Close all three rooms to deliver the letter.",28,33,414,247,17,cream,false)
		action("Ready",p:GetAttribute("TutorialReady") and "Waiting for your partner…" or "Read it • Ready to go",52,290,366,48,function() ev:FireServer("Ready") end)
	elseif key=="Daily" then
		local claimed=p:GetAttribute("ClaimDate")==day;local step=p:GetAttribute("ClaimStep") or 0
		local nextDay=step%7+1
		words(content,"Collect once per UTC day. Each collection advances the cycle.",20,3,430,51,17,cream,false)
		for i,coins in catalog.daily do
			local x=18+((i-1)%4)*110;local y=64+math.floor((i-1)/4)*82
			local f=rect(content,"Day"..i,x,y,102,72,i==(claimed and step or nextDay) and green or rgb(47,66,78),10)
			words(f,"DAY "..i,0,6,102,20,13,gold,true);words(f,"+"..coins,0,26,102,34,24,cream,true)
		end
		action("Claim",claimed and "Collected today" or "Collect day "..nextDay,45,275,380,46,function() ev:FireServer("Claim") end)
	elseif key=="Shop" then
		words(content,(p:GetAttribute("Coins") or 0).." post coins in your wallet",18,7,432,38,20,gold,true)
		for i,k in {"Small","Bundle"} do
			action(k,catalog.products[k].name.."   •   "..price(k),34,65+(i-1)*69,402,56,function() buy(k) end)
		end
		words(content,"Spend post coins on parcel wraps at the Classic Dispatch locker.",34,228,402,64,17,cream,false)
	elseif key=="Spin" then
		wheel=rect(content,"Wheel",155,0,160,160,rgb(49,79,95),80);edge(wheel,gold,4)
		for i,amount in catalog.wheel do
			local a=(i-1)*math.pi/4
			local s=rect(wheel,"Sector"..i,63+58*math.sin(a),63-58*math.cos(a),34,34,i%2==0 and green or rgb(131,68,83),17)
			words(s,tostring(amount),0,0,34,34,15,cream,true)
		end
		words(wheel,"POST",46,61,68,38,15,gold,true);words(content,"▼",212,-12,46,27,23,gold,true)
		words(content,"Coin odds: 5, 10 or 15 at 25% each • 30 or 50 at 12.5% each.",25,165,420,54,16,cream,false)
		local free=p:GetAttribute("SpinDate")~=day
		local ticket=p:GetAttribute("SpinTickets") or 0
		action("Turn",free and "Use daily free spin" or ("Use ticket  •  "..ticket.." available"),30,228,410,44,function()
			if time()>=spinUntil then ev:FireServer("Spin") end
		end)
		if studio or p:GetAttribute("PaidWheelAllowed") then action("Extra","One extra spin   •   "..price("Spin"),30,286,410,43,function() buy("Spin") end) end
	elseif key=="Troll" then
		local badge=rect(content,"Crest",195,12,76,56,navy,8);icon(badge,"Troll",colors.Troll)
		words(content,"Send a surprise visit from the night postman to everyone in this lobby.",34,78,402,80,21,cream,true)
		action("BuyHorn","Buy scare telegram  •  "..price("Horn"),36,182,398,48,function() buy("Horn") end)
		action("SendHorn","Send telegram   •   "..(p:GetAttribute("HornTickets") or 0).." available",36,244,398,48,function()
			if (p:GetAttribute("HornTickets") or 0)>0 then ev:FireServer("Scare") else say("Pick up a scare telegram first.") end
		end)
	end
end
local function invite()
	task.spawn(function()
		local ok,available=pcall(function() return Social:CanSendGameInviteAsync(p) end)
		if not ok or not available then say("Friend invites are unavailable in this session.");return end
		local sent=pcall(function() Social:PromptGameInvite(p) end)
		if not sent then say("The invite window could not open.") end
	end)
end
for i,key in {"Invite","Shop","Daily","Spin","Troll"} do
	local b=button(i<=3 and rail or right,key,"",0,((i-1)%3)*73,74,67,function() if key=="Invite" then invite() else show(key) end end,navy)
	edge(b,colors[key],2);icon(b,key,colors[key])
	local mark=b.PostageMark
	local tilt=({-6,5,-4,6,-5})[i]
	mark.Rotation=tilt
	local shine=Instance.new("UIGradient")
	shine.Color=ColorSequence.new(Color3.new(1,1,1),rgb(190,207,238))
	shine.Rotation=78;shine.Parent=mark
	for _,pt in {{3,4,6},{47,31,4}} do
		local glint=rect(mark,"Glint",pt[1],pt[2],pt[3],pt[3],cream,1)
		glint.Rotation=45
	end
	local function pop(over)
		Tween:Create(mark,TweenInfo.new(.19,Enum.EasingStyle.Back),{Rotation=over and -tilt or tilt,Position=UDim2.fromOffset(10,over and 1 or 5)}):Play()
	end
	b.MouseEnter:Connect(function() pop(true) end)
	b.MouseLeave:Connect(function() pop(false) end)
	b.SelectionGained:Connect(function() pop(true) end)
	b.SelectionLost:Connect(function() pop(false) end)
	words(b,key,0,46,74,18,13,cream,true)
end
local banner=rect(gui,"Waybill",0,0,450,84,navy,12);banner.AnchorPoint=Vector2.new(.5,0);banner.Position=UDim2.new(.5,0,0,6)
local gauge=rect(banner,"Dispatch clock",8,78,434,4,rgb(63,77,82),2)
local fill=rect(gauge,"Time remaining",0,0,434,4,green,2)
local bs=Instance.new("UIScale");bs.Parent=banner
local head=words(banner,"",8,2,434,30,18,gold,true)
local detail=words(banner,"",12,32,426,45,15,cream,false)
local commands=rect(gui,"Travel",0,0,286,44,navy,10);commands.AnchorPoint=Vector2.new(1,1);commands.Position=UDim2.new(1,-8,1,-62)
local leave=button(commands,"Return","Leave stand",146,4,136,36,function()
	ev:FireServer(p:GetAttribute("Area")=="Lobby" and "Unqueue" or "Return")
end)
local function refresh()
	local area=p:GetAttribute("Area");local stand=p:GetAttribute("Stand") or 0
	if area=="Tutorial" then show("Tutorial") elseif area~="Lobby" or active=="Tutorial" then close() elseif active and not spinning then show(active) end
	rail.Visible=area=="Lobby" and not modal.Visible
	right.Visible=rail.Visible
	banner.Visible=not modal.Visible and (area=="Lobby" or area=="Tour")
	commands.Visible=(area=="Lobby" and stand>0 and not modal.Visible) or area=="Classic" or area=="Tour" or area=="Tutorial"
	commands.BackgroundTransparency=1
	leave.Text=area=="Lobby" and "Leave stand" or "Return to lobby"
	if area=="Lobby" then
		head.Text=stand>0 and string.format("TRACK %02d   •   1 / 2",stand) or "MIDNIGHT PARCEL TERMINAL"
		detail.Text=stand>0 and "Waiting for a second signature. Your partner can join this stand." or "Choose a numbered stand. Two couriers investigate the dead-letter house."
	elseif area=="Tour" then detail.Text=p:GetAttribute("TourHint") or "" end
end
closeButton.Activated:Connect(function() task.defer(refresh) end)
for _,key in {"Area","Stand","TutorialReady","ClaimDate","ClaimStep","SpinTickets","HornTickets","Coins","PaidWheelAllowed","TourHint"} do p:GetAttributeChangedSignal(key):Connect(function() task.defer(refresh) end) end
p:GetAttributeChangedSignal("MessageAt"):Connect(function() say(p:GetAttribute("TerminalMessage") or "") end)
ev.OnClientEvent:Connect(function(kind,num)
	if kind=="Wheel" then
		spinUntil=time()+2.4
		local current=wheel
		if current and current.Parent then
			spinning=true
			Tween:Create(current,TweenInfo.new(2.2,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Rotation=1440-(num-1)*45}):Play()
		end
		task.delay(2.3,function() spinning=false;say("Postmark wheel • +"..catalog.wheel[num].." coins");refresh() end)
	elseif kind=="Scare" and p:GetAttribute("Area")=="Lobby" then
		local veil=rect(gui,"TelegramShadow",0,0,0,0,navy);veil.Size=UDim2.fromScale(1,1);veil.BackgroundTransparency=.17;veil.ZIndex=10
		local f=rect(veil,"SpecialDelivery",0,0,320,258,rgb(59,42,75),34);f.AnchorPoint=Vector2.new(.5,.5);f.Position=UDim2.fromScale(.5,.5)
		local face=rect(f,"Postman",67,38,186,154,rgb(117,134,120),51)
		rect(face,"Postal crown",-3,-21,191,47,navy,16);rect(face,"Peak",-14,12,213,17,rgb(31,25,39),9).Rotation=-5
		rect(face,"Postal insignia",80,-12,25,24,gold,5).Rotation=45
		for _,x in {26,111} do
			rect(face,"Socket",x,48,50,31,navy,15)
			rect(face,"Gleam",x+19,53,14,17,gold,7)
		end
		local grin=rect(face,"Grin",40,96,109,28,navy,12)
		for i=1,6 do rect(grin,"Perforation",i*14,4,7,12,cream,2) end
		words(f,"SPECIAL DELIVERY!",10,193,300,50,26,gold,true)
		local s=Instance.new("Sound");s.SoundId="rbxasset://sounds/ouch.ogg";s.Volume=.6;s.PlaybackSpeed=.8;s.Parent=f;s:Play()
		local zoom=Instance.new("UIScale");zoom.Scale=.35;zoom.Parent=f;Tween:Create(zoom,TweenInfo.new(.13),{Scale=1}):Play()
		task.delay(1.25,function() veil:Destroy() end)
	end
end)
for k,item in catalog.products do
	if not studio and item.id>0 then task.spawn(function()
		local ok,data=pcall(function() return Market:GetProductInfoAsync(item.id,Enum.InfoType.Product) end)
		if ok and data and data.IsForSale then info[k]=data.PriceInRobux;refresh() end
	end) end
end
close();refresh()
while gui.Parent do
	local cam=workspace.CurrentCamera
	if cam then local v=cam.ViewportSize
		ms.Scale=math.min(1,(v.X-20)/470,(v.Y-84)/420);railScale.Scale=math.clamp((v.Y-155)/250,.58,1);rightScale.Scale=railScale.Scale;bs.Scale=math.min(1,(v.X-24)/450)
		toast.Size=UDim2.fromOffset(math.min(420,v.X-16),42)
	end
	if p:GetAttribute("Area")=="Tour" then
		local sec=math.max(0,math.ceil((p:GetAttribute("TourEnds") or 0)-workspace:GetServerTimeNow()))
		local fraction=math.clamp(sec/(p:GetAttribute("LegDuration") or 90),0,1)
		fill.Size=UDim2.fromScale(fraction,1)
		fill.BackgroundColor3=sec<=15 and rgb(245,103,89) or sec<=30 and gold or colors.Invite
		head.TextColor3=fill.BackgroundColor3
		head.Text=string.format("%s  •  %d:%02d",p:GetAttribute("TourTitle") or "",math.floor(sec/60),sec%60)
	end
	gauge.Visible=p:GetAttribute("Area")=="Tour"
	if not gauge.Visible then head.TextColor3=gold end
	rail.Visible=p:GetAttribute("Area")=="Lobby" and not modal.Visible
	right.Visible=rail.Visible
	banner.Visible=not modal.Visible and (p:GetAttribute("Area")=="Lobby" or p:GetAttribute("Area")=="Tour")
	task.wait(.15)
end

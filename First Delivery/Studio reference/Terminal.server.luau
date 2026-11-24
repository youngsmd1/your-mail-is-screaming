local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Market=game:GetService("MarketplaceService")
local policy=game:GetService("PolicyService")
local studio=game:GetService("RunService"):IsStudio()
local W=require(script.Parent.PostalScenery)
local tour=require(script.Parent.ParcelTour)
local records=require(script.Parent.CourierRecords)
local catalog=require(RS.TerminalCatalog)
local spawn,stands,classic=W.lobby()
local event=Instance.new("RemoteEvent")
event.Name,event.Parent="TerminalEvent",RS
local throttle={}
local function message(p,txt)
	p:SetAttribute("TerminalMessage",txt);p:SetAttribute("MessageAt",workspace:GetServerTimeNow())
end
local function move(p,cf)
	local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart")
	if r then c:PivotTo(cf);r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero end
end
local lobbySlots={}
local function arrival(p)
	local slot=lobbySlots[p] or 0
	return spawn.CFrame*CFrame.new((slot%8-3.5)*3.4,4,(math.floor(slot/8)-2)*3.4)
end
local function home(p,msg)
	if not p.Parent then return end
	p:SetAttribute("Area","Lobby");p:SetAttribute("Stand",0);p:SetAttribute("TutorialReady",false)
	move(p,arrival(p))
	if msg and msg~="" then message(p,msg) end
end
local function draw(i)
	local s=stands[i]
	s.caption.Text=string.format("TRACK  %02d\n%s",i,s.running and "OUT ON DELIVERY" or (#s.queue.." / 2   •   BOARDING"))
	s.prompt.Enabled=not s.running
	local booth=spawn.Parent["Gatehouse "..i]
	for seat=1,2 do
		booth["Signal"..seat].Color=if s.running then Color3.fromRGB(180,71,58) elseif seat<=#s.queue then Color3.fromRGB(248,187,88) else Color3.fromRGB(109,217,178)
	end
	local stateColor=s.running and W.red or (#s.queue==1 and W.brass or W.teal)
	for _,piece in booth:GetChildren() do
		if piece.Name=="Threshold tube" then piece.Color=stateColor end
	end
	booth:SetAttribute("BoardingState",s.running and "Away" or (#s.queue==1 and "Calling" or "Open"))
	s.prompt.ActionText=#s.queue==1 and "Join or leave crew" or "Punch ticket"
	s.prompt.ObjectText=string.format("Track %02d  •  %s",i,#s.queue==1 and "One courier waiting" or "Two seats")
end
local function unqueue(p)
	for i,s in stands do
		local idx=table.find(s.queue,p)
		if idx then table.remove(s.queue,idx);draw(i) end
	end
	p:SetAttribute("Stand",0)
end
local function depart(i)
	local s=stands[i];if s.running or #s.queue~=2 then return end
	local crew=s.queue;s.queue={};s.running=true;draw(i)
	tour.start(i,crew,home,function() s.running=false;draw(i) end)
end
local function near(p,q)
	local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	return r and (r.Position-q.Parent.Position).Magnitude<=q.MaxActivationDistance+1
end
for i,s in stands do
	s.queue={};draw(i)
	s.prompt.Triggered:Connect(function(p)
		if p:GetAttribute("Area")~="Lobby" or not p:GetAttribute("RecordReady") or s.running or not near(p,s.prompt) then return end
		if table.find(s.queue,p) then unqueue(p);return end
		unqueue(p);message(p,"Ticket punched. A second courier starts the route, then both of you can open the house.");table.insert(s.queue,p);p:SetAttribute("Stand",i);draw(i)
		if #s.queue==2 then depart(i) end
	end)
end
classic.Triggered:Connect(function(p)
	if p:GetAttribute("Area")~="Lobby" or not p:GetAttribute("RecordReady") or not near(p,classic) then return end
	local slots={}
	for _,other in Players:GetPlayers() do if other:GetAttribute("Area")=="Classic" then slots[other:GetAttribute("ClassicLane") or 1]=true end end
	for i=1,4 do if not slots[i] then
		unqueue(p);p:SetAttribute("ClassicLane",i);p:SetAttribute("Area","Classic")
		move(p,workspace.NightPost.DispatchSpawn.CFrame*CFrame.new(i*2-5,4,0));return
	end end
	message(p,"Classic crew is full.")
end)
local function register(p)
	local used={}
	for _,slot in lobbySlots do used[slot]=true end
	local slot=0
	while used[slot] do slot+=1 end
	lobbySlots[p]=slot
	p.RespawnLocation=spawn
	p:SetAttribute("Area","Lobby");p:SetAttribute("Stand",0)
	local function appeared(c)
		if not c:WaitForChild("HumanoidRootPart",12) or c~=p.Character then return end
		local area=p:GetAttribute("Area")
		if area=="Tour" then tour.respawn(p)
		elseif area~="Classic" then move(p,arrival(p)) end
	end
	p.CharacterAdded:Connect(appeared)
	if p.Character then task.spawn(appeared,p.Character) end
	task.spawn(function()
		local ok,info=pcall(function() return policy:GetPolicyInfoForPlayerAsync(p) end)
		if p.Parent then p:SetAttribute("PaidWheelAllowed",ok and info.ArePaidRandomItemsRestricted==false) end
	end)
end
Players.PlayerAdded:Connect(register)
for _,p in Players:GetPlayers() do register(p) end
Players.PlayerRemoving:Connect(function(p) unqueue(p);tour.leave(p);throttle[p]=nil;lobbySlots[p]=nil end)
local function grant(key,t,data)
	local product=catalog.products[key]
	if product.coins then data.Coins+=product.coins
	elseif key=="Spin" then t.SpinTickets=(t.SpinTickets or 0)+1
	elseif key=="Horn" then t.HornTickets=(t.HornTickets or 0)+1 end
end
Market.ProcessReceipt=function(receipt)
	local p=Players:GetPlayerByUserId(receipt.PlayerId)
	if not p or not p:GetAttribute("RecordReady") then return Enum.ProductPurchaseDecision.NotProcessedYet end
	for key,v in catalog.products do
		if v.id>0 and v.id==receipt.ProductId then
			local ok=records.terminal(p,function(t,data)
				if not t.receipts[receipt.PurchaseId] then
					grant(key,t,data);t.receipts[receipt.PurchaseId]=true
				end
			end)
			if ok then return Enum.ProductPurchaseDecision.PurchaseGranted end
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
event.OnServerEvent:Connect(function(p,action,key)
	if time()<(throttle[p] or 0) or not p:GetAttribute("RecordReady") then return end
	throttle[p]=time()+.25
	local area=p:GetAttribute("Area")
	if action=="Return" then
		unqueue(p);tour.leave(p);home(p);return
	elseif action=="Ready" and area=="Tutorial" then tour.ready(p);return end
	if area~="Lobby" then return end
	local stand=p:GetAttribute("Stand") or 0
	if action=="Unqueue" then unqueue(p);return end
	local day=math.floor(os.time()/86400)
	if action=="Buy" then
		local item=catalog.products[key]
		if not item then return end
		if key=="Spin" and not studio and not p:GetAttribute("PaidWheelAllowed") then message(p,"Paid wheel tickets are unavailable.");return end
		if studio then
			local ok=records.terminal(p,function(t,data) grant(key,t,data) end)
			message(p,ok and ("Studio demo granted: "..item.name) or "Wallet busy. Try again.")
		elseif item.id>0 then
			local ok=pcall(function() Market:PromptProductPurchase(p,item.id) end)
			if not ok then message(p,"Purchase prompt unavailable.") end
		else message(p,"This product has not been connected yet.") end
		return
	end
	if action=="Claim" then
		if p:GetAttribute("ClaimDate")==day then message(p,"Already collected. Return after midnight UTC.");return end
		local ok,amount=records.terminal(p,function(t,data)
			if (t.ClaimDate or 0)>=day then return 0 end
			local step=(t.ClaimStep or 0)%7+1
			t.ClaimDate,t.ClaimStep=day,step
			data.Coins+=catalog.daily[step];return catalog.daily[step]
		end)
		message(p,ok and ("Daily collection: +"..amount.." coins") or "Wallet busy. Try again.")
	elseif action=="Spin" then
		local paid=p:GetAttribute("SpinDate")==day
		if paid and ((p:GetAttribute("SpinTickets") or 0)<1 or (not studio and not p:GetAttribute("PaidWheelAllowed"))) then message(p,"Your free spin returns at midnight UTC.");return end
		local sector=Random.new():NextInteger(1,#catalog.wheel)
		local ok,used=records.terminal(p,function(t,data)
			if (t.SpinDate or 0)<day then t.SpinDate=day
			elseif (t.SpinTickets or 0)>0 and (studio or p:GetAttribute("PaidWheelAllowed")) then t.SpinTickets-=1
			else return false end
			data.Coins+=catalog.wheel[sector];return true
		end)
		if ok and used then event:FireClient(p,"Wheel",sector) else message(p,"Spin unavailable. Try again.") end
	elseif action=="Scare" and (p:GetAttribute("HornTickets") or 0)>0 then
		local ok,used=records.terminal(p,function(t)
			if (t.HornTickets or 0)<1 then return false end
			t.HornTickets-=1;return true
		end)
		if ok and used then
			for _,other in Players:GetPlayers() do if other:GetAttribute("Area")=="Lobby" then event:FireClient(other,"Scare") end end
		else message(p,"Telegram pending. Try again.") end
	end
end)

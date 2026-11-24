-- ServerScriptService > Shift
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local depot=require(script.Parent.Depot)
local monster=require(script.Parent.Unclaimed)
local records=require(script.Parent.CourierRecords)
local d=workspace.NightPost
local pickup,delivery=d.DispatchCounter.Pickup,d.RedMailbox.Deliver
local boardEvent=Instance.new("RemoteEvent")
boardEvent.Name,boardEvent.Parent="DispatchBoard",game.ReplicatedStorage

local SHIFT_SECONDS,PARCEL_PAY,HELP_TIP=60,10,5
local MALL_SHIFTS,BRIDGE_SHIFTS,STAMP_SKIN=3,5,3
local addresses={"Moon","Moth","Match"}
local wrapColors={
	Airmail=Color3.fromRGB(114,186,192), Firefly=Color3.fromRGB(43,87,71),
	Midnight=Color3.fromRGB(43,37,85), Postmark=Color3.fromRGB(177,90,105), Kraft=Color3.fromRGB(217,162,100),
}
local states={}
local phase,job,deadline,started,restartAt="Ready","Rooftops",0,0,0
local tool,owner,deployedAt,awarded,issued="",nil,0,{},{}
local day=math.floor(os.time()/86400)
local function now() return workspace:GetServerTimeNow() end
local function phaseTo(name)
	phase=name
	d:SetAttribute("EndsAt",phase=="Running" and deadline or 0)
	d:SetAttribute("Phase",phase)
end
local function chooseJob(name)
	job=name
	day=math.floor(os.time()/86400)
	depot.selectJob(name,day)
	depot.shutter(true)
	monster.reset(name=="LastLetter")
end
local function note(p,message,duration)
	p:SetAttribute("Notice",message)
	p:SetAttribute("NoticeUntil",now()+(duration or 3))
end
local function rootOf(p)
	if p:GetAttribute("Area")~="Classic" then return nil end
	local c=p.Character
	local h=c and c:FindFirstChildOfClass("Humanoid")
	return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart") or nil
end
local function nearby(p,q)
	local r=rootOf(p)
	return r and (r.Position-q.Parent.Position).Magnitude<=q.MaxActivationDistance+1
end
local function live() return phase=="Running" and now()<deadline end
local function carrying(p,q)
	local s=states[p]
	return s and s.status=="Carrying" and live() and not s.flight and nearby(p,q)
end
local function carton(bag,root,name,size,offset,color,tilt)
	local box=Instance.new("Part")
	box.Name,box.Size,box.Color=name,size,color
	box.Massless,box.CanCollide,box.CanTouch,box.CanQuery=true,false,false,false
	box.CFrame=root.CFrame*CFrame.new(offset)*CFrame.Angles(0,0,tilt or 0)
	local weld=Instance.new("WeldConstraint")
	weld.Part0,weld.Part1,weld.Parent=root,box,box
	box.Parent=bag
	return box
end
local function render(p)
	local r=rootOf(p)
	if not r then return end
	local old=p.Character:FindFirstChild("MailSatchel")
	if old then old:Destroy() end
	local s=states[p]
	if s.carried==0 then return end
	local bag=Instance.new("Model")
	bag.Name="MailSatchel"
	local skin=p:GetAttribute("Skin")
	local pizza=skin=="Pizza"
	local h=pizza and .37 or .82
	local skinColor=wrapColors[skin] or wrapColors.Kraft
	for i=1,s.carried do
		local y=-.52+(i-1)*(h+.08)
		local size=pizza and Vector3.new(2.2,h,1.62) or Vector3.new(1.85,h,1.15)
		local box=carton(bag,r,"Parcel"..i,size,Vector3.new(0,y,1.1),skinColor)
		local tape=pizza and Color3.fromRGB(188,53,51) or Color3.fromRGB(238,217,158)
		carton(bag,r,"Tape",Vector3.new(.35,h+.03,size.Z+.03),Vector3.new(.15,y,1.1),tape)
		if job=="Misprint" and s.address then
			depot.sign(box,string.upper(s.address))
		elseif skin=="Postmark" then depot.sign(box,p:GetAttribute("LatestPrint") or "NIGHT POST")
		elseif pizza then depot.sign(box,"PIZZA") end
		if skin=="Firefly" or skin=="Midnight" then
			local color=skin=="Firefly" and Color3.fromRGB(254,214,96) or Color3.fromRGB(180,173,255)
			for _,x in {-.6,.6} do
				local seal=carton(bag,r,"FoilSeal",Vector3.new(.23,.23,.035),Vector3.new(x,y,1.12+size.Z/2),color,math.rad(45))
				seal.Material=Enum.Material.Neon
			end
		end
		if skin=="Airmail" then
			for stripe=-1,1 do
				carton(bag,r,"PostalStripe",Vector3.new(.17,.66,.05),Vector3.new(stripe*.48,y,1.1+size.Z/2),Color3.fromRGB(185,67,68),math.rad(-24))
			end
		end
	end
	bag.Parent=p.Character
end
local function load(p,status,n)
	local s=states[p]
	if not s then return end
	s.status,s.carried=status,n
	p:SetAttribute("DeliveryStatus",status)
	p:SetAttribute("Carried",n)
	render(p)
end
local function cancelFlight(s)
	if s.flight then
		if s.flight.root.Parent then s.flight.root.Anchored=false end
		s.flight=nil
	end
end
local function relocate(p,receiving)
	local s=states[p]
	cancelFlight(s)
	local r=rootOf(p)
	if not r then return end
	local offset=((s.lane-1)%4-1.5)*3
	local cf=receiving and CFrame.new(offset,28,-25) or d.DispatchSpawn.CFrame*CFrame.new(offset,3.5,0)
	p.Character:PivotTo(cf)
	r.AssemblyLinearVelocity,r.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
	s.safe=receiving
end
local function endShift()
	restartAt=now()+5
	phaseTo("Break")
	for p,s in states do
		cancelFlight(s)
		if s.status~="Paid" and s.status~="Lost" then load(p,"Expired",0) end
	end
end
local function checkFinish()
	if phase~="Running" then return end
	for player,s in states do
		if player:GetAttribute("Area")~="Classic" then continue end
		if s.status=="Carrying" then return end
		if s.status=="Waiting" and now()-started<10 then return end
	end
	endShift()
end
local function reset()
	tool,owner,awarded,issued="",nil,{},{}
	depot.clearShortcut()
	d:SetAttribute("Shortcut","")
	d:SetAttribute("ShortcutOwner",0)
	chooseJob("Rooftops")
	for p,s in states do
		s.helped,s.bridgeCross,s.caught,s.usedShortcut=false,false,false,false
		s.address=nil
		p:SetAttribute("Address",nil)
		p:SetAttribute("Sorted",false)
		p:SetAttribute("NoticeUntil",0)
		p:SetAttribute("Tips",0)
		load(p,"Waiting",0)
		relocate(p,false)
	end
	phaseTo("Ready")
end
local function launch(p)
	local s,r=states[p],rootOf(p)
	local finish=Vector3.new(4+((s.lane-1)%4-1.5)*2,28,-25)
	s.flight={root=r,start=now(),from=r.Position,to=finish}
	r.AssemblyLinearVelocity=Vector3.zero
	r.Anchored=true
end
pickup.Triggered:Connect(function(p)
	local s=states[p]
	if not s or not s.ready or s.lane>4 or s.status~="Waiting" or not nearby(p,pickup) then return end
	if phase=="Ready" then
		if day~=math.floor(os.time()/86400) then chooseJob(job) end
		started=now()
		deadline=started+SHIFT_SECONDS
		phaseTo("Running")
	end
	if not live() or issued[p.UserId] then return end
	issued[p.UserId]=true
	s.pickedAt=now()
	if job=="Misprint" then
		s.address=addresses[1+(day+s.lane+(p:GetAttribute("Shifts") or 0))%#addresses]
		p:SetAttribute("Address",s.address)
		p:SetAttribute("Sorted",false)
	end
	load(p,"Carrying",job=="LastLetter" and 1 or 2)
end)
for address,q in depot.bins do
	q.Triggered:Connect(function(p)
		if job~="Misprint" or not carrying(p,q) or p:GetAttribute("Sorted") then return end
		if address~=states[p].address then
			note(p,"Wrong window. Your parcel is addressed to "..states[p].address..".")
			return
		end
		p:SetAttribute("Sorted",true)
		note(p,"Manifest stamped. Take it to the red mailbox.",2)
	end)
end
depot.pad.Triggered:Connect(function(p)
	if not carrying(p,depot.pad) or job=="LastLetter" then return end
	local s=states[p]
	if tool=="" then
		if s.carried<2 then note(p,"Keep your last parcel for delivery."); return end
		owner,deployedAt=p.UserId,now()
		tool=p:GetAttribute("Loadout")=="Bridge" and "Deploying" or "Spring"
		d:SetAttribute("ShortcutOwner",owner)
		d:SetAttribute("Shortcut",tool)
		load(p,"Carrying",s.carried-1)
		if tool=="Spring" then
			depot.spring()
			depot.squeal:Play()
			depot.chirp:Play()
			monster.lure(now())
		else
			depot.bridge(.05)
		end
	end
	if tool=="Spring" then launch(p) end
end)
local function pay(p,isFinal)
	local s=states[p]
	local pay=s.carried*PARCEL_PAY+(job=="Misprint" and 5 or 0)
	local daily=job=="Daily" and s.carried==2 and now()-started<=30
	local priorShifts=p:GetAttribute("Shifts")
	local priorStamp=p:GetAttribute("StampDay")
	local priorPrints=p:GetAttribute("PrintCount") or 0
	local bonus=records.earn(p,pay,true,daily and day or nil,{
		FullBag=s.carried==2, ShortcutRun=s.usedShortcut==true, Express=now()-s.pickedAt<=25,
	})
	if isFinal and p:GetAttribute("RoofLetter") and p:GetAttribute("MallLetter") then records.mark(p,"Ending") end
	local receipt="+"..pay.." coins"
	if daily and priorStamp<day then receipt..=" · +1 stamp" end
	if priorShifts+1==MALL_SHIFTS then receipt..=" · Pizza skin & mall unlocked" end
	if priorShifts+1==BRIDGE_SHIFTS then receipt..=" · Folding bridge unlocked" end
	if daily and priorStamp<day and p:GetAttribute("Stamps")==STAMP_SKIN then receipt..=" · Airmail skin unlocked" end
	if isFinal then receipt="“My route is over.” The Unclaimed clocks out.  +"..pay.." coins" end
	if bonus>0 then
		receipt..=" · +"..bonus.." route card"
		if p:GetAttribute("Cards")==1 then receipt..=" · Misprint Office unlocked" end
	end
	if p:GetAttribute("PrintCount")>priorPrints then receipt..=" · New print: "..p:GetAttribute("LatestPrint") end
	p:SetAttribute("Receipt",receipt)
	p:SetAttribute("LastPay",pay)
	p:SetAttribute("NoticeUntil",0)
	load(p,"Paid",0)
	if s.helped and owner and owner~=p.UserId and not awarded[p.UserId] then
		awarded[p.UserId]=true
		local opener=Players:GetPlayerByUserId(owner)
		if opener and states[opener] and states[opener].ready then
			records.earn(opener,HELP_TIP,false)
			opener:SetAttribute("Tips",(opener:GetAttribute("Tips") or 0)+HELP_TIP)
			note(opener,"+"..HELP_TIP.." coins · "..p.DisplayName.." delivered using your shortcut.",4)
		end
	end
	checkFinish()
end
delivery.Triggered:Connect(function(p)
	if not carrying(p,delivery) or job=="LastLetter" then return end
	if job=="Misprint" and not p:GetAttribute("Sorted") then note(p,"Get your "..states[p].address.." manifest stamped first."); return end
	if job=="Mall" and (now()-started)%10>=3.5 then note(p,"Shutter closed. Watch the light."); return end
	pay(p,false)
end)
depot.final.Triggered:Connect(function(p)
	if job=="LastLetter" and carrying(p,depot.final) then pay(p,true) end
end)
depot.letter.Triggered:Connect(function(p)
	if not carrying(p,depot.letter) or job=="LastLetter" then return end
	local key=job=="Mall" and "MallLetter" or "RoofLetter"
	if records.mark(p,key) then
		local msg=key=="RoofLetter" and "Found a letter. “Forward to Moth Arcade, Bellwether Mall.”" or "Found the roster. The missing courier was never clocked out."
		note(p,msg,5)
	end
end)
depot.board.Triggered:Connect(function(p)
	if states[p] and states[p].ready and phase=="Ready" and nearby(p,depot.board) then boardEvent:FireClient(p) end
end)
boardEvent.OnServerEvent:Connect(function(p,kind,value)
	local s=states[p]
	if not s or not s.ready or phase~="Ready" or s.lane>4 or not nearby(p,depot.board) then return end
	if typeof(value)~="string" or now()<(s.nextOrder or 0) then return end
	s.nextOrder=now()+.18
	local shifts=p:GetAttribute("Shifts")
	if kind=="Job" then
		local allowed=value=="Rooftops" or value=="Daily" or (value=="Mall" and shifts>=MALL_SHIFTS)
			or (value=="Misprint" and (p:GetAttribute("Cards") or 0)>=1)
			or (value=="LastLetter" and p:GetAttribute("RoofLetter") and p:GetAttribute("MallLetter"))
		if allowed then chooseJob(value) end
	elseif kind=="Loadout" and (value=="Spring" or (value=="Bridge" and shifts>=BRIDGE_SHIFTS)) then
		records.equip(p,"Loadout",value)
	elseif kind=="Buy" and records.prices[value] then
		local message=records.buy(p,value)
		if message and p.Parent then note(p,message,3) end
	elseif kind=="Skin" and (value=="Kraft" or (value=="Pizza" and shifts>=MALL_SHIFTS) or (value=="Airmail" and p:GetAttribute("Stamps")>=STAMP_SKIN) or (value=="Postmark" and (p:GetAttribute("PrintCount") or 0)>0) or (records.prices[value] and p:GetAttribute("Own"..value))) then
		records.equip(p,"Skin",value)
	end
end)
local function register(p)
	if states[p] then return end
	local lane=p:GetAttribute("ClassicLane") or 1
	local s={lane=lane,status="Waiting",carried=0,safe=false}
	states[p]=s
	for k,v in {Loadout="Spring",Skin="Kraft",Tips=0,Lane=lane} do p:SetAttribute(k,v) end
	load(p,issued[p.UserId] and "OffDuty" or "Waiting",0)
	local function spawned(c)
		if c:WaitForChild("HumanoidRootPart",10) and p.Character==c and states[p]==s then
			relocate(p,s.safe)
			render(p)
		end
	end
	p:GetAttributeChangedSignal("Area"):Connect(function()
        cancelFlight(s)
        s.lane=p:GetAttribute("ClassicLane") or 1
        p:SetAttribute("Lane",s.lane)
        s.safe,s.helped,s.bridgeCross,s.caught,s.usedShortcut=false,false,false,false,false
        load(p,issued[p.UserId] and "OffDuty" or "Waiting",0)
        checkFinish()
    end)
    p.CharacterAdded:Connect(spawned)
	if p.Character then task.spawn(spawned,p.Character) end
	records.open(p)
	if states[p]==s then s.ready=true; p:SetAttribute("RecordReady",true) end
end
d:SetAttribute("ShiftSeconds",SHIFT_SECONDS)
reset()
Players.PlayerAdded:Connect(register)
Players.PlayerRemoving:Connect(function(p)
	local s=states[p]
	if s then cancelFlight(s) end
	states[p]=nil
	if not next(states) then reset() else checkFinish() end
	task.spawn(records.close,p)
end)
for _,p in Players:GetPlayers() do task.spawn(register,p) end

local lastBridgeStep=0
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
	elapsed+=dt
	if elapsed<1/30 then return end
	dt,elapsed=math.min(elapsed,.2),0
	local t=now()
	if phase=="Ready" and day~=math.floor(os.time()/86400) then chooseJob(job) end
	if phase=="Running" and t>=deadline then endShift()
	elseif phase=="Break" and t>=restartAt then reset() end
	if phase=="Running" and t-started>=10 then checkFinish() end
	if phase=="Running" and job=="Mall" then
		local open=(t-started)%10<3.5
		if open~=d:GetAttribute("ShutterOpen") then depot.shutter(open) end
	end
	if phase=="Running" and tool=="Deploying" and t-lastBridgeStep>.25 then
		local progress=math.min(1,(t-deployedAt)/3)
		depot.bridge(progress)
		lastBridgeStep=t
		if progress==1 then tool="Bridge"; d:SetAttribute("Shortcut",tool) end
	end
	local danger=monster.step(t,dt)
	for p,s in states do
		local r=rootOf(p)
		if not r then cancelFlight(s); continue end
		if s.flight then
			local f=s.flight
			if f.root~=r then cancelFlight(s); continue end
			local alpha=math.clamp((t-f.start)/.95,0,1)
			local point=f.from:Lerp(f.to,alpha)+Vector3.new(0,15*4*alpha*(1-alpha),0)
			r.CFrame=CFrame.new(point)
			if alpha==1 then
				cancelFlight(s)
				r.AssemblyLinearVelocity=Vector3.zero
				s.safe=true
				s.usedShortcut=true
				if owner~=p.UserId then s.helped=true end
			end
			continue
		end
		local pos=r.Position
		if pos.Y<12 then relocate(p,s.safe); continue end
		if math.abs(pos.X)<28 and pos.Y>=24 and pos.Y<=32 then
			if pos.Z>=14 and pos.Z<=52 then s.safe=false; s.bridgeCross=false end
			if not s.safe and tool=="Bridge" and math.abs(pos.X-4)<=3.5 and math.abs(pos.Z)<4 then s.bridgeCross=true end
			if pos.Z<=-13 and pos.Z>=-52 then
				if s.bridgeCross and s.status=="Carrying" then
					s.usedShortcut=true
					if owner~=p.UserId then s.helped=true end
				end
				s.safe=true
				s.bridgeCross=false
			end
		end
		if danger and live() and s.status=="Carrying" and not s.caught and (pos-danger).Magnitude<4.6 then
			s.caught=true
			local n=s.carried-1
			load(p,n>0 and "Carrying" or "Lost",n)
			relocate(p,s.safe)
			note(p,n>0 and "A sleeve brushes past. One parcel left. You can still deliver." or "The Unclaimed took your last parcel.",4)
			checkFinish()
		end
	end
end)

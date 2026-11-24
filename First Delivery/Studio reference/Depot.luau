-- ServerScriptService > Depot. Builds the working props against the original rooftop blockout.
local d = workspace.NightPost
local V, rgb = Vector3.new, Color3.fromRGB
local steel, yellow, red = rgb(51,67,75), rgb(250,185,55), rgb(197,58,62)
local function model(name,parent)
	local m = Instance.new("Model")
	m.Name, m.Parent = name,parent
	return m
end
local function part(parent,name,size,pos,color,collide,material)
	local p = Instance.new("Part")
	p.Name,p.Size,p.Position,p.Color = name,size,pos,color
	p.Anchored,p.CanCollide = true,collide == true
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface,p.BottomSurface = Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function sign(p,words,face)
	local s = Instance.new("SurfaceGui")
	s.Face,s.LightInfluence,s.PixelsPerStud = face or Enum.NormalId.Back,0,40
	s.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	s.Parent = p
	local t = Instance.new("TextLabel")
	t.Size,t.BackgroundTransparency = UDim2.fromScale(1,1),1
	t.TextColor3,t.TextScaled,t.Font = rgb(254,237,192),true,Enum.Font.GothamBold
	t.Text,t.Parent = words,s
	return t
end
local function prompt(p,name,action,object,range)
	local q=Instance.new("ProximityPrompt")
	q.Name,q.ActionText,q.ObjectText = name,action,object
	q.MaxActivationDistance,q.HoldDuration,q.RequiresLineOfSight = range or 8,0.18,false
	q.Parent=p
	return q
end
local function sound(p,name,file,volume,speed)
	local s=Instance.new("Sound")
	s.Name,s.SoundId,s.Volume,s.PlaybackSpeed=name,"rbxasset://sounds/"..file,volume,speed
	s.RollOffMaxDistance,s.RollOffMinDistance=85,8
	s.Parent=p
	return s
end
local function rod(parent,name,a,b,width,color)
	local p=part(parent,name,V(width,width,(b-a).Magnitude),(a+b)/2,color,false,Enum.Material.Metal)
	p.CFrame=CFrame.lookAt((a+b)/2,b)
	return p
end
local depot={part=part,model=model,sign=sign,rod=rod,sound=sound}
local works=model("NightShift",d)
-- The service walk follows the outside wall. Its two landings connect to the roof edges.
local exteriorOffset=V(-32,0,0)
d.MaintenanceBridge.Position+=exteriorOffset
for _,piece in d.BridgeHardware:GetChildren() do
	if piece:IsA("BasePart") then piece.Position+=exteriorOffset end
end
for _,z in {15,-15} do
	part(works,"ServiceLanding",V(33,1,7),V(-42,23.7,z),steel,true,Enum.Material.DiamondPlate)
	local outside=z+(z>0 and 3.4 or -3.4)
	part(works,"LandingRail",V(31,.26,.26),V(-43,27,outside),yellow,true)
	for x=-57,-29,7 do part(works,"LandingPost",V(.24,2.8,.24),V(x,25.6,outside),yellow,true) end
end
local board=part(works,"JobBoard",V(7,4,0.7),V(14,27,36),steel,true)
sign(board,"DISPATCH\nJOBS & LOCKERS")
depot.board=prompt(board,"Browse","Read job board","Dispatch",9)
depot.pad=prompt(d.OpenHere,"Unpack","Open 1 parcel","OPEN HERE",7)
depot.squeal=sound(d.OpenHere,"BoxSqueal","ouch.ogg",1.15,2.15)
depot.chirp=sound(d.OpenHere,"SpringChirp","action_get_up.mp3",0.8,2.6)
local tower=model("MorrowWater",works)
for _,x in {-2,2} do
	for _,z in {-2,2} do part(tower,"Leg",V(.45,7,.45),V(16+x,27.5,-38+z),steel,true) end
end
local tank=part(tower,"Tank",V(7.5,8,8),V(16,34,-38),rgb(104,127,124),true,Enum.Material.Metal)
tank.Shape=Enum.PartType.Cylinder
tank.Orientation=V(0,0,90)
sign(part(tower,"Plate",V(6,1.4,.25),V(16,34,-33.9),steel,false),"MORROW WATER")
local fire=model("FireEscape",works)
for _,x in {2,6} do part(fire,"Stringer",V(.28,24,.28),V(x,12,11.5),steel,false) end
for i=1,14 do part(fire,"Rung",V(4,.16,.3),V(4,i*1.65,11.5),steel,false) end
part(fire,"Landing",V(6,.3,3),V(4,23.9,10.7),steel,true,Enum.Material.DiamondPlate)
local letter=part(works,"DeadLetter",V(1.7,.22,1.15),V(16,24.5,-43),rgb(247,220,157),false)
sign(letter,"RETURN",Enum.NormalId.Top)
depot.letter=prompt(letter,"Read","Read undeliverable letter","Dead letters",5)
-- The warning beacon sits on the escape that the Unclaimed actually climbs.
depot.lamp=part(fire,"EscapeBeacon",V(.85,.75,.85),V(7,26.8,11.8),yellow,false,Enum.Material.Neon)
local beacon=Instance.new("PointLight")
beacon.Range,beacon.Brightness,beacon.Color,beacon.Parent=16,2,yellow,depot.lamp
local base=d.RedMailbox.Position
local fittings={}
for _,name in {"Slot","PostalBadge","DropSign","DropSignMount"} do
	local p=d.StreetScenery[name]
	fittings[p]=p.Position-base
end
local mall=model("BellwetherArcade",works)
local awning=rgb(76,114,108)
for i,name in {"RECORDS","MOTH ARCADE","ALTERATIONS"} do
	local x=(i-2)*16
	part(mall,"Storefront",V(14,7,1.5),V(x,27.7,-48),steel,true)
	for row=1,7 do part(mall,"Slat",V(12,.65,.4),V(x,24.4+row*.84,-47.1),rgb(106,119,122),false,Enum.Material.Metal) end
	sign(part(mall,"ShopName",V(14,1.8,.8),V(x,32,-47),awning,false),name)
	part(mall,"Canopy",V(15,.4,4),V(x,30.9,-46),awning,true)
end
local marquee=part(mall,"Marquee",V(22,3,.5),V(-9,37,-49),rgb(124,47,62),false)
sign(marquee,"BELLWETHER MALL")
local shutter=part(mall,"MailShutter",V(4.5,3,.4),base+V(0,.6,1.85),steel,false,Enum.Material.Metal)
local shutterText=sign(shutter,"CLOSED")
local indicator=part(mall,"ShutterLamp",V(4.5,.3,.4),base+V(0,2.3,1.85),red,false,Enum.Material.Neon)
local mallParts={}
for _,p in mall:GetDescendants() do
	if p:IsA("BasePart") then mallParts[p]={p.CFrame,p.CanCollide} end
end
local specialPlate=part(works,"ReturnedMail",V(5,3,.6),V(19,26,-29),steel,true)
sign(specialPlate,"DEAD LETTER\nOFFICE")
depot.final=prompt(specialPlate,"HandOver","Hand over the last letter","The Unclaimed",8)
local locations={V(16,26.8,-46),V(-16,26.8,-39),V(20,26.8,-27)}
local dailyNames={"behind the water tower","at the west roof rail","by the east loading bay"}

-- Three physical sorting windows. Couriers receive individual destination labels.
local hall=model("SortingHall",works)
local hallFixtures={}
local function fixture(name,size,pos,color,solid,material)
	local p=part(hall,name,size,pos,color,solid,material)
	hallFixtures[p]={home=p.CFrame,solid=solid==true}
	return p
end
local header=fixture("OfficeSign",V(28,3,1),V(-5,33.8,-38),steel,true)
sign(header,"MISPRINT OFFICE")
fixture("OfficeAwning",V(29,.38,5.5),V(-5,31.7,-37.2),rgb(146,83,70),true,Enum.Material.Metal)
fixture("Gutter",V(29,.35,.3),V(-5,31.55,-34.45),yellow,false)
local stations={{"Moon",rgb(84,109,183)},{"Moth",rgb(42,134,113)},{"Match",rgb(183,77,56)}}
depot.bins={}
for i,station in stations do
	local x=-15+(i-1)*10
	local name,color=station[1],station[2]
	fixture("Pillar",V(.6,8,.6),V(x,28,-38),steel,true)
	local bin=fixture(name,V(6.8,3.7,2.8),V(x,26.1,-36.3),color,true)
	sign(bin,string.upper(name))
	fixture("Intake",V(4.7,.45,.22),V(x,27.35,-34.81),steel,false)
	fixture("FeedTray",V(5.1,.16,1.25),V(x,27.07,-34.35),rgb(142,151,149),false,Enum.Material.Metal)
	for side=-1,1,2 do
		fixture("TrayEdge",V(.12,.33,1.25),V(x+side*2.5,27.16,-34.35),steel,false)
	end
	fixture("WorkLight",V(5,.25,.6),V(x,30,-36),color,false,Enum.Material.Neon)
	depot.bins[name]=prompt(bin,"Sort","Stamp manifest",name.." window",5.5)
end
local function selectJob(job,day)
	local isMall=job=="Mall"
	d:SetAttribute("Job",job)
	d:SetAttribute("Day",day)
	d:SetAttribute("DailyTarget",dailyNames[day%3+1])
	for p,data in hallFixtures do
		p.CFrame=data.home+(job=="Misprint" and Vector3.zero or V(0,-120,0))
		p.CanCollide=job=="Misprint" and data.solid
	end
	local pos=job=="Daily" and locations[day%3+1] or base
	d.RedMailbox.Position=pos
	for p,delta in fittings do p.Position=pos+delta end
	for p,data in mallParts do
		p.CFrame=data[1]+(isMall and Vector3.zero or V(0,-120,0))
		p.CanCollide=isMall and data[2]
	end
	letter.Position=isMall and V(-2,24.6,-45.4) or V(16,24.6,-43)
	specialPlate.Position=job=="LastLetter" and V(19,26,-29) or V(19,-100,-29)
end
depot.selectJob=selectJob
function depot.shutter(open)
	d:SetAttribute("ShutterOpen",open)
	if d:GetAttribute("Job")=="Mall" then
		shutter.Position=base+V(0,open and 3.6 or .6,1.85)
		shutterText.Text=open and "OPEN" or "CLOSED"
		indicator.Color=open and rgb(95,255,164) or red
	end
end
local shortcut=model("Shortcut",works)
function depot.clearShortcut() shortcut:ClearAllChildren() end
function depot.spring()
	local c=V(4,24.55,15)
	part(shortcut,"Crate",V(4,.6,4),c,rgb(164,100,62),false)
	local last=c+V(1.5,.3,0)
	for i=1,36 do
		local angle=i*math.pi/6
		local point=c+V(math.cos(angle)*1.5,.3+i*.052,math.sin(angle)*1.5)
		rod(shortcut,"Coil",last,point,.28,yellow)
		last=point
	end
	part(shortcut,"Cap",V(4.4,.32,4.4),c+V(0,2.4,0),yellow,false)
end
function depot.bridge(progress)
	local length=math.max(.3,28*progress)
	local deck=shortcut:FindFirstChild("FoldingDeck")
	if not deck then deck=part(shortcut,"FoldingDeck",V(6,.35,length),V(4,24.05,14-length/2),rgb(197,157,102),false,Enum.Material.WoodPlanks) end
	deck.Size=V(6,.35,length)
	deck.Position=V(4,24.05,14-length/2)
	deck.CanCollide=progress>=1
	if progress>=1 then
		for i=1,6 do part(shortcut,"Hinge",V(5.9,.07,.18),V(4,24.26,13-i*4),steel,false) end
	end
	return deck
end
return depot

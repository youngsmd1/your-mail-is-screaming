-- ServerScriptService > Unclaimed
local depot=require(script.Parent.Depot)
local d=workspace.NightPost
local V,rgb=Vector3.new,Color3.fromRGB
local actor=depot.model("The Unclaimed",d)
local origin=V(0,0,0)
local function limb(name,size,offset,color)
	return depot.part(actor,name,size,origin+offset,color,false,Enum.Material.Fabric)
end
local navy,leather,gray=rgb(42,58,83),rgb(104,68,46),rgb(154,143,116)
local torso=limb("Old uniform",V(2.25,2.2,1.1),V(0,0,0),navy)
actor.PrimaryPart=torso
limb("Face in shadow",V(1.25,1.25,1.1),V(0,1.73,0),gray)
limb("Postal cap",V(1.57,.6,1.4),V(0,2.45,0),navy)
limb("Visor",V(1.5,.15,.7),V(0,2.16,-.53),rgb(32,36,44))
limb("Cap badge",V(.35,.29,.1),V(0,2.45,-.73),rgb(216,179,96))
for _,x in {-1.38,1.38} do limb("Sleeve",V(.55,2,.8),V(x,-.07,0),navy) end
for _,x in {-.58,.58} do limb("Boot",V(.8,1.8,1),V(x,-1.93,0),rgb(38,39,44)) end
limb("Satchel",V(1.5,1.15,.65),V(.55,-.7,-.7),leather)
depot.sign(limb("Nameplate",V(.8,.35,.09),V(-.5,.6,-.6),leather),"POST",Enum.NormalId.Front)
local steps=depot.sound(torso,"FireEscapeSteps","action_footsteps_plastic.mp3",.85,.67)
steps.Looped=true
local light=depot.lamp and depot.lamp:FindFirstChildOfClass("PointLight")
local normalColor=depot.lamp and depot.lamp.Color
local patrol={V(-22,3.1,2),V(25,3.1,2)}
local points={V(4,3.1,10),V(4,15,10),V(4,27.2,11),V(4,27.2,17),V(9,27.2,17),V(4,27.2,14)}
local mode,index,pos,facing,waitUntil="Patrol",1,patrol[2],V(-1,0,0),0
local start=0
local function setMode(m)
	mode=m
	d:SetAttribute("Creature",m)
	if m=="Investigate" then steps:Play() elseif m=="Patrol" or m=="Waiting" then steps:Stop() end
end
local function pose(t)
	local bob=mode=="Waiting" and 0 or math.sin(t*8)*.09
	local here=pos+V(0,bob,0)
	actor:PivotTo(CFrame.lookAt(here,here+facing))
end
local function walk(target,speed,dt)
	local delta=target-pos
	if delta.Magnitude<=speed*dt then pos=target; return true end
	local horizontal=V(delta.X,0,delta.Z)
	if horizontal.Magnitude>.2 then facing=horizontal.Unit end
	pos+=delta.Unit*speed*dt
	return false
end
local module={}
function module.reset(final)
	if light then light.Enabled=true; depot.lamp.Color=normalColor end
	pos=final and V(19,27.2,-32) or patrol[2]
	facing=final and V(0,0,1) or V(-1,0,0)
	index=1
	setMode(final and "Waiting" or "Patrol")
	pose(0)
end
function module.lure(now)
	start,index,waitUntil=now,1,now+3.8
	setMode("Investigate")
end
function module.step(now,dt)
	local danger=false
	if mode=="Patrol" then
		if walk(patrol[index],6,dt) then index=3-index end
	elseif mode=="Investigate" then
		if light then
			local on=now-start>2.4 or math.floor((now-start)*6)%2==0
			light.Enabled=on
			depot.lamp.Color=on and normalColor or rgb(59,57,59)
		end
		if index<=#points then
			if index~=3 or now>=waitUntil then
				danger=index>=4
				if walk(points[index],index>=4 and 4 or 15,dt) then index+=1 end
			end
		else
			index=3
			setMode("Return")
		end
	elseif mode=="Return" then
		if walk(points[index],9,dt) then
			index-=1
			if index==0 then index=1; setMode("Patrol") end
		end
	end
	pose(now)
	return danger and pos or nil
end
module.reset(false)
return module

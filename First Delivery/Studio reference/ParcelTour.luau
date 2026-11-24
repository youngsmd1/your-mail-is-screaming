local W=require(script.Parent.PostalScenery)
local records=require(script.Parent.CourierRecords)
local V=Vector3.new
local jobs={}
local Tour={}
local rooms={
 {"Receiving Hall",{"Anchor","Bell","Lantern"},{"I hold a vessel still.","I speak when struck.","My flame travels with you."}},
 {"Family Archive",{"Key","Quill","Seal"},{"My teeth turn a lock.","My nib leaves a trail.","I leave an impression in warm wax."}},
 {"Last Post Office",{"Moon","Tide","Clock"},{"I vanish and return above the roof.","I climb the harbor wall without feet.","I have hands but cannot hold a letter."}},
}
local function tell(p,line) p:SetAttribute("TourHint",line) end
local function finish(j,msg)
 if jobs[j.slot]~=j then return end
 jobs[j.slot]=nil
 if j.map then j.map:Destroy() end
 for _,p in j.crew do if p.Parent then j.home(p,msg) end end
 j.done()
end
local function place(p,pos)
 local c=p.Character
 if c and c:FindFirstChild("HumanoidRootPart") then
  c:PivotTo(CFrame.new(pos));c.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
 end
end
local function openRoom(j)
 if j.map then j.map:Destroy() end
 local index=j.level
 local data=rooms[index]
 local reader=j.crew[(index-1)%2+1]
 local sorter=j.crew[index%2+1]
 local o=V(700+j.slot*220,52,-400)
 local map=W.model(workspace,"DeadLetterHouse_"..j.slot);j.map=map
 local wood=Color3.fromRGB(90,63,48)
 local plaster=({Color3.fromRGB(117,111,94),Color3.fromRGB(82,101,98),Color3.fromRGB(109,87,83)})[index]
 local function part(n,size,x,y,z,col,solid,mat)
  return W.part(map,n,size,o+V(x,y,z),col,solid,mat or Enum.Material.WoodPlanks)
 end
 part("Parquet",V(50,1,42),0,-.5,0,wood,true)
 part("Ceiling",V(50,1,42),0,15,0,plaster,true,Enum.Material.Plaster)
 for _,side in {-1,1} do
  part("Paneled wall",V(1,15,42),side*25,7.5,0,plaster,true)
  part("Gallery wall",V(50,15,1),0,7.5,side*21,plaster,true)
  part("Wainscot",V(.5,4,42),side*24.35,2,0,wood,true)
  part("Dado rail",V(49,.35,1),0,4,side*20.35,wood,false)
  part("Transom",V(6,10,1),side*11,5,2,wood,true)
  for x=-16,16,8 do part("Ceiling joist",V(.48,.7,20),x,14.2,side*10,wood,false) end
  local lamp=part("Milk glass sconce",V(1.1,1.8,1),side*17,6,-19.8,W.cream,false,Enum.Material.Neon)
  W.light(lamp,W.brass,32)
 end
 part("Runner",V(9,.09,36),0,.07,0,Color3.fromRGB(111,51,49),false,Enum.Material.Fabric)
 for i=1,3 do
  local x=-17+(i-1)*17
  if index==1 then
   part("Luggage trunk",V(5,3,3),x,1.5,17,wood,true)
   part("Leather strap",V(.45,3.1,3.1),x+1,1.5,17,W.brass,false)
  elseif index==2 then
   part("Bookcase",V(8,9,2),x,4.5,19,wood,true)
   for k=1,12 do part("Cloth spine",V(.78,2,.7),x-2.8+k%6,2+math.floor((k-1)/6)*3,17.85,k%2==0 and W.teal or W.red,false) end
  else
   for k=1,4 do part("Letter drawer",V(6,1.4,3),x,k*1.5-.75,18,wood,true);part("Brass pull",V(1,.25,.25),x,k*1.5-.65,16.4,W.brass,false) end
  end
 end
 local desk=part("Evidence desk",V(6,3,3),-16,1.5,-12,wood,true)
 local ledger=part("Witness statement",V(3,.35,2),-16,3.2,-12,W.cream,false)
 W.label(part("Door plate",V(13,2,.3),0,8,-20,wood,false),string.upper(data[1]))
 -- The rooms share a footprint but have distinct light sources and furnishings.
 for _,side in {-1,1} do
  local wx=side*24.2
  part("Rain glass",V(.18,7,7),wx,8,9,Color3.fromRGB(95,119,132),false,Enum.Material.Glass)
  part("Window crossbar",V(.45,.3,7.5),wx-side*.12,8,9,wood,false)
  part("Window mullion",V(.45,7.5,.3),wx-side*.12,8,9,wood,false)
 end
 if index==1 then
  part("Hearth stone",V(10,.4,5),0,.25,17,plaster,true)
  part("Chimney breast",V(9,14,2),0,7,19,plaster,true,Enum.Material.Brick)
  part("Firebox",V(5,4,.4),0,2,17.8,W.ink,false)
  part("Oak mantel",V(11,.65,3),0,5,18,wood,true)
  local ember=part("Banked coals",V(3,.32,.8),0,.6,17.2,Color3.fromRGB(204,108,65),false,Enum.Material.Neon);W.light(ember,ember.Color,12)
 elseif index==2 then
  for i=1,4 do
   part("Picture frame",V(4.5,5,.5),-18+i*7,9,-20,W.brass,false)
   part("Family silhouette",V(3.8,4.2,.6),-18+i*7,9,-19.9,wood,false)
   W.orb(map,"Portrait bust",V(1.6,2.6,.22),o+V(-18+i*7,9,-19.48),W.ink)
  end
 else
  for i=1,7 do part("Service grille",V(.18,4,.2),-4+i,8,-18,W.brass,false) end
  W.label(part("Counter plate",V(8,1.2,.3),0,5.3,-18,wood,false),"RETURN TO SENDER")
 end
 local correct=math.random(3)
 local revealed,solved=false,false
 local shade=W.figure(map,"Resident postmaster",o+V(0,0,-8),true)
 local deadline=workspace:GetServerTimeNow()+105
 local alarmUntil=0
 local function allowed(p,obj)
  local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
  return jobs[j.slot]==j and j.map==map and not solved and r and (r.Position-obj.Position).Magnitude<10
 end
 local function scan(p)
  if not allowed(p,ledger) then return end
  if p~=reader then tell(p,"Your partner reads the statement. You operate the lock.");return end
  revealed=true
  for _,member in j.crew do tell(member,"Witness statement: “"..data[3][correct].."”  Choose the matching brass plate.") end
 end
 W.prompt(ledger,"Read","Relay statement",8).Triggered:Connect(scan)
 for i,label in data[2] do
  local panel=part(label,V(4,4,2),12+(i-2)*5,2,-12,W.teal,true)
  W.label(panel,label)
  W.prompt(panel,"Select","Turn seal",7).Triggered:Connect(function(p)
   if not allowed(p,panel) then return end
   if p~=sorter then tell(p,"Only your partner has the winding key.");return end
   if not revealed then tell(p,"Wait for your partner to relay the statement.");return end
   if time()<alarmUntil then return end
   if i~=correct then
    revealed=false;alarmUntil=time()+4;deadline-=5
    for _,member in j.crew do member:SetAttribute("TourEnds",deadline);tell(member,"Wrong seal. The keeper is coming. Reader, relay the statement again.") end
    place(p,o+V(6,3,12));return
   end
   solved=true
   for _,member in j.crew do records.earn(member,10+5*index,true,index==3 and math.floor(workspace:GetServerTimeNow()/86400) or nil,nil,index) end
   if jobs[j.slot]~=j then return end
   if index==3 then finish(j,"Case closed. The postmaster finally received his letter.")
   else j.level+=1;openRoom(j) end
  end)
 end
 for i,p in j.crew do
  p:SetAttribute("Area","Tour");p:SetAttribute("TourTitle",data[1]);p:SetAttribute("TourEnds",deadline);p:SetAttribute("LegDuration",105)
  tell(p,p==reader and "Reader: find the ivory statement on the west desk and relay it." or "Keyholder: wait for the statement, then choose one of the three brass seals.")
  place(p,o+V(i*5-8,3,12))
 end
 local ghostPos=Vector3.new(0,3.3,-5)
 j.tick=function()
  local t=time()
  local x=time()<alarmUntil and 9 or 7*math.sin(t*.55)
  local walking=time()<alarmUntil
  local goal=V(x,3.3,walking and 6 or -4+math.cos(t*.55)*2)
  ghostPos=ghostPos:Lerp(goal,walking and .16 or .09)
  local pos=o+ghostPos+V(0,.055*math.sin(t*6),0)
  local target=sorter.Character and sorter.Character:FindFirstChild("HumanoidRootPart")
  local facing=walking and target and V(pos.X-target.Position.X,0,pos.Z-target.Position.Z)
  local pose=if facing and facing.Magnitude>.1 then CFrame.lookAt(pos,pos+facing) else CFrame.new(pos)*CFrame.Angles(0,math.sin(t*.55)*1.3,0)
  shade:PivotTo(pose)
  if workspace:GetServerTimeNow()>deadline and not solved then finish(j,"The house closed at dawn. Board together to reopen the case.") end
 end
end
function Tour.start(slot,crew,home,done)
 if #crew~=2 then return end
 jobs[slot]={slot=slot,crew=crew,home=home,done=done,ready={},level=1,untilTime=time()+90}
 for _,p in crew do p:SetAttribute("Area","Tutorial") end
end
function Tour.ready(p)
 for _,j in jobs do if table.find(j.crew,p) and not j.map then
  j.ready[p]=true;p:SetAttribute("TutorialReady",true)
  if j.ready[j.crew[1]] and j.ready[j.crew[2]] then openRoom(j) end
  return
 end end
end
function Tour.leave(p)
 for _,j in jobs do if table.find(j.crew,p) then finish(j,"Your partner left. Board again with another courier.");return end end
end
function Tour.respawn(p)
 for _,j in jobs do if j.map and table.find(j.crew,p) then place(p,V(700+j.slot*220,55,-388)) end end
end
task.spawn(function()
 while task.wait(.12) do for _,j in jobs do if j.tick then j.tick() elseif time()>j.untilTime then finish(j,"Boarding expired.") end end end
end)
return Tour
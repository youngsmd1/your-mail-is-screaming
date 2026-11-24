-- StarterPlayer > StarterPlayerScripts > ShiftHUD
local player=game:GetService("Players").LocalPlayer
local d=workspace:WaitForChild("NightPost")
local works=d:WaitForChild("NightShift")
local pickup=d:WaitForChild("DispatchCounter"):WaitForChild("Pickup")
local delivery=d:WaitForChild("RedMailbox"):WaitForChild("Deliver")
local pad=d:WaitForChild("OpenHere"):WaitForChild("Unpack")
local board=works:WaitForChild("JobBoard"):WaitForChild("Browse")
local letter=works:WaitForChild("DeadLetter"):WaitForChild("Read")
local last=works:WaitForChild("ReturnedMail"):WaitForChild("HandOver")
local event=game.ReplicatedStorage:WaitForChild("DispatchBoard")
local sorting=works:WaitForChild("SortingHall")
local sortingPrompts={}
for _,name in {"Moon","Moth","Match"} do table.insert(sortingPrompts,sorting:WaitForChild(name):WaitForChild("Sort")) end
local gui=Instance.new("ScreenGui")
gui.Name,gui.ResetOnSpawn,gui.Parent="ShiftHUD",false,player:WaitForChild("PlayerGui")
local ink=Color3.fromRGB(26,39,49)
local paper=Color3.fromRGB(255,243,214)
local gold=Color3.fromRGB(255,209,100)
local teal=Color3.fromRGB(52,100,104)
local function frame(name,parent,size,pos,color)
	local f=Instance.new("Frame")
	f.Name,f.Parent,f.Size,f.Position,f.BackgroundColor3=name,parent,size,pos,color
	f.BorderSizePixel=0
	return f
end
local function text(parent,name,size,pos,color,font,pt)
	local t=Instance.new("TextLabel")
	t.Name,t.Size,t.Position,t.TextColor3,t.Font,t.TextSize=name,size,pos,color,font,pt
	t.TextXAlignment,t.TextWrapped,t.BackgroundTransparency=Enum.TextXAlignment.Left,true,1
	t.Text,t.Parent="",parent
	return t
end
local function limit(f,width,height)
	local c=Instance.new("UISizeConstraint")
	c.MaxSize,c.Parent=Vector2.new(width,height),f
end
local panel=frame("DispatchSlip",gui,UDim2.new(.94,0,0,78),UDim2.new(.5,0,0,6),ink)
panel.AnchorPoint=Vector2.new(.5,0)
limit(panel,580,78)
local clock=text(panel,"Time",UDim2.new(.5,-14,0,24),UDim2.fromOffset(12,2),gold,Enum.Font.Code,16)
local load=text(panel,"Parcels",UDim2.new(.5,-14,0,24),UDim2.new(.5,2,0,2),gold,Enum.Font.Code,16)
load.TextXAlignment=Enum.TextXAlignment.Right
local objective=text(panel,"Objective",UDim2.new(1,-24,0,46),UDim2.fromOffset(12,25),paper,Enum.Font.GothamMedium,15)
local menu=frame("JobBoard",gui,UDim2.fromScale(.91,.83),UDim2.fromScale(.5,.51),ink)
menu.AnchorPoint=Vector2.new(.5,.5)
limit(menu,490,475)
menu.Visible=false
local title=text(menu,"Title",UDim2.new(.75,0,0,40),UDim2.fromOffset(16,6),paper,Enum.Font.GothamBold,23)
title.Text="Night dispatch"
local function button(parent,name,caption)
	local b=Instance.new("TextButton")
	b.Name,b.Text,b.Font,b.TextSize=name,caption,Enum.Font.GothamMedium,15
	b.BackgroundColor3,b.TextColor3,b.BorderSizePixel=teal,paper,0
	b.TextWrapped,b.Selectable,b.Parent=true,true,parent
	return b
end
local close=button(menu,"Close","Done")
close.AnchorPoint=Vector2.new(1,0)
close.Position,close.Size=UDim2.new(1,-12,0,10),UDim2.fromOffset(76,32)
local tabs=frame("Tabs",menu,UDim2.new(1,-28,0,35),UDim2.fromOffset(14,49),ink)
local pages,tabButtons={},{}
local function selectTab(name)
	for key,page in pages do
		page.Visible=key==name
		tabButtons[key].BackgroundColor3=key==name and Color3.fromRGB(138,84,43) or teal
	end
end
for index,key in {"Routes","Locker","Record"} do
	local tab=button(tabs,key,key)
	tab.Position,tab.Size=UDim2.fromScale((index-1)/3,0),UDim2.new(1/3,-4,1,0)
	local page=Instance.new("ScrollingFrame")
	page.Name=key=="Routes" and "Jobs" or key.."Page"
	page.Position,page.Size=UDim2.fromOffset(14,94),UDim2.new(1,-28,1,-104)
	page.BackgroundTransparency,page.BorderSizePixel,page.ScrollBarThickness=1,0,5
	page.CanvasSize,page.AutomaticCanvasSize,page.Parent=UDim2.new(),Enum.AutomaticSize.Y,menu
	local list=Instance.new("UIListLayout")
	list.Padding,list.SortOrder,list.Parent=UDim.new(0,5),Enum.SortOrder.LayoutOrder,page
	pages[key],tabButtons[key]=page,tab
	tab.Activated:Connect(function() selectTab(key) end)
end
local scroll=pages.Routes
local order=0
local function row(obj,h)
	order+=1
	obj.LayoutOrder,obj.Size=order,UDim2.new(1,-7,0,h)
	return obj
end
local function heading(name,h)
	return row(text(scroll,name,UDim2.new(),UDim2.new(),gold,Enum.Font.Code,14),h)
end
local nextPunch=heading("NextPunch",42)
heading("Route",23).Text="CREW ROUTE"
local names={Rooftops="Morrow rooftops",Mall="Bellwether Mall",Misprint="Misprint Office",Daily="Daily stamp run",LastLetter="Letter to the Unclaimed",Spring="Screaming spring",Bridge="Folding bridge",Kraft="Kraft paper",Pizza="Pizza box",Airmail="Airmail stripes",Firefly="Firefly foil",Midnight="Midnight foil"}
local prices={Firefly=45,Midnight=100}
names.Postmark="Collector's postmark"
local choices={}
local function choicesFor(kind,values)
	for _,value in values do
		local b=row(button(scroll,value,names[value]),33)
		choices[value]={button=b,kind=kind}
		b.Activated:Connect(function()
			if not b.Active then return end
			local buy=prices[value] and not player:GetAttribute("Own"..value)
			event:FireServer(buy and "Buy" or kind,value)
		end)
	end
end
choicesFor("Job",{"Rooftops","Daily","Misprint","Mall","LastLetter"})
local dailyText=heading("DailyJob",45)
scroll=pages.Locker
local wallet=heading("Wallet",36)
heading("Contents",23).Text="ISSUED EQUIPMENT"
choicesFor("Loadout",{"Spring","Bridge"})
heading("Wrap",23).Text="PARCEL WRAPPING"
choicesFor("Skin",{"Kraft","Pizza","Airmail","Firefly","Midnight","Postmark"})
scroll=pages.Record
local record=heading("Record",54)
local pass=heading("Passbook",125)
local weekly=heading("WeeklyEdition",68)
local shelf=heading("PrintCollection",78)
local clue=heading("LetterClue",64)
selectTab("Routes")
local function hideMenu()
	menu.Visible=false
	if game.GuiService.SelectedObject and game.GuiService.SelectedObject:IsDescendantOf(menu) then game.GuiService.SelectedObject=nil end
end
close.Activated:Connect(hideMenu)
event.OnClientEvent:Connect(function()
	menu.Visible=true
	selectTab("Routes")
	for _,page in pages do page.CanvasPosition=Vector2.zero end
	if game:GetService("UserInputService").PreferredInput==Enum.PreferredInput.Gamepad then game.GuiService.SelectedObject=close end
end)
local function attr(k) return player:GetAttribute(k) end
local function refreshMenu(job)
	local shifts,stamps=attr("Shifts") or 0,attr("Stamps") or 0
	local cards=attr("Cards") or 0
	local hint=(attr("FullBag") or 0)==0 and "deliver both parcels" or ((attr("ShortcutRun") or 0)==0 and "ride or cross a shortcut, then deliver" or "deliver within 25 seconds")
	nextPunch.Text=string.format("Next punch on card %d: %s.",cards+1,hint)
	local titleName=cards>=6 and "Night postmaster" or (cards>=3 and "Route captain" or (cards>=1 and "Route regular" or "Relief courier"))
	record.Text=string.format("%s   ·   %d complete cards\n%d shifts   /   %d stamps   /   %s",titleName,cards,shifts,stamps,attr("SaveState") or "")
	local function punch(key) return (attr(key) or 0)>0 and "✓" or "○" end
	pass.Text=string.format("ROUTE CARD %02d   ·   15 coins\n%s  Deliver both parcels\n%s  Deliver after using a shortcut\n%s  Deliver within 25s of pickup\n%s",cards+1,punch("FullBag"),punch("ShortcutRun"),punch("Express"),cards==0 and "First card opens the Misprint Office." or "Extra punches carry to your next card.")
	dailyText.Text=attr("StampDay")==d:GetAttribute("Day") and "Today's stamp is in your book. New address at 00:00 UTC." or ("Today's stamp: deliver both in 30s "..(d:GetAttribute("DailyTarget") or "")..".")
	weekly.Text=string.format("WEEKLY PRINT · %s\nDaily stamps on two dates this week: %d/2. New print on Monday (UTC).",attr("WeeklyDesign") or "",attr("WeeklyDays") or 0)
	shelf.Visible=(attr("PrintCount") or 0)>0
	shelf.Text=string.format("COLLECTED PRINTS · %d\n%s",attr("PrintCount") or 0,attr("PrintShelf") or "")
	wallet.Text=(attr("NoticeUntil") or 0)>workspace:GetServerTimeNow() and attr("Notice") or string.format("%d COINS",attr("Coins") or 0)
	local locks={}
	if shifts<3 then locks.Mall="3 shifts"; locks.Pizza="3 shifts" end
	if shifts<5 then locks.Bridge="5 shifts" end
	if stamps<3 then locks.Airmail="3 stamps" end
	if cards<1 then locks.Misprint="1 route card" end
	if (attr("PrintCount") or 0)<1 then locks.Postmark="1 weekly print" end
	if not (attr("RoofLetter") and attr("MallLetter")) then locks.LastLetter="both letters" end
	for value,entry in choices do
		local selected=({Job=job,Loadout=attr("Loadout"),Skin=attr("Skin")})[entry.kind]==value
		local name=names[value]
		if value=="Daily" then name..=" · 2 parcels in 30s" end
		if prices[value] and not attr("Own"..value) then
			name="Buy "..name.." · "..prices[value].." coins"
			if (attr("Coins") or 0)<prices[value] then locks[value]="need "..(prices[value]-(attr("Coins") or 0)).." more" end
		end
		local b=entry.button
		b.Active=locks[value]==nil
		b.Text=(selected and "✓  " or "")..name..(locks[value] and ("  /  "..locks[value]) or "")
		b.BackgroundColor3=locks[value] and Color3.fromRGB(62,68,72) or (selected and Color3.fromRGB(145,89,48) or teal)
	end
	clue.Text=attr("Ending") and "CASE CLOSED · The missing courier finally clocked out."
		or (not attr("RoofLetter") and "DEAD LETTERS · Return address partly legible: MORROW WATER. Check behind the tank."
		or (not attr("MallLetter") and "DEAD LETTERS · Forwarding address: Moth Arcade. Try the closed storefront." or "DEAD LETTERS · Both addresses recovered. Select Letter to the Unclaimed."))
end
local function faceMailbox(character)
	local root=character:WaitForChild("HumanoidRootPart",10)
	if root and player:GetAttribute("Area")=="Classic" and player.Character==character and workspace.CurrentCamera then
		workspace.CurrentCamera.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,5,10),d.RedMailbox.Position)
	end
end
player.CharacterAdded:Connect(faceMailbox)
if player.Character then task.spawn(faceMailbox,player.Character) end
while gui.Parent do
	gui.Enabled=player:GetAttribute("Area")=="Classic"
	if not gui.Enabled then hideMenu(); task.wait(.2); continue end
	local t=workspace:GetServerTimeNow()
	local phase,job,tool=d:GetAttribute("Phase"),d:GetAttribute("Job"),d:GetAttribute("Shortcut")
	local status,n=attr("DeliveryStatus"),attr("Carried") or 0
	local ready,run=phase=="Ready",phase=="Running"
	local active=status=="Carrying" and run
	local seconds=ready and 60 or (run and math.max(0,math.ceil((d:GetAttribute("EndsAt") or t)-t)) or 0)
	clock.Text=string.format("SHIFT  %d:%02d",math.floor(seconds/60),seconds%60)
	load.Text="PARCELS  "..n
	local admitted=(attr("Lane") or 1)<=4
	if not ready and menu.Visible then hideMenu() end
	if menu.Visible then
		local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not r or (r.Position-board.Parent.Position).Magnitude>11 then hideMenu() else refreshMenu(job) end
	end
	panel.Visible=not menu.Visible
	pickup.Enabled=not menu.Visible and admitted and attr("RecordReady")==true and status=="Waiting" and (ready or run)
	board.Enabled=ready and not menu.Visible and admitted and attr("RecordReady")==true
	pad.Enabled=active and job~="LastLetter" and (tool=="Spring" or (tool=="" and n>=2))
	pad.ActionText=tool=="Spring" and "Ride spring" or (attr("Loadout")=="Bridge" and "Unfold bridge · 1 parcel" or "Open spring · 1 parcel")
	delivery.Enabled=active and job~="LastLetter" and (job~="Misprint" or attr("Sorted")==true) and (job~="Mall" or d:GetAttribute("ShutterOpen")==true)
	for _,q in sortingPrompts do
		q.Enabled=active and job=="Misprint" and attr("Sorted")~=true
	end
	last.Enabled=active and job=="LastLetter"
	letter.Enabled=active and job~="LastLetter" and not attr(job=="Mall" and "MallLetter" or "RoofLetter")
	if (attr("NoticeUntil") or 0)>t then objective.Text=attr("Notice") or ""
	elseif not admitted then objective.Text="Crew full. A dispatch slot opens when a courier leaves."
	elseif status=="OffDuty" then objective.Text="Your load for this shift was already issued. Catch the next shift."
	elseif status=="Paid" then objective.Text=(attr("Receipt") or "Delivered").." · "..(attr("Coins") or 0).." total"
	elseif status=="Lost" then objective.Text="Bag empty. Back to dispatch next shift."
	elseif phase=="Break" then objective.Text="Shift closed. Back to dispatch soon."
	elseif active then
		if job=="LastLetter" then objective.Text="Hand the letter to the old uniform at the Dead Letter Office."
		elseif job=="Misprint" then objective.Text=attr("Sorted") and "Stamped. Deliver at the red mailbox for 5 extra coins." or ("Cross to the sorting office. Stamp the parcel at the "..(attr("Address") or "assigned").." window.")
		elseif job=="Daily" then
			local left=math.max(0,seconds-30)
			objective.Text=(left>0 and n==2 and ("Stamp in "..left.."s · ") or "Deliver · ")..(d:GetAttribute("DailyTarget") or "red mailbox")
		elseif job=="Mall" then objective.Text=d:GetAttribute("ShutterOpen") and "Green light! Deliver at the mall shutter." or "Get to the red mailbox. The shutter opens every 10s."
		elseif d:GetAttribute("Creature")=="Investigate" then objective.Text="Footsteps on the fire escape. Clear the yellow pad!"
		elseif tool=="Deploying" then objective.Text="Bridge unfolding. Give the hinges three seconds."
		elseif n==1 or tool~="" then objective.Text="Take your parcel"..(n==1 and "" or "s").." to the red mailbox."
		else objective.Text="Left bridge keeps both. OPEN HERE trades one for a shortcut." end
	else objective.Text=job=="Rooftops" and ((attr("Shifts") or 0)>0 and "Pick up your next load, or check your card at the job board." or "Pick up two parcels at the dispatch counter.") or ("At the counter: "..(names[job] or "next shift")..".") end
	task.wait(.12)
end

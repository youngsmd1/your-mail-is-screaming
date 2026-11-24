-- ServerScriptService > CourierRecords. Each login contributes cumulative deltas.
-- UpdateAsync can replay a write without charging twice, even during a server hop.
local DataStoreService=game:GetService("DataStoreService")
local HttpService=game:GetService("HttpService")
local sandbox=game.PlaceId==0 or game:GetService("RunService"):IsStudio()
local store
if not sandbox then store=DataStoreService:GetDataStore("NightPost_Couriers_v1") end
local records={}
local profiles={}
local punchKeys={"FullBag","ShortcutRun","Express"}
local prices={Firefly=45, Midnight=100}
records.prices=prices
local function cards(data)
	return math.min(data.FullBag,data.ShortcutRun,data.Express)
end
local printNames={"Morrow Moth","Night Window","Water Tower","Last Light"}
local function syncPostmarks(p,r)
	local today=math.floor(os.time()/86400)
	r.syncedDay=today
	local currentWeek=math.floor((today+3)/7)
	local weeks={}
	for date in r.data.stampDays do
		local day=tonumber(date)
		if day then
			local week=math.floor((day+3)/7)
			weeks[week]=(weeks[week] or 0)+1
		end
	end
	local editions={}
	for week,count in weeks do
		if count>=2 then table.insert(editions,week) end
	end
	table.sort(editions,function(a,b) return a>b end)
	local shelf={}
	for i=1,math.min(4,#editions) do
		local week=editions[i]
		local date=os.date("!%d %b %Y",(week*7-3)*86400)
		table.insert(shelf,printNames[week%4+1].."  ·  "..date)
	end
	p:SetAttribute("PrintCount",#editions)
	p:SetAttribute("PrintShelf",table.concat(shelf,"\n"))
	p:SetAttribute("LatestPrint",editions[1] and printNames[editions[1]%4+1] or "")
	p:SetAttribute("WeeklyDesign",printNames[currentWeek%4+1])
	p:SetAttribute("WeeklyDays",math.min(2,weeks[currentWeek] or 0))
end
local function clean(data)
	data=type(data)=="table" and data or {}
	for _,k in {"Coins","Shifts","Stamps","StampDay"} do data[k]=tonumber(data[k]) or 0 end
	for _,key in punchKeys do data[key]=tonumber(data[key]) or 0 end
	data.wraps=type(data.wraps)=="table" and data.wraps or {}
	data.sessions=type(data.sessions)=="table" and data.sessions or {}
	data.stampDays=type(data.stampDays)=="table" and data.stampDays or {}
	if data.StampDay>0 then data.stampDays[tostring(data.StampDay)]=true end
	data.preferences=type(data.preferences)=="table" and data.preferences or {}
	data.terminal=type(data.terminal)=="table" and data.terminal or {}
	data.terminal.receipts=data.terminal.receipts or {}
	return data
end
local function sync(p,r)
	for _,key in {"ClaimDate","ClaimStep","SpinDate","SpinTickets","HornTickets","TourBest"} do
		p:SetAttribute(key,r.data.terminal[key] or 0)
	end
	syncPostmarks(p,r)
	local completed=cards(r.data)
	p:SetAttribute("Cards",completed)
	for _,key in punchKeys do p:SetAttribute(key,r.data[key]-completed) end
	for wrap in prices do p:SetAttribute("Own"..wrap,r.data.wraps[wrap]==true) end
	for _,k in {"Coins","Shifts","Stamps","StampDay"} do p:SetAttribute(k,r.data[k]) end
	for _,k in {"RoofLetter","MallLetter","Ending"} do p:SetAttribute(k,r.data[k]==true) end
	for k,entry in r.data.preferences do
		if k=="Loadout" or k=="Skin" then p:SetAttribute(k,entry.value) end
	end
end
function records.open(p)
	local r={id=HttpService:GenerateGUID(false),data=clean(),coins=0,shifts=0,punches={},days={},revision=0,saved=0}
	for _,key in punchKeys do r.punches[key]=0 end
	profiles[p]=r
	p:SetAttribute("SaveState",sandbox and "Practice session" or "Loading record")
	if store then
		local ok,result=pcall(function() return store:GetAsync(tostring(p.UserId)) end)
		if profiles[p]~=r then return end
		if ok then r.data=clean(result) end
		p:SetAttribute("SaveState",ok and "Record loaded" or "Record pending sync")
		if not ok then r.revision+=1 end
	end
	sync(p,r)
	return r
end
function records.earn(p,coins,success,stampDay,punches,tourLevel)
	local r=profiles[p]
	if tourLevel then
		r.best=math.max(r.best or 0,tourLevel)
		r.data.terminal.TourBest=math.max(r.data.terminal.TourBest or 0,tourLevel)
	end
	local previous=cards(r.data)
	for _,key in punchKeys do
		if punches and punches[key] then
			r.data[key]+=1
			r.punches[key]+=1
		end
	end
	local bonus=15*(cards(r.data)-previous)
	r.coins+=coins
	r.data.Coins+=coins+bonus
	if success then r.shifts+=1; r.data.Shifts+=1 end
	if stampDay and stampDay>r.data.StampDay then
		r.days[tostring(stampDay)]=true
		r.data.stampDays[tostring(stampDay)]=true
		r.data.StampDay=stampDay
		r.data.Stamps+=1
	end
	r.revision+=1
	sync(p,r)
	return bonus
end
function records.equip(p,key,value)
	local r=profiles[p]
	r.data.preferences[key]={value=value,at=workspace:GetServerTimeNow()}
	r.revision+=1
	p:SetAttribute(key,value)
end
function records.mark(p,key)
	local r=profiles[p]
	if r.data[key] then return false end
	r.data[key]=true
	r.revision+=1
	sync(p,r)
	return true
end
local function flush(p,r,purchase,operation)
	if sandbox or r.busy or (r.saved==r.revision and not purchase and not operation) then return false end
	r.busy=true
	local result
	local rev,coins,shifts=r.revision,r.coins,r.shifts
	local days=table.clone(r.days)
	local punches=table.clone(r.punches)
	local best=r.best or 0
	local preferences=table.clone(r.data.preferences)
	local flags={RoofLetter=r.data.RoofLetter,MallLetter=r.data.MallLetter,Ending=r.data.Ending}
	local ok,out=pcall(function()
		return store:UpdateAsync(tostring(p.UserId),function(old)
			local data=clean(old)
			data.terminal.TourBest=math.max(data.terminal.TourBest or 0,best)
			local prior=data.sessions[r.id] or {coins=0,shifts=0}
			local completed=cards(data)
			for _,key in punchKeys do data[key]+=math.max(0,punches[key]-(prior[key] or 0)) end
			data.Coins+=15*(cards(data)-completed)
			data.Coins+=math.max(0,coins-prior.coins)
			if purchase and not data.wraps[purchase] and data.Coins>=prices[purchase] then
				data.Coins-=prices[purchase]
				data.wraps[purchase]=true
			end
			data.Shifts+=math.max(0,shifts-prior.shifts)
			for key in days do
				if not data.stampDays[key] then
					data.stampDays[key]=true
					data.StampDay=math.max(data.StampDay,tonumber(key))
					data.Stamps+=1
				end
			end
			for key,entry in preferences do
				local priorPref=data.preferences[key]
				if not priorPref or entry.at>priorPref.at then data.preferences[key]=entry end
			end
			for k,v in flags do if v then data[k]=true end end
			for id,receipt in data.sessions do
				if receipt.time and os.time()-receipt.time>7*86400 then data.sessions[id]=nil end
			end
			data.sessions[r.id]={coins=coins,shifts=shifts,time=os.time()}
			for _,key in punchKeys do data.sessions[r.id][key]=punches[key] end
			if operation then result=operation(data.terminal,data) end
			return data
		end)
	end)
	r.busy=false
	if ok and out then
		r.saved=rev
		r.data.terminal=out.terminal
		r.data.terminal.TourBest=math.max(r.data.terminal.TourBest or 0,r.best or 0)
		for _,key in punchKeys do r.data[key]=out[key]+r.punches[key]-punches[key] end
		r.data.wraps=out.wraps
		r.data.Coins=out.Coins+r.coins-coins+15*(cards(r.data)-cards(out))
		r.data.Shifts=out.Shifts+r.shifts-shifts
		r.data.Stamps=out.Stamps
		for key in r.days do
			if out.stampDays[key] then r.days[key]=nil else r.data.Stamps+=1 end
		end
		r.data.StampDay=math.max(out.StampDay,r.data.StampDay)
		for key in out.stampDays do r.data.stampDays[key]=true end
		for key,entry in out.preferences do
			local localPref=r.data.preferences[key]
			if not localPref or entry.at>localPref.at then r.data.preferences[key]=entry end
		end
		for _,k in {"RoofLetter","MallLetter","Ending"} do r.data[k]=r.data[k] or out[k] end
		if p.Parent then sync(p,r); p:SetAttribute("SaveState","Record saved") end
		return true,result
	elseif p.Parent then p:SetAttribute("SaveState","Save pending") end
	return false
end
function records.terminal(p,operation)
	local r=profiles[p]
	if not r or r.leaving or r.busy then return false end
	if sandbox then
		local result=operation(r.data.terminal,r.data)
		sync(p,r)
		return true,result
	end
	return flush(p,r,nil,operation)
end
function records.buy(p,wrap)
	local r=profiles[p]
	local cost=prices[wrap]
	if not r or not cost then return end
	if not r.data.wraps[wrap] then
		if r.data.Coins<cost then return "Need "..cost.." coins for this wrap." end
		if sandbox then
			r.data.Coins-=cost
			r.data.wraps[wrap]=true
			sync(p,r)
		elseif not flush(p,r,wrap) then
			return "Purchase pending verification. Try again in a moment."
		end
	end
	if r.data.wraps[wrap] and profiles[p]==r and not r.leaving then
		records.equip(p,"Skin",wrap)
		return wrap.." wrapping equipped."
	end
	return "Check your balance and try again."
end
function records.close(p)
	local r=profiles[p]
	if not r then return end
	r.leaving=true
	for _=1,6 do
		while r.busy do task.wait(.1) end
		flush(p,r)
		if sandbox or r.saved==r.revision then profiles[p]=nil; return end
		task.wait(1)
	end
end
task.spawn(function()
	while task.wait(10) do
		for p,r in profiles do
			if p.Parent and r.syncedDay and r.syncedDay~=math.floor(os.time()/86400) then syncPostmarks(p,r) end
			if r.leaving and not r.busy and r.saved==r.revision then profiles[p]=nil
			else task.spawn(flush,p,r) end
		end
	end
end)
game:BindToClose(function()
	if sandbox then return end
	local count=0
	for p in profiles do
		count+=1
		task.spawn(function() records.close(p); count-=1 end)
	end
	local limit=time()+26
	while count>0 and time()<limit do task.wait(.1) end
end)
return records

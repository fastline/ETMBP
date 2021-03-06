-- Reactor controller v2.0 ETMBP, Ede Teller must be proud project

bSide = "bottom"
wSide = "left"
mSide = "back"
reactorMon = "monitor_9"
turbineMon = "monitor_10"
terminalMon = "monitor_12"

function printArray(a)
	for i, v in pairs(a) do
		print(i, " ", v.id)
	end
end
-- Device class, mother of all
local Device = {}
Device.__index = Device

setmetatable(Device ,{
	__call = function (cls, ...)
	local self = setmetatable({}, cls)
	self:_init(...)
	return self
end,
})
function Device:_init (id, number, obj, category, shortName)
	self.id = id or "N/A"
	self.number = number or "N/A"
	self.obj = obj or "N/A"
	self.category = category or "N/A"
	self.shortName = shortName or "N/A"
end

function Device:getCategory()
	return self.category
end

--Reactor class from Device
local Reactor = {}
Reactor.__index = Reactor

setmetatable(Reactor, {
	__index = Device,
	__call = function(cls, ...)
	local self = setmetatable({}, cls)
	self:_init(...)
	return self
end,
})

function Reactor:_init(id)
	self.id = id or "N/A"
	self.obj = peripheral.wrap(self.id)
end

function Reactor:getConnected() 
	 return self.obj.getConnected()
end

function Reactor:getActive()
	return self.obj.getActive
end

function Reactor:setActive(online)
	self.obj.setActive(online)
end

function Reactor:getYelloriumTemp()
	return math.floor(self.obj.getFuelTemperature())
end

function Reactor:getRodSetting()
	return self.obj.getControlRodLevel(1)
end

function Reactor:setRodSetting(level)
	self.obj.setAllControlRodLevels(level)
end

function Reactor:getRadiation()
	return math.floor(self.obj.getFuelReactivity())
end

function Reactor:getSteamOutput()
	return math.floor(self.obj.getHotFluidProducedLastTick())
end

function Reactor:getYelloriumMax()
	return math.floor(self.obj.getFuelAmountMax())
end

function Reactor:getYelloriumLeft()
	return math.floor(self.obj.getFuelAmount())
end

function Reactor:getYelloriumConsumption()
	return self.obj.getFuelConsumedLastTick()
end

--Monitor class
local Monitor = {}
Monitor.__index = Monitor

setmetatable(Monitor, {
	__index = Device,
	__call = function(cls, ...)
	local self = setmetatable({}, cls)
	self:_init(...)
	return self
end,
})
function Monitor:_init(id)
	self.id = id or "N/A"
	self.obj = peripheral.wrap(self.id)
	self.tag = ""
end

function Monitor:getSize()
	return self.obj.getSize()
end

function Monitor:getPos()
	return self.obj.getCursorPos()
end

function Monitor:setPos(x, y)
	self.obj.setCursorPos(x, y)
end

function Monitor:setColor(color)
	self.obj.setTextColor(color)
end

function Monitor:setBGColor(color)
	self.obj.setBackgroundColor(color)
end

function Monitor:reset()
	self.obj.clear()
	self.obj.setCursorPos(1,1)
	self.obj.setTextScale(1)
	self.obj.setTextColor(colors.white)
	self.obj.setBackgroundColor(colors.black)
end

function Monitor:writeOut(what, putNewLine)
	self.putNewLine = putNewLine or false
	x, y = self:getPos()
	self.obj.write(what)
	if putNewLine then
		self:setPos(1, y+1)
	end
end

function Monitor:getTag()
	return self.tag
end

function Monitor:setTag(newTag)
	self.tag = newTag
end

function Monitor:tagMonitors()
		if (self.id == reactorMon) then
			self:setTag("reactor")
		elseif (self.id == turbineMon) then
			self:setTag("turbine")
		elseif (self.id == termMon) then
			self:setTag("terminal")
		end
end

-- Turbine Class
local Turbine = {}
Turbine.__index = Turbine

setmetatable(Turbine, {
	__index = Device,
	__call = function(cls, ...)
	local self = setmetatable({}, cls)
	self:_init(...)
	return self
end,
})
function Turbine:_init(id)
	self.id = id or "N/A"
	self.obj = peripheral.wrap(self.id)
end

function Turbine:getConnected()
	return self.obj.getConnected()
end

function Turbine:getActive()
	return self.obj.getActive()
end

function Turbine:setActive(online)
	self.obj.setActive(online)
end

function Turbine:getCoilActive()
	return self.obj.getInductorEngaged()
end

function Turbine:setCoilActive(online)
	self.obj.setInductorEngaged(online)
end

function Turbine:getRPM()
	return math.floor(self.obj.getRotorSpeed())
end

function Turbine:getSteamInput()
	return math.floor(self.obj.getInputAmount())
end

function Turbine:getRFGenerated()
	return math.floor(self.obj.getEnergyProducedLastTick())
end

function Turbine:setOffline()
	self:setActive(false)
	self:setCoilActive(false)
end

--Capacitor class
local Capacitor = {}
Capacitor.__index = Capacitor

setmetatable(Capacitor, {
	__index = Device,
	__call = function(cls, ...)
	local self = setmetatable({}, cls)
	self:_init(...)
	return self
end,
})
function Capacitor:_init(id, blockCount, blockStore)
	self.id = id or "N/A"
	self.obj = peripheral.wrap(self.id)
	self.blockCount = blockCount or 51
	self.blockStore = blockStore or 2500000
end

function Capacitor:getCapacity()
	return self.blockCount * self.blockStore
end

function Capacitor:getStored()
	return self.obj.getEnergyStored() * self.blockCount
end

function Capacitor.getPercent()
	return self:getStored() / (self:getCapacity() / 100)
end

function Capacitor:getFlow()
	before = self:getStored()
	sleep(0.1)
	return math.floor((self:getStored() - before) / 3)
end

--Controller class with some Vytutas mineral water
local Controller = {}
Controller.__index = Controller

setmetatable(Controller, {
	__call = function (cls, ...)
	local self = setmetatable({}, cls)
	self:_init(...)
	return self
end,
})
function Controller:_init(optimalRPM, optimalRodPercent, minTemp, maxTemp, minStoredPercent, maxStoredPercent, yelloriumEmitterLevel, controlledDevices, countByType, liveSettings)
	self.optimalRPM = optimalRPM or 1870
	self.optimalRodPercent = optimalRodPercent or 40
	self.minTemp = minTemp or 500
	self.maxTemp = maxTemp or 550
	self.minStoredPercent = minStoredPercent or 45
	self.maxStoredPercent = maxStoredPercent or 98
	self.yelloriumEmitterLevel = yelloriumEmitterLevel or 1000
	self.controlledDevices = controlledDevices or self:wrapAll()
	self.countByType = countByType or self:countTypes()
	self.liveSettings = liveSettings or { maintenanceByLever = false, maintenancebyPalm = false, maintenancebyYelloriumLevel = false, generate = false, forceOnLine = false }
end

function Controller:countTypes()
	countByType = { turbine = 0, reactor = 0, monitor = 0, capacitor = 0}
	for i, v in pairs(self.controlledDevices) do
		if v.category == "turbine" then countByType["turbine"] = countByType["turbine"] + 1
		elseif v.category == "monitor" then countByType["monitor"] = countByType["monitor"] + 1
		elseif v.category == "reactor" then countByType["reactor"] = countByType["reactor"] + 1
		elseif v.category == "capacitor" then countByType["capacitor"] = countByType["capacitor"] + 1 end
	end
	return countByType
end

function Controller:wrapAll()
	devicesList = peripheral.getNames()
	controlledDevices = {}
	for i, v in pairs(devicesList) do
		--Digsite
		if string.find(v, "-Reactor") then
			table.insert(controlledDevices, Reactor(v))
			controlledDevices[#controlledDevices].category = "reactor"
		elseif string.find(v, "Turbine") then
			table.insert(controlledDevices, Turbine(v))
			controlledDevices[#controlledDevices].category = "turbine"
		elseif string.find(v, "capacitor") then
			table.insert(controlledDevices, Capacitor(v))
			controlledDevices[#controlledDevices].category = "capacitor"
		elseif string.find(v, "monitor") then
			table.insert(controlledDevices, Monitor(v))
			controlledDevices[#controlledDevices].category = "monitor"
		end
	end
	return controlledDevices
end

function Controller:getCableActive(color)
	return colors.test(redstone.getBundledInput(bSide), color)
end

function Controller:getMaintenance()
	if self:getCableActive(colors.white) or self:getCableActive(colors.purple) or self.liveSettings["maintenancebyYelloriumLevel"] then return true
	else return false end
end

function Controller:setReactorOnline(state)
	for i, v in pairs(self.controlledDevices) do
		if v:getCategory() == "reactor" then v:setActive(state) end
	end
end

function Controller:setAllTurbineOnline(state)
	for i, v in pairs(self.controlledDevices) do
		if v:getCategory() == "turbine" then v:setActive(state) end
	end
end

--Regulate by Warren G
function Controller:regulate()
	generationCycle = false
	firstRun = true
	capacitorIndex = 0
	for i,v in pairs(controlledDevices) do
		if v.category == "capacitor" then
			capacitorIndex = i
		end
	end
	if self:getMaintenance() then
		self:setReactorOnline(false)
		self:setAllTurbineOnline(false)
		sleep(5)
	else
		if generationCycle then
			if firstRun then
				--Activate reactor
				--Set rod 0
				--set turbines online
				--wait 10
				--Set Coil online
				firstRun = false
			elseif controlledDevices[capacitorIndex]:getPercent() > self.maxStoredPercent then
				--stop generation
			end
		else
			if self.liveSettings["forceOnLine"] then
				--Activate reactor
				--Activate turbines
			else
				for i, v in pairs(controlledDevices) do
					if v.category == "turbine" then
						if v:getRPM() < self.optimalRPM then
							--activate turbine
						else
							--deactivate turbine
						end
					end
				end
				for i, v in pairs(controlledDevices) do
					if v.category == "turbine" then
						if v:getActive() then
							--Activate reactor
							break
						else
							--deactivate reactor
						end
					end
				end
			end
			for i, v in pairs(controlledDevices) do
				if v.category == "reactor" then
					if v:getActive() then
						if v:getYelloriumTemp() < self.minTemp then
							--Pull out rods by one
						elseif v:getYelloriumTemp() > maxTemp then
							--Push rods by one
						end
					end
				end
			end
		end
	end
end

function Controller:listenToPalm()
	rednet.open("left")
	id, msg = rednet.receive()
	if msg == keys.e then
		--Do things
	end
end

function Controller:getMonitors()
	monitors = {}
	for i, v in pairs(controlledDevices) do
		if (v:getCategory() == "monitor") then
			table.insert(monitors, v)
		end
	end
	return monitors
end

--View
local View = {}
View.__index = View

setmetatable(View ,{
	__call = function (cls, ...)
	local self = setmetatable({}, cls)
	self:_init(...)
	return self
end,
})
function View:_init(monitors)
	self.monitors = monitors
end

function View:selectMonitor(monTag)
	for i, v in pairs(self.monitors) do
		if (monTag == v.id) then
			return v
		end
	end
end

function View:printOut(monTag, text, newLine, color, bColor)
	mon = self:selectMonitor(monTag)
	col, row = mon:getPos()
	_, height = mon:getSize()
	if (height < row) and newLine then
		mon.obj.scroll(1)
		mon:setPos(col, height-1)
	end
	mon:setColor(color or colors.white)
	mon:setBGColor(bColor or colors.black)
	mon:writeOut(text, newLine)
	mon:setColor(colors.white)
	mon:setBGColor(colors.black)
end

function View:resetAllMonitor()
	for i, v in pairs(self.monitors) do
		v:reset()
	end
end

function View:listDevices(controller)
	for i, v in pairs(controller.controlledDevices) do
		if ((v:getCategory() == "reactor") or (v:getCategory() == "turbine")) then
			self:printOut(terminalMon, v.id)
			if v:getConnected() then
				self:printOut(terminalMon, " OK", true, colors.green)
			else
				self:printOut(terminalMon, " NOT OK", true, colors.red)
			end
		else
			self:printOut(terminalMon, v.id)
			if v.obj then
				self:printOut(terminalMon, " OK", true, colors.green)
			else
				self:printOut(terminalMon, " NOT OK", true, colors.red)
			end
		end
	end
end

function View:printCount(controller)
	for i, v in pairs(controller.countByType) do
		text = v.." "..i
		self:printOut(terminalMon, text, true)
	end
end

function View:postScreen(controller)
	self:printOut(terminalMon, "ETMBP Started", true)
	self:printOut(terminalMon, "Check for connected devices...", true)
	self:listDevices(controller)
	text = tostring(#controller.controlledDevices).." Device reached"
	self:printOut(terminalMon, text, true)
	self:printCount(controller)
end

function View:redirect(mon)
	target = vw:selectMonitor(mon)
	oldmon = term.redirect(target.obj)
	return oldmon
end

--Do the hardwork
print("Try to gather online devices")
c = Controller()
vw = View(c:getMonitors())
vw:resetAllMonitor()
vw:redirect(terminalMon)
vw:postScreen(c)
print("Ede Teller Must Be Proud!")

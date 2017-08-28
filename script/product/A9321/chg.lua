--[[
模块名称：chg
模块功能：充电模块处理函数
模块最后修改时间：2017.08.25
]]

require"sys"
module(...,package.seeall)

local inf = {}

--[[
函数名：proc
功能  ：充电消息处理
参数  ：上报消息
返回值：无
]]
local function proc(msg)
	if msg then	
		if msg.level == 255 then return end
		setcharger(msg.charger)
		--[[if inf.state ~= msg.state then
			inf.state = msg.state
			sys.dispatch("DEV_CHG_IND","CHG_STATUS",getstate())
		end]]
		
		inf.vol = msg.voltage
		
		inf.lev = msg.level
		local flag = (islowvolt() and getstate() ~= 1)
		if inf.low ~= flag then
			if (inf.low and (getstate()==1)) or flag then
				inf.low = flag
				sys.dispatch("DEV_CHG_IND","BAT_LOW",flag)
			end
			--[[inf.low = flag
			sys.dispatch("DEV_CHG_IND","BAT_LOW",flag)]]
		end		
		
		local flag = (islow1volt() and getstate() ~= 1)
		if inf.low1 ~= flag then
			if (inf.low1 and (getstate()==1)) or flag then
				inf.low1 = flag
				sys.dispatch("DEV_CHG_IND","BAT_LOW1",flag)
			end
		end	
		
		if inf.lev == 0 and not inf.chg then
			if not inf.poweroffing then
				inf.poweroffing = true
				sys.timer_start(rtos.poweroff,30000,"chg")
			end
		elseif inf.poweroffing then
			sys.timer_stop(rtos.poweroff,"chg")
			inf.poweroffing = false
		end
		print("chg proc",inf.chg,inf.lev,inf.vol,inf.state)
		sys.dispatch("DEV_VOLT_IND",inf.vol)
	end
end

--[[
函数名：init
功能  ：初始化
参数  ：无
返回值：无
]]
local function init()
	inf.vol = 0
	inf.lev = 0
	inf.chg = false
	inf.state = false
	inf.poweroffing = false
	inf.lowvol = 3600
	inf.low = false
	inf.low1vol = _G.LOWVOLT_FLY
	inf.low1 = false
	
	local para = {}
	para.batdetectEnable = 0
	para.currentFirst = 300
	para.currentSecond = 100
	para.currentThird = 50
	para.intervaltimeFirst = 180
	para.intervaltimeSecond = 60
	para.intervaltimeThird = 30
	para.battlevelFirst = 4100
	para.battlevelSecond = 4150
	para.pluschgctlEnable = 1
	para.pluschgonTime = 5
	para.pluschgoffTime = 1
	pmd.init(para)
end

function getcharger()
	return inf.chg
end

function setcharger(f)
	if inf.chg ~= f then
		inf.chg = f
		sys.dispatch("DEV_CHG_IND","CHARGER",f)
	end
end

function getvolt()
	return inf.vol
end

function getlev()
	if inf.lev == 255 then inf.lev = 95 end
	return inf.lev
end

function getstate()
	return inf.state
end

function islow()
	return false --inf.low
end

function islow1()
	return false --inf.low1
end

function islowvolt()
	return inf.vol<=inf.lowvol
end

function islow1volt()
	return inf.vol<=inf.low1vol
end

function stateind(data)
	print("state ind",data)
	if inf.state ~= data then
		inf.state = data
		sys.dispatch("DEV_CHG_IND","CHG_STATUS",getstate())
	end
end

--注册消息的处理函数
sys.regmsg(rtos.MSG_PMD,proc)
init()
nvm.init("config.lua")

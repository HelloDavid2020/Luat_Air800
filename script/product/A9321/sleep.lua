--[[
模块名称：sleep
模块功能：休眠处理
模块最后修改时间：2017.08.25
]]

module(...,package.seeall)

local function print(...)
	_G.print("sleep",...)
end

--[[
函数名：wake
功能  ：唤醒GPS
参数  ：
		s:true唤醒
返回值：无
]]
local function wake(s)
	print("wake",s,nvm.get("workmod"))
	if nvm.get("workmod")~="LONGPS" or s then
		nvm.set("gpsleep",false)
	end
end

--[[
函数名：parachangeind
功能  ：模式切换处理
参数  ：nvm.set参数
返回值：true
]]
local function parachangeind(k,v,r)	
	print("parachangeind",k)
	if k == "workmod" then
		wake(true)
	end
	return true
end

local function atguard()
	nvm.set("guard",true,"auto")	
end

--[[
函数名：gpsleep
功能  ：gpsleep就让GPS休眠状态
参数  ：无
返回值：无
]]
local function gpsleep()
	print("gpsleep",nvm.get("workmod"))
	if nvm.get("workmod")=="LONGPS" then return end
	nvm.set("gpsleep",true,"gps")
	if nvm.get("autoguard") then
		sys.timer_start(atguard,900*1000)
	end
end

--[[
函数名：shkind
功能  ：GPSMOD_WAKE_NOSHK_SLEEP_FREQ秒无震动进入GPS休眠模式
参数  ：无
返回值：true
]]
local function shkind()
	print("shkind")
	sys.timer_start(gpsleep,_G.GPSMOD_WAKE_NOSHK_SLEEP_FREQ*1000)
	return true
end

--[[
函数名：wakegps
功能  ：满足震动条件进入GPS模式
参数  ：无
返回值：无
]]
local function wakegps()
	print("wakegps",nvm.get("workmod"))
	if nvm.get("workmod")=="GPS" then
		print("wakegps")
		nvm.set("gpsleep",false)
		sys.timer_stop(atguard)
	end
end

local function gpsmodopnshk()
	print("gpsmodopnshk",chg.islow(),chg.islow1())
	if chg.islow1() then return true end
	if nvm.get("workmod")=="GPS" and not chg.islow() then
		wakegps()
	end
	return true
end

--[[
函数名：Blowpwoff
功能  ：低电关机
参数  ：无
返回值：无
]]
local function Blowpwoff()
	sys.poweroff()
end 

local function chgind(e,val)
	print("chgind",e,val)
	if e == "BAT_LOW1" then
		if val then 
			nvm.set("powerofflg",1)
			sys.dispatch("SLEEP_OR_POWEROFF_REQ","BLOW")
			sys.timer_start(Blowpwoff,3000)
			return
		else
			sys.timer_stop(Blowpwoff)	
		end
	end
	if e=="CHG_STATUS" then return true end
	return true
end

local procer = {
	DEV_SHK_IND = shkind,
	GPSMOD_OPN_GPS_VALIDSHK_IND = gpsmodopnshk,
	DEV_CHG_IND = chgind,
	PARA_CHANGED_IND = parachangeind,
}
--注册消息的处理函数
sys.regapp(procer)
nvm.set("gpsleep",false)

--[[
模块名称：gpsmng
模块功能：GPS打开关闭控制
模块最后修改时间：2017.08.25
]]

require"pincfg"
require"agpsupgpd"
module(...,package.seeall)

--[[
函数名：print
功能  ：打印接口，此文件中的所有打印都会加上gpsmng前缀
参数  ：无
返回值：无
]]
local function print(...)
	_G.print("gpsmng",...)
end

--[[
函数名：gpsopen
功能  ：打开GPS,val秒到关闭GPS
参数  ：无
返回值：true
]]
local function gpsopen()
	gps.open(gps.TIMER,{cause="GPSMOD",val=_G.GPSMOD_CLOSE_GPS_INVALIDSHK_FREQ+5})
	return true
end

--[[
函数名：gpsclose
功能  ：关闭GPS
参数  ：无
返回值：无
]]
local function gpsclose()
	gps.closegps("gpsapp")	
end

--[[
函数名：shkind
功能  ：震动中断消息处理
参数  ：无
返回值：true
]]
local function shkind()
	print("shkind",gps.isactive(gps.TIMER,{cause="GPSMOD"}))
	if gps.isactive(gps.TIMER,{cause="GPSMOD"}) then
		gps.open(gps.TIMER,{cause="GPSMOD",val=_G.GPSMOD_CLOSE_GPS_INVALIDSHK_FREQ+5})
	end
	return true
end

--[[
函数名：Extlonggps
功能  ：退出LONGPS模式
参数  ：无
返回值：无
]]
local function Extlonggps()
	print("Extlonggps")
	if nvm.get("workmod")=="LONGPS" then
		nvm.set("workmod","GPS","EXTLGPS")	
	end
end

--[[
函数名：opnlongps
功能  ：GPS一直打开
参数  ：无
返回值：无
]]
local function opnlongps()
	print("opnlongps")
	sys.timer_start(Extlonggps,7200000)
	gps.open(gps.DEFAULT,{cause="LONGPSMOD"})
end

--[[
函数名：clslongps
功能  ：GPS一直打开
参数  ：无
返回值：无
]]
local function clslongps()
	print("clslongps")
	gps.close(gps.DEFAULT,{cause="LONGPSMOD"})
end

--[[
函数名：workmodind
功能  ：工作模式切换处理
参数  ：工作模式
返回值：无
]]
local function workmodind(s)
	if nvm.get("workmod") ~= "GPS" then
		gpsclose()
		if nvm.get("workmod") == "LONGPS" then
			opnlongps()
		else
			clslongps()
		end
	else
		if s then gpsopen() end
		clslongps()
	end
end

--[[
函数名：accind
功能  ：acc状态处理
参数  ：acc状态
返回值：无
]]
local function accind(on)
	print("accind on",on)
	if on then
		gps.open(gps.DEFAULT,{cause="ACC"})
	else
		gps.close(gps.DEFAULT,{cause="ACC"})
	end		
	return true
end

local function parachangeind(k,v,r)	
	if k == "workmod" then
		workmodind(true)
	end
	return true
end

local procer =
{
	GPSMOD_OPN_GPS_VALIDSHK_IND = gpsopen,
	PARA_CHANGED_IND = parachangeind,
	[gps.GPS_STATE_IND] = gpstaind,
	DEV_SHK_IND = shkind,
	DEV_ACC_IND = accind,
}

--注册消息的处理函数
sys.regapp(procer)

--gps初始化
gps.init(nil,nil,true,1000,2,115200,8,uart.PAR_NONE,uart.STOP_1)
gps.setgpsfilter(1)
gps.settimezone(gps.GPS_BEIJING_TIME)
rtos.sys32k_clk_out(1);

gpsopen()
accind(acc.getflag())

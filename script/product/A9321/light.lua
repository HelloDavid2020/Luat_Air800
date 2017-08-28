--[[
模块名称：light
模块功能：GPS指示灯控制
模块最后修改时间：2017.08.25
]]

module(...,package.seeall)

local ONTIME,OFFTIME = 1000,1000

-- 0:常灭 1:常亮 2:闪烁
local ledgps,ledgsm = 0,0

--[[
函数名：gprsready
功能  ：根据gprs上报的消息控制gsm灯状态
参数  ：gprs状态
返回值：无
]]
local function gprsready(suc)
	ledgsm = suc and 1 or 2
end

--[[
函数名：netmsg
功能  ：根据网络状态控制gsm灯状态
参数  ：网络状态
返回值：true
]]
local function netmsg(id,data)
	ledgsm = (data == "REGISTERED") and 2 or 0
	return true
end

--[[
函数名：gpstateind
功能  ：根据GPS上报的消息控制GPS灯状态
参数  ：无
返回值：true
]]
local function gpstateind(evt)
	if evt == gps.GPS_LOCATION_SUC_EVT then
		ledgps = 1
	elseif evt == gps.GPS_OPEN_EVT or evt == gps.GPS_LOCATION_FAIL_EVT then
		ledgps = 2
	elseif evt == gps.GPS_CLOSE_EVT then
		ledgps = 0
	end
	return true
end

local procer = {
	NET_GPRS_READY = gprsready,
	[gps.GPS_STATE_IND] = gpstateind,
}
--注册消息的处理函数
sys.regapp(procer)

--[[
函数名：set
功能  ：根据灯的状态设置对应的PIN脚值
参数  ：无
返回值：无
]]
local function set(pin,mode,val)
	if mode == 0 then
		pins.set(false,pin)
	elseif mode == 1 then
		pins.set(true,pin)
	elseif mode == 2 then
		pins.set(val,pin)
	end
end

--[[
函数名：blinkoff
功能  ：控制灯为关闭状态
参数  ：无
返回值：无
]]
local function blinkoff()
	--set(pincfg.LED_GSM,ledgsm,false)
	set(pincfg.LED_GPS,ledgps,false)

	sys.timer_start(blinkon,OFFTIME)
end

--[[
函数名：blinkon
功能  ：控制灯为打开状态
参数  ：无
返回值：无
]]
function blinkon()
	--set(pincfg.LED_GSM,ledgsm,true)
	set(pincfg.LED_GPS,ledgps,true)

	sys.timer_start(blinkoff,ONTIME)
end

sys.timer_start(blinkon,OFFTIME)
--注册消息的处理函数
sys.regapp(netmsg,"NET_STATE_CHANGED")

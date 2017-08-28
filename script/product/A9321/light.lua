--[[
ģ�����ƣ�light
ģ�鹦�ܣ�GPSָʾ�ƿ���
ģ������޸�ʱ�䣺2017.08.25
]]

module(...,package.seeall)

local ONTIME,OFFTIME = 1000,1000

-- 0:���� 1:���� 2:��˸
local ledgps,ledgsm = 0,0

--[[
��������gprsready
����  ������gprs�ϱ�����Ϣ����gsm��״̬
����  ��gprs״̬
����ֵ����
]]
local function gprsready(suc)
	ledgsm = suc and 1 or 2
end

--[[
��������netmsg
����  ����������״̬����gsm��״̬
����  ������״̬
����ֵ��true
]]
local function netmsg(id,data)
	ledgsm = (data == "REGISTERED") and 2 or 0
	return true
end

--[[
��������gpstateind
����  ������GPS�ϱ�����Ϣ����GPS��״̬
����  ����
����ֵ��true
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
--ע����Ϣ�Ĵ�����
sys.regapp(procer)

--[[
��������set
����  �����ݵƵ�״̬���ö�Ӧ��PIN��ֵ
����  ����
����ֵ����
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
��������blinkoff
����  �����Ƶ�Ϊ�ر�״̬
����  ����
����ֵ����
]]
local function blinkoff()
	--set(pincfg.LED_GSM,ledgsm,false)
	set(pincfg.LED_GPS,ledgps,false)

	sys.timer_start(blinkon,OFFTIME)
end

--[[
��������blinkon
����  �����Ƶ�Ϊ��״̬
����  ����
����ֵ����
]]
function blinkon()
	--set(pincfg.LED_GSM,ledgsm,true)
	set(pincfg.LED_GPS,ledgps,true)

	sys.timer_start(blinkoff,ONTIME)
end

sys.timer_start(blinkon,OFFTIME)
--ע����Ϣ�Ĵ�����
sys.regapp(netmsg,"NET_STATE_CHANGED")

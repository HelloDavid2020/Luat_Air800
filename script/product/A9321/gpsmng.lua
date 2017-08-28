--[[
ģ�����ƣ�gpsmng
ģ�鹦�ܣ�GPS�򿪹رտ���
ģ������޸�ʱ�䣺2017.08.25
]]

require"pincfg"
require"agpsupgpd"
module(...,package.seeall)

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������gpsmngǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("gpsmng",...)
end

--[[
��������gpsopen
����  ����GPS,val�뵽�ر�GPS
����  ����
����ֵ��true
]]
local function gpsopen()
	gps.open(gps.TIMER,{cause="GPSMOD",val=_G.GPSMOD_CLOSE_GPS_INVALIDSHK_FREQ+5})
	return true
end

--[[
��������gpsclose
����  ���ر�GPS
����  ����
����ֵ����
]]
local function gpsclose()
	gps.closegps("gpsapp")	
end

--[[
��������shkind
����  �����ж���Ϣ����
����  ����
����ֵ��true
]]
local function shkind()
	print("shkind",gps.isactive(gps.TIMER,{cause="GPSMOD"}))
	if gps.isactive(gps.TIMER,{cause="GPSMOD"}) then
		gps.open(gps.TIMER,{cause="GPSMOD",val=_G.GPSMOD_CLOSE_GPS_INVALIDSHK_FREQ+5})
	end
	return true
end

--[[
��������Extlonggps
����  ���˳�LONGPSģʽ
����  ����
����ֵ����
]]
local function Extlonggps()
	print("Extlonggps")
	if nvm.get("workmod")=="LONGPS" then
		nvm.set("workmod","GPS","EXTLGPS")	
	end
end

--[[
��������opnlongps
����  ��GPSһֱ��
����  ����
����ֵ����
]]
local function opnlongps()
	print("opnlongps")
	sys.timer_start(Extlonggps,7200000)
	gps.open(gps.DEFAULT,{cause="LONGPSMOD"})
end

--[[
��������clslongps
����  ��GPSһֱ��
����  ����
����ֵ����
]]
local function clslongps()
	print("clslongps")
	gps.close(gps.DEFAULT,{cause="LONGPSMOD"})
end

--[[
��������workmodind
����  ������ģʽ�л�����
����  ������ģʽ
����ֵ����
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
��������accind
����  ��acc״̬����
����  ��acc״̬
����ֵ����
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

--ע����Ϣ�Ĵ�����
sys.regapp(procer)

--gps��ʼ��
gps.init(nil,nil,true,1000,2,115200,8,uart.PAR_NONE,uart.STOP_1)
gps.setgpsfilter(1)
gps.settimezone(gps.GPS_BEIJING_TIME)
rtos.sys32k_clk_out(1);

gpsopen()
accind(acc.getflag())

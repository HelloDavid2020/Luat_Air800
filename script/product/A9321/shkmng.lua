--[[
模块名称：shkmng
模块功能：震动传感器中断处理
模块最后修改时间：2017.08.25
]]
module(...,package.seeall)

local function print(...)
	_G.print("shkmng",...)
end

local tick = 0

--[[
函数名：timerfnc
功能  ：1S中定时回调函数
参数  ：无
返回值：无
]]
local function timerfnc()
	tick = tick+1
end

local tshkapp = 
{
	["GPSMOD_OPN_GPS"] = {flg={},idx=0,cnt=_G.GPSMOD_OPN_GPS_VALIDSHK_CNT,freq=_G.GPSMOD_OPN_GPS_VALIDSHK_FREQ},
	["LONGPSMOD"] = {flg={},idx=0,cnt=_G.LONGPSMOD_VALIDSHK_CNT,freq=_G.LONGPSMOD_VALIDSHK_FREQ},
	["SHKCNT"] = {flg={},idx=0,cnt=_G.SHKCNT_VALIDSHK_CNT,freq=_G.SHKCNT_VALIDSHK_FREQ},
}

local function reset(name)
	local i
	for i=1,tshkapp[name].cnt do
		tshkapp[name].flg[i] = 0
	end
	tshkapp[name].idx = 0
end

local function shkprint(name,suffix)
	local str,i = ""	
	for i=1,tshkapp[name].cnt do
		str = str..","..tshkapp[name].flg[i]
	end
	print("shkprint fnc",name..suffix,str)
end

--[[
函数名：fnc
功能  ：根据震动条件判断是否满足正当要求，然后抛出相应消息
参数  ：无
返回值：无
]]
local function fnc()
	local k,v
	for k,v in pairs(tshkapp) do
		shkprint(k,"1")
		--print("fnc",k,v.idx,v.cnt,tick,v.flg[v.idx],v.freq)
		if v.idx==0 then
			v.flg[1] = tick
			v.idx = 1
		elseif v.idx<v.cnt then
			if ((tick-v.flg[v.idx])>v.freq) and ((tick-v.flg[v.idx])<(v.freq*2)) then
				v.idx = v.idx+1
				if v.idx==v.cnt then
					v.idx = 1
					v.flg[v.cnt-1] = tick
					sys.dispatch(k.."_VALIDSHK_IND")
					print(k.."_VALIDSHK_IND")
				else
					v.flg[v.idx] = tick
				end
			elseif (tick-v.flg[v.idx])>=(v.freq*2) then
				reset(k)
			end
		end
		shkprint(k,"2")
	end	
end

local function shkind()
	--print("shkind fnc")
	fnc()
	return true
end

local function init()
	local k,v
	for k,v in pairs(tshkapp) do
		reset(k)
	end
end

init()
--注册消息的处理函数
sys.regapp(shkind,"DEV_SHK_IND")
sys.timer_loop_start(timerfnc,1000)

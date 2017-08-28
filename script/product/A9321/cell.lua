--[[
模块名称：cell
模块功能：cell是否满足上报条件
模块最后修改时间：2017.08.25
]]

module(...,package.seeall)

local shkflg,lastlbs

local function print(...)
	_G.print("cell",...)
end

--[[
函数名：move
功能  ：cell是否满足上报条件
参数  ：无
返回值：true 或 false
]]
function move()
	if not shkflg then return end
	shkflg = nil
	if not lastlbs or lastlbs=="" then return true end
	local cur = net.getcellinfoext()
	local oldcnt,newcnt,subcnt,chngcnt,laci = 0,0,0,0
	
	for laci in string.gmatch(lastlbs,"(%d+%.%d+%.%d+%.%d+%.)%d+;") do
		oldcnt = oldcnt + 1
	end
	
	for laci in string.gmatch(cur,"(%d+%.%d+%.%d+%.%d+%.)%d+;") do
		newcnt = newcnt + 1
		if not string.match(lastlbs,laci) then chngcnt = chngcnt + 1 end
	end
	
	if chngcnt==0 and newcnt<=oldcnt then return false end
	
	if oldcnt > newcnt then chngcnt = chngcnt + (oldcnt-newcnt) end
	local mv = chngcnt*100/(newcnt>oldcnt and newcnt or oldcnt)
	print("move",lastlbs,cur,mv)
	return mv >= 80
end

local function shkind()
	shkflg = true
	return true
end

local function lbslocrpt(v)
	lastlbs = v
end


local procer =
{
	GSENSOR_SHK_IND = shkind,
	LBS_LOC_RPT = lbslocrpt,
}
--注册消息的处理函数
sys.regapp(procer)

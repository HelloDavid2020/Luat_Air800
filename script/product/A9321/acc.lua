--[[
模块名称：ACC
模块功能：ACC检测
模块最后修改时间：2017.08.25
]]

module(...,package.seeall)

local rstcnt = 0

local function clrrst()
	rstcnt = 0
end

--[[
函数名：ind
功能  ：ACC中断处理
参数  ：中断回调返回值
返回值：无
]]
function ind(data)
	print("acc ind",data)

	if rstcnt == 0 then
		sys.timer_start(clrrst,10000)
	end
	rstcnt = rstcnt + 1
	if rstcnt >= 5 then dbg.restart("ACC") end

	sys.dispatch("DEV_ACC_IND",data)
end

--[[
函数名：getflag
功能  ：获取ACC管脚值，如果为高电平，则返回false；如果为低电平，则返回true
参数  ：无
返回值：无
]]
function getflag()
	return pins.get(pincfg.ACC) or false
end

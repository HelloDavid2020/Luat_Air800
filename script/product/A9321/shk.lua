--[[
模块名称：shk
模块功能：震动传感器中断处理
模块最后修改时间：2017.08.25
]]
module(...,package.seeall)

--[[
函数名：ind
功能  ：震动传感器中断处理
参数  ：中断回调返回值
返回值：无
]]
function ind(data)
	print("shk.ind",data)
	if not data then  --下降沿中断
		print("shk.ind DEV_SHK_IND")
		sys.dispatch("DEV_SHK_IND")
	end
end

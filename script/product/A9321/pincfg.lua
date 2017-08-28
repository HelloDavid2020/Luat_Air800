--[[
模块名称：pincfg
模块功能：pin脚配置
模块最后修改时间：2017.08.25
]]

require"pins"
module(...,package.seeall)

--LED_GSM = {pin=pio.P0_28} --网络指示灯 高有效
LED_GPS = {pin=pio.P0_2} --GPS 指示灯 高有效

CHG_STATUS = {pin=pio.P0_0,dir=pio.INT,valid=0,chg.stateind} --充电状态检测 低有效，检测充电芯片是否在充电
CHARGER = {pin=pio.P0_3,dir=pio.INPUT,valid=1} --外电检测 高有效，检测充电芯片是否在充电

ACC = {pin=pio.P0_10,dir=pio.INT,valid=0,intcb=acc.ind} --ACC检测 低有效，检测是否点火状态

EXT1 = {pin=pio.P0_13,dir=pio.INPUT,valid=0} --预留的外部IO 1
EXT2 = {pin=pio.P0_9,dir=pio.INPUT,valid=0} --预留的外部IO 2

GSENSOR = {pin=pio.P1_2,dir=pio.INT,valid=1,intcb=shk.ind} --高有效，来自机械振动传感器的中断

--注册PIN脚的配置，并且初始化PIN脚
pins.reg(LED_GPS,CHG_STATUS,CHARGER,ACC,EXT1,EXT2,GSENSOR)

chg.stateind(pins.get(CHG_STATUS))

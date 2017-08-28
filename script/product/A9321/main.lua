--必须在这个位置定义PROJECT和VERSION变量
--PROJECT：ascii string类型，可以随便定义，只要不使用,就行
--VERSION：ascii string类型，如果使用Luat物联云平台固件升级的功能，必须按照"X.X.X"定义，X表示1位数字；否则可随便定义
PROJECT = "A9321"
VERSION = "1.0.0"
PRJID = 24
UPDMODE = 0
PRODUCT_KEY = "2PrHMHkwK4EEwO4ahttzfLLRAvKQioUN"
GKFR_NAME = "GK_9501"
GKVERSION = "1.0.0"
LONGPSMOD_DFT_HEART = 1800
LONGPSMOD_DFT_RPTFREQ = 5
LONGPSMOD_VALIDSHK_CNT = 3
LONGPSMOD_VALIDSHK_FREQ = 10
SHKCNT_VALIDSHK_CNT = 2
SHKCNT_VALIDSHK_FREQ = 10
GPSMOD_DFT_HEART = 900
GPSMOD_DFT_RPTFREQ = 10
GPSMOD_NOGPS_HEART = 900
GPSMOD_NOGPS_RPTFREQ = 3600*2
GPSMOD_OPN_GPS_VALIDSHK_CNT = 3
GPSMOD_OPN_GPS_VALIDSHK_FREQ = 10
GPSMOD_CLOSE_GPS_INVALIDSHK_FREQ = 120
GPSMOD_WAKE_NOSHK_SLEEP_FREQ = 300
PWRMOD_DFT_HEART = 7200
PWRMOD_DFT_RPTFREQ = 1200
LOWVOLT_FLY = 3500 --单位MV
_G.collectgarbage("setpause",90)
function appendprj(suffix)
	PROJECT = PROJECT .. suffix
end
require"sys"
require"config"
require"nvm"
require"pins"
require"chg"
require"link"
require"update"
require"gps"
require"shk"
require"acc"
require"adcv"
require"pincfg"
require"light"
require"agps"
require"dbg"
require"cell"
require"shkmng"
require"mqtt"
require"linkair"
require"wdt1"
require"sleep"
require"manage"
require"gpsmng"

--[[
如果使用UART输出trace，打开这行注释的代码"--sys.opntrace(true,1)"即可，第2个参数1表示UART1输出trace，根据自己的需要修改这个参数
这里是最早可以设置trace口的地方，代码写在这里可以保证UART口尽可能的输出“开机就出现的错误信息”
如果写在后面的其他位置，很有可能无法输出错误信息，从而增加调试难度
]]
--sys.opntrace(true,1)

sys.init(0,0)
--ril.request("AT*EXASSERT=1")
sys.run()

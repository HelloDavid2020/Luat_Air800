--���������λ�ö���PROJECT��VERSION����
--PROJECT��ascii string���ͣ�������㶨�壬ֻҪ��ʹ��,����
--VERSION��ascii string���ͣ����ʹ��Luat������ƽ̨�̼������Ĺ��ܣ����밴��"X.X.X"���壬X��ʾ1λ���֣��������㶨��
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
LOWVOLT_FLY = 3500 --��λMV
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
���ʹ��UART���trace��������ע�͵Ĵ���"--sys.opntrace(true,1)"���ɣ���2������1��ʾUART1���trace�������Լ�����Ҫ�޸��������
�����������������trace�ڵĵط�������д��������Ա�֤UART�ھ����ܵ�����������ͳ��ֵĴ�����Ϣ��
���д�ں��������λ�ã����п����޷����������Ϣ���Ӷ����ӵ����Ѷ�
]]
--sys.opntrace(true,1)

sys.init(0,0)
--ril.request("AT*EXASSERT=1")
sys.run()

--[[
模块名称：SSD 1306驱动芯片命令配置
模块功能：初始化芯片命令
模块最后修改时间：2017.08.08
]]

--[[
disp库目前仅支持SPI接口的屏，硬件连线图如下：
Air800模块				LCD
GND---------------------地
GPIO10/SPI1_CS----------片选
GPIO8/SPI1_CLK----------时钟
GPIO11/SPI1_DO----------数据
GPIO34------------------数据/命令选择
VDDIO-------------------电源
GPIO9-------------------复位
]]

module(...,package.seeall)

--[[
函数名：init
功能  ：初始化LCD参数
参数  ：无
返回值：无
]]
local function init()
	local para =
	{
		width = 128, --分辨率宽度，128像素；用户根据屏的参数自行修改
		height = 64, --分辨率高度，64像素；用户根据屏的参数自行修改
		bpp = 1, --位深度，1表示单色。单色屏就设置为1，不可修改
		bus = disp.BUS_SPI, --led位标准SPI接口，不可修改
		hwfillcolor = 0xFFFF, --填充色，黑色
		pinrst = pio.P0_9, --reset，复位引脚
		pinrs = pio.P1_2, --rs，命令/数据选择引脚
		--初始化命令
		initcmd =
		{
			0xAE, --display off
			0x20, --Set Memory Addressing Mode	
			0x10, --00,Horizontal Addressing Mode;01,Vertical Addressing Mode;10,Page Addressing Mode (RESET);11,Invalid
			0xb0, --Set Page Start Address for Page Addressing Mode,0-7
			0xc8, --Set COM Output Scan Direction
			0x00, ---set low column address
			0x10, ---set high column address
			0x40, --set start line address
			0x81, --set contrast control register
			0xdf, --
			0xa1, --set segment re-map 0 to 127
			0xa6, --set normal display
			0xa8, --set multiplex ratio(1 to 64)
			0x3f, --
			0xa4, --0xa4,Output follows RAM content;0xa5,Output ignores RAM content
			0xd3, --set display offset
			0x20, --not offset
			0xd5, --set display clock divide ratio/oscillator frequency
			0xf0, --set divide ratio
			0xd9, --set pre-charge period
			0x22, --
			0xda, --set com pins hardware configuration
			0x12, --
			0xdb, --set vcomh
			0x20, --0x20,0.77xVcc
			0x8d, --set DC-DC enable
			0x14, --
			0xaf, --turn on oled panel 
		},
		--休眠命令
		sleepcmd = {
			0xAE,
		},
		--唤醒命令
		wakecmd = {
			0xAF,
		}
	}
	disp.init(para)
	disp.clear()
	disp.update()
end

--控制SPI引脚的电压域
pmd.ldoset(6,pmd.LDO_VMMC)
init()

from migen import *
from migen.build.generic_platform import *
from migen.build.xilinx import XilinxPlatform
from litex.soc.interconnect.csr import *


class Color_read(Module, AutoCSR):
    def __init__(self, pads, clk=ClockSignal()):
#        self.rst = Signal()
        self.clk = clk
#        self.prescale = CSRStorage(16)
 #       self.control = CSRStorage(8)
 #       self.transmit = CSRStorage(8)
 #       self.receive = CSRStorage(8)
 #       self.command = CSRStorage(8)
 #       self.error=CSRStatus(1)
 #       self.init=CSRStorage(1)
        self.done=CSRStatus(1)
        self.dataout=CSRStatus(8)
        self.addrout=CSRStorage(16)
        self.switch=CSRStatus(1)
        ##Instancia
        self.specials += [Instance("test_cam",
                                   i_clk=self.clk,
                                   i_rst=pads.rst,
    #                          i_prescale=self.prescale.storage,
    #                               i_control=self.control.storage,
    #                               i_transmit=self.transmit.storage,
    #                               o_receive=self.receive.storage,
    #                               i_command=self.command.storage,
                                   o_Done=self.done.status,
                                   o_data_mem=self.dataout.status,
                                   i_addr_SoC=self.addrout.storage,
                                   #o_error=self.error.status,
                                   i_init=pads.init,
                                    o_switch = self.switch.status,
    #                              io_scl=pads.scl,
    #                             io_sda=pads.sda,
                                   o_CAM_xclk=pads.CAM_xclk,
                                   o_CAM_pwdn=pads.CAM_pwdn,
                                   o_CAM_reset=pads.CAM_reset,
                                   i_CAM_pclk=pads.CAM_pclk,
                                   i_CAM_vsync=pads.CAM_vsync,
                                   i_CAM_href=pads.CAM_href,
                                   i_CAM_px_data_0=pads.Cam_px_data_0,
                                   i_CAM_px_data_1=pads.Cam_px_data_1,
                                   i_CAM_px_data_2=pads.Cam_px_data_2,
                                   i_CAM_px_data_3=pads.Cam_px_data_3,
                                   i_CAM_px_data_4=pads.Cam_px_data_4,
                                   i_CAM_px_data_5=pads.Cam_px_data_5,
                                   i_CAM_px_data_6=pads.Cam_px_data_6,
                                   i_CAM_px_data_7=pads.Cam_px_data_7,
                                   o_led =pads.led,
                                   i_sw =pads.sw
                                   
                                   )]


def _test(dut):
    yield dut.rst.eq(0)
    yield
    yield
    yield dut.rst.eq(1)

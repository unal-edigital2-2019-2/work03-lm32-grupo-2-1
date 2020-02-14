#!/usr/bin/python3

from migen import *
from migen.build.generic_platform import *
from migen.build.xilinx import XilinxPlatform
from litex.soc.interconnect.csr import *


class CAM_Master(Module, AutoCSR):
    def __init__(self, pads, clk=ClockSignal()):
        self.rst =Signal()
        self.clk =clk
        self.init=CSRStorage(8)
        self.done=CSRStatus(8)
        self.result=CSRStatus(8)
        ##Instancia
        self.specials += [Instance("test_cam",
                                   i_clk=self.clk,
                                   i_rst=self.rst,
    #                          
                                   o_done=self.done.status,
                                   o_result=self.result.status,
                                   i_init=self.init.storage,
    #                
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
                                   i_CAM_px_data_7=pads.Cam_px_data_7
                        
                                   
                                   )]


def _test(dut):
    yield dut.rst.eq(0)
    yield
    yield
    yield dut.rst.eq(1)


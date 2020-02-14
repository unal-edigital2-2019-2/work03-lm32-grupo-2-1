from abc import ABC

from migen import *

from migen.genlib.io import CRG

from litex.build.generic_platform import *
from litex.build.xilinx import XilinxPlatform

import litex.soc.integration.soc_core as SC
from litex.soc.integration.builder import *

from CAMMaster import CAM_Master
#from Color_read import Color_read
#
# platform
#

_io = [

    ("clk32", 0, Pins("E3"), IOStandard("LVCMOS33")),

    ("cpu_reset", 0, Pins("C12"), IOStandard("LVCMOS33")),

  ("serial", 0,
    Subsignal("tx", Pins("D4")),
    Subsignal("rx", Pins("C4")),
     IOStandard("LVCMOS33"),
     ),

#   ("color_read", 0,
#    Subsignal("scl", Pins("P29")),
#    Subsignal("sda", Pins("P30")),
#   IOStandard("LVCMOS33")
#     ),
    ("cam_master", 0,
     Subsignal("CAM_pclk", Pins("P15")),
     Subsignal("CAM_href", Pins("G14")),
     Subsignal("CAM_vsync", Pins("V11")),
     Subsignal("CAM_xclk", Pins("V15")),
     Subsignal("CAM_pwdn", Pins("K16")),
     Subsignal("CAM_reset", Pins("R16")),
     Subsignal("Cam_px_data_0", Pins("B13")),
     Subsignal("Cam_px_data_1", Pins("F14")),
     Subsignal("Cam_px_data_2", Pins("D17")),
     Subsignal("Cam_px_data_3", Pins("E17")),
     Subsignal("Cam_px_data_4", Pins("G13")),
     Subsignal("Cam_px_data_5", Pins("C17")),
     Subsignal("Cam_px_data_6", Pins("D18")),
     Subsignal("Cam_px_data_7", Pins("E18")),
     IOStandard("LVCMOS33"))
]


class Platform(XilinxPlatform, ABC):
    default_clk_name = "clk32"
    default_clk_period = 100

    def __init__(self):
        #      XilinxPlatform.__init__(self, "xc6slx9-TQG144-2", _io, toolchain="ise")
        XilinxPlatform.__init__(self, "xc7a100t-CSG324-1", _io, toolchain="ise")

    def do_finalize(self, fragment):
        XilinxPlatform.do_finalize(self, fragment, ngdbuild_opt="ngdbuild -p")
## Pruebas interrupciones
#def csr_map_update(csr_map, csr_peripherals):
#    csr_map.update(dict((n, v)
#        for v, n in enumerate(csr_peripherals, start=max(csr_map.values()) + 1)))

#
# design
#

# create our platform (fpga interface)

#platform = Platform()
# platform.add_source("i2c_verilog/i2c.v")
# platform.add_source("i2c_verilog/i2c_master_byte_ctrl.v")
# platform.add_source("i2c_verilog/i2c_master_bit_ctrl.v")
# platform.add_source("i2c_verilog/i2c_master_defines.v")
# platform.add_source("i2c_verilog/timescale.v")

platform = Platform()
platform.add_source("Testcam_verilog/analizador.v")
platform.add_source("Testcam_verilog/cam_read.v")
platform.add_source("Testcam_verilog/divisor.v")
platform.add_source("Testcam_verilog/buffer_ram_dp.v")
platform.add_source("Testcam_verilog/test_cam.v")


# create our soc (fpga description)
class BaseSoC(SC.SoCCore):
    # Peripherals CSR declaration
    csr_peripherals = {
       
        "cam": 3
#        "color:"4
    }
    SC.SoCCore.csr_map = csr_peripherals
   ## Pruebas interrupciones 
#    interrupt_map = {
#       "button" : 4,
#    }

#    SC.SoCCore.interrupt_map= interrupt_map

#   csr_map_update(SC.SoCCore.csr_map, csr_peripherals)

    def __init__(self, platform):
        sys_clk_freq = int(100e6)
        # SoC with CPU
        SC.SoCCore.__init__(self, platform,
                            cpu_type="lm32",
                            clk_freq=100e6,
                            ident="CPU Test SoC", ident_version=True,
                            integrated_rom_size=0x8000,
                            csr_data_width=32,
                            integrated_main_ram_size=16 * 1024)

        # Clock Reset Generation
        self.submodules.crg = CRG(platform.request("clk32"), ~platform.request("cpu_reset"))

        # Spi
        self.submodules.cam = CAM_Master(platform.request("cam_master"))
    # Camara
    #  self.submodules.camara = Camara_Master(platform.request("Cam_master"))
        # Analizador
 #       self.submodules.cam = Color_read(platform.request("color_read"))

soc = BaseSoC(platform)

#
# build
#
builder = Builder(soc, output_dir="build", csr_csv="csr.csv")

builder.build()

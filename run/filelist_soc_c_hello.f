+incdir+../rtl/veer_el2/snapshots/default
+incdir+../rtl/veer_el2/design/include
+incdir+../rtl/veer_el2/design/lib
+incdir+../rtl/axi_uart/include
+incdir+../rtl/axi_uart/rtl

-top tb_soc_c_hello

../rtl/veer_el2/snapshots/default/common_defines.vh
../rtl/veer_el2/design/include/el2_def.sv
-v ../rtl/veer_el2/design/lib/mem_lib.sv
-v ../rtl/veer_el2/design/lib/beh_lib.sv
../rtl/veer_el2/design/lib/el2_assert.sv
../rtl/veer_el2/design/el2_mubi_pkg.sv
../rtl/veer_el2/design/el2_lockstep_pkg.sv
../rtl/veer_el2/design/lib/el2_mem_if.sv
../rtl/veer_el2/design/lib/el2_prim_generic_buf.sv
../rtl/veer_el2/design/lib/el2_prim_buf.sv
../rtl/veer_el2/design/lib/el2_lib.sv
../rtl/veer_el2/design/lib/ahb_to_axi4.sv
../rtl/veer_el2/design/lib/axi4_to_ahb.sv

../rtl/veer_el2/design/dmi/dmi_mux.v
../rtl/veer_el2/design/dmi/dmi_wrapper.v
../rtl/veer_el2/design/dmi/dmi_jtag_to_core_sync.v
../rtl/veer_el2/design/dmi/rvjtag_tap.v

../rtl/veer_el2/design/dec/el2_dec_decode_ctl.sv
../rtl/veer_el2/design/dec/el2_dec_gpr_ctl.sv
../rtl/veer_el2/design/dec/el2_dec_ib_ctl.sv
../rtl/veer_el2/design/dec/el2_dec_pmp_ctl.sv
../rtl/veer_el2/design/dec/el2_dec_tlu_ctl.sv
../rtl/veer_el2/design/dec/el2_dec_trigger.sv
../rtl/veer_el2/design/dec/el2_dec.sv

../rtl/veer_el2/design/exu/el2_exu_alu_ctl.sv
../rtl/veer_el2/design/exu/el2_exu_mul_ctl.sv
../rtl/veer_el2/design/exu/el2_exu_div_ctl.sv
../rtl/veer_el2/design/exu/el2_exu.sv

../rtl/veer_el2/design/ifu/el2_ifu_aln_ctl.sv
../rtl/veer_el2/design/ifu/el2_ifu_compress_ctl.sv
../rtl/veer_el2/design/ifu/el2_ifu_ifc_ctl.sv
../rtl/veer_el2/design/ifu/el2_ifu_bp_ctl.sv
../rtl/veer_el2/design/ifu/el2_ifu_ic_mem.sv
../rtl/veer_el2/design/ifu/el2_ifu_mem_ctl.sv
../rtl/veer_el2/design/ifu/el2_ifu_iccm_mem.sv
../rtl/veer_el2/design/ifu/el2_ifu.sv

../rtl/veer_el2/design/lsu/el2_lsu_clkdomain.sv
../rtl/veer_el2/design/lsu/el2_lsu_addrcheck.sv
../rtl/veer_el2/design/lsu/el2_lsu_lsc_ctl.sv
../rtl/veer_el2/design/lsu/el2_lsu_stbuf.sv
../rtl/veer_el2/design/lsu/el2_lsu_bus_buffer.sv
../rtl/veer_el2/design/lsu/el2_lsu_bus_intf.sv
../rtl/veer_el2/design/lsu/el2_lsu_ecc.sv
../rtl/veer_el2/design/lsu/el2_lsu_dccm_mem.sv
../rtl/veer_el2/design/lsu/el2_lsu_dccm_ctl.sv
../rtl/veer_el2/design/lsu/el2_lsu_trigger.sv
../rtl/veer_el2/design/lsu/el2_lsu.sv

../rtl/veer_el2/design/dbg/el2_dbg.sv
../rtl/veer_el2/design/el2_pic_ctrl.sv
../rtl/veer_el2/design/el2_dma_ctrl.sv
../rtl/veer_el2/design/el2_pmp.sv
../rtl/veer_el2/design/el2_mem.sv
../rtl/veer_el2/design/el2_veer.sv
../rtl/veer_el2/design/el2_veer_lockstep.sv
../rtl/veer_el2/design/el2_veer_wrapper.sv
../rtl/veer_el2/design/veer_wrapper.sv

../lib/cdc_sync.sv
../lib/sync_fifo.sv
../lib/axi4_to_axil_lite.sv
../lib/axi_ram.sv

../rtl/axi_uart/rtl/axi_internal_fifo.v
../rtl/axi_uart/rtl/uart_parity_bit_compute.v
../rtl/axi_uart/rtl/uart_transmitter.v
../rtl/axi_uart/rtl/uart_receiver.v
../rtl/axi_uart/rtl/uart_controller.v
../rtl/axi_uart/rtl/axi_uart_top.v

../rtl/timer/timer.sv
../rtl/gpio/gpio.sv
../rtl/spi_controller/spi_controller.sv
../rtl/watchdog/watchdog.sv
../rtl/fir_filter/fir_filter.sv
../rtl/sample_buffer/sample_buffer.sv
../rtl/dma_controller/dma_controller.sv
../rtl/vga_controller/vga_controller.sv

../rtl/interconnect/priority_encoder.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_5x20.v
../rtl/axi_interconnect_uart_top.v

../rtl/interconnect/axi_adapter_64_to_32.sv
../rtl/soc_top.sv

../tb/adc_model.sv
../tb/tb_soc_c_hello.sv

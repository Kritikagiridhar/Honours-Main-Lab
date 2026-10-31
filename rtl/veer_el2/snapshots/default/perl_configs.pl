#  Copyright 2019-2026 Western Digital Corporation or its affiliates.
#  Copyright 2022-2026 Antmicro <www.antmicro.com>
# 
#  SPDX-License-Identifier: Apache-2.0
#  Licensed under the Apache License, Version 2.0, see LICENSE for details.
# 
#  This is an automatically generated file by student on Sat Sep 26 15:05:48 IST 2026
# 
#  cmd:    veer -set=ext_datawidth=32 
# 
# To use this in a perf script, use 'require $RV_ROOT/configs/config.pl'
# Reference the hash via $config{name}..


%config = (
            'core' => {
                        'div_new' => 1,
                        'bitmanip_zba' => 1,
                        'bitmanip_zbr' => 0,
                        'timer_legal_en' => '1',
                        'fast_interrupt_redirect' => '1',
                        'bitmanip_zbs' => 1,
                        'bitmanip_zbe' => 0,
                        'iccm_only' => 'derived',
                        'div_bit' => '4',
                        'bitmanip_zbp' => 0,
                        'icache_only' => 'derived',
                        'bitmanip_zbf' => 0,
                        'lsu_num_nbload' => '4',
                        'bitmanip_zbc' => 1,
                        'iccm_icache' => 1,
                        'bitmanip_zbb' => 1,
                        'no_iccm_no_icache' => 'derived',
                        'lsu_stbuf_depth' => '4',
                        'fpga_optimize' => 1,
                        'lsu_num_nbload_width' => '2',
                        'dma_buf_depth' => '5',
                        'lsu2dma' => 0
                      },
            'physical' => '1',
            'protection' => {
                              'data_access_mask7' => '0xffffffff',
                              'inst_access_addr1' => '0x00000000',
                              'inst_access_enable2' => '0x0',
                              'inst_access_mask6' => '0xffffffff',
                              'data_access_addr7' => '0x00000000',
                              'inst_access_mask7' => '0xffffffff',
                              'data_access_addr1' => '0x00000000',
                              'data_access_enable3' => '0x0',
                              'data_access_addr5' => '0x00000000',
                              'data_access_mask0' => '0xffffffff',
                              'data_access_enable0' => '0x0',
                              'data_access_enable6' => '0x0',
                              'data_access_addr3' => '0x00000000',
                              'inst_access_addr7' => '0x00000000',
                              'data_access_addr2' => '0x00000000',
                              'data_access_enable1' => '0x0',
                              'data_access_mask3' => '0xffffffff',
                              'inst_access_addr4' => '0x00000000',
                              'inst_access_enable0' => '0x0',
                              'data_access_enable5' => '0x0',
                              'data_access_mask5' => '0xffffffff',
                              'inst_access_mask1' => '0xffffffff',
                              'inst_access_enable4' => '0x0',
                              'data_access_mask1' => '0xffffffff',
                              'data_access_addr6' => '0x00000000',
                              'inst_access_addr2' => '0x00000000',
                              'inst_access_mask0' => '0xffffffff',
                              'inst_access_addr3' => '0x00000000',
                              'pmp_entries' => '16',
                              'inst_access_mask5' => '0xffffffff',
                              'data_access_enable4' => '0x0',
                              'data_access_addr4' => '0x00000000',
                              'inst_access_mask4' => '0xffffffff',
                              'inst_access_addr0' => '0x00000000',
                              'data_access_enable7' => '0x0',
                              'data_access_mask2' => '0xffffffff',
                              'inst_access_enable3' => '0x0',
                              'inst_access_enable1' => '0x0',
                              'data_access_mask4' => '0xffffffff',
                              'data_access_enable2' => '0x0',
                              'data_access_mask6' => '0xffffffff',
                              'inst_access_enable6' => '0x0',
                              'inst_access_enable7' => '0x0',
                              'inst_access_enable5' => '0x0',
                              'inst_access_mask3' => '0xffffffff',
                              'inst_access_addr5' => '0x00000000',
                              'inst_access_addr6' => '0x00000000',
                              'inst_access_mask2' => '0xffffffff',
                              'data_access_addr0' => '0x00000000'
                            },
            'user_ec_rv_icg' => 'user_clock_gate',
            'perf_events' => [
                               1,
                               2,
                               3,
                               4,
                               5,
                               6,
                               7,
                               8,
                               9,
                               10,
                               11,
                               12,
                               13,
                               14,
                               15,
                               16,
                               17,
                               18,
                               19,
                               20,
                               21,
                               22,
                               23,
                               24,
                               25,
                               26,
                               27,
                               28,
                               30,
                               31,
                               32,
                               34,
                               35,
                               36,
                               37,
                               38,
                               39,
                               40,
                               41,
                               42,
                               43,
                               44,
                               45,
                               46,
                               47,
                               48,
                               49,
                               50,
                               54,
                               55,
                               56,
                               512,
                               513,
                               514,
                               515,
                               516
                             ],
            'num_mmode_perf_regs' => '4',
            'pic' => {
                       'pic_offset' => '0xc0000',
                       'pic_mpiccfg_count' => 1,
                       'pic_meie_count' => 31,
                       'pic_size' => 32,
                       'pic_meigwclr_mask' => '0x0',
                       'pic_meie_offset' => '0x2000',
                       'pic_mpiccfg_mask' => '0x1',
                       'pic_meipt_mask' => '0x0',
                       'pic_region' => '0xf',
                       'pic_meie_mask' => '0x1',
                       'pic_base_addr' => '0xf00c0000',
                       'pic_int_words' => 1,
                       'pic_meigwclr_offset' => '0x5000',
                       'pic_meip_count' => 1,
                       'pic_meigwclr_count' => 31,
                       'pic_meigwctrl_mask' => '0x3',
                       'pic_meigwctrl_count' => 31,
                       'pic_meigwctrl_offset' => '0x4000',
                       'pic_bits' => 15,
                       'pic_meipt_offset' => '0x3004',
                       'pic_mpiccfg_offset' => '0x3000',
                       'pic_meipt_count' => 31,
                       'pic_total_int' => 31,
                       'pic_meipl_mask' => '0xf',
                       'pic_total_int_plus1' => 32,
                       'pic_meipl_count' => 31,
                       'pic_meip_offset' => '0x1000',
                       'pic_meip_mask' => '0x0',
                       'pic_meipl_offset' => '0x0000'
                     },
            'iccm' => {
                        'iccm_bank_index_lo' => 4,
                        'iccm_sadr' => '0xee000000',
                        'iccm_bits' => 16,
                        'iccm_size' => 64,
                        'iccm_num_banks_4' => '',
                        'iccm_bank_bits' => 2,
                        'iccm_region' => '0xe',
                        'iccm_offset' => '0xe000000',
                        'iccm_index_bits' => 12,
                        'iccm_rows' => '4096',
                        'iccm_data_cell' => 'ram_4096x39',
                        'iccm_eadr' => '0xee00ffff',
                        'iccm_ecc_width' => '7',
                        'iccm_reserved' => '0x1000',
                        'iccm_enable' => 1,
                        'iccm_num_banks' => '4',
                        'iccm_bank_hi' => 3,
                        'iccm_size_64' => ''
                      },
            'csr' => {
                       'mcounteren' => {
                                         'exists' => 'false'
                                       },
                       'mitctl0' => {
                                      'number' => '0x7d4',
                                      'exists' => 'true',
                                      'mask' => '0x00000007',
                                      'reset' => '0x1'
                                    },
                       'miccmect' => {
                                       'number' => '0x7f1',
                                       'exists' => 'true',
                                       'mask' => '0xffffffff',
                                       'reset' => '0x0'
                                     },
                       'mcgc' => {
                                   'mask' => '0x000003ff',
                                   'reset' => '0x200',
                                   'number' => '0x7f8',
                                   'exists' => 'true',
                                   'poke_mask' => '0x000003ff'
                                 },
                       'meicurpl' => {
                                       'reset' => '0x0',
                                       'mask' => '0xf',
                                       'comment' => 'External interrupt current priority level.',
                                       'exists' => 'true',
                                       'number' => '0xbcc'
                                     },
                       'mhpmevent4' => {
                                         'exists' => 'true',
                                         'reset' => '0x0',
                                         'mask' => '0xffffffff'
                                       },
                       'mitcnt0' => {
                                      'number' => '0x7d2',
                                      'exists' => 'true',
                                      'reset' => '0x0',
                                      'mask' => '0xffffffff'
                                    },
                       'mhartid' => {
                                      'poke_mask' => '0xfffffff0',
                                      'exists' => 'true',
                                      'reset' => '0x0',
                                      'mask' => '0x0'
                                    },
                       'micect' => {
                                     'reset' => '0x0',
                                     'mask' => '0xffffffff',
                                     'exists' => 'true',
                                     'number' => '0x7f0'
                                   },
                       'mhpmevent6' => {
                                         'exists' => 'true',
                                         'mask' => '0xffffffff',
                                         'reset' => '0x0'
                                       },
                       'mhpmcounter6h' => {
                                            'mask' => '0xffffffff',
                                            'reset' => '0x0',
                                            'exists' => 'true'
                                          },
                       'mitbnd1' => {
                                      'number' => '0x7d6',
                                      'exists' => 'true',
                                      'reset' => '0xffffffff',
                                      'mask' => '0xffffffff'
                                    },
                       'meicidpl' => {
                                       'number' => '0xbcb',
                                       'exists' => 'true',
                                       'reset' => '0x0',
                                       'comment' => 'External interrupt claim id priority level.',
                                       'mask' => '0xf'
                                     },
                       'tselect' => {
                                      'exists' => 'true',
                                      'mask' => '0x3',
                                      'reset' => '0x0'
                                    },
                       'mhpmcounter5h' => {
                                            'exists' => 'true',
                                            'reset' => '0x0',
                                            'mask' => '0xffffffff'
                                          },
                       'mfdht' => {
                                    'shared' => 'true',
                                    'exists' => 'true',
                                    'number' => '0x7ce',
                                    'reset' => '0x0',
                                    'mask' => '0x0000003f',
                                    'comment' => 'Force Debug Halt Threshold'
                                  },
                       'mcpc' => {
                                   'comment' => 'Core pause',
                                   'mask' => '0x0',
                                   'reset' => '0x0',
                                   'number' => '0x7c2',
                                   'exists' => 'true'
                                 },
                       'mimpid' => {
                                     'reset' => '0x4',
                                     'mask' => '0x0',
                                     'exists' => 'true'
                                   },
                       'mdccmect' => {
                                       'exists' => 'true',
                                       'number' => '0x7f2',
                                       'mask' => '0xffffffff',
                                       'reset' => '0x0'
                                     },
                       'instret' => {
                                      'exists' => 'false'
                                    },
                       'mitctl1' => {
                                      'reset' => '0x1',
                                      'mask' => '0x0000000f',
                                      'exists' => 'true',
                                      'number' => '0x7d7'
                                    },
                       'dicad1' => {
                                     'comment' => 'Cache diagnostics.',
                                     'mask' => '0x3',
                                     'reset' => '0x0',
                                     'debug' => 'true',
                                     'number' => '0x7ca',
                                     'exists' => 'true'
                                   },
                       'mitbnd0' => {
                                      'reset' => '0xffffffff',
                                      'mask' => '0xffffffff',
                                      'exists' => 'true',
                                      'number' => '0x7d3'
                                    },
                       'marchid' => {
                                      'mask' => '0x0',
                                      'reset' => '0x00000010',
                                      'exists' => 'true'
                                    },
                       'dicago' => {
                                     'reset' => '0x0',
                                     'mask' => '0x0',
                                     'comment' => 'Cache diagnostics.',
                                     'exists' => 'true',
                                     'number' => '0x7cb',
                                     'debug' => 'true'
                                   },
                       'mhpmcounter4' => {
                                           'exists' => 'true',
                                           'mask' => '0xffffffff',
                                           'reset' => '0x0'
                                         },
                       'mhpmevent5' => {
                                         'exists' => 'true',
                                         'reset' => '0x0',
                                         'mask' => '0xffffffff'
                                       },
                       'mie' => {
                                  'mask' => '0x70000888',
                                  'reset' => '0x0',
                                  'exists' => 'true'
                                },
                       'mvendorid' => {
                                        'reset' => '0x45',
                                        'mask' => '0x0',
                                        'exists' => 'true'
                                      },
                       'mhpmcounter4h' => {
                                            'exists' => 'true',
                                            'mask' => '0xffffffff',
                                            'reset' => '0x0'
                                          },
                       'mcountinhibit' => {
                                            'poke_mask' => '0x7d',
                                            'exists' => 'true',
                                            'commnet' => 'Performance counter inhibit. One bit per counter.',
                                            'mask' => '0x7d',
                                            'reset' => '0x0'
                                          },
                       'mhpmcounter3h' => {
                                            'reset' => '0x0',
                                            'mask' => '0xffffffff',
                                            'exists' => 'true'
                                          },
                       'dcsr' => {
                                   'debug' => 'true',
                                   'poke_mask' => '0x00008dcc',
                                   'exists' => 'true',
                                   'mask' => '0x00008c04',
                                   'reset' => '0x40000003'
                                 },
                       'dmst' => {
                                   'exists' => 'true',
                                   'debug' => 'true',
                                   'number' => '0x7c4',
                                   'mask' => '0x0',
                                   'comment' => 'Memory synch trigger: Flush caches in debug mode.',
                                   'reset' => '0x0'
                                 },
                       'misa' => {
                                   'mask' => '0x0',
                                   'reset' => '0x40001104',
                                   'exists' => 'true'
                                 },
                       'meipt' => {
                                    'mask' => '0xf',
                                    'comment' => 'External interrupt priority threshold.',
                                    'reset' => '0x0',
                                    'exists' => 'true',
                                    'number' => '0xbc9'
                                  },
                       'time' => {
                                   'exists' => 'false'
                                 },
                       'mip' => {
                                  'exists' => 'true',
                                  'poke_mask' => '0x70000888',
                                  'reset' => '0x0',
                                  'mask' => '0x0'
                                },
                       'mhpmcounter5' => {
                                           'exists' => 'true',
                                           'reset' => '0x0',
                                           'mask' => '0xffffffff'
                                         },
                       'mrac' => {
                                   'reset' => '0x0',
                                   'mask' => '0xffffffff',
                                   'comment' => 'Memory region io and cache control.',
                                   'shared' => 'true',
                                   'exists' => 'true',
                                   'number' => '0x7c0'
                                 },
                       'mstatus' => {
                                      'exists' => 'true',
                                      'reset' => '0x1800',
                                      'mask' => '0x88'
                                    },
                       'mpmc' => {
                                   'number' => '0x7c6',
                                   'exists' => 'true',
                                   'mask' => '0x2',
                                   'reset' => '0x2'
                                 },
                       'cycle' => {
                                    'exists' => 'false'
                                  },
                       'mhpmcounter3' => {
                                           'reset' => '0x0',
                                           'mask' => '0xffffffff',
                                           'exists' => 'true'
                                         },
                       'mitcnt1' => {
                                      'number' => '0x7d5',
                                      'exists' => 'true',
                                      'reset' => '0x0',
                                      'mask' => '0xffffffff'
                                    },
                       'mhpmevent3' => {
                                         'exists' => 'true',
                                         'mask' => '0xffffffff',
                                         'reset' => '0x0'
                                       },
                       'dicawics' => {
                                       'comment' => 'Cache diagnostics.',
                                       'mask' => '0x0130fffc',
                                       'reset' => '0x0',
                                       'number' => '0x7c8',
                                       'debug' => 'true',
                                       'exists' => 'true'
                                     },
                       'mscause' => {
                                      'number' => '0x7ff',
                                      'exists' => 'true',
                                      'reset' => '0x0',
                                      'mask' => '0x0000000f'
                                    },
                       'mfdc' => {
                                   'reset' => '0x00070040',
                                   'mask' => '0x00071fff',
                                   'number' => '0x7f9',
                                   'exists' => 'true'
                                 },
                       'mfdhs' => {
                                    'exists' => 'true',
                                    'number' => '0x7cf',
                                    'reset' => '0x0',
                                    'mask' => '0x00000003',
                                    'comment' => 'Force Debug Halt Status'
                                  },
                       'mhpmcounter6' => {
                                           'exists' => 'true',
                                           'mask' => '0xffffffff',
                                           'reset' => '0x0'
                                         },
                       'dicad0' => {
                                     'number' => '0x7c9',
                                     'debug' => 'true',
                                     'exists' => 'true',
                                     'reset' => '0x0',
                                     'comment' => 'Cache diagnostics.',
                                     'mask' => '0xffffffff'
                                   }
                     },
            'even_odd_trigger_chains' => 'true',
            'max_mmode_perf_event' => '516',
            'btb' => {
                       'btb_btag_fold' => 0,
                       'btb_addr_lo' => '2',
                       'btb_index3_hi' => 25,
                       'btb_array_depth' => 256,
                       'btb_enable' => '1',
                       'btb_index1_hi' => 9,
                       'btb_index1_lo' => '2',
                       'btb_fold2_index_hash' => 0,
                       'btb_toffset_size' => '12',
                       'btb_btag_size' => 5,
                       'btb_addr_hi' => 9,
                       'btb_index2_hi' => 17,
                       'btb_size' => 512,
                       'btb_index2_lo' => 10,
                       'btb_index3_lo' => 18
                     },
            'bus' => {
                       'lsu_bus_tag' => 3,
                       'sb_bus_id' => '1',
                       'dma_bus_id' => '1',
                       'ifu_bus_id' => '1',
                       'dma_bus_tag' => '1',
                       'ifu_bus_tag' => '3',
                       'lsu_bus_id' => '1',
                       'bus_prty_default' => '3',
                       'sb_bus_tag' => '1',
                       'dma_bus_prty' => '2',
                       'lsu_bus_prty' => '2',
                       'ifu_bus_prty' => '2',
                       'sb_bus_prty' => '2'
                     },
            'config_key' => '32\'hdeadbeef',
            'numiregs' => '32',
            'reset_vec' => '0x80000000',
            'bht' => {
                       'bht_ghr_size' => 8,
                       'bht_ghr_range' => '7:0',
                       'bht_ghr_hash_1' => '',
                       'bht_array_depth' => 256,
                       'bht_hash_string' => '{hashin[8+1:2]^ghr[8-1:0]}// cf2',
                       'bht_size' => 512,
                       'bht_addr_hi' => 9,
                       'bht_addr_lo' => '2'
                     },
            'memmap' => {
                          'unused_region7' => '0x10000000',
                          'unused_region3' => '0x50000000',
                          'serialio' => '0xd0580000',
                          'unused_region4' => '0x40000000',
                          'unused_region8' => '0x00000000',
                          'external_data_1' => '0xb0000000',
                          'external_data' => '0xc0580000',
                          'unused_region2' => '0x60000000',
                          'unused_region0' => '0x90000000',
                          'unused_region1' => '0x70000000',
                          'unused_region6' => '0x20000000',
                          'debug_sb_mem' => '0xa0580000',
                          'unused_region5' => '0x30000000',
                          'consoleio' => '0xd0580000'
                        },
            'regwidth' => '32',
            'icache' => {
                          'icache_banks_way' => 2,
                          'icache_index_hi' => 12,
                          'icache_num_lines_bank' => '64',
                          'icache_fdata_width' => 71,
                          'icache_num_ways' => 2,
                          'icache_beat_bits' => 3,
                          'icache_num_lines' => 256,
                          'icache_tag_index_lo' => '6',
                          'icache_tag_cell' => 'ram_128x25',
                          'icache_ecc' => '1',
                          'icache_size' => 16,
                          'icache_data_depth' => '512',
                          'icache_data_index_lo' => 4,
                          'icache_tag_num_bypass' => '2',
                          'icache_waypack' => '1',
                          'icache_bank_bits' => 1,
                          'icache_data_width' => 64,
                          'icache_tag_bypass_enable' => '1',
                          'icache_ln_sz' => 64,
                          'icache_tag_lo' => 13,
                          'icache_scnd_last' => 6,
                          'icache_status_bits' => 1,
                          'icache_data_cell' => 'ram_512x71',
                          'icache_num_lines_way' => '128',
                          'icache_num_bypass_width' => 2,
                          'icache_bypass_enable' => '1',
                          'icache_bank_lo' => 3,
                          'icache_enable' => 1,
                          'icache_num_beats' => 8,
                          'icache_tag_num_bypass_width' => 2,
                          'icache_beat_addr_hi' => 5,
                          'icache_bank_hi' => 3,
                          'icache_num_bypass' => '2',
                          'icache_2banks' => '1',
                          'icache_tag_depth' => 128,
                          'icache_bank_width' => 8
                        },
            'retstack' => {
                            'ret_stack_size' => '8'
                          },
            'harts' => 1,
            'testbench' => {
                             'sterr_rollback' => '0',
                             'clock_period' => '100',
                             'build_axi_native' => 1,
                             'lderr_rollback' => '1',
                             'build_axi4' => 1,
                             'TOP' => 'tb_top',
                             'ext_addrwidth' => '32',
                             'RV_TOP' => '`TOP.rvtop_wrapper.rvtop',
                             'CPU_TOP' => '`RV_TOP.veer',
                             'ext_datawidth' => '32',
                             'SDVT_AHB' => 0
                           },
            'target' => 'default',
            'nmi_vec' => '0x11110000',
            'triggers' => [
                            {
                              'poke_mask' => [
                                               '0x081818c7',
                                               '0xffffffff',
                                               '0x00000000'
                                             ],
                              'reset' => [
                                           '0x23e00000',
                                           '0x00000000',
                                           '0x00000000'
                                         ],
                              'mask' => [
                                          '0x081818c7',
                                          '0xffffffff',
                                          '0x00000000'
                                        ]
                            },
                            {
                              'mask' => [
                                          '0x081810c7',
                                          '0xffffffff',
                                          '0x00000000'
                                        ],
                              'reset' => [
                                           '0x23e00000',
                                           '0x00000000',
                                           '0x00000000'
                                         ],
                              'poke_mask' => [
                                               '0x081810c7',
                                               '0xffffffff',
                                               '0x00000000'
                                             ]
                            },
                            {
                              'mask' => [
                                          '0x081818c7',
                                          '0xffffffff',
                                          '0x00000000'
                                        ],
                              'reset' => [
                                           '0x23e00000',
                                           '0x00000000',
                                           '0x00000000'
                                         ],
                              'poke_mask' => [
                                               '0x081818c7',
                                               '0xffffffff',
                                               '0x00000000'
                                             ]
                            },
                            {
                              'reset' => [
                                           '0x23e00000',
                                           '0x00000000',
                                           '0x00000000'
                                         ],
                              'mask' => [
                                          '0x081810c7',
                                          '0xffffffff',
                                          '0x00000000'
                                        ],
                              'poke_mask' => [
                                               '0x081810c7',
                                               '0xffffffff',
                                               '0x00000000'
                                             ]
                            }
                          ],
            'tec_rv_icg' => 'clockhdr',
            'xlen' => 32,
            'dccm' => {
                        'dccm_enable' => '1',
                        'dccm_bank_bits' => 2,
                        'dccm_size' => 64,
                        'lsu_sb_bits' => 16,
                        'dccm_num_banks' => '4',
                        'dccm_size_64' => '',
                        'dccm_width_bits' => 2,
                        'dccm_sadr' => '0xf0040000',
                        'dccm_ecc_width' => 7,
                        'dccm_num_banks_4' => '',
                        'dccm_fdata_width' => 39,
                        'dccm_data_cell' => 'ram_4096x39',
                        'dccm_offset' => '0x40000',
                        'dccm_rows' => '4096',
                        'dccm_bits' => 16,
                        'dccm_eadr' => '0xf004ffff',
                        'dccm_region' => '0xf',
                        'dccm_reserved' => '0x1400',
                        'dccm_data_width' => 32,
                        'dccm_byte_width' => '4',
                        'dccm_index_bits' => 12
                      }
          );
1;

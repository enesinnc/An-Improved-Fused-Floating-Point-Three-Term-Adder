Note: === TEST 1: 16 x 1.0 ===
Time: 40 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T1_RESULT  sign='0' exp=131 man=0 | OV='0' UF='0' NaN='0' Inf='0'
Time: 150 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 2: 8x1.0 + 8x(-1.0) ===
Time: 150 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T2_RESULT  sign='0' exp=0 man=0 | OV='0' UF='0' NaN='0' Inf='0'
Time: 260 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 3: All zeros ===
Time: 260 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T3_RESULT  sign='0' exp=0 man=0 | OV='0' UF='0' NaN='0' Inf='0'
Time: 370 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 4: Mixed magnitudes (1.0, 2.0, 0.5) ===
Time: 370 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T4_RESULT  sign='0' exp=131 man=160 | OV='0' UF='0' NaN='0' Inf='0'
Time: 480 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 5: NaN propagation ===
Time: 480 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T5_RESULT  sign='0' exp=255 man=1 | OV='0' UF='0' NaN='1' Inf='0'
Time: 590 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 6: Swamping (1xBIG + 15xTINY) ===
Time: 590 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T6_RESULT  sign='0' exp=150 man=0 | OV='0' UF='0' NaN='0' Inf='0'
Time: 700 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 7: Cancellation with Remainder (1xBIG + 1xMBIG + 14x1.0) ===
Time: 700 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T7_RESULT  sign='0' exp=130 man=768 | OV='0' UF='0' NaN='0' Inf='0'
Time: 810 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 8: Overflow (16xMAX) ===
Time: 810 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T8_RESULT  sign='0' exp=254 man=1023 | OV='0' UF='1' NaN='0' Inf='0'
Time: 920 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 9: Minimum Normals (16xMIN) ===
Time: 920 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
INFO: [USF-XSim-96] XSim completed. Design snapshot 'tb_fp16_adder_tree_behav' loaded.
INFO: [USF-XSim-97] XSim simulation ran for 1000ns
launch_simulation: Time (s): cpu = 00:00:03 ; elapsed = 00:00:08 . Memory (MB): peak = 1258.012 ; gain = 0.000
run 10 us
Note: T9_RESULT  sign='0' exp=5 man=0 | OV='0' UF='0' NaN='0' Inf='0'
Time: 1030 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 10: Infinity Propagation (1xINF + 15x1.0) ===
Time: 1030 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T10_RESULT  sign='0' exp=255 man=0 | OV='0' UF='0' NaN='0' Inf='1'
Time: 1140 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 11: Inf - Inf = NaN ===
Time: 1140 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T11_RESULT  sign='0' exp=255 man=1 | OV='0' UF='0' NaN='1' Inf='0'
Time: 1250 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 12: A - B + C (4.0 - 2.0 + 1.0 = 3.0) ===
Time: 1250 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T12_RESULT  sign='0' exp=128 man=512 | OV='0' UF='0' NaN='0' Inf='0'
Time: 1360 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 13: A - B - C (4.0 - 2.0 - 1.0 = 1.0) ===
Time: 1360 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T13_RESULT  sign='0' exp=127 man=0 | OV='0' UF='0' NaN='0' Inf='0'
Time: 1470 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 14: -A - B - C (-4.0 - 2.0 - 1.0 = -7.0) ===
Time: 1470 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T14_RESULT  sign='1' exp=129 man=768 | OV='0' UF='0' NaN='0' Inf='0'
Time: 1580 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === TEST 15: Alternating Signs (8x1.0 + 8x-2.0 = -8.0) ===
Time: 1580 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: T15_RESULT  sign='1' exp=130 man=0 | OV='0' UF='0' NaN='0' Inf='0'
Time: 1690 ns  Iteration: 0  Process: /tb_fp16_adder_tree/line__134  File: C:/Users/pc/VHDL_hazirlik/fused_floating_point_three_term_adder/fused_floating_point_three_term_adder.srcs/sim_1/new/tb_fp16_adder_tree.vhd
Note: === All tests complete ===

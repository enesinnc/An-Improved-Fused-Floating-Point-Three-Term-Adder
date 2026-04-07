-- =============================================================================
-- fp16_adder_tree.vhd
-- 16-Input BF19 Floating-Point Adder Tree
--
-- Computes: result = in0 + in1 + ... + in15 (all BF19)
--
-- Topology (fused three-term adders, minimising intermediate rounding):
--
--   Level 0 (6 fused 3-adders + 1 passthrough):
--     L0_0 = in0  + in1  + in2
--     L0_1 = in3  + in4  + in5
--     L0_2 = in6  + in7  + in8
--     L0_3 = in9  + in10 + in11
--     L0_4 = in12 + in13 + in14
--     L0_5 = in15  (passthrough, broadcast as itself)
--
--   Level 1 (2 fused 3-adders):
--     L1_0 = L0_0 + L0_1 + L0_2
--     L1_1 = L0_3 + L0_4 + L0_5
--
--   Level 2 (final fused 3-adder with a zero-padded dummy):
--     result = L1_0 + L1_1 + 0
--
-- Total pipeline latency:
--   Non-pipelined : 3 levels × combinational delay
--   Pipelined     : (3 levels × 3 stages) = 9 clock cycles
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bf19_pkg.all;

entity fp16_adder_tree is
  generic (
    PIPELINE_EN : boolean := true
  );
  port (
    clk      : in  std_logic;
    rst_n    : in  std_logic;
    rnd_mode : in  std_logic_vector(2 downto 0);

    -- 16 BF19 inputs
    in0, in1, in2, in3   : in std_logic_vector(BF19_WIDTH-1 downto 0);
    in4, in5, in6, in7   : in std_logic_vector(BF19_WIDTH-1 downto 0);
    in8, in9, in10, in11 : in std_logic_vector(BF19_WIDTH-1 downto 0);
    in12, in13, in14, in15: in std_logic_vector(BF19_WIDTH-1 downto 0);

    -- Final BF19 sum
    result   : out std_logic_vector(BF19_WIDTH-1 downto 0);

    -- Aggregated exception flags
    exc_overflow  : out std_logic;
    exc_underflow : out std_logic;
    exc_inexact   : out std_logic;
    exc_inf       : out std_logic;
    exc_nan       : out std_logic;
    exc_zero      : out std_logic
  );
end entity fp16_adder_tree;

architecture structural of fp16_adder_tree is

  -- Constant zero operand
  constant BF19_ZERO : std_logic_vector(BF19_WIDTH-1 downto 0) := (others => '0');

  -- Level 0 outputs (6 fused adder results + passthrough)
  signal l0_0, l0_1, l0_2 : std_logic_vector(BF19_WIDTH-1 downto 0);
  signal l0_3, l0_4, l0_5 : std_logic_vector(BF19_WIDTH-1 downto 0);

  -- Level 0 exception aggregates
  signal l0_ov, l0_uf, l0_ix, l0_inf, l0_nan, l0_zero : std_logic_vector(5 downto 0);

  -- Level 1 outputs
  signal l1_0, l1_1 : std_logic_vector(BF19_WIDTH-1 downto 0);
  signal l1_ov, l1_uf, l1_ix, l1_inf, l1_nan, l1_zero : std_logic_vector(1 downto 0);

  -- Level 2 output
  signal l2_0 : std_logic_vector(BF19_WIDTH-1 downto 0);
  signal l2_ov, l2_uf, l2_ix, l2_inf, l2_nan, l2_zero : std_logic;

begin

  -- ===========================================================================
  -- LEVEL 0: 6 fused three-term adders
  -- ===========================================================================

  -- L0_0: in0 + in1 + in2
  u_l0_0 : entity work.fused_fp3_adder
    generic map (PIPELINE_EN => PIPELINE_EN)
    port map (
      clk => clk, rst_n => rst_n,
      a_in => in0, b_in => in1, c_in => in2,
      op1 => '0', op2 => '0', rnd_mode => rnd_mode,
      result => l0_0,
      exc_overflow => l0_ov(0), exc_underflow => l0_uf(0),
      exc_inexact  => l0_ix(0), exc_inf => l0_inf(0),
      exc_nan      => l0_nan(0), exc_zero => l0_zero(0)
    );

  -- L0_1: in3 + in4 + in5
  u_l0_1 : entity work.fused_fp3_adder
    generic map (PIPELINE_EN => PIPELINE_EN)
    port map (
      clk => clk, rst_n => rst_n,
      a_in => in3, b_in => in4, c_in => in5,
      op1 => '0', op2 => '0', rnd_mode => rnd_mode,
      result => l0_1,
      exc_overflow => l0_ov(1), exc_underflow => l0_uf(1),
      exc_inexact  => l0_ix(1), exc_inf => l0_inf(1),
      exc_nan      => l0_nan(1), exc_zero => l0_zero(1)
    );

  -- L0_2: in6 + in7 + in8
  u_l0_2 : entity work.fused_fp3_adder
    generic map (PIPELINE_EN => PIPELINE_EN)
    port map (
      clk => clk, rst_n => rst_n,
      a_in => in6, b_in => in7, c_in => in8,
      op1 => '0', op2 => '0', rnd_mode => rnd_mode,
      result => l0_2,
      exc_overflow => l0_ov(2), exc_underflow => l0_uf(2),
      exc_inexact  => l0_ix(2), exc_inf => l0_inf(2),
      exc_nan      => l0_nan(2), exc_zero => l0_zero(2)
    );

  -- L0_3: in9 + in10 + in11
  u_l0_3 : entity work.fused_fp3_adder
    generic map (PIPELINE_EN => PIPELINE_EN)
    port map (
      clk => clk, rst_n => rst_n,
      a_in => in9, b_in => in10, c_in => in11,
      op1 => '0', op2 => '0', rnd_mode => rnd_mode,
      result => l0_3,
      exc_overflow => l0_ov(3), exc_underflow => l0_uf(3),
      exc_inexact  => l0_ix(3), exc_inf => l0_inf(3),
      exc_nan      => l0_nan(3), exc_zero => l0_zero(3)
    );

  -- L0_4: in12 + in13 + in14
  u_l0_4 : entity work.fused_fp3_adder
    generic map (PIPELINE_EN => PIPELINE_EN)
    port map (
      clk => clk, rst_n => rst_n,
      a_in => in12, b_in => in13, c_in => in14,
      op1 => '0', op2 => '0', rnd_mode => rnd_mode,
      result => l0_4,
      exc_overflow => l0_ov(4), exc_underflow => l0_uf(4),
      exc_inexact  => l0_ix(4), exc_inf => l0_inf(4),
      exc_nan      => l0_nan(4), exc_zero => l0_zero(4)
    );

  -- L0_5: in15 passthrough (no operation needed, assign directly)
  l0_5     <= in15;
  l0_ov(5) <= '0'; l0_uf(5) <= '0'; l0_ix(5) <= '0';
  l0_inf(5)<= '0'; l0_nan(5)<= '0'; l0_zero(5)<= '0';

  -- ===========================================================================
  -- LEVEL 1: 2 fused three-term adders
  -- ===========================================================================

  -- L1_0: L0_0 + L0_1 + L0_2
  u_l1_0 : entity work.fused_fp3_adder
    generic map (PIPELINE_EN => PIPELINE_EN)
    port map (
      clk => clk, rst_n => rst_n,
      a_in => l0_0, b_in => l0_1, c_in => l0_2,
      op1 => '0', op2 => '0', rnd_mode => rnd_mode,
      result => l1_0,
      exc_overflow => l1_ov(0), exc_underflow => l1_uf(0),
      exc_inexact  => l1_ix(0), exc_inf => l1_inf(0),
      exc_nan      => l1_nan(0), exc_zero => l1_zero(0)
    );

  -- L1_1: L0_3 + L0_4 + L0_5
  u_l1_1 : entity work.fused_fp3_adder
    generic map (PIPELINE_EN => PIPELINE_EN)
    port map (
      clk => clk, rst_n => rst_n,
      a_in => l0_3, b_in => l0_4, c_in => l0_5,
      op1 => '0', op2 => '0', rnd_mode => rnd_mode,
      result => l1_1,
      exc_overflow => l1_ov(1), exc_underflow => l1_uf(1),
      exc_inexact  => l1_ix(1), exc_inf => l1_inf(1),
      exc_nan      => l1_nan(1), exc_zero => l1_zero(1)
    );

  -- ===========================================================================
  -- LEVEL 2: Final fused three-term adder  (L1_0 + L1_1 + 0)
  -- ===========================================================================
  u_l2 : entity work.fused_fp3_adder
    generic map (PIPELINE_EN => PIPELINE_EN)
    port map (
      clk => clk, rst_n => rst_n,
      a_in => l1_0, b_in => l1_1, c_in => BF19_ZERO,
      op1 => '0', op2 => '0', rnd_mode => rnd_mode,
      result => l2_0,
      exc_overflow => l2_ov, exc_underflow => l2_uf,
      exc_inexact  => l2_ix, exc_inf => l2_inf,
      exc_nan      => l2_nan, exc_zero => l2_zero
    );

  -- ===========================================================================
  -- Output assignment
  -- ===========================================================================
  result <= l2_0;

  -- Aggregate exceptions across all levels (OR reduction)
  exc_overflow  <= l2_ov  or l1_ov(0)  or l1_ov(1)
                          or l0_ov(0) or l0_ov(1) or l0_ov(2)
                          or l0_ov(3) or l0_ov(4);
  exc_underflow <= l2_uf  or l1_uf(0)  or l1_uf(1)
                          or l0_uf(0) or l0_uf(1) or l0_uf(2)
                          or l0_uf(3) or l0_uf(4);
  exc_inexact   <= l2_ix  or l1_ix(0)  or l1_ix(1)
                          or l0_ix(0) or l0_ix(1) or l0_ix(2)
                          or l0_ix(3) or l0_ix(4);
  exc_inf       <= l2_inf or l1_inf(0) or l1_inf(1)
                          or l0_inf(0) or l0_inf(1) or l0_inf(2)
                          or l0_inf(3) or l0_inf(4);
  exc_nan       <= l2_nan or l1_nan(0) or l1_nan(1)
                          or l0_nan(0) or l0_nan(1) or l0_nan(2)
                          or l0_nan(3) or l0_nan(4);
  exc_zero      <= l2_zero;

end architecture structural;
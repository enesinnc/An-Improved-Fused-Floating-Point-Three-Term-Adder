-- =============================================================================
-- fused_fp3_adder.vhd
-- Top-Level: Fused Floating-Point Three-Term Adder (BF19)
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bf19_pkg.all;

entity fused_fp3_adder is
  generic ( PIPELINE_EN : boolean := false );
  port (
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    a_in, b_in, c_in : in  std_logic_vector(BF19_WIDTH-1 downto 0);
    op1, op2      : in  std_logic;
    rnd_mode      : in  std_logic_vector(2 downto 0);
    result        : out std_logic_vector(BF19_WIDTH-1 downto 0);
    exc_overflow, exc_underflow, exc_inexact, exc_inf, 
    exc_nan, exc_zero : out std_logic
  );
end entity fused_fp3_adder;

architecture rtl of fused_fp3_adder is
  component exp_compare_align is
    port (
      a_in, b_in, c_in : in  std_logic_vector(BF19_WIDTH-1 downto 0);
      op1, op2         : in  std_logic;
      sign_a, sign_b, sign_c : out std_logic;
      seff_a, seff_b, seff_c : out std_logic;
      exp_max : out unsigned(EXP_WIDTH-1 downto 0);
      shf_a, shf_b, shf_c : out unsigned(SIG_WIDTH-1 downto 0);
      exc_a, exc_b, exc_c : out std_logic_vector(1 downto 0)
    );
  end component;

  component dual_reduction is
    port (
      seff_a, seff_b, seff_c : in  std_logic;
      shf_a, shf_b, shf_c    : in  unsigned(SIG_WIDTH-1 downto 0);
      p_sum, p_carry         : out unsigned(SIG_WIDTH+1 downto 0);
      n_sum, n_carry         : out unsigned(SIG_WIDTH+1 downto 0);
      lza_a, lza_b, lza_c    : out unsigned(SIG_WIDTH+1 downto 0)
    );
  end component;

  component three_input_lza is
    port (
      lza_a, lza_b, lza_c : in  unsigned(SIG_WIDTH+1 downto 0);
      lzc_raw             : out unsigned(4 downto 0);
      lzc_err             : out std_logic;
      signif_comp         : out std_logic
    );
  end component;

  component early_norm_add is
    port (
      p_sum, p_carry : in  unsigned(SIG_WIDTH+1 downto 0);
      n_sum, n_carry : in  unsigned(SIG_WIDTH+1 downto 0);
      lzc_raw        : in  unsigned(4 downto 0);
      lzc_err        : in  std_logic;
      signif_comp    : in  std_logic;
      rnd_mode       : in  std_logic_vector(2 downto 0);
      final_sign_out : out std_logic;
      sig_norm       : out unsigned(MANT_WIDTH downto 0);
      norm_shift_out : out unsigned(5 downto 0);
      carry_out      : out std_logic_vector(1 downto 0);
      sig_zero       : out std_logic
    );
  end component;

  component exp_adjust is
    port (
      exp_max    : in  unsigned(EXP_WIDTH-1 downto 0);
      norm_shift : in  unsigned(5 downto 0);
      carry_out  : in  std_logic_vector(1 downto 0);
      round_up   : in  std_logic;
      exc_a, exc_b, exc_c : in std_logic_vector(1 downto 0);
      adj_exp       : out unsigned(EXP_WIDTH-1 downto 0);
      exc_overflow, exc_underflow, exc_inexact, 
      exc_inf, exc_nan, exc_zero : out std_logic
    );
  end component;

  signal s1_sign_a, s1_sign_b, s1_sign_c, s1_seff_a, s1_seff_b, s1_seff_c : std_logic;
  signal s1_exp_max : unsigned(EXP_WIDTH-1 downto 0);
  signal s1_shf_a, s1_shf_b, s1_shf_c : unsigned(SIG_WIDTH-1 downto 0);
  signal s1_exc_a, s1_exc_b, s1_exc_c : std_logic_vector(1 downto 0);

  signal s2_p_sum, s2_p_carry, s2_n_sum, s2_n_carry, s2_lza_a, s2_lza_b, s2_lza_c : unsigned(SIG_WIDTH+1 downto 0);
  signal s2_lzc : unsigned(4 downto 0);
  signal s2_lzc_err, s2_signif_comp : std_logic;
  signal s2_sig_norm : unsigned(MANT_WIDTH downto 0);
  signal s2_norm_shift : unsigned(5 downto 0);
  signal s2_carry_out : std_logic_vector(1 downto 0);
  signal s2_sig_zero, s2_final_sign : std_logic;

  signal s3_sign_a, s3_rnd_up, s3_sig_zero : std_logic;
  signal s3_exp_max : unsigned(EXP_WIDTH-1 downto 0);
  signal s3_norm_shift : unsigned(5 downto 0);
  signal s3_carry_out : std_logic_vector(1 downto 0);
  signal s3_exc_a, s3_exc_b, s3_exc_c : std_logic_vector(1 downto 0);
  signal s3_sig_norm : unsigned(MANT_WIDTH downto 0);
  signal s3_adj_exp : unsigned(EXP_WIDTH-1 downto 0);
  signal s3_ov_of, s3_ov_uf, s3_ov_ix, s3_ov_inf, s3_ov_nan, s3_ov_zero : std_logic;

begin

  stage1_exp_align : exp_compare_align
    port map (
      a_in => a_in, b_in => b_in, c_in => c_in, op1 => op1, op2 => op2,
      sign_a => s1_sign_a, sign_b => s1_sign_b, sign_c => s1_sign_c,
      seff_a => s1_seff_a, seff_b => s1_seff_b, seff_c => s1_seff_c,
      exp_max => s1_exp_max, shf_a => s1_shf_a, shf_b => s1_shf_b, shf_c => s1_shf_c,
      exc_a => s1_exc_a, exc_b => s1_exc_b, exc_c => s1_exc_c
    );

  stage2_dual_red : dual_reduction
    port map (
      seff_a => s1_seff_a, seff_b => s1_seff_b, seff_c => s1_seff_c,
      shf_a => s1_shf_a, shf_b => s1_shf_b, shf_c => s1_shf_c,
      p_sum => s2_p_sum, p_carry => s2_p_carry, n_sum => s2_n_sum, n_carry => s2_n_carry,
      lza_a => s2_lza_a, lza_b => s2_lza_b, lza_c => s2_lza_c
    );

  stage2_lza : three_input_lza
    port map (
      lza_a => s2_lza_a, lza_b => s2_lza_b, lza_c => s2_lza_c,
      lzc_raw => s2_lzc, lzc_err => s2_lzc_err, signif_comp => s2_signif_comp
    );

  stage2_norm_add : early_norm_add
    port map (
      p_sum => s2_p_sum, p_carry => s2_p_carry, n_sum => s2_n_sum, n_carry => s2_n_carry,
      lzc_raw => s2_lzc, lzc_err => s2_lzc_err, signif_comp => s2_signif_comp,
      rnd_mode => rnd_mode, final_sign_out => s2_final_sign,
      sig_norm => s2_sig_norm, norm_shift_out => s2_norm_shift,
      carry_out => s2_carry_out, sig_zero => s2_sig_zero
    );

process(clk, rst_n)
  begin
    if rst_n = '0' then
      s3_sign_a <= '0';
      s3_exp_max <= (others => '0'); s3_norm_shift <= (others => '0');
      s3_carry_out <= (others => '0'); s3_rnd_up <= '0';
      s3_exc_a <= "00"; s3_exc_b <= "00"; s3_exc_c <= "00";
      s3_sig_norm <= (others => '0'); s3_sig_zero <= '0';
    elsif rising_edge(clk) then
      s3_sign_a <= s1_sign_a XOR s2_final_sign;
      s3_exp_max <= s1_exp_max; s3_norm_shift <= s2_norm_shift;
      s3_carry_out <= s2_carry_out;
      s3_rnd_up <= s2_carry_out(0);
      s3_exc_a <= s1_exc_a; s3_exc_b <= s1_exc_b; s3_exc_c <= s1_exc_c;
      s3_sig_norm <= s2_sig_norm; s3_sig_zero <= s2_sig_zero;
    end if;
  end process;

  stage3_exp_adj : exp_adjust
    port map (
      exp_max => s3_exp_max, norm_shift => s3_norm_shift, carry_out => s3_carry_out,
      round_up => s3_rnd_up, exc_a => s3_exc_a, exc_b => s3_exc_b, exc_c => s3_exc_c,
      adj_exp => s3_adj_exp, exc_overflow => s3_ov_of, exc_underflow => s3_ov_uf,
      exc_inexact => s3_ov_ix, exc_inf => s3_ov_inf, exc_nan => s3_ov_nan, exc_zero => s3_ov_zero
    );

  process(s3_sig_norm, s3_adj_exp, s3_sign_a, s3_ov_of, s3_ov_uf, s3_ov_nan, s3_ov_inf, s3_ov_zero, s3_sig_zero)
    variable packed : std_logic_vector(BF19_WIDTH-1 downto 0);
    variable mant   : unsigned(MANT_WIDTH-1 downto 0);
    variable exp_v  : unsigned(EXP_WIDTH-1 downto 0);
    variable sgn    : std_logic;
  begin
    sgn := s3_sign_a; exp_v := s3_adj_exp;
    mant := s3_sig_norm(MANT_WIDTH-1 downto 0);

    if s3_ov_nan = '1' then
      exp_v := EXP_INF_NAN;
      mant := (0 => '1', others => '0'); sgn := '0';
    elsif s3_ov_zero = '1' or s3_sig_zero = '1' then
      exp_v := EXP_ZERO;
      mant := (others => '0'); sgn := '0';
    elsif s3_ov_inf = '1' or s3_ov_of = '1' then
      exp_v := EXP_INF_NAN;
      mant := (others => '0');
    elsif s3_ov_uf = '1' then
      exp_v := EXP_ZERO;
      mant := (others => '0'); sgn := '0';
    end if;
    packed := sgn & std_logic_vector(exp_v) & std_logic_vector(mant);
    result <= packed;
  end process;

  exc_overflow <= s3_ov_of; exc_underflow <= s3_ov_uf; exc_inexact <= s3_ov_ix;
  exc_inf <= s3_ov_inf; exc_nan <= s3_ov_nan; exc_zero <= s3_ov_zero;
end architecture rtl;
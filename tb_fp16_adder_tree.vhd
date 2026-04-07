-- =============================================================================
-- tb_fp16_adder_tree.vhd
-- Testbench for fp16_adder_tree (16-input BF19 fused adder)
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bf19_pkg.all;

entity tb_fp16_adder_tree is
end entity tb_fp16_adder_tree;

architecture sim of tb_fp16_adder_tree is

  -- Clock period
  constant CLK_PERIOD : time := 10 ns;
  -- Pipeline depth (3 stages x 3 levels)
  constant PIPE_DEPTH : integer := 9;

  signal clk      : std_logic := '0';
  signal rst_n    : std_logic := '0';
  signal rnd_mode : std_logic_vector(2 downto 0) := RND_NEAREST_EVEN;

  -- 16 inputs
  signal in0, in1, in2, in3   : std_logic_vector(BF19_WIDTH-1 downto 0) := (others => '0');
  signal in4, in5, in6, in7   : std_logic_vector(BF19_WIDTH-1 downto 0) := (others => '0');
  signal in8, in9, in10, in11 : std_logic_vector(BF19_WIDTH-1 downto 0) := (others => '0');
  signal in12, in13, in14, in15: std_logic_vector(BF19_WIDTH-1 downto 0) := (others => '0');

  -- Outputs
  signal result         : std_logic_vector(BF19_WIDTH-1 downto 0);
  signal exc_overflow   : std_logic;
  signal exc_underflow  : std_logic;
  signal exc_inexact    : std_logic;
  signal exc_inf        : std_logic;
  signal exc_nan        : std_logic;
  signal exc_zero       : std_logic;

  -- -------------------------------------------------------------------------
  -- Helper: pack BF19 from components
  -- -------------------------------------------------------------------------
  function pack_bf19(sgn : std_logic; exp : integer; man : integer) return std_logic_vector is
    variable res_v : std_logic_vector(BF19_WIDTH-1 downto 0);
  begin
    res_v := (others => '0');
    res_v(SIGN_BIT) := sgn;
    res_v(EXP_HI downto EXP_LO) := std_logic_vector(to_unsigned(exp, EXP_WIDTH));
    res_v(MANT_HI downto MANT_LO) := std_logic_vector(to_unsigned(man, MANT_WIDTH));
    return res_v;
  end function;

  -- Unpack helper
  procedure unpack_bf19(
    val : in  std_logic_vector(BF19_WIDTH-1 downto 0);
    sgn : out std_logic;
    exp : out integer;
    man : out integer) is
  begin
    sgn := val(SIGN_BIT);
    exp := to_integer(unsigned(val(EXP_HI downto EXP_LO)));
    man := to_integer(unsigned(val(MANT_HI downto MANT_LO)));
  end procedure;

  -- Print procedure
  procedure print_result(
    msg   : in string;
    res   : in std_logic_vector(BF19_WIDTH-1 downto 0);
    ov    : in std_logic;
    uf    : in std_logic;
    nan_f : in std_logic;
    inf_f : in std_logic) is
    variable sgn : std_logic;
    variable e   : integer;
    variable m   : integer;
  begin
    unpack_bf19(res, sgn, e, m);
    report msg & 
      "  sign=" & std_logic'image(sgn) & 
      " exp=" & integer'image(e) & 
      " man=" & integer'image(m) & 
      " | OV=" & std_logic'image(ov) & 
      " UF=" & std_logic'image(uf) & 
      " NaN=" & std_logic'image(nan_f) & 
      " Inf=" & std_logic'image(inf_f);
  end procedure;

  -- -------------------------------------------------------------------------
  -- Test Constants
  -- -------------------------------------------------------------------------
  constant BF19_ONE    : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('0', 127, 0);
  constant BF19_MONE   : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('1', 127, 0);
  constant BF19_TWO    : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('0', 128, 0);
  constant BF19_MTWO   : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('1', 128, 0);
  constant BF19_FOUR   : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('0', 129, 0);
  constant BF19_MFOUR  : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('1', 129, 0);
  constant BF19_HALF   : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('0', 126, 0);
  constant BF19_NAN    : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('0', 255, 512);
  constant BF19_ZERO_C : std_logic_vector(BF19_WIDTH-1 downto 0) := (others => '0');
  
  -- Edge-Case Constants
  constant BF19_BIG    : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('0', 150, 0);    -- 2^23
  constant BF19_MBIG   : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('1', 150, 0);    -- -(2^23)
  constant BF19_TINY   : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('0', 100, 0);    -- 2^-27
  constant BF19_MAX    : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('0', 254, 1023); -- Maximum Normal Positive
  constant BF19_MIN    : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('0', 1, 0);      -- Minimum Normal Positive
  constant BF19_INF    : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('0', 255, 0);    -- +Infinity
  constant BF19_MINF   : std_logic_vector(BF19_WIDTH-1 downto 0) := pack_bf19('1', 255, 0);    -- -Infinity

begin

  -- DUT instantiation
  dut : entity work.fp16_adder_tree
    generic map (PIPELINE_EN => true)
    port map (
      clk => clk, rst_n => rst_n, rnd_mode => rnd_mode,
      in0 => in0, in1 => in1, in2 => in2, in3 => in3,
      in4 => in4, in5 => in5, in6 => in6, in7 => in7,
      in8 => in8, in9 => in9, in10 => in10, in11 => in11,
      in12 => in12, in13 => in13, in14 => in14, in15 => in15,
      result => result,
      exc_overflow => exc_overflow, exc_underflow => exc_underflow,
      exc_inexact => exc_inexact, exc_inf => exc_inf,
      exc_nan => exc_nan, exc_zero => exc_zero
    );

  -- Clock generation
  process
  begin
    clk <= '0'; wait for CLK_PERIOD/2;
    clk <= '1'; wait for CLK_PERIOD/2;
  end process;

  -- Stimulus process
  process
    variable pipe_flush : integer := PIPE_DEPTH + 2;
    
    procedure apply_to_all(val : in std_logic_vector(BF19_WIDTH-1 downto 0)) is
    begin
        in0 <= val; in1 <= val; in2 <= val; in3 <= val;
        in4 <= val; in5 <= val; in6 <= val; in7 <= val;
        in8 <= val; in9 <= val; in10 <= val; in11 <= val;
        in12 <= val; in13 <= val; in14 <= val; in15 <= val;
    end procedure;

  begin
    -- Reset
    rst_n <= '0';
    apply_to_all(BF19_ZERO_C);
    wait for CLK_PERIOD * 3;
    rst_n <= '1';
    wait for CLK_PERIOD;

    -- Test 1: 16 x 1.0
    report "=== TEST 1: 16 x 1.0 ===";
    apply_to_all(BF19_ONE);
    wait for CLK_PERIOD * pipe_flush;
    print_result("T1_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 2: 8 x 1.0 + 8 x -1.0
    report "=== TEST 2: 8x1.0 + 8x(-1.0) ===";
    in0 <= BF19_ONE;  in1 <= BF19_ONE;  in2 <= BF19_ONE;  in3 <= BF19_ONE;
    in4 <= BF19_ONE;  in5 <= BF19_ONE;  in6 <= BF19_ONE;  in7 <= BF19_ONE;
    in8 <= BF19_MONE; in9 <= BF19_MONE; in10 <= BF19_MONE; in11 <= BF19_MONE;
    in12 <= BF19_MONE; in13 <= BF19_MONE; in14 <= BF19_MONE; in15 <= BF19_MONE;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T2_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 3: All zeros
    report "=== TEST 3: All zeros ===";
    apply_to_all(BF19_ZERO_C);
    wait for CLK_PERIOD * pipe_flush;
    print_result("T3_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 4: Mixed magnitudes
    report "=== TEST 4: Mixed magnitudes (1.0, 2.0, 0.5) ===";
    in0  <= BF19_ONE;  in1  <= BF19_TWO;  in2  <= BF19_HALF; in3  <= BF19_ONE;
    in4  <= BF19_TWO;  in5  <= BF19_HALF; in6  <= BF19_ONE;  in7  <= BF19_TWO;
    in8  <= BF19_HALF; in9  <= BF19_ONE;  in10 <= BF19_TWO;  in11 <= BF19_HALF;
    in12 <= BF19_ONE;  in13 <= BF19_TWO;  in14 <= BF19_HALF; in15 <= BF19_ONE;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T4_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 5: NaN injection
    report "=== TEST 5: NaN propagation ===";
    apply_to_all(BF19_ONE);
    in7 <= BF19_NAN;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T5_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 6: Loss of Significance (Swamping)
    report "=== TEST 6: Swamping (1xBIG + 15xTINY) ===";
    apply_to_all(BF19_TINY);
    in0 <= BF19_BIG;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T6_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 7: Cancellation with Remainder
    report "=== TEST 7: Cancellation with Remainder (1xBIG + 1xMBIG + 14x1.0) ===";
    apply_to_all(BF19_ONE);
    in0 <= BF19_BIG;
    in1 <= BF19_MBIG;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T7_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 8: Overflow Generation
    report "=== TEST 8: Overflow (16xMAX) ===";
    apply_to_all(BF19_MAX);
    wait for CLK_PERIOD * pipe_flush;
    print_result("T8_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 9: Underflow Generation
    report "=== TEST 9: Minimum Normals (16xMIN) ===";
    apply_to_all(BF19_MIN);
    wait for CLK_PERIOD * pipe_flush;
    print_result("T9_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 10: Infinity Propagation
    report "=== TEST 10: Infinity Propagation (1xINF + 15x1.0) ===";
    apply_to_all(BF19_ONE);
    in3 <= BF19_INF;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T10_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 11: Invalid Operation
    report "=== TEST 11: Inf - Inf = NaN ===";
    apply_to_all(BF19_ZERO_C);
    in0 <= BF19_INF;
    in1 <= BF19_MINF;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T11_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- =========================================================================
    -- YENÝ EKLENEN CEBÝRSEL (ALGEBRAIC) KOMBÝNASYON TESTLERÝ
    -- =========================================================================

    -- Test 12: A - B + C
    -- 4.0 - 2.0 + 1.0 = 3.0
    -- Expected: 3.0 -> exp=128, man=512
    report "=== TEST 12: A - B + C (4.0 - 2.0 + 1.0 = 3.0) ===";
    apply_to_all(BF19_ZERO_C);
    in0 <= BF19_FOUR;
    in1 <= BF19_MTWO;
    in2 <= BF19_ONE;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T12_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 13: A - B - C
    -- 4.0 - 2.0 - 1.0 = 1.0
    -- Expected: 1.0 -> exp=127, man=0
    report "=== TEST 13: A - B - C (4.0 - 2.0 - 1.0 = 1.0) ===";
    apply_to_all(BF19_ZERO_C);
    in0 <= BF19_FOUR;
    in1 <= BF19_MTWO;
    in2 <= BF19_MONE;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T13_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 14: -A - B - C
    -- -4.0 - 2.0 - 1.0 = -7.0
    -- Expected: -7.0 -> sign='1', exp=129, man=768
    report "=== TEST 14: -A - B - C (-4.0 - 2.0 - 1.0 = -7.0) ===";
    apply_to_all(BF19_ZERO_C);
    in0 <= BF19_MFOUR;
    in1 <= BF19_MTWO;
    in2 <= BF19_MONE;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T14_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    -- Test 15: Alternating Signs
    -- 8 * (1.0) + 8 * (-2.0) = -8.0
    -- Expected: -8.0 -> sign='1', exp=130, man=0
    report "=== TEST 15: Alternating Signs (8x1.0 + 8x-2.0 = -8.0) ===";
    in0 <= BF19_ONE; in1 <= BF19_MTWO; in2 <= BF19_ONE; in3 <= BF19_MTWO;
    in4 <= BF19_ONE; in5 <= BF19_MTWO; in6 <= BF19_ONE; in7 <= BF19_MTWO;
    in8 <= BF19_ONE; in9 <= BF19_MTWO; in10 <= BF19_ONE; in11 <= BF19_MTWO;
    in12 <= BF19_ONE; in13 <= BF19_MTWO; in14 <= BF19_ONE; in15 <= BF19_MTWO;
    wait for CLK_PERIOD * pipe_flush;
    print_result("T15_RESULT", result, exc_overflow, exc_underflow, exc_nan, exc_inf);

    report "=== All tests complete ===";
    wait;
  end process;

end architecture sim;
-- =============================================================================
-- bf19_pkg.vhd
-- BF19 Floating-Point Package
-- Format: 1-bit sign | 8-bit exponent (biased-127) | 10-bit mantissa
-- Total: 19 bits
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package bf19_pkg is

  -- -------------------------------------------------------------------------
  -- BF19 bit-field constants
  -- -------------------------------------------------------------------------
  constant BF19_WIDTH   : integer := 19;
  constant EXP_WIDTH    : integer := 8;
  constant MANT_WIDTH   : integer := 10;   -- stored (no implicit 1)
  constant EXP_BIAS     : integer := 127;

  -- Sign, exponent, mantissa slice positions (downto 0)
  constant SIGN_BIT     : integer := 18;
  constant EXP_HI       : integer := 17;
  constant EXP_LO       : integer := 10;
  constant MANT_HI      : integer := 9;
  constant MANT_LO      : integer := 0;

  -- -------------------------------------------------------------------------
  -- Internal significand width used during the fused addition
  --   Alignment field: 2f+6 bits  (f = MANT_WIDTH+1 = 11, implicit 1 added)
  --   We track guard(1) + round(1) + sticky(1) beyond LSB => 2*11+6 = 28
  -- -------------------------------------------------------------------------
  constant F            : integer := MANT_WIDTH + 1;   -- 11 (with implicit 1)
  constant SIG_WIDTH    : integer := 2*F + 6;          -- 28 aligned bits
  -- After early-normalization the adder is reduced to F+1 = 12 bits MSBs
  constant ADD_WIDTH    : integer := F + 1;            -- 12

  -- -------------------------------------------------------------------------
  -- Special exponent codes
  -- -------------------------------------------------------------------------
  constant EXP_INF_NAN  : unsigned(EXP_WIDTH-1 downto 0) := (others => '1');
  constant EXP_ZERO     : unsigned(EXP_WIDTH-1 downto 0) := (others => '0');

  -- -------------------------------------------------------------------------
  -- Rounding mode encoding (IEEE-754 compatible)
  -- -------------------------------------------------------------------------
  constant RND_NEAREST_EVEN : std_logic_vector(2 downto 0) := "000";
  constant RND_NEAREST_AWAY : std_logic_vector(2 downto 0) := "001";
  constant RND_TOWARD_ZERO  : std_logic_vector(2 downto 0) := "010";
  constant RND_TOWARD_POS   : std_logic_vector(2 downto 0) := "011";
  constant RND_TOWARD_NEG   : std_logic_vector(2 downto 0) := "100";

end package bf19_pkg;
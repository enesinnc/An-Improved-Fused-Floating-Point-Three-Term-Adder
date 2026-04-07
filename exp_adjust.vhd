library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bf19_pkg.all;

entity exp_adjust is
  port (
    exp_max       : in  unsigned(EXP_WIDTH-1 downto 0);
    norm_shift    : in  unsigned(5 downto 0);
    carry_out     : in  std_logic_vector(1 downto 0);
    round_up      : in  std_logic;
    exc_a, exc_b, exc_c : in std_logic_vector(1 downto 0);

    adj_exp       : out unsigned(EXP_WIDTH-1 downto 0);
    exc_overflow  : out std_logic;
    exc_underflow : out std_logic;
    exc_inexact   : out std_logic;
    exc_inf       : out std_logic;
    exc_nan       : out std_logic;
    exc_zero      : out std_logic
  );
end entity exp_adjust;

architecture rtl of exp_adjust is
  constant ADJ_BITS : integer := EXP_WIDTH + 2;
  constant PLACEMENT_OFFSET : integer := 3;
  signal sig_carry    : unsigned(1 downto 0);
  signal exp_adjusted : unsigned(ADJ_BITS-1 downto 0);
begin
  sig_carry <= unsigned(carry_out);
  
  process(exp_max, norm_shift, sig_carry)
    variable e : unsigned(ADJ_BITS-1 downto 0);
  begin
    e := resize(exp_max,    ADJ_BITS)
       - resize(norm_shift, ADJ_BITS)
       + resize(sig_carry,  ADJ_BITS)
       + to_unsigned(PLACEMENT_OFFSET, ADJ_BITS);
    exp_adjusted <= e;
  end process;

  adj_exp <= exp_adjusted(EXP_WIDTH-1 downto 0);
  
  process(exp_adjusted, round_up, exc_a, exc_b, exc_c)
    variable any_nan, any_inf, any_zero, ovf, uvf : std_logic;
  begin
    any_nan := '0'; any_inf := '0'; any_zero := '0';
    if exc_a = "11" or exc_b = "11" or exc_c = "11" then any_nan := '1'; end if;
    if exc_a = "10" or exc_b = "10" or exc_c = "10" then
      if (exc_a = "10" and (exc_b = "10" or exc_c = "10")) or (exc_b = "10" and exc_c = "10") then
        any_nan := '1';
      else any_inf := '1'; end if;
    end if;
    if exc_a = "01" and exc_b = "01" and exc_c = "01" then any_zero := '1'; end if;

    ovf := '0'; uvf := '0';
    if any_nan = '0' and any_inf = '0' and any_zero = '0' then
      if exp_adjusted(ADJ_BITS-1) = '0' and exp_adjusted(EXP_WIDTH-1 downto 0) >= EXP_INF_NAN then ovf := '1'; end if;
      if exp_adjusted(ADJ_BITS-1) = '1' or exp_adjusted(ADJ_BITS-1 downto 0) = 0 then uvf := '1'; end if;
    end if;

    exc_nan <= any_nan; exc_inf <= any_inf and not any_nan;
    exc_zero <= any_zero and not any_nan and not any_inf;
    exc_overflow <= ovf; exc_underflow <= uvf;
    exc_inexact <= round_up or ovf or uvf;
  end process;
end architecture rtl;
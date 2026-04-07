library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bf19_pkg.all;

entity exp_compare_align is
  port (
    a_in     : in  std_logic_vector(BF19_WIDTH-1 downto 0);
    b_in     : in  std_logic_vector(BF19_WIDTH-1 downto 0);
    c_in     : in  std_logic_vector(BF19_WIDTH-1 downto 0);
    op1      : in  std_logic;
    op2      : in  std_logic;
    sign_a   : out std_logic;
    sign_b   : out std_logic;
    sign_c   : out std_logic;
    seff_a   : out std_logic;
    seff_b   : out std_logic;
    seff_c   : out std_logic;
    exp_max  : out unsigned(EXP_WIDTH-1 downto 0);
    shf_a    : out unsigned(SIG_WIDTH-1 downto 0);
    shf_b    : out unsigned(SIG_WIDTH-1 downto 0);
    shf_c    : out unsigned(SIG_WIDTH-1 downto 0);
    exc_a    : out std_logic_vector(1 downto 0);
    exc_b    : out std_logic_vector(1 downto 0);
    exc_c    : out std_logic_vector(1 downto 0)
  );
end entity exp_compare_align;

architecture rtl of exp_compare_align is
  signal exp_a, exp_b, exp_c : unsigned(EXP_WIDTH-1 downto 0);
  signal man_a, man_b, man_c : unsigned(MANT_WIDTH-1 downto 0);
  signal sig_a, sig_b, sig_c : unsigned(F-1 downto 0);
  signal diff_ab, diff_ba, diff_bc, diff_cb, diff_ac, diff_ca : unsigned(EXP_WIDTH downto 0);
  signal abs_ab, abs_bc, abs_ac : unsigned(EXP_WIDTH-1 downto 0);
  signal a_ge_b, b_ge_c, c_ge_a : std_logic;
  signal shamt_a, shamt_b, shamt_c : unsigned(EXP_WIDTH-1 downto 0);

  function or_reduce(v : unsigned) return std_logic is
    variable r : std_logic := '0';
  begin
    for i in v'range loop r := r or v(i); end loop; return r;
  end function;

  function classify(exp_v : unsigned; man_v : unsigned) return std_logic_vector is
    variable ret : std_logic_vector(1 downto 0);
  begin
    if exp_v = EXP_ZERO then
      if unsigned(man_v) = 0 then ret := "01";
      else ret := "00"; end if;
    elsif exp_v = EXP_INF_NAN then
      if unsigned(man_v) = 0 then ret := "10";
      else ret := "11"; end if;
    else
      ret := "00";
    end if;
    return ret;
  end function;

  function barrel_shift_r(sig_in : unsigned(F-1 downto 0); shamt : unsigned(EXP_WIDTH-1 downto 0)) return unsigned is
    variable full    : unsigned(SIG_WIDTH-1 downto 0);
    variable shamt_i : integer;
    variable sticky  : std_logic;
    variable result  : unsigned(SIG_WIDTH-1 downto 0);
  begin
    full := (others => '0');
    full(SIG_WIDTH-4 downto SIG_WIDTH-F-3) := sig_in;
    shamt_i := to_integer(shamt);
    if shamt_i > SIG_WIDTH - 1 then shamt_i := SIG_WIDTH - 1; end if;
    sticky := '0';
    if shamt_i > 0 then
      for k in 0 to SIG_WIDTH-1 loop
        if k < shamt_i then sticky := sticky or full(k);
        end if;
      end loop;
    end if;
    if to_integer(shamt) >= SIG_WIDTH then sticky := sticky or (or_reduce(sig_in)); end if;
    result := shift_right(full, shamt_i);
    result(0) := result(0) or sticky;
    return result;
  end function;
begin
  sign_a <= a_in(SIGN_BIT);
  sign_b <= b_in(SIGN_BIT); sign_c <= c_in(SIGN_BIT);
  exp_a  <= unsigned(a_in(EXP_HI downto EXP_LO)); exp_b <= unsigned(b_in(EXP_HI downto EXP_LO));
  exp_c <= unsigned(c_in(EXP_HI downto EXP_LO));
  man_a  <= unsigned(a_in(MANT_HI downto MANT_LO)); man_b <= unsigned(b_in(MANT_HI downto MANT_LO));
  man_c <= unsigned(c_in(MANT_HI downto MANT_LO));

  sig_a <= ('1' & man_a) when exp_a /= EXP_ZERO else ('0' & man_a);
  sig_b <= ('1' & man_b) when exp_b /= EXP_ZERO else ('0' & man_b);
  sig_c <= ('1' & man_c) when exp_c /= EXP_ZERO else ('0' & man_c);

  seff_a <= '0';
  seff_b <= a_in(SIGN_BIT) xor (b_in(SIGN_BIT) xor op1);
  seff_c <= a_in(SIGN_BIT) xor (c_in(SIGN_BIT) xor op2);

  exc_a <= classify(exp_a, man_a);
  exc_b <= classify(exp_b, man_b); exc_c <= classify(exp_c, man_c);

  diff_ab <= ('0' & exp_a) - ('0' & exp_b);
  diff_ba <= ('0' & exp_b) - ('0' & exp_a);
  diff_bc <= ('0' & exp_b) - ('0' & exp_c);
  diff_cb <= ('0' & exp_c) - ('0' & exp_b);
  diff_ac <= ('0' & exp_a) - ('0' & exp_c);
  diff_ca <= ('0' & exp_c) - ('0' & exp_a);

  a_ge_b <= not diff_ab(EXP_WIDTH); b_ge_c <= not diff_bc(EXP_WIDTH);
  c_ge_a <= not diff_ca(EXP_WIDTH);

  abs_ab <= diff_ab(EXP_WIDTH-1 downto 0) when a_ge_b = '1' else diff_ba(EXP_WIDTH-1 downto 0);
  abs_bc <= diff_bc(EXP_WIDTH-1 downto 0) when b_ge_c = '1' else diff_cb(EXP_WIDTH-1 downto 0);
  abs_ac <= diff_ac(EXP_WIDTH-1 downto 0) when (not c_ge_a) = '1' else diff_ca(EXP_WIDTH-1 downto 0);

  process(a_ge_b, b_ge_c, c_ge_a, exp_a, exp_b, exp_c, abs_ab, abs_bc, abs_ac)
  begin
    if a_ge_b = '1' and (not c_ge_a) = '1' then
      exp_max <= exp_a;
      shamt_a <= (others => '0'); shamt_b <= abs_ab; shamt_c <= abs_ac;
    elsif b_ge_c = '1' and a_ge_b = '0' then
      exp_max <= exp_b; shamt_a <= abs_ab;
      shamt_b <= (others => '0'); shamt_c <= abs_bc;
    else
      exp_max <= exp_c; shamt_a <= abs_ac;
      shamt_b <= abs_bc; shamt_c <= (others => '0');
    end if;
  end process;

  shf_a <= barrel_shift_r(sig_a, shamt_a);
  shf_b <= barrel_shift_r(sig_b, shamt_b);
  shf_c <= barrel_shift_r(sig_c, shamt_c);
end architecture rtl;
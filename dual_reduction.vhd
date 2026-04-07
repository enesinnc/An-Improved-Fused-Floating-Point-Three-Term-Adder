library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bf19_pkg.all;

entity dual_reduction is
  port (
    seff_a  : in  std_logic;
    seff_b  : in  std_logic;
    seff_c  : in  std_logic;
    shf_a   : in  unsigned(SIG_WIDTH-1 downto 0);
    shf_b   : in  unsigned(SIG_WIDTH-1 downto 0);
    shf_c   : in  unsigned(SIG_WIDTH-1 downto 0);
    p_sum   : out unsigned(SIG_WIDTH+1 downto 0);
    p_carry : out unsigned(SIG_WIDTH+1 downto 0);
    n_sum   : out unsigned(SIG_WIDTH+1 downto 0);
    n_carry : out unsigned(SIG_WIDTH+1 downto 0);
    lza_a   : out unsigned(SIG_WIDTH+1 downto 0);
    lza_b   : out unsigned(SIG_WIDTH+1 downto 0);
    lza_c   : out unsigned(SIG_WIDTH+1 downto 0)
  );
end entity dual_reduction;

architecture rtl of dual_reduction is
  constant W : integer := SIG_WIDTH + 2;
  signal a_ext, b_ext, c_ext       : unsigned(1 downto 0);
  signal n_a_ext, n_b_ext, n_c_ext : unsigned(1 downto 0);

  function csa_bit(a, b, ci : std_logic) return std_logic_vector is
    variable s_out, c_out : std_logic;
    variable result : std_logic_vector(1 downto 0);
  begin
    s_out  := a xor b xor ci;
    c_out  := (a and b) or (b and ci) or (a and ci);
    result := c_out & s_out;
    return result;
  end function;
begin
  process(seff_a, seff_b, seff_c)
    variable sel : std_logic_vector(2 downto 0);
  begin
    sel := seff_a & seff_b & seff_c;
    case sel is
      when "000"  => a_ext <= "00"; b_ext <= "00"; c_ext <= "00";
      when "001"  => a_ext <= "10"; b_ext <= "00"; c_ext <= "10";
      when "010"  => a_ext <= "00"; b_ext <= "10"; c_ext <= "10";
      when "011"  => a_ext <= "10"; b_ext <= "11"; c_ext <= "11";
      when "100"  => a_ext <= "10"; b_ext <= "10"; c_ext <= "00";
      when "101"  => a_ext <= "11"; b_ext <= "10"; c_ext <= "11";
      when "110"  => a_ext <= "11"; b_ext <= "11"; c_ext <= "10";
      when "111"  => a_ext <= "00"; b_ext <= "00"; c_ext <= "00";
      when others => a_ext <= "00"; b_ext <= "00"; c_ext <= "00";
    end case;
  end process;

  process(seff_a, seff_b, seff_c)
    variable sel : std_logic_vector(2 downto 0);
  begin
    sel := (not seff_a) & (not seff_b) & (not seff_c);
    case sel is
      when "000"  => n_a_ext <= "00"; n_b_ext <= "00"; n_c_ext <= "00";
      when "001"  => n_a_ext <= "10"; n_b_ext <= "00"; n_c_ext <= "10";
      when "010"  => n_a_ext <= "00"; n_b_ext <= "10"; n_c_ext <= "10";
      when "011"  => n_a_ext <= "10"; n_b_ext <= "11"; n_c_ext <= "11";
      when "100"  => n_a_ext <= "10"; n_b_ext <= "10"; n_c_ext <= "00";
      when "101"  => n_a_ext <= "11"; n_b_ext <= "10"; n_c_ext <= "11";
      when "110"  => n_a_ext <= "11"; n_b_ext <= "11"; n_c_ext <= "10";
      -- DÜZELTME: 111 durumunda 3'ü de negatiftir. Ekstansiyon kaybýný önlemek için maksimum 11 dolduruyoruz.
      when "111"  => n_a_ext <= "11"; n_b_ext <= "11"; n_c_ext <= "11"; 
      when others => n_a_ext <= "00"; n_b_ext <= "00"; n_c_ext <= "00";
    end case;
  end process;

  process(seff_a, seff_b, seff_c, shf_a, shf_b, shf_c, a_ext, b_ext, c_ext)
    variable a_bop, b_bop, c_bop : unsigned(SIG_WIDTH-1 downto 0);
    variable a_op, b_op, c_op    : unsigned(W-1 downto 0);
    variable s_v, co_v           : unsigned(W-1 downto 0);
    variable csa_r               : std_logic_vector(1 downto 0);
  begin
    if seff_a = '0' then a_bop := shf_a; else a_bop := not shf_a; end if;
    if seff_b = '0' then b_bop := shf_b; else b_bop := not shf_b; end if;
    if seff_c = '0' then c_bop := shf_c; else c_bop := not shf_c; end if;

    a_op := a_bop & a_ext;
    b_op := b_bop & b_ext; 
    c_op := c_bop & c_ext;
    
    lza_a <= a_op; lza_b <= b_op; lza_c <= c_op;
    
    s_v := (others => '0'); co_v := (others => '0');
    for i in 0 to W-1 loop
      csa_r := csa_bit(a_op(i), b_op(i), c_op(i));
      s_v(i) := csa_r(0);
      if i < W-1 then co_v(i+1) := csa_r(1); end if;
    end loop;
    p_sum <= s_v; p_carry <= co_v;
  end process;

  process(seff_a, seff_b, seff_c, shf_a, shf_b, shf_c, n_a_ext, n_b_ext, n_c_ext)
    variable a_bop, b_bop, c_bop : unsigned(SIG_WIDTH-1 downto 0);
    variable a_op, b_op, c_op    : unsigned(W-1 downto 0);
    variable s_v, co_v           : unsigned(W-1 downto 0);
    variable csa_r               : std_logic_vector(1 downto 0);
  begin
    if seff_a = '0' then a_bop := not shf_a; else a_bop := shf_a; end if;
    if seff_b = '0' then b_bop := not shf_b; else b_bop := shf_b; end if;
    if seff_c = '0' then c_bop := not shf_c; else c_bop := shf_c; end if;

    a_op := a_bop & n_a_ext;
    b_op := b_bop & n_b_ext; 
    c_op := c_bop & n_c_ext;

    s_v := (others => '0'); co_v := (others => '0');
    for i in 0 to W-1 loop
      csa_r := csa_bit(a_op(i), b_op(i), c_op(i));
      s_v(i) := csa_r(0);
      if i < W-1 then co_v(i+1) := csa_r(1); end if;
    end loop;
    n_sum <= s_v; n_carry <= co_v;
  end process;
end architecture rtl;
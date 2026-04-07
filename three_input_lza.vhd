library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bf19_pkg.all;

entity three_input_lza is
  port (
    lza_a       : in  unsigned(SIG_WIDTH+1 downto 0);
    lza_b       : in  unsigned(SIG_WIDTH+1 downto 0);
    lza_c       : in  unsigned(SIG_WIDTH+1 downto 0);
    lzc_raw     : out unsigned(4 downto 0);   
    lzc_err     : out std_logic;     
    signif_comp : out std_logic               
  );
end entity three_input_lza;

architecture rtl of three_input_lza is
  constant W : integer := SIG_WIDTH + 2;
  type slv_arr is array (0 to W-1) of std_logic;
  signal z_s, t_s, g_s, f_s : slv_arr;

begin
  preenc_gen : for i in 0 to W-1 generate
    preenc_proc : process(lza_a, lza_b, lza_c)
      variable ai, bi, ci          : std_logic;
      variable sum2                : unsigned(1 downto 0);
      variable p0i, p1i, p2i, p3i  : std_logic;
      variable p0j, p1j, p2j, p3j  : std_logic;
      variable ai_p, bi_p, ci_p    : std_logic;
      variable sum2_p              : unsigned(1 downto 0);
    begin
      ai := lza_a(i); bi := lza_b(i); ci := lza_c(i);
      sum2 := ("0" & ai) + ("0" & bi) + ("0" & ci);
      
      p0i := (not sum2(1)) and (not sum2(0));
      p1i := (not sum2(1)) and      sum2(0);
      p2i :=      sum2(1)  and (not sum2(0));
      p3i :=      sum2(1)  and      sum2(0);

      if i = 0 then
        z_s(0) <= p0i;
        g_s(0) <= p2i or p3i;
        t_s(0) <= p1i;
      else
        ai_p := lza_a(i-1); bi_p := lza_b(i-1); ci_p := lza_c(i-1);
        sum2_p := ("0" & ai_p) + ("0" & bi_p) + ("0" & ci_p);
        
        p0j := (not sum2_p(1)) and (not sum2_p(0));
        p1j := (not sum2_p(1)) and      sum2_p(0);
        p2j :=      sum2_p(1)  and (not sum2_p(0));
        p3j :=      sum2_p(1)  and      sum2_p(0);

        z_s(i) <= (p0i and (p0j or p1j)) or (p3i and (p2j or p3j));
        g_s(i) <= (p2i and (p0j or p1j)) or (p1i and (p2j or p3j)) or (p3i and (p0j or p1j));
        t_s(i) <= (not ((p0i and (p0j or p1j)) or (p3i and (p2j or p3j)))) and
                  (not ((p2i and (p0j or p1j)) or (p1i and (p2j or p3j)) or (p3i and (p0j or p1j))));
      end if;
    end process preenc_proc;
  end generate preenc_gen;

  fvec_gen : for i in 0 to W-1 generate
    fvec_interior : if (i >= 1 and i <= W-2) generate
      f_s(i) <= (    t_s(i+1)  and ((g_s(i) and not z_s(i-1)) or (z_s(i) and not g_s(i-1))))
             or ((not t_s(i+1)) and ((z_s(i) and not z_s(i-1)) or (g_s(i) and not g_s(i-1))));
    end generate fvec_interior;

    fvec_lower : if i = 0 generate
      f_s(0) <= (t_s(1) and g_s(0)) or ((not t_s(1)) and z_s(0));
    end generate fvec_lower;

    fvec_upper : if i = W-1 generate
      f_s(W-1) <= '0';
    end generate fvec_upper;
  end generate fvec_gen;

  lzd_proc : process(f_s)
    variable found : boolean;
    variable cnt   : unsigned(4 downto 0);
    variable pred  : integer;
  begin
    found := false;
    cnt   := to_unsigned(W-1, 5);   

    for i in W-1 downto 0 loop
      if f_s(i) = '1' and not found then
        cnt   := to_unsigned(W-1-i, 5);
        found := true;
      end if;
    end loop;

    lzc_raw <= cnt;
    pred := (W-1) - to_integer(cnt) + 1;
    if pred <= W-1 and pred >= 0 then
      lzc_err <= f_s(pred);
    else
      lzc_err <= '0';
    end if;
  end process lzd_proc;

  signif_comp_proc : process(z_s, t_s)
    variable comp    : std_logic;
    variable t_chain : std_logic;
  begin
    comp    := z_s(W-1);
    t_chain := t_s(W-1);
    for i in W-2 downto 0 loop
      comp    := comp or (t_chain and z_s(i));
      t_chain := t_chain and t_s(i);
    end loop;
    comp := comp or t_chain;
    signif_comp <= comp;
  end process signif_comp_proc;

end architecture rtl;
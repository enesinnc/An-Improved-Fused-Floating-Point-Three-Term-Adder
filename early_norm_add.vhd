-- =============================================================================
-- early_norm_add.vhd
-- Stage 2c/3 - Hybrid LZA/LZD Normalization + Significand Addition
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bf19_pkg.all;

entity early_norm_add is
  port (
    p_sum          : in  unsigned(SIG_WIDTH+1 downto 0);
    p_carry        : in  unsigned(SIG_WIDTH+1 downto 0);
    n_sum          : in  unsigned(SIG_WIDTH+1 downto 0);
    n_carry        : in  unsigned(SIG_WIDTH+1 downto 0);
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
end entity early_norm_add;

architecture rtl of early_norm_add is
  constant W : integer := SIG_WIDTH + 2;
begin
  process(p_sum, p_carry, n_sum, n_carry, lzc_raw, lzc_err, rnd_mode)
    variable sh_lza           : integer range 0 to W-1;
    variable sh               : integer range 0 to 63;
    variable sh_exact         : integer range 0 to W;
    variable full_sum         : unsigned(W-1 downto 0);
    variable full_norm_sum    : unsigned(W downto 0);
    variable ac               : std_logic;
    variable g, r, s_bit, lsb : std_logic;
    variable mant_v           : unsigned(MANT_WIDTH-1 downto 0);
    variable snp              : unsigned(MANT_WIDTH downto 0);
    variable snp_ext          : unsigned(MANT_WIDTH+1 downto 0);
    variable rnd_carry, rnd_up_v : std_logic;
    variable rnd_pos, rnd_neg, rnd_nea, rnd_naw : std_logic;
    variable true_sign        : std_logic;
  begin
    full_sum := p_sum + p_carry;
    true_sign := full_sum(W-1);
    final_sign_out <= true_sign;
    
    if true_sign = '1' then 
      full_sum := n_sum + n_carry; 
    end if;

    if full_sum = to_unsigned(0, W) then
      sig_zero       <= '1';
      carry_out      <= "00";
      norm_shift_out <= (others => '0');
      sig_norm       <= (others => '0');
    else
      sig_zero <= '0';

      -- ===================================================================
      -- DÜZELTME: LZA Verification mantýðý kandýrýlmasýn diye p_sum ve 
      -- p_carry'yi kaydýrýp toplamak yerine doðrudan temiz olan full_sum
      -- üzerinden shift alýyoruz.
      -- ===================================================================
      if lzc_err = '1' then sh_lza := to_integer(lzc_raw) + 1;
      else sh_lza := to_integer(lzc_raw); end if;
      if sh_lza > W-1 then sh_lza := W-1; end if;

      full_norm_sum := shift_left('0' & full_sum, sh_lza);
      ac := full_norm_sum(W);

      -- LZA doðrulamasý: Ýþaret bitlerinden arýnmýþ sonuçta test edilir
      if ac = '1' then sh := sh_lza;
      elsif full_norm_sum(W-1) = '1' then sh := sh_lza;
      elsif full_norm_sum(W-2) = '1' then sh := sh_lza + 1;
      elsif full_norm_sum(W-3) = '1' then sh := sh_lza + 2;
      else 
        -- Fallback: Kesin (Exact) LZD
        sh_exact := 0;
        for i in W-1 downto 0 loop
          if full_sum(i) = '1' then
            sh_exact := W - 1 - i;
            exit;
          end if;
        end loop;
        sh := sh_exact;
        full_norm_sum := shift_left('0' & full_sum, sh);
        ac := full_norm_sum(W);
      end if;

      if sh > 63 then sh := 63; end if;
      norm_shift_out <= to_unsigned(sh, 6);

      if ac = '1' then 
        mant_v := full_norm_sum(W-1 downto W-MANT_WIDTH);
        lsb    := full_norm_sum(W-MANT_WIDTH);
        g      := full_norm_sum(W-MANT_WIDTH-1);
        r      := full_norm_sum(W-MANT_WIDTH-2);
        s_bit  := '0';
        for i in 0 to W-MANT_WIDTH-3 loop s_bit := s_bit or full_norm_sum(i); end loop;
      elsif full_norm_sum(W-1) = '1' then 
        mant_v := full_norm_sum(W-2 downto W-MANT_WIDTH-1);
        lsb    := full_norm_sum(W-MANT_WIDTH-1);
        g      := full_norm_sum(W-MANT_WIDTH-2);
        r      := full_norm_sum(W-MANT_WIDTH-3);
        s_bit  := '0';
        for i in 0 to W-MANT_WIDTH-4 loop s_bit := s_bit or full_norm_sum(i); end loop;
      elsif full_norm_sum(W-2) = '1' then 
        mant_v := full_norm_sum(W-3 downto W-MANT_WIDTH-2);
        lsb    := full_norm_sum(W-MANT_WIDTH-2);
        g      := full_norm_sum(W-MANT_WIDTH-3);
        r      := full_norm_sum(W-MANT_WIDTH-4);
        s_bit  := '0';
        for i in 0 to W-MANT_WIDTH-5 loop s_bit := s_bit or full_norm_sum(i); end loop;
      elsif full_norm_sum(W-3) = '1' then 
        mant_v := full_norm_sum(W-4 downto W-MANT_WIDTH-3);
        lsb    := full_norm_sum(W-MANT_WIDTH-3);
        g      := full_norm_sum(W-MANT_WIDTH-4);
        r      := full_norm_sum(W-MANT_WIDTH-5);
        s_bit  := '0';
        for i in 0 to W-MANT_WIDTH-6 loop s_bit := s_bit or full_norm_sum(i); end loop;
      else 
        mant_v := full_norm_sum(W-5 downto W-MANT_WIDTH-4);
        lsb    := full_norm_sum(W-MANT_WIDTH-4);
        g      := full_norm_sum(W-MANT_WIDTH-5);
        r      := full_norm_sum(W-MANT_WIDTH-6);
        s_bit  := '0';
        for i in 0 to W-MANT_WIDTH-7 loop s_bit := s_bit or full_norm_sum(i); end loop;
      end if;

      snp := ac & mant_v;

      rnd_pos := (not true_sign) and (g or r or s_bit);
      rnd_neg :=      true_sign  and (g or r or s_bit);
      rnd_nea := g and (lsb or r or s_bit);
      rnd_naw := g;

      case rnd_mode is
        when RND_NEAREST_EVEN => rnd_up_v := rnd_nea;
        when RND_NEAREST_AWAY => rnd_up_v := rnd_naw;
        when RND_TOWARD_ZERO  => rnd_up_v := '0';
        when RND_TOWARD_POS   => rnd_up_v := rnd_pos;
        when RND_TOWARD_NEG   => rnd_up_v := rnd_neg;
        when others           => rnd_up_v := rnd_nea;
      end case;

      if rnd_up_v = '1' then snp_ext := ('0' & snp) + 1;
      else snp_ext := '0' & snp; end if;

      rnd_carry := snp_ext(MANT_WIDTH+1);
      sig_norm  <= snp_ext(MANT_WIDTH downto 0);
      
      if ac = '1' and rnd_carry = '1' then carry_out <= "10";
      elsif ac = '1' or rnd_carry = '1' then carry_out <= "01";
      else carry_out <= "00"; end if;
    end if;
  end process;
end architecture rtl;
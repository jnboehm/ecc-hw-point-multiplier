library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity submod is
  generic(width : integer := 396;
          base  : integer := 18);

  port (a   : in  std_logic_vector(width - 1 downto 0);
        b   : in  std_logic_vector(width - 1 downto 0);
        cin : in  std_logic;
        s   : out std_logic_vector(width - 1 downto 0));
end entity submod;

architecture Behavioral of submod is
  signal tmp     : std_logic_vector(width - 1 downto 0);
  signal tmp2    : std_logic_vector(width - 1 downto 0);
  signal sum_tmp : std_logic_vector(width - 1 downto 0);
  signal sum_mod_tmp : std_logic_vector(width - 1 downto 0);

  -- the constant p192 as specified by the NIST standard.
  constant p192 : std_logic_vector(width - 1 downto 0) := "000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101111111111111111111111111111111111111111111111111111111111111111";
begin
  tmp  <= std_logic_vector((b'range => '1') xor b);
  tmp2 <= std_logic_vector(unsigned(tmp) + 1);

  adder : entity work.rc_adder_standard (Behavioral)
    generic map (width => width,
                 base  => base)
    port map (a   => a,
              b   => tmp2,
              cin => cin,
              s   => sum_tmp);

  maybe_add : entity work.rc_adder_standard (Behavioral)
    generic map (width => width,
                 base  => base)
    port map(a => sum_tmp,
             b => p192,
             cin => cin,
             s => sum_mod_tmp);

  s <= sum_tmp when sum_tmp(sum_tmp'high) = '0'
       else sum_mod_tmp;

end architecture;

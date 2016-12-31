library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity subtraction is
  generic(width : integer := 396;
          base  : integer := 18);

  port (a   : in  std_logic_vector(width - 1 downto 0);
        b   : in  std_logic_vector(width - 1 downto 0);
        cin : in  std_logic;
        s   : out std_logic_vector(width - 1 downto 0));
end entity;

architecture Behavioral of subtraction is
  signal tmp     : std_logic_vector(width - 1 downto 0);
  signal tmp2    : std_logic_vector(width - 1 downto 0);
  signal sum_tmp : std_logic_vector(width downto 0);
begin
  tmp  <= std_logic_vector((b'range => '1') xor b);
  tmp2 <= std_logic_vector(unsigned(tmp) + 1);

  adder : entity work.rc_adder (Behavioral)
    generic map (width => width,
                 base  => base)
    port map (a   => a,
              b   => tmp2,
              cin => cin,
              s   => sum_tmp);

  s <= sum_tmp(width - 1 downto 0);

end architecture;

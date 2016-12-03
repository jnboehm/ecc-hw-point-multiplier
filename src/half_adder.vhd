library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity half_adder is

  generic (base : integer := 25);

  port (a    : in  std_logic_vector(base-1 downto 0);
        b    : in  std_logic_vector(base-1 downto 0);
        s    : out std_logic_vector(base-1 downto 0);
        cout : out std_logic);
end half_adder;

architecture Behavioral of half_adder is

  signal t : std_logic_vector(base downto 0);

begin

  t    <= std_logic_vector(unsigned("0" & a) + unsigned("0" & b));
  s    <= t(base-1 downto 0);
  cout <= t(base);

end Behavioral;

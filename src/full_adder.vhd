library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity full_adder is
  generic(base : integer);

  port (a    : in  std_logic_vector(base-1 downto 0);
        b    : in  std_logic_vector(base-1 downto 0);
        cin  : in  std_logic;
        s    : out std_logic_vector(base-1 downto 0);
        cout : out std_logic);

end full_adder;

architecture Behavioral of full_adder is

  signal sum1           : std_logic_vector(base-1 downto 0);
  signal carry1, carry2 : std_logic;
begin

  adder1 : entity work.half_adder(Behavioral)
    generic map (base => base)
    port map (a    => a,
              b    => b,
              s    => sum1,
              cout => carry1);

  adder2 : entity work.half_adder(Behavioral)
    generic map (base => base)
    port map (a                    => sum1,
              b(0)                 => cin,
              b(base - 1 downto 1) => (others => '0'),
              s                    => s,
              cout                 => carry2);

  --not sure
  cout <= carry1 or carry2;

end Behavioral;

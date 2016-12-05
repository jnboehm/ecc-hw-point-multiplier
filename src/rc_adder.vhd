library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rc_adder is

  generic(width : integer := 256;
          base  : integer := 32);

  port (a   : in  std_logic_vector(width - 1 downto 0);
        b   : in  std_logic_vector(width - 1 downto 0);
        cin : in  std_logic;
        s   : out std_logic_vector(width downto 0));

end rc_adder;

architecture Behavioral of rc_adder is

  signal carry : std_logic_vector(width / base downto 0) := (others => '0');

begin

  adders : for I in 0 to width / base - 1 generate
  begin

    adder : entity work.full_adder (Behavioral)
      generic map (base => base)
      port map (a    => a((I + 1) * base - 1 downto I * base),
                b    => b((I + 1) * base - 1 downto I * base),
                cin  => carry(I),
                s    => s((I + 1) * base - 1 downto I * base),
                cout => carry(I + 1));

  end generate;

  carry(0)  <= cin;
  s(s'high) <= carry(carry'high);

end Behavioral;

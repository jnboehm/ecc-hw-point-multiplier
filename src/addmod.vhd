library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity addmod is

  generic(width : integer := 256;
          base  : integer := 32);

  port (a    : in  std_logic_vector(width - 1 downto 0);
        b    : in  std_logic_vector(width - 1 downto 0);
        cin  : in  std_logic;
        s    : out std_logic_vector(width - 1 downto 0);
        cout : out std_logic);

end addmod;

architecture Behavioral of addmod is

  signal carry            : std_logic_vector(width / base downto 0) := (others => '0');
  signal s_tmp, s_mod_tmp : std_logic_vector(width - 1 downto 0);

  -- the constant p192 as specified by the NIST standard.
  constant p192 : std_logic_vector(width - 1 downto 0) := "000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101111111111111111111111111111111111111111111111111111111111111111";
begin

  adders : for I in 0 to width / base - 1 generate
  begin

    adder : entity work.full_adder (Behavioral)
      generic map (base => base)
      port map (a    => a((I + 1) * base - 1 downto I * base),
                b    => b((I + 1) * base - 1 downto I * base),
                cin  => carry(I),
                s    => s_tmp((I + 1) * base - 1 downto I * base),
                cout => carry(I + 1));

  end generate;

  maybe_sub : entity work.subtraction (Behavioral)
    generic map (width => width,
                 base  => base)
    port map(a => s_tmp,
             b => p192,
             cin => cin,
             s => s_mod_tmp);


  s <= s_tmp when s_tmp < p192
       else s_mod_tmp;

  carry(0)  <= cin;
  cout <= carry(carry'high);

end Behavioral;

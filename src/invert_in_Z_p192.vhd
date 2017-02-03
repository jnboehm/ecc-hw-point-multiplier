library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inert_in_Z_p192 is
  generic(base  : integer := 2;
          width : integer := 4);

  port (clk     : in  std_logic;
        num     : in  std_logic_vector(width - 1 downto 0);
        inv_num : out std_logic_vector(width - 1 downto 0);
        start   : in  std_logic;
        ready   : out std_logic;
        reset   : in  std_logic);
end inert_in_Z_p192;

architecture Behavioral of inert_in_Z_p192 is

  -- the constant p192 as specified by the NIST standard.
  constant p192 : std_logic_vector(width - 1 downto 0) := "000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101111111111111111111111111111111111111111111111111111111111111111";

begin

  inverter : entity work.gcd (Behavioral)
    generic map (width => width,
                base  => base)
    port map(clk => clk,
             u_in => num,
             v_in => p192,
             gcd => open,
             ratio_u => inv_num,
             ratio_v => open,
             start => start,
             ready => ready,
             reset => reset);

end Behavioral;

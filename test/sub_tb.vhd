
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity sub_tb is
--  Port ( );
    generic( width : integer := 6;
             base : integer := 2 );

end sub_tb;

architecture Behavioral of sub_tb is

  -- Clock period definition (100Mhz)
  constant clk_period : time := 10 ns;

  -- Clock
  signal clk : std_logic;

  -- Output
  -- signal led : std_logic;

  signal a :   std_logic_vector(width-1 downto 0);
  signal b :   std_logic_vector(width-1 downto 0);
  signal cin : std_logic := '0';
  signal s : std_logic_vector(width - 1 downto 0);

begin

  uut : entity work.subtraction
    generic map( width => width, base => base )
    port map ( a => a, b => b, cin => cin, s => s );

  -- Clock process definitions
  clk_process : process
  begin
    clk <= '0';
    wait for clk_period/2;
    clk <= '1';
    wait for clk_period/2;
  end process;

  -- Stimulus process
  stim_proc : process

    -- Text I/O
    variable lineBuffer : line;

  begin

    -- Give a info message
    write(lineBuffer, string'("Reset not needed"));
    writeline(output, lineBuffer);

    -- Wait 30ns
    wait for 30ns;

    -- Wait for the next rising edge
    wait until rising_edge(clk);

    a <= "001000";
    b <= "010000";

     -- Wait 30ns
     wait for 30ns;

    -- Simply wait forever
    wait;

  end process;
end Behavioral;

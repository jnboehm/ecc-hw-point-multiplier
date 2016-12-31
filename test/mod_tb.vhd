
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity mod_tb is
--  Port ( );
  generic(width : integer := 396;
          base  : integer := 18);

end mod_tb;

architecture Behavioral of mod_tb is

  -- Clock period definition (100Mhz)
  constant clk_period : time := 10 ns;

  -- Clock
  signal clk : std_logic;

  -- Output
  -- signal led : std_logic;

  signal c :   std_logic_vector(width-1 downto 0);
  signal res : std_logic_vector(191 downto 0);

begin

  uut : entity work.modp192
    generic map( width => width, base => base )
    port map ( c => c, res => res );

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

    c <= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000";


     -- Wait 30ns
     wait for 30ns;

    -- Simply wait forever
    wait;

  end process;
end Behavioral;

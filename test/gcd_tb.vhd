
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity gcd_tb is
--  Port ( );
  generic(width : integer := 396;
          base  : integer := 18);

end gcd_tb;

architecture Behavioral of gcd_tb is

  -- Clock period definition (100Mhz)
  constant clk_period : time := 10 ns;

  -- Clock
  signal clk : std_logic;

  -- Output
  -- signal led : std_logic;

  signal gcd_res : std_logic_vector(width - 1 downto 0);
  signal u_in, v_in : std_logic_vector(width - 1 downto 0);
  signal r_u, r_v : std_logic_vector(width - 1 downto 0);
  signal start, reset, ready : std_logic;

begin

  uut : entity work.gcd
    generic map( width => width )
    port map ( clk => clk, u_in => u_in,
               v_in => v_in, gcd => gcd_res,
               ratio_u => r_u, ratio_v => r_v,
               start => start, reset => reset,
               ready => ready );

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
    write(lineBuffer, string'("Simulation start"));
    writeline(output, lineBuffer);

    -- Wait 30ns
    wait for 30 ns;

    reset <= '1';

    wait for 33 ns;

    reset <= '0';

    wait for 31 ns;

    u_in <= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110010";
    v_in <= "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011100";

    -- Wait for the next rising edge
    wait until rising_edge(clk);

    start <= '1';

     -- Wait 30ns
     wait for 30 ns;

    -- Simply wait forever
    wait;

  end process;
end Behavioral;

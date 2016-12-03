
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity incr_tb is
    
end incr_tb;

architecture Behavioral of incr_tb is

  -- Clock period definition (100Mhz)
  constant clk_period : time := 10 ns;

  -- Clock
  signal clk : std_logic;
  
  -- Output
  
  signal start : std_logic;
  signal ready : std_logic;
  signal reset: std_logic;
  signal val : std_logic_vector(3 downto 0);

begin
  
  uut : entity work.addone
    port map ( clk => clk, start => start, ready => ready, reset => reset, val => val );

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

    reset <= '1';

    -- Wait 30ns
    wait for 30ns;

    reset <= '0';
    
    wait for 200ns;
   
    start <= '1';
    
    wait for 53ns;
    
    start <= '0';
   
    -- Simply wait forever
    wait;

  end process;
  
end Behavioral;
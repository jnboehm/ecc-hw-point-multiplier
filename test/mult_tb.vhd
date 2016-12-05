
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity mult_tb is
--  Port ( );
  generic(width_a : integer := 16;
          width_b : integer := 16;
          base    : integer := 4);

end mult_tb;

architecture Behavioral of mult_tb is

  -- Clock period definition (100Mhz)
  constant clk_period : time := 10 ns;

  -- Clock
  signal clk : std_logic;

  -- Output

  signal a     : std_logic_vector(width_a - 1 downto 0) := "0000001000000001";
  signal b     : std_logic_vector(width_b - 1 downto 0) := "0000001000000001";
  signal prd   : std_logic_vector(width_a + width_b - 1 downto 0);
  signal start : std_logic;
  signal ready : std_logic;
  signal reset : std_logic;

begin

  uut : entity work.multiplication
    generic map(base    => base,
                width_a => width_a,
                width_b => width_b)
    port map (clk => clk, a => a, b => b, prd => prd, start => start, ready => ready, reset => reset);

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

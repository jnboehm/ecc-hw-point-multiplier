
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity mult_tb is
--  Port ( );
  generic(width_a : integer := 512;
          width_b : integer := 512;
          base    : integer := 16);

end mult_tb;

architecture Behavioral of mult_tb is

  -- Clock period definition (100Mhz)
  constant clk_period : time := 10 ns;

  -- Clock
  signal clk : std_logic;


  -- Output

  signal a     : std_logic_vector(width_a - 1 downto 0) := "10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010000101111011100111000010101111111001111101101100001011100011011001100110111110111010001101000001101010";
  signal b     : std_logic_vector(width_b - 1 downto 0) := "10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010101010110010101010101010000111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111000000000000101010000101111011100111000010101111111001111101101100001011100011011001100110111110111010001101000001101010";
  signal prd   : std_logic_vector(width_a + width_b - 1 downto 0);
  signal start : std_logic;
  signal ready : std_logic;
  signal reset : std_logic;

  signal z : real;
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

    -- -- Text I/O
    -- variable lineBuffer : line;

    -- -- File stuff
    -- file testfile      : text is in "/home/nik/hsrm/study/vhdl/fpga-curves/work/fpga-curves/test.txt";
    -- variable inline    : line;
    -- variable dataread1 : real;
  begin

    -- Give a info message
    -- write(lineBuffer, string'("Reset not needed"));
    -- writeline(output, lineBuffer);

    -- if (not endfile(testfile)) then
    --     readline(testfile, inline);
    --     read(inline, dataread1);
    --     a <= std_logic_vector(unsigned(dataread1));
    -- end if;
    -- wait for 30 ns;

    -- -- test write
    -- write(lineBuffer, a);
    -- writeline(output, lineBuffer);

    reset <= '1';

    -- Wait 30ns
    wait for 30 ns;

    reset <= '0';

    wait for 200 ns;

    start <= '1';

    wait for 53 ns;

    start <= '0';

    -- Simply wait forever
    wait;

  end process;
end Behavioral;

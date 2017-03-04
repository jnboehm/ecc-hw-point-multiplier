library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity rdaa is
--  Port ( );
  generic(width : integer := 198;
          base  : integer := 18;
          k_width : integer := 192);

end rdaa;

architecture Behavioral of rdaa is

  -- Clock period definition (100Mhz)
  constant clk_period : time := 10 ns;

  -- Clock
  signal clk : std_logic;

  -- Output
  -- signal led : std_logic;

  signal x1, y1                    : std_logic_vector(width - 1 downto 0);
  signal X3, Y3, Z3                : std_logic_vector(width - 1 downto 0);
  signal x, y                      : std_logic_vector(width - 1 downto 0);
  signal start, reset, ready       : std_logic;
  signal c_start, c_reset, c_ready : std_logic;

  signal k : std_logic_vector(k_width - 1 downto 0);
begin

  uut : entity work.rep_doub_and_add (Behavioral)
    generic map(base => base,
                width => width,
                k_width => k_width)
    port map (clk => clk,
              x1 => x1,
              y1 => y1,
              k => k,
              X3 => X3,
              Y3 => Y3,
              Z3 => Z3,
              start => start,
              ready => ready,
              reset => reset);

    convert : entity work.projtoaffine
    generic map(base => base,
                width => width)
    port map(clk => clk,
             X_in => X3,
             Y_in => Y3,
             Z_in => Z3,
             x_affine => x,
             y_affine => y,
             start => c_start, reset => c_reset,
             ready => c_ready);

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


    wait for 31 ns;

    X1 <= "000000000110001000110110101000000011101011000000110000100100001111011001111100101111110010000011101011010000111010000110001000000000001111010011111111000010101111110110000010111111110001000000010010";
    Y1 <= "000000000001110001100100101011100101011111111111001000110110100111100001100011000100000001000111101101011010110010010011001101110101010111001111111001011101111010000100011110011110010100100000010001";

    k <= "111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100110011101111011111000001101100001010001101011110010011011000110110100110100100010100000110001";
         --"110001110101110111011100101011110111011010000111000010011";
    -- Wait 30ns
    wait for 30 ns;

    reset <= '1';

    wait for 33 ns;

    reset <= '0';

    -- Wait for the next rising edge
    wait until rising_edge(clk);

    start <= '1';

    -- Wait 30ns
    wait for 30 ns;

    start <= '0';

    -- wait until addiiton is done
    wait until ready = '1';

    c_reset <= '1';

    wait for 33 ns;

    c_reset <= '0';

    -- Wait for the next rising edge
    wait until rising_edge(clk);

    c_start <= '1';

    -- Wait 30ns
    wait for 30 ns;

    c_start <= '0';

    -- Simply wait forever
    wait;

  end process;
end Behavioral;

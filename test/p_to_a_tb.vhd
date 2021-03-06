library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity p_to_a_tb is
--  Port ( );
  generic(width : integer := 198;
          base  : integer := 18);

end p_to_a_tb;

architecture Behavioral of p_to_a_tb is

  -- Clock period definition (100Mhz)
  constant clk_period : time := 10 ns;

  -- Clock
  signal clk : std_logic;

  -- Output
  -- signal led : std_logic;

  signal X1, X2, Y1, Y2, Z1, Z2 : std_logic_vector(width - 1 downto 0);
  signal X3, Y3, Z3             : std_logic_vector(width - 1 downto 0);
  signal x, y                   : std_logic_vector(width - 1 downto 0);
  signal start, reset, ready    : std_logic;
  signal c_start, c_reset, c_ready    : std_logic;

begin

  uut : entity work.point_addition
    generic map(base => base,
                width => width)
    port map (clk   => clk,
              X1    => X1, Y1 => Y1, Z1 => Z1,
              X2_p  => X2, Y2_p => Y2, Z2_p => Z2,
              X3 => X3, Y3 => Y3, Z3 => Z3,
              start => start, reset => reset,
              ready => ready);

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
    Z1 <= (0 => '1', others => '0');

    X2 <= "000000110110101111111010111111010110000010100001111000001111110010101011010011010101010011010001100011000101011000100010100011111101100010100110100111000011111011000101101001100000101010100010001000";
    Y2 <= "000000110111010110101111011010000011011001100100111101101000001111101001000110101100100111101110111100000101000001101110000110100011110101100100110011000110101111101001011100011111101001001110101011";
    Z2 <= (0 => '1', others => '0');

    -- X1 <= (0          => '1', others => '0');  -- 1
    -- Y1 <= (2 downto 0 => '1', others => '0');  -- 7
    -- Z1 <= (1          => '1', others => '0');  -- 2

    -- X2 <= (0 => '1', others => '0');    -- 1
    -- Y2 <= (1 => '1', others => '0');    -- 2
    -- Z2 <= (0 => '1', others => '0');    -- 1


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

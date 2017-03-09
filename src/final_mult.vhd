library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

entity final_mult is
--  Port ( );
  generic(width   : integer := 198;
          base    : integer := 18;
          k_width : integer := 192);

  port (clk : in  std_logic;
        led : out std_logic_vector (15 downto 0));

end final_mult;

architecture Behavioral of final_mult is

  -- Clock period definition (100Mhz)
  constant clk_period : time := 10 ns;

  -- Output
  -- signal led : std_logic;

  signal x1, y1                    : std_logic_vector(width - 1 downto 0);
  signal X3, Y3, Z3                : std_logic_vector(width - 1 downto 0);
  signal x, y                      : std_logic_vector(width - 1 downto 0);
  signal start, reset, ready       : std_logic;
  signal c_start, c_reset, c_ready : std_logic;

  signal k : std_logic_vector(k_width - 1 downto 0);

  -- states of transition logic
  type state_t is (init, mult_reset, mult_start, mult_wait, conv_reset, conv_start, conv_wait, idle);

  -- variable representation of states
  signal state_reg  : state_t := init;
  signal state_next : state_t;
begin

  uut : entity work.rep_doub_and_add (Behavioral)
    generic map(base    => base,
                width   => width,
                k_width => k_width)
    port map (clk   => clk,
              x1    => x1,
              y1    => y1,
              k     => k,
              X3    => X3,
              Y3    => Y3,
              Z3    => Z3,
              start => start,
              ready => ready,
              reset => reset);

  convert : entity work.projtoaffine
    generic map(base  => base,
                width => width)
    port map(clk      => clk,
             X_in     => X3,
             Y_in     => Y3,
             Z_in     => Z3,
             x_affine => x,
             y_affine => y,
             start    => c_start, reset => c_reset,
             ready    => c_ready);

  state_handler : process (clk)
  begin

    if rising_edge(clk) then            -- Changes on rising edge
      state_reg <= state_next;
    end if;

  end process;
  -- Stimulus process
  stim_proc : process (c_ready, ready, state_reg)


  begin
    state_next <= state_reg;
    reset <= '0';
    start <= '0';
    c_reset <= '0';
    c_start <= '0';

    -- Wait 30ns
    case state_reg is

      when init =>
        state_next <= mult_reset;

      when mult_reset =>
        reset      <= '1';
        state_next <= mult_start;

      when mult_start =>
        reset      <= '0';
        start      <= '1';
        state_next <= mult_wait;

      when mult_wait =>
        start <= '0';
        if ready = '1' then
          state_next <= conv_reset;
        end if;

      when conv_reset =>
        c_reset    <= '1';
        state_next <= conv_start;

      when conv_start =>
        c_reset    <= '0';
        c_start    <= '1';
        state_next <= conv_wait;

      when conv_wait =>
        c_start <= '0';
        if c_ready = '1' then
          state_next <= idle;
        end if;

      -- Simply wait forever
      when idle =>
        state_next <= idle;

    end case;

  end process;

  -- hardcode the values for the point multiplier
  X1 <= "000000000110001000110110101000000011101011000000110000100100001111011001111100101111110010000011101011010000111010000110001000000000001111010011111111000010101111110110000010111111110001000000010010";
  Y1 <= "000000000001110001100100101011100101011111111111001000110110100111100001100011000100000001000111101101011010110010010011001101110101010111001111111001011101111010000100011110011110010100100000010001";

  -- k equals the rank (?) (Ordnung) of the curve, should produce the
  -- point at infinity
  k <= "111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100110011101111011111000001101100001010001101011110010011011000110110100110100100010100000110001";
--"110001110101110111011100101011110111011010000111000010011";

  led(0) <= x(0);
  led(1) <= x(1);
  led(2) <= x(2);
  led(3) <= x(3);
  led(4) <= x(4);
  led(5) <= x(5);
  led(6) <= x(6);
  led(7) <= x(7);
  led(8) <= x(8);
  led(9) <= x(9);
  led(10) <= x(10);
  led(11) <= x(11);
  led(12) <= x(12);
  led(13) <= x(13);
  led(14) <= x(14);
  led(15) <= x(15);

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity addone is
  port (start : in  std_logic;
        ready : out std_logic;
        reset : in  std_logic;
        clk   : in  std_logic;
        val   : out std_logic_vector(3 downto 0));
end addone;

architecture Behavioral of addone is

  type state_t is (idle, load, check, calc, output);

  signal state_reg              : state_t;
  signal state_next             : state_t;
  signal i, i_next, i_plus_eins : std_logic_vector(3 downto 0);
  signal i_waste                : std_logic;

begin

  state_handler : process (clk, reset)
  begin

    if (reset = '1') then

      state_reg <= idle;                -- Set initial state
      i <= "0000";

    elsif (rising_edge(clk)) then       -- Changes on rising edge

      state_reg <= state_next;
      i <= i_next;

    end if;
    
  end process;

  transition : process (state_reg, i, start)
  begin

    state_next <= state_reg;
    i_next     <= i;
    ready      <= '0';

    case state_reg is

      when idle =>

        if (start = '1') then
          state_next <= load;
        end if;

      when load =>

        i_next <= "0000";

        state_next <= check;

      when check =>

        if unsigned(i) = 10 then
          state_next <= output;
        else
          state_next <= calc;
        end if;

      when calc =>

        i_next     <= i_plus_eins;
        state_next <= check;

      when output =>

        ready      <= '1';
        state_next <= idle;

    end case;

  end process;

  val <= i;
  
  rc_adder_1 : entity work.rc_adder (Behavioral)
    generic map (base  => 2,
                 width => 4)
    port map (a             => i,
              b             => "0001",
              cin           => '0',
              s(3 downto 0) => i_plus_eins,
              s(4)          => i_waste);

end Behavioral;

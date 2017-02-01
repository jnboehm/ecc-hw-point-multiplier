library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity projtoaffine is
  generic(base  : integer := 2;
          width : integer := 4);

  port (clk      : in  std_logic;
        -- Point in projective coordinates.
        X_in     : in  std_logic_vector(width - 1 downto 0);
        Y_in     : in  std_logic_vector(width - 1 downto 0);
        Z_in     : in  std_logic_vector(width - 1 downto 0);
        -- Affine coordinates
        x_affine : out std_logic_vector(width - 1 downto 0);
        y_affine : out std_logic_vector(width - 1 downto 0);
        start    : in  std_logic;
        ready    : out std_logic;
        reset    : in  std_logic);
end projtoaffine;

architecture Behavioral of projtoaffine is
  type state_t is (idle);

  signal state_reg, state_next : state_t;

  -- the constant p192 as specified by the NIST standard.
  constant p192 : std_logic_vector(width - 1 downto 0) := "000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101111111111111111111111111111111111111111111111111111111111111111";

begin

  --=================================
  -- PROCESS: STATE_HANDLER
  -- DEF: state and signal assignment
  --=================================
  state_handler : process (clk, reset)
  begin

    -----------------------------------
    -- initialize reg signals
    -----------------------------------
    if (reset = '1') then
      state_reg <= idle;
    -----------------------------------
    -- assign next value to reg
    -----------------------------------
    elsif (rising_edge(clk)) then       -- Changes on rising edge
      state_reg  <= state_next;

    end if;

  end process;

end Behavioral;

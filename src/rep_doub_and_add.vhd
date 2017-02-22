library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity rep_doub_and_add is
  generic (base  : integer := 18;
           width : integer := 198;
           k_width : integer := 32);

  port (clk   : in  std_logic;
        x1    : in  std_logic_vector(width - 1 downto 0);
        y1    : in  std_logic_vector(width - 1 downto 0);
        k     : in  std_logic_vector(k_width - 1 downto 0);
        X3    : out std_logic_vector(width - 1 downto 0);
        Y3    : out std_logic_vector(width - 1 downto 0);
        Z3    : out std_logic_vector(width - 1 downto 0);
        start : in  std_logic;
        ready : out std_logic;
        reset : in  std_logic);

end rep_doub_and_add;

architecture Behavioral of rep_doub_and_add is

  -----------------------------------
  -- state logic signal
  -----------------------------------
  -- states of transition logic
  type state_t is (idle,
                   load,
                   double_init, double_begin, double_wait, double_result,
                   check_add,
                   add_init, add_begin, add_wait, add_result,
                   add_d_init, add_d_begin, add_d_wait, add_d_result,
                   check,
                   output);

  -- variable representation of states
  signal state_reg, state_next : state_t;

  -----------------------------------
  -- reg signal
  -----------------------------------
  signal X2 : std_logic_vector(width - 1 downto 0);
  signal Y2 : std_logic_vector(width - 1 downto 0);
  signal Z2 : std_logic_vector(width - 1 downto 0);
  -----------------------------------
  signal i  : integer;
  -----------------------------------
  signal double_start, double_ready, double_reset    : std_logic;
  signal add_start, add_ready, add_reset, add_double : std_logic;

  -----------------------------------
  -- next signal
  -----------------------------------
  signal X2_next : std_logic_vector(width - 1 downto 0);
  signal Y2_next : std_logic_vector(width - 1 downto 0);
  signal Z2_next : std_logic_vector(width - 1 downto 0);
  -----------------------------------
  signal i_next  : integer;
  -----------------------------------
  signal double_start_next, double_reset_next : std_logic;
  signal add_start_next, add_reset_next       : std_logic;

  -----------------------------------
  -- calc signal
  -----------------------------------
  signal X2_calc : std_logic_vector(width - 1 downto 0);
  signal Y2_calc : std_logic_vector(width - 1 downto 0);
  signal Z2_calc : std_logic_vector(width - 1 downto 0);
  signal X2_calc_double : std_logic_vector(width - 1 downto 0);
  signal Y2_calc_double : std_logic_vector(width - 1 downto 0);
  signal Z2_calc_double : std_logic_vector(width - 1 downto 0);



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
      state_reg <= idle;                -- Set initial state
      -----------------------------------
      X2        <= (0      => '1', others => '0');
      Y2        <= (0      => '1', others => '0');
      Z2        <= (others => '0');
      -----------------------------------
      i         <= k'high;

    -----------------------------------
    -- assign next value to reg
    -----------------------------------
    elsif (rising_edge(clk)) then       -- Changes on rising edge
      state_reg    <= state_next;
      -----------------------------------
      X2           <= X2_next;
      Y2           <= Y2_next;
      Z2           <= Z2_next;
      -----------------------------------
      i            <= i_next;
      -----------------------------------
      double_start <= double_start_next;
      double_reset <= double_reset_next;
      add_start    <= add_start_next;
      add_reset    <= add_reset_next;

    end if;

  end process;

  --=================================
  -- PROCESS: TRANSITION
  -- DEF: state and signal assignment
  --=================================
  transition : process(X2, X2_calc, X2_calc_double, Y2, Y2_calc,
                       Y2_calc_double, Z2, Z2_calc, Z2_calc_double, add_ready,
                       double_ready, i, k, start, state_reg)

  begin

    -----------------------------------
    -- Set state logic signal defaults
    -----------------------------------
    state_next <= state_reg;
    ready      <= '0';
    -----------------------------------
    X2_next    <= X2;
    Y2_next    <= Y2;
    Z2_next    <= Z2;
    -----------------------------------
    i_next <= i;
    -----------------------------------
    double_start_next <= double_start;
    double_reset_next <= double_reset;
    add_start_next    <= add_start;
    add_reset_next    <= add_reset;

    -----------------------------------
    -- STATE LOGIC
    -----------------------------------
    case (state_reg) is

      -- waits for start flag to run
      when idle =>

        if (start = '1') then
          state_next <= load;
        else
          state_next <= idle;
        end if;

      -- sets initial signal value
      when load =>
        X2_next <= (0      => '1', others => '0');
        Y2_next <= (0      => '1', others => '0');
        Z2_next <= (others => '0');

        state_next <= double_init;

      when double_init =>
        double_reset_next <= '1';

        state_next <= double_begin;

      when double_begin =>
        double_start_next <= '1';
        double_reset_next <= '0';

        state_next <= double_wait;

      when double_wait =>
        double_start_next <= '0';

        if double_ready = '1' then
          state_next <= double_result;
        else
          state_next <= double_wait;
        end if;

      when double_result =>
        X2_next <= X2_calc_double;
        Y2_next <= Y2_calc_double;
        Z2_next <= Z2_calc_double;

        state_next <= check_add;

      when check_add =>
        if k(i) = '1' then
          state_next <= add_init;
        else
          state_next <= check;
        end if;

      when add_init =>
        add_reset_next <= '1';

        state_next <= add_begin;

      when add_begin =>
        add_start_next <= '1';
        add_reset_next <= '0';

        state_next <= add_wait;

      when add_wait =>

        add_start_next <= '0';

        if add_ready = '1' then
          state_next <= add_result;
        elsif add_double = '1' then
          state_next <= add_d_init;
        else
          state_next <= add_wait;
        end if;

      when add_result =>
        X2_next <= X2_calc;
        Y2_next <= Y2_calc;
        Z2_next <= Z2_calc;

        state_next <= check;

      when add_d_init =>
        double_reset_next <= '1';

        state_next <= add_d_begin;

      when add_d_begin =>
        double_start_next <= '1';
        double_reset_next <= '0';

        state_next <= add_d_wait;

      when add_d_wait =>
        double_start_next <= '0';

        if double_ready = '1' then
          state_next <= add_d_result;
        else
          state_next <= add_d_wait;
        end if;

      when add_d_result =>
        X2_next <= X2_calc_double;
        Y2_next <= Y2_calc_double;
        Z2_next <= Z2_calc_double;

        state_next <= check_add;

      when check =>

        if i = 0 then
          state_next <= output;
        else
          state_next <= double_init;
        end if;

        i_next <= i - 1;

      -- signals finished calculation
      when output =>

        ready      <= '1';
        state_next <= idle;

    end case;

  end process;

  X3 <= X2;
  Y3 <= Y2;
  Z3 <= Z2;



  double : entity work.point_doubling (Behavioral)
    generic map (base  => base,
                 width => width)
    port map (clk   => clk,
              X1    => X2,
              Y1    => Y2,
              Z1    => Z2,
              X3    => X2_calc_double,
              Y3    => Y2_calc_double,
              Z3    => Z2_calc_double,
              start => double_start,
              ready => double_ready,
              reset => double_reset);


  add : entity work.point_addition (Behavioral)
    generic map (base  => base,
                 width => width)
    port map (clk   => clk,
              X1    => X2,
              Y1    => Y2,
              Z1    => Z2,
              x2    => x1,
              y2    => y1,
              X3    => X2_calc,
              Y3    => Y2_calc,
              Z3    => Z2_calc,
              double=> add_double,
              start => add_start,
              ready => add_ready,
              reset => add_reset);


end Behavioral;

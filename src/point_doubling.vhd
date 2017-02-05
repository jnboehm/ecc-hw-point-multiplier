library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity point_doubling is

  generic(base  : integer := 2;
          width : integer := 4);

  port (clk   : in  std_logic;
        X1    : in  std_logic_vector(width - 1 downto 0);
        Y1    : in  std_logic_vector(width - 1 downto 0);
        Z1    : in  std_logic_vector(width - 1 downto 0);
        X3    : out std_logic_vector(width - 1 downto 0);
        Y3    : out std_logic_vector(width - 1 downto 0);
        Z3    : out std_logic_vector(width - 1 downto 0);
        start : in  std_logic;
        ready : out std_logic;
        reset : in  std_logic);
end point_doubling;

-- The algorithm for point doubling in Jacobian coordinates, as
-- specified in "Guide to Elliptic Curve Cryptography" by Darrel
-- Hankerson (3.21).
architecture Behavioral of point_doubling is

  --=================================
  -- INIT Signals
  --=================================

  -----------------------------------
  -- state logic signal
  -----------------------------------
  -- states of transition logic
  type state_t is (idle,
                   load,
                   check_infty,

                   -- c and a number correspond to the number in the algorithm
                   -- specified above (3.22).
                   c2_init, c2_start, c2_wait, c2_result,      -- T1 <= Z1^2
                   c3_init, c3_result,                         -- T2 <= X1 - T1
                   c4_init, c4_result,                         -- T1 <= X1 + T1
                   c5_init, c5_start, c5_wait, c5_result,      -- T2 <= T2 * T1
                   c6_init, c6_start, c6_wait, c6_result,       -- T2 <= 3 * T2
                   c7_double, c7_mod, c7_result,               -- Y3 <= 2 * Y1
                   c8_init, c8_start, c8_wait, c8_result,      -- Z3 <= Y3 * Z1
                   c9_init, c9_start, c9_wait, c9_result,      -- Y3 <= Y3^2
                   c10_init, c10_start, c10_wait, c10_result,  -- T3 <= Y3 * X1
                   c11_init, c11_start, c11_wait, c11_result,  -- Y3 <= Y3^2
                   c12_prepare, c12_result, c12_devide,        -- Y3 <= Y3/2
                   c13_init, c13_start, c13_wait, c13_result,  -- X3 <= T2^2
                   c14_double, c14_mod, c14_result,            -- T1 <= 2 * T3
                   c15_init, c15_result,                       -- X3 <= X3 - T1
                   c16_init, c16_result,                       -- T1 <= T3 - X3
                   c17_init, c17_start, c17_wait, c17_result,  -- T1 <= T1 * T2
                   c18_init, c18_result,                       -- Y3 <= T1 - Y3
                   output);

  -- variable representation of states
  signal state_reg, state_next : state_t;

  -----------------------------------
  -- reg signal
  -----------------------------------
  signal T1     : std_logic_vector(width - 1 downto 0);
  signal T2     : std_logic_vector(width - 1 downto 0);
  signal T3     : std_logic_vector(width - 1 downto 0);
  -----------------------------------
  signal X3_tmp : std_logic_vector(width - 1 downto 0);
  signal Y3_tmp : std_logic_vector(width - 1 downto 0);
  signal Z3_tmp : std_logic_vector(width - 1 downto 0);

  -----------------------------------
  -- next signal
  -----------------------------------
  signal T1_next         : std_logic_vector(width - 1 downto 0);
  signal T2_next         : std_logic_vector(width - 1 downto 0);
  signal T3_next         : std_logic_vector(width - 1 downto 0);
  -----------------------------------
  signal X3_next         : std_logic_vector(width - 1 downto 0);
  signal Y3_next         : std_logic_vector(width - 1 downto 0);
  signal Z3_next         : std_logic_vector(width - 1 downto 0);
  -----------------------------------
  signal add_a_next      : std_logic_vector(width - 1 downto 0);
  signal add_b_next      : std_logic_vector(width - 1 downto 0);
  signal add_sum_next    : std_logic_vector(width - 1 downto 0);
  -----------------------------------
  signal sub_a_next      : std_logic_vector(width - 1 downto 0);
  signal sub_b_next      : std_logic_vector(width - 1 downto 0);
  signal sub_dif_next    : std_logic_vector(width - 1 downto 0);
  -----------------------------------
  signal mult_a_next     : std_logic_vector(width - 1 downto 0);
  signal mult_b_next     : std_logic_vector(width - 1 downto 0);
  signal mult_reset_next : std_logic;
  signal mult_start_next : std_logic;
  signal mult_ready_next : std_logic;
  signal mult_prd_next   : std_logic_vector(width - 1 downto 0);

  -----------------------------------
  -- function signals
  -----------------------------------
  signal add_a      : std_logic_vector(width - 1 downto 0);
  signal add_b      : std_logic_vector(width - 1 downto 0);
  signal add_sum    : std_logic_vector(width - 1 downto 0);
  -----------------------------------
  signal sub_a      : std_logic_vector(width - 1 downto 0);
  signal sub_b      : std_logic_vector(width - 1 downto 0);
  signal sub_dif    : std_logic_vector(width - 1 downto 0);
  -----------------------------------
  signal mult_a     : std_logic_vector(width - 1 downto 0);
  signal mult_b     : std_logic_vector(width - 1 downto 0);
  signal mult_reset : std_logic;
  signal mult_start : std_logic;
  signal mult_ready : std_logic;
  signal mult_prd   : std_logic_vector(width - 1 downto 0);

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
      state_reg <= idle;                -- Set initial state
      -----------------------------------
      T1        <= (others => '0');
      T2        <= (others => '0');
      T3        <= (others => '0');
      -----------------------------------
      X3_tmp    <= (others => '0');
      Y3_tmp    <= (others => '0');
      Z3_tmp    <= (others => '0');

    -----------------------------------
    -- assign next value to reg
    -----------------------------------
    elsif (rising_edge(clk)) then       -- Changes on rising edge
      state_reg  <= state_next;
      -----------------------------------
      T1         <= T1_next;
      T2         <= T2_next;
      T3         <= T3_next;
      -----------------------------------
      X3         <= X3_next;
      Y3         <= Y3_next;
      Z3         <= Z3_next;
      -----------------------------------
      X3_tmp     <= X3_next;
      Y3_tmp     <= Y3_next;
      Z3_tmp     <= Z3_next;
      -----------------------------------
      add_a      <= add_a_next;
      add_b      <= add_b_next;
      add_sum    <= add_sum_next;
      -----------------------------------
      sub_a      <= sub_a_next;
      sub_b      <= sub_b_next;
      sub_dif    <= sub_dif_next;
      -----------------------------------
      mult_a     <= mult_a_next;
      mult_b     <= mult_b_next;
      mult_reset <= mult_reset_next;
      mult_start <= mult_start_next;
      mult_ready <= mult_ready_next;
      mult_prd   <= mult_prd_next;

    end if;

  end process;


  --=================================
  -- PROCESS: TRANSITION
  -- DEF: state and signal assignment
  --=================================
  transition : process(T1, T1_next, T2, T3, X1, X3_tmp, Y1,
                       Y3_tmp, Z1, Z3_tmp, add_a, add_b, add_sum, mult_a,
                       mult_b, mult_prd, mult_ready, mult_reset, mult_start,
                       start, state_reg, sub_a, sub_b, sub_dif)

  begin

    -----------------------------------
    -- Set state logic signal defaults
    -----------------------------------
    state_next      <= state_reg;
    ready           <= '0';
    -----------------------------------
    T1_next         <= T1;
    T2_next         <= T2;
    T3_next         <= T3;
    -----------------------------------
    X3_next         <= X3_tmp;
    Y3_next         <= Y3_tmp;
    Z3_next         <= Z3_tmp;
    -----------------------------------
    add_a_next      <= add_a;
    add_b_next      <= add_b;
    add_sum_next    <= add_sum;
    -----------------------------------
    sub_a_next      <= sub_a;
    sub_b_next      <= sub_b;
    sub_dif_next    <= sub_dif;
    -----------------------------------
    mult_a_next     <= mult_a;
    mult_b_next     <= mult_b;
    mult_reset_next <= mult_reset;
    mult_start_next <= mult_start;
    mult_ready_next <= mult_ready;
    mult_prd_next   <= mult_prd;

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

        -- set in case logic assigned values to init value

        -- state_next <= NEXT_CASE;


      -- when NEXT_CASE =>
      --TODO: HOw do I return Infitiy
      -- if either one of the points is the point at infinity, then return the other one as teh result
      when check_infty =>

        if Z1 = (width - 1 downto 0 => '0') then
          X3_next    <= X1;
          Y3_next    <= Y1;
          Z3_next    <= Z1;
          state_next <= output;
        else
          state_next <= c2_init;
        end if;

      --******************************************
      --
      -- IMPLEMENT POINT ADDITION PROCEDURE
      --
      --******************************************
      --
      -- USE:
      --  i) adding new signal for calc process
      --      - declare reg and next for signal
      --      - if signal being assigned to in state logic
      --          - set default
      --          - init in case 'load'
      --      - if signal is assigned in state handler
      --          - init in reset
      --          - assign signal next to signal reg
      --
      --------------------------------------------
      when c2_init =>                   -- T1 <= Z1^2

        mult_a_next     <= Z1;
        mult_b_next     <= Z1;
        mult_reset_next <= '1';

        state_next <= c2_start;

      when c2_start =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= c2_wait;

      when c2_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= c2_result;
        else
          state_next <= c2_wait;
        end if;

      when c2_result =>

        T1_next <= mult_prd;

        state_next <= c3_init;

      when c3_init =>                   -- T2 <= X1 - T1

        sub_a_next <= X1;
        sub_b_next <= T1;

        state_next <= c3_result;

      when c3_result =>

        T2_next <= sub_dif;

        state_next <= c4_init;

      when c4_init =>

        add_a_next <= X1;
        add_b_next <= T1;

        state_next <= c4_result;

      when c4_result =>

        T1_next <= add_sum;

        state_next <= c5_init;

      when c5_init =>                   -- T2 <= T2 * T1

        mult_a_next     <= T2;
        mult_b_next     <= T1;
        mult_reset_next <= '1';

        state_next <= c5_start;

      when c5_start =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= c5_wait;

      when c5_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= c5_result;
        else
          state_next <= c5_wait;
        end if;

      when c5_result =>

        T2_next <= mult_prd;

        state_next <= c6_init;

      when c6_init =>                  -- T2 <= 3 * T2

        mult_a_next     <= (1 downto 0 => '1', others => '0');
        mult_b_next     <= T2;
        mult_reset_next <= '1';

        state_next <= c6_start;

      when c6_start =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= c6_wait;

      when c6_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= c6_result;
        else
          state_next <= c6_wait;
        end if;

      when c6_result =>

        T2_next <= mult_prd;

        state_next <= c7_double;

      when c7_double =>                 -- Y3 <= 2 * Y1

        Y3_next <= Y1(width - 2 downto 0) & "0";

        if unsigned(Y3_next) > unsigned(p192) then
          state_next <= c7_mod;
        else
          state_next <= c8_init;
        end if;

        state_next <= c7_mod;

      when c7_mod =>

        sub_a_next <= Y3_tmp;
        sub_b_next <= p192;

        state_next <= c7_result;

      when c7_result =>

        Y3_next <= sub_dif;

        state_next <= c8_init;

      when c8_init =>                   -- Z3 <= Y3 * Z1

        mult_a_next     <= Y3_tmp;
        mult_b_next     <= Z1;
        mult_reset_next <= '1';

        state_next <= c8_start;

      when c8_start =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= c8_wait;

      when c8_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= c8_result;
        else
          state_next <= c8_wait;
        end if;

      when c8_result =>

        Z3_next <= mult_prd;

        state_next <= c9_init;


      when c9_init =>                   -- Y3 <= Y3^2

        mult_a_next     <= Y3_tmp;
        mult_b_next     <= Y3_tmp;
        mult_reset_next <= '1';

        state_next <= c9_start;

      when c9_start =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= c9_wait;

      when c9_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= c9_result;
        else
          state_next <= c9_wait;
        end if;

      when c9_result =>

        Y3_next <= mult_prd;

        state_next <= c10_init;

      when c10_init =>                  -- T3 <= Y3 * X1

        mult_a_next     <= Y3_tmp;
        mult_b_next     <= X1;
        mult_reset_next <= '1';

        state_next <= c10_start;

      when c10_start =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= c10_wait;

      when c10_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= c10_result;
        else
          state_next <= c10_wait;
        end if;

      when c10_result =>

        T3_next <= mult_prd;

        state_next <= c10_init;

      when c11_init =>                  -- Y3 <= Y3^2

        mult_a_next     <= Y3_tmp;
        mult_b_next     <= Y3_tmp;
        mult_reset_next <= '1';

        state_next <= c11_start;

      when c11_start =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= c11_wait;

      when c11_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= c11_result;
        else
          state_next <= c11_wait;
        end if;

      when c11_result =>

        Y3_next <= mult_prd;

        state_next <= c12_prepare;

      when c12_prepare =>               -- Y3 <= Y3/2

        if Y3_tmp(Y3_tmp'low) = '1' then

          add_a_next <= (width - 1 downto 1 => '0') & "1";
          add_b_next <= Y3_tmp;

          state_next <= c12_result;
        else
          state_next <= c12_result;
        end if;

      when c12_result =>

        Y3_next <= add_sum;

        state_next <= c12_devide;

      when c12_devide =>

        Y3_next <= "0" & Y3_tmp(width - 1 downto 1);

        state_next <= c13_init;

      when c13_init =>                  -- X3 <= T2^2

        mult_a_next     <= T2;
        mult_b_next     <= T2;
        mult_reset_next <= '1';

        state_next <= c13_start;

      when c13_start =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= c13_wait;

      when c13_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= c13_result;
        else
          state_next <= c13_wait;
        end if;

      when c13_result =>

        X3_next <= mult_prd;

        state_next <= c14_double;


      when c14_double =>                -- T1 <= 2 * T3

        T1_next <= T3(width - 2 downto 0) & "0";

        if unsigned(Y3_next) > unsigned(p192) then
          state_next <= c14_mod;
        else
          state_next <= c15_init;
        end if;

        state_next <= c14_mod;

      when c14_mod =>

        sub_a_next <= T1;
        sub_b_next <= p192;

        state_next <= c14_result;

      when c14_result =>

        T1_next <= sub_dif;

        state_next <= c15_init;


      when c15_init =>                  -- X3 <= X3 - T1

        sub_a_next <= X3_tmp;
        sub_b_next <= T1;

        state_next <= c15_result;

      when c15_result =>

        X3_next <= sub_dif;

        state_next <= c16_init;

      when c16_init =>                  -- T1 <= T3 - X3

        sub_a_next <= T3;
        sub_b_next <= X3_tmp;

        state_next <= c16_result;

      when c16_result =>

        T1_next <= sub_dif;

        state_next <= c17_init;

      when c17_init =>                  -- T1 <= T1 * T2

        mult_a_next     <= T1;
        mult_b_next     <= T2;
        mult_reset_next <= '1';

        state_next <= c17_start;

      when c17_start =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= c17_wait;

      when c17_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= c17_result;
        else
          state_next <= c17_wait;
        end if;

      when c17_result =>

        T1_next <= mult_prd;

        state_next <= c18_init;


      when c18_init =>                  -- Y3 <= T1 - Y3

        sub_a_next <= T1;
        sub_b_next <= Y3_tmp;

        state_next <= c18_result;

      when c18_result =>

        Y3_next <= sub_dif;

        state_next <= output;


      -- signals finished calculation
      when output =>

        ready      <= '1';
        state_next <= idle;

    end case;

  end process;

  --TODO: why?
  -- res <= tmp_res

  --=================================
  -- FUNCTION POOL
  -----------------------------------
  -- DEF: Does field operations with predefined signals
  -- USE: Write into inputs and read output in next signal
  --=================================

  -----------------------------------
  -- ADDITION
  -----------------------------------
  add : entity work.rc_adder_standard (Behavioral)
    generic map (base  => base,
                 width => width)
    port map (a   => add_a,
              b   => add_b,
              cin => '0',
              s   => add_sum);

  -----------------------------------
  -- SUBTRACTION
  -----------------------------------
  subtract : entity work.subtraction (Behavioral)
    generic map (base  => base,
                 width => width)
    port map (a   => sub_a,
              b   => sub_b,
              cin => '0',
              s   => sub_dif);

  -----------------------------------
  -- MULTIPLICATION
  -----------------------------------
  multiply : entity work.modmult (Behavioral)
    generic map (base  => base,
                 width => width)
    port map (clk   => clk,
              a     => mult_a,
              b     => mult_b,
              reset => mult_reset,
              start => mult_start,
              ready => mult_ready,      -- assign mult_prd when mult_ready == 1
              prd   => mult_prd);



end Behavioral;

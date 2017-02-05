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
        -- x = X / Z^2
        x_affine : out std_logic_vector(width - 1 downto 0);
        -- y = Y / Z^3
        y_affine : out std_logic_vector(width - 1 downto 0);
        start    : in  std_logic;
        ready    : out std_logic;
        reset    : in  std_logic);
end projtoaffine;

-- This module calulculates the affine coordinates from the given
-- representant in projective coordinates.  It is expected, that we
-- have Jacobian coordinates.
architecture Behavioral of projtoaffine is
  type state_t is (idle, load,
                   inv_init, inv_begin, inv_wait, inv_result,  -- calc Z_in^(-1)
                   squ_init, squ_begin, squ_wait, squ_result,  -- calc Z^-2
                   cb_init, cb_begin, cb_wait, cb_result,      -- calc Z^-3
                   invx_init, invx_begin, invx_wait, invx_result,  -- calc X / Z^2
                   invy_init, invy_begin, invy_wait, invy_result,  -- calc Y / Z^3
                   output);

  signal state_reg, state_next : state_t;

  -- internal signals
  signal inv_z    : std_logic_vector(width - 1 downto 0);
  signal inv_z_sq : std_logic_vector(width - 1 downto 0);
  signal inv_z_cb : std_logic_vector(width - 1 downto 0);
  signal x_affine_tmp: std_logic_vector(width - 1 downto 0);
  signal y_affine_tmp: std_logic_vector(width - 1 downto 0);

  -- entity signals
  signal mult_a     : std_logic_vector(width - 1 downto 0);
  signal mult_b     : std_logic_vector(width - 1 downto 0);
  signal mult_reset : std_logic;
  signal mult_start : std_logic;
  signal mult_ready : std_logic;
  signal mult_prd   : std_logic_vector(width - 1 downto 0);

  signal inv_num   : std_logic_vector(width - 1 downto 0);
  signal inv_reset : std_logic;
  signal inv_start : std_logic;
  signal inv_ready : std_logic;
  signal inv_out   : std_logic_vector(width - 1 downto 0);

  -- next signals
  signal mult_a_next     : std_logic_vector(width - 1 downto 0);
  signal mult_b_next     : std_logic_vector(width - 1 downto 0);
  signal mult_reset_next : std_logic;   -- are reset signals necessary?
  signal mult_start_next : std_logic;

  signal x_affine_next : std_logic_vector(width - 1 downto 0);
  signal y_affine_next : std_logic_vector(width - 1 downto 0);

  signal inv_num_next   : std_logic_vector(width - 1 downto 0);
  signal inv_reset_next : std_logic;
  signal inv_start_next : std_logic;

  signal inv_z_next    : std_logic_vector(width - 1 downto 0);
  signal inv_z_sq_next : std_logic_vector(width - 1 downto 0);
  signal inv_z_cb_next : std_logic_vector(width - 1 downto 0);


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

      mult_a     <= (others => '0');
      mult_b     <= (others => '0');
      mult_reset <= '0';
      mult_start <= '0';

      inv_num   <= (others => '0');
      inv_reset <= '0';
      inv_start <= '0';

      x_affine_tmp <= (others => '0');
      y_affine_tmp <= (others => '0');

    -----------------------------------
    -- assign next value to reg
    -----------------------------------
    elsif (rising_edge(clk)) then       -- Changes on rising edge
      state_reg <= state_next;

      mult_a     <= mult_a_next;
      mult_b     <= mult_b_next;
      mult_reset <= mult_reset_next;
      mult_start <= mult_start_next;

      inv_num   <= inv_num_next;
      inv_reset <= inv_reset_next;
      inv_start <= inv_start_next;

      inv_z    <= inv_z_next;
      inv_z_sq <= inv_z_sq_next;
      inv_z_cb <= inv_z_cb_next;

      x_affine_tmp <= x_affine_next;
      y_affine_tmp <= y_affine_next;

    end if;

  end process;

  transition : process(X_in, Y_in, Z_in, inv_num, inv_out, inv_ready,
                       inv_start, inv_z, inv_z_cb, inv_z_sq, mult_a, mult_b,
                       mult_prd, mult_ready, mult_reset, mult_start, start,
                       state_reg, x_affine_tmp, y_affine_tmp)
  begin
    -- Set defaults
    state_next <= state_reg;

    mult_a_next     <= mult_a;
    mult_b_next     <= mult_b;
    mult_reset_next <= mult_reset;
    mult_start_next <= mult_start;

    inv_num_next   <= inv_num;
    inv_start_next <= inv_start;

    inv_z_next    <= inv_z;
    inv_z_sq_next <= inv_z_sq;
    inv_z_cb_next <= inv_z_cb;

    x_affine_next <= x_affine_tmp;
    y_affine_next <= y_affine_tmp;


    case (state_reg) is

      when idle =>

        if (start = '1') then
          state_next <= load;
        else
          state_next <= idle;
        end if;

      when load =>

        mult_a_next     <= (others => '0');
        mult_b_next     <= (others => '0');
        mult_reset_next <= '0';
        mult_start_next <= '0';

        inv_num_next   <= (others => '0');
        inv_reset_next <= '0';
        inv_start_next <= '0';

        inv_z_next    <= (others => '0');
        inv_z_sq_next <= (others => '0');
        inv_z_cb_next <= (others => '0');

        x_affine_next <= (others => '0');
        y_affine_next <= (others => '0');


        state_next <= inv_init;

      when inv_init =>                  -- z^-1

        inv_num_next   <= Z_in;
        inv_reset_next <= '1';

        state_next <= inv_begin;

      when inv_begin =>

        inv_reset_next <= '0';
        inv_start_next <= '1';

        state_next <= inv_wait;

      when inv_wait =>

        inv_start_next <= '0';

        if inv_ready = '1' then
          state_next <= inv_result;
        else
          state_next <= inv_wait;
        end if;

      when inv_result =>

        inv_z_next <= inv_out;

        state_next <= squ_init;

      when squ_init =>                  -- z^-2 <= z^(-1) * z^(-1)

        mult_a_next     <= inv_z;
        mult_b_next     <= inv_z;
        mult_reset_next <= '1';

        state_next <= squ_begin;

      when squ_begin =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= squ_wait;

      when squ_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= squ_result;
        else
          state_next <= squ_wait;
        end if;

      when squ_result =>

        inv_z_sq_next <= mult_prd;

        state_next <= cb_init;

      when cb_init =>                   -- z^(-3) <= z^(-2) * z^(-1)

        mult_a_next     <= inv_z_sq;
        mult_b_next     <= inv_z;
        mult_reset_next <= '1';

        state_next <= cb_begin;

      when cb_begin =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= cb_wait;

      when cb_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= cb_result;
        else
          state_next <= cb_wait;
        end if;

      when cb_result =>

        inv_z_cb_next <= mult_prd;

        state_next <= invx_init;

      when invx_init =>                 -- x_affine <= x_projective * z^(-2)

        mult_a_next     <= X_in;
        mult_b_next     <= inv_z_sq;
        mult_reset_next <= '1';

        state_next <= invx_begin;

      when invx_begin =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= invx_wait;

      when invx_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= invx_result;
        else
          state_next <= invx_wait;
        end if;

      when invx_result =>

        x_affine_next <= mult_prd;

        state_next <= invy_init;

      when invy_init =>                 -- y_affine <= y_projective * z^(-3)

        mult_a_next     <= Y_in;
        mult_b_next     <= inv_z_cb;
        mult_reset_next <= '1';

        state_next <= invy_begin;

      when invy_begin =>

        mult_reset_next <= '0';
        mult_start_next <= '1';

        state_next <= invy_wait;

      when invy_wait =>

        mult_start_next <= '0';

        if mult_ready = '1' then
          state_next <= invy_result;
        else
          state_next <= invy_wait;
        end if;

      when invy_result =>

        y_affine_next <= mult_prd;

        state_next <= output;

      when output =>

        ready      <= '1';
        state_next <= idle;

    end case;

  end process;

  x_affine <= x_affine_tmp;
  y_affine <= y_affine_tmp;

  mult : entity work.modmult (Behavioral)
    generic map(base  => base,
                width => width)
    port map(clk   => clk,
             a     => mult_a,
             b     => mult_b,
             prd   => mult_prd,
             start => mult_start,
             ready => mult_ready,
             reset => mult_reset);


  inverter : entity work.invert_in_Z_p192 (Behavioral)
    generic map(base  => base,
                width => width)
    port map(clk     => clk,
             num     => inv_num,
             inv_num => inv_out,
             start   => inv_start,
             ready   => inv_ready,
             reset   => inv_reset);
end Behavioral;

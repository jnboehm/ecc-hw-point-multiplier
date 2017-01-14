library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity modmult is
  generic(base    : integer := 18;
          width : integer := 198);

  port (clk   : in  std_logic;
        a     : in  std_logic_vector(width - 1 downto 0);
        b     : in  std_logic_vector(width - 1 downto 0);
        prd   : out std_logic_vector(width - 1 downto 0);
        start : in  std_logic;
        ready : out std_logic;
        reset : in  std_logic);
end modmult;

architecture Behavioral of modmult is

  -- states of transition logic
  type state_t is (idle, load, check, incr_i, mult, acc, wait_mod, output);

  -- variable representation of states
  signal state_reg, state_next : state_t;

  -- product of a digit and b digit

  -- product of a digit and b
  signal line_prd_calc  : std_logic_vector((width + width) - 1 downto 0);
  signal line_prd_next  : std_logic_vector((width + width) - 1 downto 0);
  signal line_prd       : std_logic_vector((width + width) - 1 downto 0);

  -- product of a and b
  signal tmp_prd_calc  : std_logic_vector((width + width) - 1 downto 0);
  signal tmp_prd_next  : std_logic_vector((width + width) - 1 downto 0);
  signal tmp_prd       : std_logic_vector((width + width) - 1 downto 0);
  signal tmp_prd_waste : std_logic;
  signal tmp_tmp       : std_logic_vector((width + width) downto 0);

  signal pre_mod_prd   : std_logic_vector((width + width) - 1 downto 0);
  -- fits the size of the result from modp192.  Used for combinatorial
  -- circuit.
  signal prd_small_calc : std_logic_vector(191 downto 0);
  signal prd_small_next : std_logic_vector(191 downto 0);
  signal prd_small : std_logic_vector(191 downto 0);

  signal ready_next : std_logic;

  -- counter of sum of line products
  signal i      : integer := 0;
  signal i_next : integer;
begin

  state_handler : process (clk, reset)
  begin

    if (reset = '1') then
      state_reg   <= idle;              -- Set initial state
      line_prd    <= (others => '0');
      tmp_prd     <= (others => '0');
      prd_small   <= (others => '0');
      i           <= 0;

    elsif (rising_edge(clk)) then       -- Changes on rising edge
      state_reg <= state_next;
      line_prd  <= line_prd_next;
      tmp_prd   <= tmp_prd_next;
      i         <= i_next;
      ready     <= ready_next;
      prd_small <= prd_small_next;

    end if;

  end process;

  transition : process(i, line_prd, line_prd_calc, start, state_reg, tmp_prd,
                       tmp_prd_calc)
  begin
    -- Set defaults
    state_next    <= state_reg;
    line_prd_next <= line_prd;
    tmp_prd_next  <= tmp_prd;
    i_next        <= i;
    ready_next    <= '0';
    prd_small_next <= prd_small;

    case (state_reg) is

      when idle =>

        if (start = '1') then
          state_next <= load;
        else
          state_next <= idle;
        end if;

      when load =>

        line_prd_next <= (others => '0');
        tmp_prd_next  <= (others => '0');
        i_next        <= 0;

        state_next <= mult;

      when mult =>

        line_prd_next <= line_prd_calc;
        state_next    <= acc;

      when acc =>

        -- Add lineprd to tmpprd
        tmp_prd_next  <= tmp_prd_calc;
        line_prd_next <= (others => '0');
        state_next    <= check;

      when check =>

        -- TODO: bound check?? ,5 klären
        if (i = width/base - 1) then
          state_next <= wait_mod;
        else
          -- set index to calc new line
          i_next     <= i + 1;
          state_next <= incr_i;
        end if;

      when incr_i =>

        state_next <= mult;

      when wait_mod =>

        prd_small_next <= prd_small_calc;
        state_next <= output;

      when output =>

        ready_next <= '1';
        state_next <= idle;

    end case;

  end process;

  lmult : entity work.linemult (Behavioral)
    generic map (base => base, width_a => width, width_b => width)
    port map (a   => a,
              b   => b,
              i   => i,
              prd => line_prd_calc);

  -- tmp_prd = tmp_prd + line_prd
  rc_adder_2 : entity work.rc_adder (Behavioral)
    generic map (base  => base,
                 width => (width + width))
    port map (a   => tmp_prd(width + width - 1 downto 0),
              b   => line_prd(width + width - 1 downto 0),
              cin => '0',
              s   => tmp_tmp);

  tmp_prd_calc <= tmp_tmp(width + width - 1 downto 0);

  modprd : entity work.modp192 (Behavioral)
    generic map (base => base,
                 width => 2 * width)
    port map (c => tmp_prd,
              res => prd_small_calc);

  prd <= "000000" & prd_small;
end Behavioral;

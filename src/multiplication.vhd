library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplication is
  generic(base    : integer := 16;
          width_a : integer := 256;
          width_b : integer := 256);

  port (clk   : in  std_logic;
        a     : in  std_logic_vector(width_a - 1 downto 0);
        b     : in  std_logic_vector(width_b - 1 downto 0);
        prd   : out std_logic_vector((width_a + width_b) - 1 downto 0);
        start : in  std_logic;
        ready : out std_logic;
        reset : in  std_logic);
end multiplication;

architecture Behavioral of multiplication is

  -- states of transition logic
  type state_t is (idle, load, check, incr_i, mult, acc, output);

  -- variable represantation of states
  signal state_reg, state_next : state_t;

  -- product of a digit and b digit
  signal digit_prd : std_logic_vector((width_a + width_b) - 1 downto 0);

  -- product of a digit and b
  signal line_prd_calc  : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal line_prd_next  : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal line_prd       : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal line_prd_waste : std_logic;
  signal s_tmp          : std_logic_vector((width_a + width_b) downto 0);

  -- product of a and b
  signal tmp_prd_calc  : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal tmp_prd_next  : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal tmp_prd       : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal tmp_prd_waste : std_logic;
  signal tmp_tmp       : std_logic_vector((width_a + width_b) downto 0);

  -- counter of sum of line products
  signal i      : integer;
  signal i_next : integer;
begin

  state_handler : process (clk, reset)
  begin

    if (reset = '1') then
      state_reg <= idle;                -- Set initial state
      line_prd  <= (others => '0');
      tmp_prd   <= (others => '0');
      i         <= 0;

    elsif (rising_edge(clk)) then       -- Changes on rising edge
      state_reg <= state_next;
      line_prd  <= line_prd_next;
      tmp_prd   <= tmp_prd_next;
      i         <= i_next;

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
    ready         <= '0';

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

        --line_prd_next <= std_logic_vector(unsigned(line_prd_calc) sll i * base);
        line_prd_next <= line_prd_calc;
        state_next    <= acc;

      when acc =>

        -- Add lineprd to tmpprd
        tmp_prd_next  <= tmp_prd_calc;
        line_prd_next <= (others => '0');
        state_next    <= check;

      when check =>

        -- TODO: bound check?? ,5 klären
        if (i = width_a/base - 1) then
          state_next <= output;
        else
          -- set index to calc new line
          i_next     <= i + 1;
          state_next <= incr_i;
        end if;

      when incr_i =>

        state_next <= mult;

      when output =>

        ready      <= '1';
        state_next <= idle;

    end case;

  end process;

  prd <= tmp_prd;

  -- mult a digit with b digits
  digits : for J in 0 to width_b / base - 1 generate
  begin

    -- digit_prd <= (others => '0');
    digit_prd ((2 * base + J * base) - 1 downto J * base) <= std_logic_vector(unsigned(a((i + 1) * base - 1 downto i * base))
                                                                              * unsigned(b((J + 1) * base - 1 downto J * base)));

    rc_adder_1 : entity work.rc_adder (Behavioral)
      generic map (base  => base,
                   width => width_a + width_b)
      port map (a   => line_prd,
                b   => digit_prd,
                cin => '0',
                s   => s_tmp);

    line_prd_calc <= s_tmp(width_a + width_b - 1 downto 0);
  end generate;

  -- tmp_prd = tmp_prd + line_prd
  rc_adder_2 : entity work.rc_adder (Behavioral)
    generic map (base  => base,
                 width => (width_a + width_b))
    port map (a   => tmp_prd(width_a + width_b - 1 downto 0),
              b   => line_prd(width_a + width_b - 1 downto 0),
              cin => '0',
              s   => tmp_tmp);

  tmp_prd_calc <= tmp_tmp(width_a + width_b - 1 downto 0);
end Behavioral;

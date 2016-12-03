library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity multiplication is
  generic(base    : integer := 16;
          width_a : integer := 256;
          width_b : integer := 256);

  port (clk    : in  std_logic;
        a      : in  std_logic_vector(width_a - 1 downto 0);
        b      : in  std_logic_vector(width_b - 1 downto 0);
        prd    : out std_logic_vector((width_a + width_b) - 1 downto 0);
        start  : in  std_logic;
        ready  : out std_logic;
        opcode : out std_logic_vector(3 downto 0);
        reset  : in  std_logic);
end multiplication;

architecture Behavioral of multiplication is

  --states of transition logic
  type state_t is (idle, load, check, mult, acc, output);

  --variable represantation of states
  signal state_reg, state_next : state_t;

  --product of a digit and b digit
  signal digit_prd      : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal digit_prd_next : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal low_index      : integer;

--product of a digit and b
  signal line_prd_calc  : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal line_prd_next  : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal line_prd       : std_logic_vector((width_a + width_b) - 1 downto 0);  --product of a and b
  signal line_prd_waste : std_logic;

  --
  signal tmp_prd_calc  : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal tmp_prd_next  : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal tmp_prd       : std_logic_vector((width_a + width_b) - 1 downto 0);
  signal tmp_prd_waste : std_logic;

  --unused
  --signal carry     : STD_LOGIC_VECTOR(base - 1 downto 0);
  --counter of sum of line products
  signal i      : integer;
  signal i_next : integer;
  signal tmp    : std_logic_vector((width_a + width_b) - 1 downto 0);
begin

  state_handler : process (clk, reset)
  begin

    if (reset = '1') then
      state_reg <= idle;                -- Set initial state
      digit_prd <= (others => '0');
      line_prd  <= (others => '0');
      tmp_prd   <= (others => '0');
      i         <= 0;

    elsif (rising_edge(clk)) then       -- Changes on rising edge
      state_reg <= state_next;
      line_prd  <= line_prd_next;
      tmp_prd   <= tmp_prd_next;
      digit_prd <= digit_prd_next;
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

        digit_prd_next <= (others => '0');
        line_prd_next  <= (others => '0');
        tmp_prd_next   <= (others => '0');
        i_next         <= 0;

        state_next <= check;

      when check =>

        if (i = width_a/base - 1) then
          state_next <= output;
          opcode     <= "1111";
        else
          state_next <= mult;
          opcode     <= "0001";

        end if;

      when mult =>

        --line_prd_next <= std_logic_vector(unsigned(line_prd_calc) sll i * base);
        line_prd_next <= line_prd_calc;
        state_next    <= acc;

      when acc =>

        -- Add lineprd to tmpprd
        tmp_prd_next <= tmp_prd_calc;
        i_next       <= i + 1;
        state_next   <= check;

      when output =>

        ready      <= '1';
        state_next <= idle;

    end case;

  end process;

  prd <= tmp_prd;

  -- mult a digit with b digits
  digits : for J in 0 to width_b / base - 1 generate
  begin

    digit_prd ((2 * base) - 1 downto 0) <= std_logic_vector(unsigned(a((i + 1) * base - 1 downto i * base)) * unsigned(b((J + 1) * base - 1 downto J * base)));
    tmp                                            <= (others => '0');
    tmp((2 * base + J * base) - 1 downto J * base) <= digit_prd(2*base - 1 downto 0);

    rc_adder_1 : entity work.rc_adder (Behavioral)
      generic map (base  => base,
                   width => width_a + width_b)
      port map (a                                 => line_prd(width_a + width_b - 1 downto 0),  -- Pass full line_prd except of last bit to fit the addition process
                b                                 => tmp,
                cin                               => '0',
                s(width_a + width_b - 1 downto 0) => line_prd_calc,
                s(width_a + width_b)              => line_prd_waste);
  end generate;

  -- tmp_prd = tmp_prd + line_prd
  rc_adder_2 : entity work.rc_adder (Behavioral)
    generic map (base  => base,
                 width => (width_a + width_b))
    port map (a                                 => tmp_prd(width_a + width_b - 1 downto 0),
              b                                 => line_prd(width_a + width_b - 1 downto 0),
              cin                               => '0',
              s(width_a + width_b - 1 downto 0) => tmp_prd_calc,
              s(width_a + width_b)              => tmp_prd_waste);

end Behavioral;
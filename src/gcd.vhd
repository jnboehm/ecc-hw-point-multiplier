library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- The algorithm presented in Knuth's "The Art of Computer
-- Programming" Vol. 2 in "Answers to the Exercises" pg.646
entity gcd is

  generic (
    width : integer := 392);            -- bit vector width

  port (
    clk     : in  std_logic;            -- clock signal
    u_in    : in  std_logic_vector(width - 1 downto 0);  -- the input u as defined in the reference algorithm
    v_in    : in  std_logic_vector(width - 1 downto 0);
    gcd     : out std_logic_vector(width - 1 downto 0);  -- the greatest common divisor
    ratio_u : out std_logic_vector(width - 1 downto 0);
    ratio_v : out std_logic_vector(width - 1 downto 0);
    start   : in  std_logic;
    reset   : in  std_logic;
    ready   : out std_logic);

end entity gcd;

architecture Behavioral of gcd is

  -- The states as defined in the algorithm (More are probably needed)
  type state_t is
    (idle,                              -- Beginning state
     y1,                                -- Find power of two
     y2,                                -- Initialize
     y3,                                -- Halve t_3
     y4,                                -- Is t_3 even?
     y5,                                -- Reset max(u_3, v_3)
     y6);                               -- Subtract

  signal state_reg, state_next     : state_t;
  signal u, v                      : std_logic_vector(width - 1 downto 0);
  signal u1, u2, u3                : std_logic_vector(width - 1 downto 0);
  signal v1, v2, v3                : std_logic_vector(width - 1 downto 0);
  signal t1, t2, t3                : std_logic_vector(width - 1 downto 0);
  signal u1_next, u2_next, u3_next : std_logic_vector(width - 1 downto 0);
  signal v1_next, v2_next, v3_next : std_logic_vector(width - 1 downto 0);
  signal t1_next, t2_next, t3_next : std_logic_vector(width - 1 downto 0);



  -- constants that need to be calulated for the initialization
  signal one_minus_u      : std_logic_vector(width - 1 downto 0);
  signal minus_u, minus_v : std_logic_vector(width - 1 downto 0);

  -- calculations that are needed throughout the process
  signal t1_plus_v, t2_minus_u, v_minus_t1, minus_u_minus_t2, minus_t3 : std_logic_vector(width - 1 downto 0);
  signal u1_minus_v1, u2_minus_v2, u3_minus_v3                         : std_logic_vector(width - 1 downto 0);

  constant one : std_logic_vector(width - 1 downto 0) := (0 => '1', others => '0');
begin  -- architecture Behavioral

  state_handler : process (clk, reset)
  begin  -- process state_handler
    if reset = '1' then                 -- asynchronous reset (active high)
      state_reg <= idle;
    -- really nothing else?
    elsif rising_edge(clk) then         -- rising clock edge
      state_reg <= state_next;
      u1        <= u1_next; v1 <= v1_next; t1 <= t1_next;
      u2        <= u2_next; v2 <= v2_next; t2 <= t2_next;
      u3        <= u3_next; v3 <= v3_next; t3 <= t3_next;
    end if;
  end process state_handler;

  transition : process (minus_t3, minus_u_minus_t2, minus_v, one_minus_u,
                        start, state_reg, t1, t1_plus_v, t2, t2_minus_u, t3, u,
                        u1, u2, u3, v, v1, v2, v3, v_minus_t1)
  begin  -- process transition

    -- default transitions
    state_next <= state_reg;
    u1_next    <= u1;
    u2_next    <= u2;
    u3_next    <= u3;
    v1_next    <= v1;
    v2_next    <= v2;
    v3_next    <= v3;
    t1_next    <= t1;
    t2_next    <= t2;
    t3_next    <= t3;

    case state_reg is

      when idle =>

        -- wait for the start signal
        if start = '1' then
          state_next <= y1;
        end if;

      when y1 =>                        -- find power of two
        -- set u and v to have no common powers of two anymore!
        state_next <= y2;

      when y2 =>                        -- initialize variables

        -- set (u1, u2, u3) <- (1, 0, u)
        u1 <= one;
        u2 <= (others => '0');
        u3 <= u;

        -- and (v1, v2, v3) <- (v, 1 - u, v)
        v1 <= v;
        v2 <= one_minus_u;
        v3 <= v;

        if u(u'right) = '1' then        -- u is odd
          -- set (t1, t2, t3) <- 0, -1, -v)
          t1         <= (others => '0');
          t2         <= (others => '1');  -- -1 in two's complement representation
          t3         <= minus_v;
          state_next <= y4;
        else                            -- u is even
          t1         <= (others => '0');
          t2         <= (others => '1');
          t3         <= u;
          state_next <= y3;
        end if;

      when y3 =>                        -- halve t3

        state_next <= y4;
        if (t1(t1'right) = '0') and (t2(t2'right) = '0') then
          -- ghetto sra instruction as it's not supported in vivado
          -- for some reason (use highest bit and truncate the last bit
          t1_next <= t1(t1'high downto t1'high) & t1(width - 1 downto 1);
          t2_next <= t2(t2'high downto t2'high) & t2(width - 1 downto 1);
          t3_next <= t3(t3'high downto t3'high) & t3(width - 1 downto 1);
        else
          t1_next <= t1_plus_v(t1_plus_v'high downto t1_plus_v'high) & t1_plus_v(width - 1 downto 1);
          t2_next <= t2_minus_u(t2_minus_u'high downto t2_minus_u'high) & t2_minus_u(width - 1 downto 1);
          t3_next <= t3(t3'high downto t3'high) & t3(width - 1 downto 1);
        end if;

      when y4 =>

        if t3(t3'right) = '0' then
          state_next <= y3;             -- t3 is even
        else
          state_next <= y5;
        end if;

      when y5 =>                        -- reset max(u3, v3)

        state_next <= y6;
        if t3(t3'left) = '0' then       -- t3 is positive (does 0 count too?)
          u1_next <= t1;
          u2_next <= t2;
          u3_next <= t3;
        else
          v1_next <= v_minus_t1;
          v2_next <= minus_u_minus_t2;
          v3_next <= minus_t3;
        end if;

      when y6 =>

        if t3 = (t3'range => '0') then
          ready      <= '1';
          state_next <= idle;
        else
          state_next <= y3;
        end if;

    end case;
  end process transition;

  ratio_u <= u1;
  ratio_v <= u2;
  gcd     <= u3;                        -- append the zeros that have been
  -- truncated at the beginning

  -- The entities below simply calculate values for the algorithm, the names of
  -- the output itself should give away what the result is.

  one_sub_u : entity work.subtraction (Behavioral)
    generic map(width => width)
    port map(a   => one,
             b   => u,
             cin => '0',
             s   => one_minus_u);

  zero_sub_v : entity work.invert_twos_complement (Behavioral)
    generic map(width => width)
    port map(num => v,
             neg => minus_v);

  zero_sub_u : entity work.invert_twos_complement (Behauioral)
    generic map(width => width)
    port map(num => u,
             neg => minus_u);


  -- t1 + v
  t1_add_v : entity work.rc_adder_standard (Behavioral)
    generic map (width => width)
    port map (a    => t1,
              b    => v,
              cin  => '0',
              s    => t1_plus_v,
              cout => open);

  -- t2 - u
  t2_sub_u : entity work.subtraction (Behavioral)
    generic map (width => width)
    port map (a   => t2,
              b   => u,
              cin => '0',
              s   => t2_minus_u);

  -- v - t1
  v_sub_t1 : entity work.subtraction (Behavioral)
    generic map (width => width)
    port map (a   => v,
              b   => t1,
              cin => '0',
              s   => v_minus_t1);

  -- -u - t2
  minus_u_sub_t2 : entity work.subtraction (Behavioral)
    generic map (width => width)
    port map (a   => minus_u,
              b   => t2,
              cin => '0',
              s   => minus_u_minus_t2);

  -- -t3
  zero_sub_t3 : entity work.invert_twos_complement (Behavioral)
    generic map (width => width)
    port map(num => t3,
             neg => minus_t3);

  -- u1 - v1
  u1_sub_v1 : entity work.subtraction (Behavioral)
    generic map (width => width)
    port map (a   => u1,
              b   => v1,
              cin => '0',
              s   => u1_minus_v1);

  -- u2 - v2
  u2_sub_v2 : entity work.subtraction (Behavioral)
    generic map (width => width)
    port map (a   => u2,
              b   => v2,
              cin => '0',
              s   => u2_minus_v2);

  -- u3 - v3
  u3_sub_v3 : entity work.subtraction (Behavioral)
    generic map (width => width)
    port map (a   => u3,
              b   => v3,
              cin => '0',
              s   => u3_minus_v3);

end architecture Behavioral;

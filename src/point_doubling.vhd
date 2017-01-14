library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity point_doubling is

    generic(base    : integer := 2;
            width : integer := 4);

    port (clk   : in  std_logic;
          X_1   : in  std_logic_vector(width - 1 downto 0);
          Y_1   : in  std_logic_vector(width - 1 downto 0);
          Z_1   : in  std_logic_vector(width - 1 downto 0);
          x_2   : in  std_logic_vector(width - 1 downto 0);
          y_2   : in  std_logic_vector(width - 1 downto 0);
          X_3   : out std_logic_vector(width - 1 downto 0);
          Y_3   : out std_logic_vector(width - 1 downto 0);
          Z_3   : out std_logic_vector(width - 1 downto 0);
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
    type state_t is (idle, load, output);
    
    -- variable representation of states
    signal state_reg, state_next : state_t;
    
    -----------------------------------
    -- reg signal
    -----------------------------------
    
    -----------------------------------
    -- next signal
    -----------------------------------
    
    -----------------------------------
    -- function signals
    -----------------------------------
    signal add_a      : std_logic_vector(width - 1 downto 0);
    signal add_b      : std_logic_vector(width - 1 downto 0);
    signal add_sum    : std_logic_vector(width - 1 downto 0);
    -----------------------------------
    signal sub_a      : std_logic_vector(width - 1 downto 0);
    signal sub_b      : std_logic_vector(width - 1 downto 0);
    signal sub_sum    : std_logic_vector(width - 1 downto 0);
    -----------------------------------
    signal mult_a     : std_logic_vector(width - 1 downto 0);
    signal mult_b     : std_logic_vector(width - 1 downto 0);
    signal mult_reset : std_logic;
    signal mult_start : std_logic;
    signal mult_ready : std_logic;
    signal mult_prd   : std_logic_vector(2 * width - 1 downto 0);
    -----------------------------------
    signal mod_in     : std_logic_vector(2 * width - 1 downto 0);
    signal mod_res    : std_logic_vector(width - 1 downto 0);

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
    -- assign next value to reg
    ----------------------------------- 
    elsif (rising_edge(clk)) then       -- Changes on rising edge
      state_reg <= state_next;
      -- 
    
    end if;
    
    end process;
    

    --=================================
    -- PROCESS: TRANSITION
    -- DEF: state and signal assignment
    --=================================
    transition : process(start, state_reg) -- TODO: Add relevant signals
    
    begin
    
    -----------------------------------     
    -- Set state logic signal defaults
    ----------------------------------- 
    state_next    <= state_reg;
    ready         <= '0';
    
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
                     width => (width + width))
        port map (a   => add_a,
                  b   => add_b,
                  cin => '0',
                  s   => add_sum);

    -----------------------------------     
    -- SUBTRACTION
    ----------------------------------- 
    subtract : entity work.subtraction (Behavioral)
        generic map (base  => base,
                     width => (width + width))
        port map (a   => sub_a,
                  b   => sub_b,
                  cin => '0',
                  s   => sub_sum);
    
    -----------------------------------     
    -- MULTIPLICATION
    ----------------------------------- 
    multiply : entity work.multiplication (Behavioral)
        generic map (base  => base,
                   width_a => width,
                   width_b => width)
        port map (clk => clk,
                  a => mult_a,
                  b => mult_b,
                  reset => mult_reset,
                  start => mult_start,
                  ready => mult_ready, -- assign mult_prd when mult_ready == 1
                  prd   => mult_prd);
                  
    -----------------------------------     
    -- MODULO
    ----------------------------------- 
    modulo : entity work.modp192 (Behavioral)
        generic map (base  => base,
                   width => (width + width))
        port map (c     => mod_in,
                  res   => mod_res);


end Behavioral;

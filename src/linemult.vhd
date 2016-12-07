library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity linemult is

  generic (base    : integer := 16;
           width_a : integer := 256;
           width_b : integer := 256);

  port (a   : in  std_logic_vector(width_a - 1 downto 0);
        b   : in  std_logic_vector(width_b - 1 downto 0);
        i   : in  integer;
        prd : out std_logic_vector(width_a + width_b - 1 downto 0));

end linemult;

architecture Behavioral of linemult is


begin
  process (a, b, i)
    variable digit_prd_raw   : std_logic_vector(base * 2 - 1 downto 0);
    variable digit_prd_shift : std_logic_vector(width_a + width_b - 1 downto 0);
    variable digit_prd_final : std_logic_vector(width_a + width_b - 1 downto 0);
    variable line_prd        : std_logic_vector(width_a + width_b - 1 downto 0);
  begin
    line_prd := (others => '0');
    -- mult a digit with b digits
    for J in 0 to width_b / base - 1 loop

      -- We write the bits into the _raw var, then we simply concatenate
      -- 0s to the front it it and save that into _shift.  We can then
      -- use the sll operation to shift it to the correct location (we
      -- have the real digit product of out two digits) and save that
      -- into _final and give it to the rc_adder.
      digit_prd_raw := std_logic_vector(unsigned(a((i + 1) * base - 1 downto i * base))
                                        * unsigned(b((J + 1) * base - 1 downto J * base)));

      digit_prd_shift := (digit_prd_shift'high - 1 downto digit_prd_raw'high => '0') & digit_prd_raw;
      digit_prd_final := std_logic_vector(unsigned(digit_prd_shift) sll (i * base + J));

      line_prd := std_logic_vector(unsigned(line_prd) + unsigned(digit_prd_final));

    end loop;

    prd <= line_prd;
  end process;
end Behavioral;

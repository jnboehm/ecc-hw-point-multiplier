library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity invert_twos_complement is
  generic (width : integer := 396);

  port (num : in  std_logic_vector(width - 1 downto 0);
        neg : out std_logic_vector(width - 1 downto 0));

end entity;

architecture Behavioral of invert_twos_complement is
  signal tmp : std_logic_vector(width - 1 downto 0);
begin
  tmp <= std_logic_vector((num'range => '1') xor num);
  neg <= std_logic_vector(unsigned(tmp) + 1);
end architecture;

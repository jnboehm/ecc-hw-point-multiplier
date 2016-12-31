library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity modp192 is
  generic(base  : integer := 18;
          width : integer := 396);

  port (c   : in  std_logic_vector(width - 1 downto 0);
        res : out std_logic_vector(191 downto 0));
end modp192;

architecture Behavioral of modp192 is

  -- the width that is internally used to calculate the intemediate
  -- results.  This size prevents overflows in our bit vectors.
  constant internal_width : integer := 198;

  -- the constant p192 as specified by the NIST standard.
  constant p192 : unsigned(internal_width - 1 downto 0) := "000000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101111111111111111111111111111111111111111111111111111111111111111";


  -- the variables as defined in the algorithm 2.27 in "Guide to Elliptic Curve
  -- Cryptography" by Darrel Hankerson (2004).
  signal c0, c1, c2, c3, c4, c5         : std_logic_vector(63 downto 0);
  signal s1, s2, s3, s4                 : std_logic_vector(internal_width - 1 downto 0);

  -- to prevent simultaneous writing to a signal we define multiple
  -- temp signals.  The modulo reduction is performed in a
  -- combinatorial circuit.
  --
  -- holds the temporary sum.
  signal s1_tmp, s2_tmp, s3_tmp, s4_tmp : std_logic_vector(internal_width - 1 downto 0);

  -- calculate (s*_tmp - p192) and save.  It is only used when (s*_tmp > p192).
  -- No time is lost by calculation.
  signal s1_sub, s2_sub, s3_sub         : std_logic_vector(internal_width - 1 downto 0);

  -- carries the modulo reduced intermediate value.
  signal s1_mod, s2_mod, s3_mod         : std_logic_vector(internal_width - 1 downto 0);

  -- a constant for filling up the s* signals, to resolve alignment
  -- issues.
  constant zeros : std_logic_vector(5 downto 0) := "000000";

begin

  c0 <= c(63 downto 0);
  c1 <= c(127 downto 64);
  c2 <= c(191 downto 128);
  c3 <= c(255 downto 192);
  c4 <= c(319 downto 256);
  c5 <= c(383 downto 320);

  s1 <= zeros & c2 & c1 & c0;
  s2 <= zeros & (63 downto 0 => '0') & c3 & c3;
  s3 <= zeros & c4 & c4 & (63 downto 0 => '0');
  s4 <= zeros & c5 & c5 & c5;

  -- add s1 and s2 and check whether sum > p192, subtract p192 if so, mod
  -- using rc_adder_standard to prevent odd bit vector lengths
  rc_adder_1 : entity work.rc_adder_standard (Behavioral)
    generic map (base  => base,
                 width => internal_width)
    port map (a   => s1,
              b   => s2,
              cin => '0',
              s   => s1_tmp);

  sub1 : entity work.subtraction (Behavioral)
    generic map (base  => base,
                 width =>internal_width)
    port map(a   => s1_tmp,
             b   => std_logic_vector(p192),
             cin => '0',
             s   => s1_sub);

  s1_mod <= s1_sub when unsigned(s1_tmp) >= p192
            else s1_tmp;

  -- add s1 & s2 and s3 and check whether sum > p192, subtract p192 if so, mod
  rc_adder_2 : entity work.rc_adder_standard (Behavioral)
    generic map (base  => base,
                 width => internal_width)
    port map (a   => s1_mod,
              b   => s3,
              cin => '0',
              s   => s2_tmp);

  sub2 : entity work.subtraction (Behavioral)
    generic map (base  => base,
                 width => internal_width)
    port map(a   => s2_tmp,
             b   => std_logic_vector(p192),
             cin => '0',
             s   => s2_sub);

  s2_mod <= s2_sub when unsigned(s2_tmp) >= p192
            else s2_tmp;

  -- add s1 & s2 & s3 and s4 and check whether sum > p192, subtract p192 if so, mod
  rc_adder_3 : entity work.rc_adder_standard (Behavioral)
    generic map (base  => base,
                 width => internal_width)
    port map (a   => s2_mod,
              b   => s4,
              cin => '0',
              s   => s3_tmp);

  sub3 : entity work.subtraction (Behavioral)
    generic map (base  => base,
                 width => internal_width)
    port map(a   => s3_tmp,
             b   => std_logic_vector(p192),
             cin => '0',
             s   => s3_sub);

  s3_mod <= s3_sub when unsigned(s3_tmp) >= p192
            else s3_tmp;

  res <= s3_mod(191 downto 0);

end Behavioral;

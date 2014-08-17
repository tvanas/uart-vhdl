-----------------------------------------------------------
--               UART | Test application
-----------------------------------------------------------
--
-- Copyright (c) 2008, Thijs van As <t.vanas@gmail.com>
--
-----------------------------------------------------------
-- Input:      clk        | System clock
--             reset      | System reset
--             rx         | RX signal
--
-- Output:     tx         | TX signal
-----------------------------------------------------------
-- UART test application which echoes received signal back
-- via transmitter.
-----------------------------------------------------------
-- uart_test.vhd
-----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity uart_test is
    port (clk   : in std_logic;
          reset : in std_logic;
          rx    : in std_logic;

          tx : out std_logic);
end entity uart_test;

architecture behavioural of uart_test is
    component clk_18432 is
        port (clk   : in std_logic;
              reset : in std_logic;

              clk_18432 : out std_logic);
    end component clk_18432;

    component uart_tx is
        port (clk      : in std_logic;
              reset    : in std_logic;
              data_in  : in std_logic_vector(7 downto 0);
              in_valid : in std_logic;

              tx        : out std_logic;
              accept_in : out std_logic);
    end component uart_tx;

    component uart_rx is
        port (clk   : in std_logic;
              reset : in std_logic;
              rx    : in std_logic;

              data_out  : out std_logic_vector(7 downto 0);
              out_valid : out std_logic);
    end component uart_rx;

    signal clk_18432_s : std_logic                    := '0';
    signal data_s      : std_logic_vector(7 downto 0) := x"00";
    signal in_valid_s  : std_logic                    := '0';
    signal out_valid_s : std_logic                    := '0';
    signal accept_s    : std_logic                    := '0';
begin
    in_valid_s <= accept_s and out_valid_s;
    
    clk_gen : clk_18432 port map (clk   => clk,
                                  reset => reset,

                                  clk_18432 => clk_18432_s);

    tx_0 : uart_tx port map (clk      => clk_18432_s,
                             reset    => reset,
                             data_in  => data_s,
                             in_valid => in_valid_s,

                             tx        => tx,
                             accept_in => accept_s);

    rx_0 : uart_rx port map (clk   => clk_18432_s,
                             reset => reset,
                             rx    => rx,

                             data_out  => data_s,
                             out_valid => out_valid_s);                               
end architecture behavioural;

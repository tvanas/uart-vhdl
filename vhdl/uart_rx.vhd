-----------------------------------------------------------
--                 UART | Receiver unit
-----------------------------------------------------------
--
-- Copyright (c) 2008, Thijs van As <t.vanas@gmail.com>
--
-----------------------------------------------------------
-- Input:      clk        | System clock at 1.8432 MHz
--             reset      | System reset
--             rx         | RX line
--
-- Output:     data_out   | Output data
--             out_valid  | Output data valid
-----------------------------------------------------------
-- uart_rx.vhd
-----------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity uart_rx is
    port (clk   : in std_logic;
          reset : in std_logic;
          rx    : in std_logic;

          data_out  : out std_logic_vector(7 downto 0);
          out_valid : out std_logic);
end entity uart_rx;


architecture behavioural of uart_rx is
    type   tx_state is (reset_state, idle, receive_data, stop_bit);
    signal current_state, next_state : tx_state;
    signal data_counter              : std_logic_vector(2 downto 0) := (others => '0');
    signal ticker                    : std_logic_vector(3 downto 0) := (others => '0');
    signal data_buffer               : std_logic_vector(7 downto 0);
    signal rx_filtered               : std_logic                    := '1';
    signal rx_state                  : std_logic_vector(1 downto 0) := "11";
begin
    data_out <= data_buffer;

    -- Filters input data
    filter : process(clk, reset)
    begin
        if (reset = '1') then
            rx_filtered <= '1';
            rx_state    <= "11";
        elsif (clk = '1' and clk'event) then
            if (rx = '0' and rx_state /= "00") then
                if (rx_state = "01") then
                    rx_filtered <= '0';
                end if;
                rx_state <= rx_state - 1;
            elsif (rx = '1' and rx_state /= "11") then
                if (rx_state = "10") then
                    rx_filtered <= '1';
                end if;
                rx_state <= rx_state + 1;
            end if;
        end if;
    end process filter;

    -- Updates the states in the statemachine at a 115200 bps rate
    clkgen_115k2 : process(clk, reset)
    begin
        if (reset = '1') then
            ticker        <= (others => '0');
            current_state <= reset_state;
            data_counter  <= "000";
            data_buffer   <= (others => '0');
        elsif (clk = '1' and clk'event) then
            if (ticker = 15
                or (current_state = idle and next_state = receive_data and ticker = 7)
                or (current_state = idle and next_state = idle))  then
                ticker        <= (others => '0');
                current_state <= next_state;
                if (current_state = receive_data) then
                    data_buffer  <= rx_filtered & data_buffer(7 downto 1);
                    data_counter <= data_counter + 1;
                else
                    data_buffer  <= data_buffer;
                    data_counter <= "000";
                end if;
            else
                data_buffer   <= data_buffer;
                current_state <= current_state;
                ticker        <= ticker + 1;
            end if;
        end if;
    end process clkgen_115k2;

    rx_control : process (current_state, rx_filtered, data_counter)
    begin
        case current_state is
            when reset_state =>
                out_valid <= '0';

                next_state <= idle;
            when idle =>
                out_valid <= 'X';

                if (rx_filtered = '0') then
                    next_state <= receive_data;
                else
                    next_state <= idle;
                end if;
            when receive_data =>
                out_valid <= '0';

                if (data_counter = 7) then
                    next_state <= stop_bit;
                else
                    next_state <= receive_data;
                end if;
            when stop_bit =>
                out_valid <= '1';

                if (rx_filtered = '1') then
                    next_state <= idle;
                else
                    next_state <= stop_bit;
                end if;
            when others =>
                out_valid <= '0';

                next_state <= reset_state;
        end case;
    end process rx_control;
end architecture behavioural;

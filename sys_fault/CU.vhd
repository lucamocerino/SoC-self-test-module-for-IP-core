library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity CU is		--control unit

	port(
	
		clk: in std_logic;
	power_on: in std_logic;
	ok_status: out std_logic;
	fault_status: out std_logic;
	debug_port: out std_logic_vector(15 downto 0);
	
	WEA: out std_logic_vector(0 downto 0);
	ram_address: out std_logic_vector(10 downto 0);		-- 2048 words
	ram_out: in std_logic_vector(15 downto 0);	
	ram_in: out std_logic_vector(15 downto 0);	

	rom_address: out std_logic_vector(11 downto 0);		-- 4096 words
	rom_out: in std_logic_vector(31 downto 0);	
	
	-- atctgh core
	x: out std_logic_vector(15 downto 0);
	y: out std_logic_vector(15 downto 0);
	phase: in std_logic_vector(15 downto 0)
	);
	
end CU;

architecture fsm_process OF CU IS
	
	type state_type is (S0, S1, S2, S3, S4, S4bis, S5, S6, S7, S8, S8bis, S9, S10, S10bis, S11, S11bis, S12, S12bis, final_state);
	
	-- signal declarations
	signal state: state_type := final_state;
	signal temp32 : std_logic_vector(31 downto 0);
	signal temp16 : std_logic_vector(15 downto 0);
	
begin

	-- FSM
	fsm_process: process(clk)
	
			variable faults_count : natural := 0;			-- counting faults
			variable delay_count : natural:= 0;				-- used to count delays
			variable int_rom_addr: std_logic_vector(11 downto 0);		
			variable cnt: natural:=0;							--syncr. counter
			variable int_ram_addr: natural:=0;				-- support ram address
	begin
		if(rising_edge(clk) )then 
			if( power_on='1') then			-- i use power-on signal as asynchronous reset 
				state <= S0;
			else
			
				case state is
				
					when S0 =>	
					
						ok_status <= '0';
						fault_status <= '0';
						debug_port <= (others => '0');
						WEA <= "0";
						ram_address <= (others => '0');
						ram_in <= (others => '0');
						x <= (others => '0');
						y <= (others=> '0');
						rom_address <= (others => '0');
						int_rom_addr := (others => '0');
						faults_count := 0;
						delay_count := 0;
						cnt:=0;
						int_ram_addr:=0;
						state <= S1;	
										
					when S1 =>	
					
						if(int_rom_addr = "100000000000") then	--(2048) half of ROM in which there're all inputs pattern
							state <= S7;	
						else
							state <= S2;
							temp32 <= rom_out;	
						end if;
						
					when S2 =>		
						x <= temp32(15 downto 0);		
						y <= temp32(31 downto 16);
						int_rom_addr := int_rom_addr + "100000000000";  --access to "golden" rom, the second part
						rom_address <= int_rom_addr;
						state <= S3;	
					
					when S3 =>		
						if(cnt=21) then 				--manage cordic delay
						state<=S4;
						else
							cnt:=cnt+1;
							state<=S3;
						end if;
						
					when S4 =>
						cnt:=0;
						temp16 <= phase;		
						ram_address <= std_logic_vector(to_unsigned(faults_count, 11));
						state <= S5;
						
					when S4bis =>		
						if(cnt=3) then 		--manage ram syncrhronization 
						state<=S5;
						else
						cnt:=cnt+1;
						state<=S4bis;
						end if;
						
						
					when S5 =>
							cnt:=0;
						if (temp16 /= rom_out(15 downto 0)) then	-- compare the rom's output with cordic's output and 
							WEA <= "1";										--write enable
							ram_in <= rom_out(15 downto 0);		
							faults_count := faults_count + 1;		--	increment faults counter if there'are any
						end if;
						int_rom_addr := int_rom_addr - "100000000000" + 1;	-- return to use input pattern
						rom_address <= int_rom_addr;
						state <= S6;
						
					when S6 =>
						WEA <= "0";							--read enable ( syncr. )
						state <= S1;
						
					when S7 =>									
						if (faults_count = 0) then		--if no errors occur
							ok_status <= '1';
							state <= S8;
						else
							state <= S9;					
						end if;
						
					when S8 =>
						if(delay_count = 7496) then		-- (50 us/6.67 ns) need 7496 c.c.
							ok_status <= '0';
							state <= final_state;
						else
							delay_count  := delay_count  + 1;
							state <= S8bis;					
						end if;
						
					WHEN S8bis =>
						delay_count  := delay_count  + 1;
						state <= S8;
						
					when S9 =>
						fault_status <= '1';
						debug_port <= std_logic_vector(to_unsigned(faults_count, 16));
						delay_count := 0;
						state <= S10;
						
					when S10 =>
						if(delay_count = 150) then						-- (1 us/6.67 ns) need 150 c.c.
							state <= S11;
						else
							delay_count := delay_count+ 1;
							state <= S10bis;
						end if;
						
					when S10bis =>
						delay_count := delay_count+ 1;
						state <= S10;
						
					when S11 =>
						IF (faults_count >= 0) then			--- prepare to drive wrong results in output
							cnt:=0;
							state<=S11bis;
							else
							fault_status <= '0';
							state <= final_state;
							end if;
							
					when S11bis =>
					if(faults_count=int_ram_addr) then	 -- ram addr 
							fault_status <= '0';
							state <= final_state;
						else state<=s12;
						end if;
						
					WHEN S12 =>
						
						ram_address<= std_logic_vector(to_unsigned(int_ram_addr, 11));
						int_ram_addr:= int_ram_addr+ 1;
						state <= S12bis;
						
							
					when S12bis =>						--ram synchronization
					
					if (cnt=2) then 
						debug_port <= ram_out;	
						cnt:=0;
						state<=S11bis;
						else cnt:=cnt+1;
						state <= S12bis;
						end if;
						
					when final_state=> 				--stable final state
						state <= final_state;	
						
					when others=>						--19 states coded on 5 bits (12 possibles illegal states)
						state <= final_state;	
				
				end case;
			
			end if;
		end if;
end process;

end fsm_process;

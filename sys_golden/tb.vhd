LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
 
ENTITY tb IS
END tb;
 
ARCHITECTURE behavior OF tb IS 
 
  
 
 
    COMPONENT system
    PORT(
         clk : IN  std_logic;
         car_power_on : IN  std_logic;
         ok_status : OUT  std_logic;
         fault_status : OUT  std_logic;
         debug_port : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
	 
    


   --Inputs
   signal clk : std_logic := '0';
   signal car_power_on : std_logic := '0';

 	--Outputs
   signal Ok_status : std_logic;
   signal Fault_status : std_logic;
   signal Debug_port : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant clk_period : time := 6.67 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: system PORT MAP (
          clk => clk,
          car_power_on => car_power_on,
          Ok_status => Ok_status,
          Fault_status => Fault_status,
          Debug_port => Debug_port
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
 

   -- Stimulus process
   stim_proc: process
   begin
	
		car_power_on <= '0';
      wait for 2*clk_period;	
		car_power_on <= '1';
		wait for 2 us;
		car_power_on <= '0';
 
      wait;
   end process;

end;

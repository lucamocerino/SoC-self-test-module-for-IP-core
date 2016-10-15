library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity system is

PORT(
		clk: IN STD_LOGIC;
		car_power_on : IN STD_LOGIC;
		ok_status : OUT STD_LOGIC;
		fault_status : OUT STD_LOGIC;
		debug_port : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
	
end system;

architecture Behavioral of system is

component RAM 
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END component;


component ROM 
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END component;

component CU 
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
	
end component;


component cordic_v4_0 
  port (
    x_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    y_in : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    phase_out : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    clk : IN STD_LOGIC
  );
end component;

--internal signals

	signal WEA: std_logic_vector(0 downto 0);
	signal ram_address: std_logic_vector(10 downto 0);		
	signal ram_out: std_logic_vector(15 downto 0);	
	signal ram_in: std_logic_vector(15 downto 0);	
	signal rom_address:std_logic_vector(11 downto 0);		
	signal rom_out: std_logic_vector(31 downto 0);	
	signal x: std_logic_vector(15 downto 0);
	signal y: std_logic_vector(15 downto 0);
	signal phase: std_logic_vector(15 downto 0);
	
begin

-- Components

ram0:	RAM port map(clk, WEA, ram_address, ram_in,ram_out);
rom0:	ROM port map(clk, rom_address, rom_out);

control_unit: CU port map(clk, car_power_on, ok_status, fault_status, debug_port, WEA,ram_address,ram_out,ram_in, 
								rom_address,rom_out,
								x, y, phase);
								
arctgh: cordic_v4_0 PORT MAP(x, y, phase,clk);

end Behavioral;


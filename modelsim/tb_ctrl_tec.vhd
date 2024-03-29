library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_ctrl_tec is   
end entity;

architecture tb of tb_ctrl_tec is

    signal clk           : std_logic;
    signal nRst          : std_logic;
    signal columna       : std_logic_vector(3 downto 0);
    signal tic_1ms       : std_logic;
    signal fila          : std_logic_vector(3 downto 0);    
    signal tecla_valida_reg  : std_logic;
    signal tecla         : std_logic_vector(3 downto 0);
    signal duracion_pulso: std_logic;
    signal flanco_bajada_col: std_logic;
    signal columna_color : std_logic_vector(1 downto 0);
    constant tclk:       time := 20 ns;
begin
dut: entity work.ctrl_tec(rtl)
port map(
    clk           =>clk,
    nRst          =>nRst,
    columna       =>columna,
    tic_1ms       =>tic_1ms,
    fila          =>fila,
    tecla_valida_reg  =>tecla_valida_reg,
    tecla         =>tecla,
    duracion_pulso=>duracion_pulso,
    flanco_bajada_col => flanco_bajada_col,
    columna_color =>columna_color
    );

reloj: process
begin
    clk <= '0';
    wait for tclk/2;
    clk <= '1';
    wait for tclk/2;
end process ;         -- Fin proceso de reloj

tic_1mss : process
begin
    tic_1ms <= '0';
    wait for tclk*25;
    wait until clk'event and clk='1';
    tic_1ms <= '1';
    wait for tclk;
    wait until clk'event and clk='1';
end process ;        -- Fin proceso generar tic_1ms

est : process
begin
  -- Inicizalización asíncrona
  nRst         <=  '0';
  columna      <=   "1111";
  wait for tclk*25;
  wait until clk'event and clk='1';
  nRst<='1';
  -- Fin inicialización asíncrona
  
  -- Simulación escalada, suponiendo 25 ciclos un tic de temporización.
  -- Inicialización síncrona
  columna      <=   "1110";        -- Seleccionamos una tecla de la col0
  wait for tclk*25*20;             -- tengo pulsada la tecla 1 segundo 
  wait until clk'event and clk='1'; 
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo 
  wait until clk'event and clk='1';
  columna      <=   "1011";  
  wait for tclk*25*60;             -- tengo pulsada la tecla 3 segundos 
  wait until clk'event and clk='1'; 
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo
  columna      <=   "1011";  
  wait for tclk*25*10;             -- tengo pulsada la tecla 0.5 segundos 
  wait until clk'event and clk='1';
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo

  columna      <=   "1101";        -- Seleccionamos una tecla de la col1
  wait for tclk*25*20;             -- tengo pulsada la tecla 1 segundo 
  wait until clk'event and clk='1'; 
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo 
  wait until clk'event and clk='1';
  columna      <=   "1011";  
  wait for tclk*25*60;             -- tengo pulsada la tecla 3 segundos 
  wait until clk'event and clk='1'; 
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo
  columna      <=   "1011";  
  wait for tclk*25*10;             -- tengo pulsada la tecla 0.5 segundos 
  wait until clk'event and clk='1';
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo 
  
  columna      <=   "1011";        -- Seleccionamos una tecla de la col2
  wait for tclk*25*20;             -- tengo pulsada la tecla 1 segundo 
  wait until clk'event and clk='1'; 
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo 
  wait until clk'event and clk='1';
  columna      <=   "1011";  
  wait for tclk*25*60;             -- tengo pulsada la tecla 3 segundos 
  wait until clk'event and clk='1'; 
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo
  columna      <=   "1011";  
  wait for tclk*25*10;             -- tengo pulsada la tecla 0.5 segundos 
  wait until clk'event and clk='1';
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo 
  
  columna      <=   "0111";        -- Seleccionamos una tecla de la col3
  wait for tclk*25*20;             -- tengo pulsada la tecla 1 segundo 
  wait until clk'event and clk='1'; 
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo 
  wait until clk'event and clk='1';
  columna      <=   "1011";  
  wait for tclk*25*60;             -- tengo pulsada la tecla 3 segundos 
  wait until clk'event and clk='1'; 
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo
  columna      <=   "1011";  
  wait for tclk*25*10;             -- tengo pulsada la tecla 0.5 segundos 
  wait until clk'event and clk='1';
  columna      <=   "1111";
  wait for tclk*25*20;             -- dejo de pulsar la tecla 1 segundo 
  assert false
  report "done"
  severity failure;
end process ;

end architecture; -- tb
-- Interfaz del modo de juego
-- Se recibe la se�al de star del modo de configuraci�n cuando se quiere iniciar una partida, y se ordena la captura y escritura de un color.
-- Cuando la escritura se realiza se ordena el reseteo del timer del temporizador
-- A continuaci�n, se lee toda la memoria para poder representar cada color en el interfaz de salida:
--- Se realiza la lectura cuando se estan contando los primeros 0,2 segundos
--- se saca por la se�al de salida color_salida el valor le�do durante 0,8 segundos

--- cuando se termina de representar el �ltimo color de la memoria pasa al estado leer_clr
-- Esta �ltimo estado, realiza una lectura y se registra el valor de tecla pulsado por el usuario

-- Despu�s, se realiza la comprobaci�n, dependiendo de esta:
--- el color puede ser correcto o incorrecto.
--- si es correcto:  Se incrementa la direcci�n de lectura de la memoria siempre
--- si es correcto:  y no se ha terminado la lectura de la secuencia entera (lectura memoria entera), vuelve al estado leer_clr
--- si es correcto:  y se ha terminado la lectura de la secuencia entera (lectura memoria entera) y no se ha llegado a la longitud programada, se espera la recepcion de una tecla para volver a pedir un color
--- si es correcto:  y se ha terminado la lectura de la secuencia entera (lectura memoria entera) y se ha llegado a la longitud programada se pasa al estado partida terminada.
--- si es incorrecto:  se pasa al estado partida terminada.

-- en el estado de partida_terminada se env�a la se�al fin_partida al modo configuraci�n.
-- este control vuelve al stado inicio, a esperar un nuevo comienzo de partida

library ieee;
use ieee.std_logic_1164.all;  
use ieee.std_logic_unsigned.all; 
 
entity control_modo_juego  is 
	port(
	     clk: in 		std_logic;
	     nRst:	in 		std_logic;
	     clr_ready:	in std_logic; 					                                    -- Habilitaci�n de escritura (wr)
	     start: in std_logic;                                              -- Habilitaci�n para el inicio del modo juego
	     we_mem: in std_logic;                                             -- Indica que la escritura se ha realizado
       full_programado:	in	std_logic;                                    -- Indica que se ha llegado a la longitud programada
       fin_lectura_secuencia: in	std_logic;                              -- Se termina de leer toda la memoria
       tic_1s: in std_logic;
       flanco_bajada_col: in std_logic;                                  -- Tic se ha dejado de pulsar COLUMNA
       tiempo_secuencia: in std_logic;                                   -- Forma de onda de 0.2 a '0' y 0.8 a '1' 
       columna_color : in std_logic_vector(1 downto 0);                  -- Columna pulsada
       d_out: in 	std_logic_vector(1 downto 0);                          -- Color le�do
       
       color_salida: buffer std_logic_vector(1 downto 0);                -- Color para la interfaz de salida			                                         
       pick_clr:	buffer std_logic;					                                  -- Se�al para generar el color
       rst_time: buffer std_logic;                                       -- Se�al para resetar el temporizador
       reset: buffer std_logic;                                          -- Se�al para resetear la memoria y longitud
       rd: buffer std_logic;                                             -- Habilitaci�n para la lectura
       nueva_lectura: buffer std_logic;                                  -- Indico nueva lectura, reseteo de addr
       mostrando_secuencia: buffer std_logic;                            -- Activado durante el estado de mostrar secuencia
       fin_partida:	buffer std_logic;                                    -- Indico al automata de CONF que se ha terminado la partida
       puntuacion_almacenada: buffer std_logic_vector(13 downto 0);
       cuenta_num_mostrado: buffer std_logic_vector (13 downto 0);
       posicion_secuencia: buffer std_logic_vector(13 downto 0));		                                                                            
end entity;


architecture rtl of control_modo_juego is
  signal guarda_puntuacion: std_logic;
  signal sigue_jugando: std_logic;
  signal puntuacion: std_logic_vector(13 downto 0);
  -- Se�ales de comparacion:
  signal color_memoria_leida: std_logic_vector(1 downto 0);     -- Valor de la memoria leida para comparar
  signal color_pulsado: std_logic_vector(1 downto 0);           -- Col pulsada para comparar
  
  -- Se�ales para el color OK/ERROR y su registro
  signal color_ok: std_logic;
  signal color_ok_reg: std_logic;
  signal color_fallido: std_logic; 
  signal color_fallido_reg: std_logic;
  
  -- Se�ales entrada para el estado comprobar para:
  signal lectura: std_logic;    -- leer siguiente color para comparar
  signal wait_col: std_logic;   -- introducir color
  signal terminar: std_logic;   -- terminar y pasar al estado partida_terminada para avisar al automata de CONF.
  signal start_reg: std_logic;
  
	type t_estado is (introducir_clr, mostrar_secuencia, detectar_tecla_clr, comprobar_clr, wait_columna_clr, partida_terminada); 
	signal estado: t_estado;

 begin
  -- Procesador de juego
  process(clk,nRst)
    begin
      if nRst = '0' then
        estado <= introducir_clr;
        rst_time <= '0';
        reset <= '0';
        nueva_lectura <= '0'; 
        fin_partida <= '0'; 
        mostrando_secuencia <= '0';
        sigue_jugando <= '0';
      elsif clk'event and clk = '1' then        
        case estado is   
                 
          when introducir_clr => 
          
            guarda_puntuacion <= '0'; ---------------
            nueva_lectura <= '0';    
            if start = '1' and we_mem = '1' then                  -- A�ado un color cuando estoy en MODO JUEGO y puedo escribir.               
               estado <= mostrar_secuencia;            
               rst_time <= '1';                                      -- Reseteo una vez el timer para sincornizacion de tiempos.     
            end if;
            
          when mostrar_secuencia =>   
               
               rst_time <= '0';  
            if fin_lectura_secuencia = '1' and tic_1s = '1' then  -- Termino de leer toda la secuencia y representar el �ltimo color (tic = 1s) 
               sigue_jugando <= '0';                      
               estado <= detectar_tecla_clr; 
               nueva_lectura <= '1';                                 -- Indico una nueva lectura de la memoria 
               mostrando_secuencia <= '0'; 
            else 
               mostrando_secuencia <= '1';                             -- Se�al para indicar que se esta mostrando la secuencia por I.out      
              end if;
            
          when detectar_tecla_clr =>  
           
              nueva_lectura <= '0';                         
            if columna_color /= "00" then                         -- Pulso cualquier tecla (Gestiono solamente el valor de la columna)                 
               estado <= comprobar_clr;            
            end if;
            
          when comprobar_clr =>
           
            if lectura = '1' then                                 --  Color correcto, vuelvo a detectar otra tecla                              
               estado <= detectar_tecla_clr;  
            elsif wait_col = '1' then                         --  �ltimo color correcto y sigo jugando
               estado <= wait_columna_clr;
            elsif terminar = '1' then                             -- Color fallido o juego terminado
               estado <= partida_terminada;
               reset <= '1';                                         -- Reset memoria y longitud
               rst_time <= '1';                                      -- Vuelvo a resetear timer para la puntuacion   
               fin_partida <= '1';                       
             end if;
            
          when wait_columna_clr =>   
                                                                       -- Espero a pulsar cualquier tecla (columna) para a�adir un nuevo color
             if color_pulsado /= "00" and flanco_bajada_col = '1' then                         
               estado <= introducir_clr;
               nueva_lectura <= '1';
               guarda_puntuacion <= '1'; ---------------------- 
             end if;
                     
          when partida_terminada =>                               -- Partida terminada, se ha reseteado y enviado la se�al fin_partida al aut�mata de MODO CONF                
            
            estado <= introducir_clr;
            sigue_jugando <= '1';
            reset <= '0';
            fin_partida <= '0'; 
            rst_time <= '0';                                         
          end case;
   		end if;
end process; 
																					  

----------------------------------------------------------- SE�ALES SALIDA INTRODUCIR COLOR: 
-- Comando de habilitaci�n para obtener un color. 
process(clk, nRst)
	begin
	  if nRst = '0' then
	     pick_clr <= '0';	      
	  elsif clk'event and clk = '1' then
	    
	    if start = '1' and clr_ready = '0' and estado = introducir_clr then
	       pick_clr <= '1';
      elsif clr_ready = '1' then
         pick_clr <= '0';                 
	     end if;
	   end if;
 end process;

----------------------------------------------------------- SE�ALES SALIDA MOSTRAR SECUENCIA:                      
-- Comando para la lectura de toda la secuencia de colores de la memoria
process(clk,nRst) 
	begin
		if nRst = '0' then
			 rd <= '0';
		elsif clk'event and clk ='1' then
			
			if (estado = mostrar_secuencia and tiempo_secuencia = '1' and fin_lectura_secuencia = '0' and tic_1s = '1') or (color_ok = '1' and fin_lectura_secuencia = '0') then
					rd <= '1';
			else
					rd <= '0'; 
				end if;
		end if ;
	end process ;   -- mostrar_secuencia

	
 color_salida <= d_out when tiempo_secuencia = '1' and estado = mostrar_secuencia 
                       else "00";

----------------------------------------------------------- SE�ALES SALIDA DETECTAR TECLA COLOR:
   
-- Comando para la lectura de un color 
-- Comando para detectar la columna pulsada
-- Registrar se�al start
process(clk, nRst)
	begin
	  if nRst = '0' then
	     color_memoria_leida <= (others => '0');
	     color_pulsado <= (others => '0');
	     start_reg <= '0';      
	  elsif clk'event and clk = '1' then	   
	       start_reg <= start;
	    if estado = detectar_tecla_clr then
	       color_memoria_leida <= d_out;                          -- Se lee el dato mientras se espera en este estado
	       color_pulsado <= columna_color;                        -- Almaceno el valor pulsado antes de pasar a comprobar el color 
	    elsif estado = wait_columna_clr then 
	       color_pulsado <= columna_color;                                                               
	     end if;
	   end if;
 end process;


----------------------------------------------------------- SE�ALES SALIDA COMPROBAR COLOR: 
-- Comando comprobar un color 
-- Obtenemos si el color es VALIDO/FALLIDO y si podemos activar RD para la proxima lectura
                    
color_ok      <= '1' when estado = comprobar_clr and color_memoria_leida = color_pulsado and flanco_bajada_col = '1'   -- Color correcto y el usuario ha terminado d pulsar la tecla (COLUMNA)
                     else '0';
color_fallido <= '1' when estado = comprobar_clr and color_memoria_leida /= color_pulsado and flanco_bajada_col = '1'  -- Color incorrecto
                     else '0';                  


process(clk, nRst)  -- Registro para enumerar el n� de color mostrando
	begin
	  if nRst = '0' then
	     cuenta_num_mostrado <= (0 => '1', others => '0');  
	  elsif clk'event and clk = '1' then	
	   
	    if mostrando_secuencia = '0' then
	       cuenta_num_mostrado <= (0 => '1', others => '0');
	    elsif mostrando_secuencia = '1' and tic_1s = '1' then
           cuenta_num_mostrado <= cuenta_num_mostrado + 1;
                          
	     end if; 
	   end if;
 end process;
 
 process(clk, nRst)  -- Registro para la posicion secuencia 
	begin
	  if nRst = '0' then
	     posicion_secuencia <= (0 => '1', others => '0');  
	  elsif clk'event and clk = '1' then	
	    
	    if nueva_lectura = '1' then
	       posicion_secuencia <= (0 => '1', others => '0'); 
	    elsif estado = comprobar_clr and color_ok_reg = '1' and fin_lectura_secuencia = '0' then
	       posicion_secuencia <= posicion_secuencia + 1;                            
	     end if; 
	   end if;
 end process; 

  process(clk, nRst)  -- Registro para la puntuacion
	begin
	  if nRst = '0' then
	     puntuacion <= (others => '0'); 
	  elsif clk'event and clk = '1' then	
	    
	    if start_reg = '0' and start = '1' then
	      puntuacion <= (others => '0'); 
	    elsif nueva_lectura = '1' then
	       puntuacion <= (others => '0'); 
	    elsif estado = comprobar_clr and color_ok_reg = '1' then     
	       puntuacion <= puntuacion + 1;                             
	     end if; 
	   end if;
 end process;
 
  process(clk, nRst) 
	begin
	  if nRst = '0' then
	     puntuacion_almacenada <= (others => '0'); 
	  elsif clk'event and clk = '1' then		
	    if estado = mostrar_secuencia and sigue_jugando = '1' then
	       puntuacion_almacenada <= (others => '0');
	    elsif guarda_puntuacion = '1' then    
	       puntuacion_almacenada <= puntuacion;                         
	     end if; 
	   end if;
 end process;

----------------------------------------------------------- 
----------------------------------------------------------- 
-- SE�ALES DE ENTRADA PARA AVANZAR EN EL AUT�MATA --

-- Registro del color acertado 
-- Registro del color incorrecto    
                               
process(clk, nRst)  
	begin
	  if nRst = '0' then
	     color_ok_reg <= '0';  
	     color_fallido_reg <= '0';
	  elsif clk'event and clk = '1' then	   
	      color_ok_reg <= color_ok;
	      color_fallido_reg <= color_fallido;
	   end if;
 end process;

                   
lectura <= '1' when color_ok_reg = '1' and fin_lectura_secuencia = '0' and full_programado = '0'   -- Entrada para volver a leer otro color
               else '0';
wait_col <= '1' when color_ok_reg = '1' and fin_lectura_secuencia = '1' and full_programado = '0'  -- Entrada para esperar una pulsaci�n y a�adir un color
            else '0';
terminar <= '1' when (color_ok_reg = '1' and fin_lectura_secuencia = '1' and full_programado = '1') or color_fallido_reg = '1'  -- Entrada para finalizar el modo juego
                else '0';

		                                       
end rtl;
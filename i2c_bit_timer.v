/********1*********2*********3*********4*********5*********6*********7*********8
* File : i2c_bit_timer.v
*_______________________________________________________________________________
*
* Revision history
*
* Name  Marc, Erwin     Date  12/03/2024      Observations
* _______________________________________________________________________________
*
* Description
* //
* 
* 
*________________________________________________________________________________

* (c) Copyright Universitat de Barcelona, 2024
*
*********1*********2*********3*********4*********5*********6*********7*********/

module i2c_bit_timer #(parameter SIZE = 8)
		     (Clk, Rst_n, Ticks, Start, Stop, Out);
	/*-----
	  I/O
	------*/
	//1b wire inputs. Inputs must be set as wires
	input Clk,   //Rellotge del sistema
	      Rst_n, //Reset asincron actiu per flanc de baixada. Posa tant el valor del comptador com de la sortida a 0
	      Start, //Si esta actiu el Timer ha de poder tornar al valor inicial en qualsevol moment i mantenir-se en aquest estat
	      Stop;  //Si esta actiu el Timer para de decreixer

	//8b wire inputs. Inputs must be set as wires
	input [SIZE-1:0]Ticks; //valor a partir del qual el timer comencara a decreixer. Un cop el valor arriba a 0 el Timer es reincia i comenca a comptar de nou. PRER

	//1b reg output. LHS outputs inside always must be set as reg
	output reg Out; //Flag del timer. Cada N cicles de rellotge (en funcio del prescaler) genera un pols que indica que el comptador ha arribat a 0

	//variables internas con minuscula
	reg [SIZE-1:0]counter; //registro interno

	/*--------------------------------------------------------------------
	 * Timer decreciente ciclico con reset asincrono por flanco de bajada
	 * 
	 * 
	--------------------------------------------------------------------*/
	always @(posedge Clk or negedge Rst_n) begin
		//reset asincrono
		if (!Rst_n) begin
			Out <= 1'b0;
			counter[SIZE-1:0] <= {SIZE{1'b0}};
		end
		//start = 1 or counter = 0
		else begin
			if (Stop) begin
				Out     <= 1'b0;
				counter <= counter;
			end

			else if (Start || ~|counter) begin
				Out     <= 1'b1;
				counter <= Ticks;
			end

			else begin
				Out     <= 1'b0;
				counter <= counter - 1'b1;
			end
		end
	end

endmodule //tanquem el module i2c_bit_timer

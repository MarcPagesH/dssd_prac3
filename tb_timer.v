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

/*---------
  Includes
----------*/
`include "../misc/timescale.v"

/*--------
  Defines
---------*/
`define DELAY 2 //delay between clock posedge and check
`define RTL_LVL //verification level: RTL_LVL (todo es ideal) GATE_LVL (sim post sintesi)

module tb_timer(); //module name (same as the file)
  //___________________________________________________________________________
  //Parameter
  parameter SIZE = 4;      //data size of the

  //input (reg) signals for the DUT
  reg            clk;   //
  reg            rst_n; //
  reg [SIZE-1:0] ticks; //
  reg            start; //
  reg            stop;  //
  
  //output (wire) signals for the DUT
  wire out;  //shift register serial data output

  //test signals
  integer errors;    //Accumulated errors during the simulation
  integer bitCntr;   //used to count bits
  reg     [SIZE-1:0] ticks2load; //data to load in the shift register
  reg     [SIZE-1:0] countNtimes;
  reg     vExpected; //expected value
  reg     vObtained; //obtained value

  //___________________________________________________________________________
  //Instantiation of the module to be verified. If `define = RTL_LVL  -> shiftreg #(.SIZE(8)) DUT(
  //                                            If `define = GATE_LVL -> shiftreg DUT(
  `ifdef RTL_LVL
  i2c_bit_timer #(.SIZE(SIZE)) DUT( //RTL_LVL
  `else                          //GATE_LVL
  i2c_bit_timer DUT(             //used by post-syntesis verification
  `endif

    //the instantiation is common for both RTL_LVL and GATE_LVL
    .Clk   (clk),
	.Rst_n (rst_n),
	.Ticks (ticks),
	.Start (start),
	.Stop  (stop),
	.Out   (out)
  );

  //___________________________________________________________________________
  //100 MHz clock generation
  initial clk = 1'b0;
  always #5 clk = ~ clk;

  //___________________________________________________________________________
  //input signals and vars initialization
  initial begin
    //IO
    //clk = 1'b0;
    rst_n = 1'b1;
    start = 1'b0;
    stop  = 1'b0;
    ticks = {SIZE{1'b0}};

    //test signals
    errors    = 0;
    bitCntr   = 0;
    countNtimes = 4'd0;
    ticks2load = 1'b0;
    vExpected = 1'b0;
    vObtained = 1'b0;
  end

  //___________________________________________________________________________
  //Test Vectors
  initial begin
    $timeformat(-9, 2, " ns", 10); //format for the time print
    errors = 0;                    //initialize the errors counter
    reset;                         //puts the DUT in a known stage
    wait_cycles(5);                //waits 5 clock cicles

    //init carreguem
    ticks2load = 4'd15;
    wait_cycles(1);
    load_timer(ticks2load);

    //timer
    $display("[Info- %t] N vegades", $time);
    countNtimes = 4'd5;
    test_timer(countNtimes);      
    check_errors;                  //TASK. checks if an error is ocurred during the simulation
    errors = 0;

    //check stop
    $display("[Info- %t] check stop", $time);
    check_stop(ticks2load);
    check_errors;

    wait_cycles(1);                //for easy visualization of the end
    $stop;                         //atura el simulador i el posa en el mode interactiu on usuari pot introduir comandes per tal de poder analitzar els resultats
  end

  //Monitor. Everytime a signal changes it transcripts the current values. Only 1 monitor in the whole testbench can be called
  initial begin
    $monitor("[Info- %t] Start=%b Stop=%b Out=%b",
             $time, start, stop, out);
  end

  //___________________________________________________________________________
  //Test tasks

  //una resta
  task test_counter_timeout;
    input [SIZE-1:0]data;             //TICKS

    begin
      bitCntr = data;                    //bit counter set to 0
      stop = 1'b0;

      repeat(data) begin            //repeats the loop Ntimes
        bitCntr = bitCntr - 1;        //increase by 1 the bit counter. Usat per recorrer la dada serie d'entrada
	vExpected = 1'b0;
	vObtained = out;
	wait_cycles(1);
      end

      vExpected = 1'b1;     //expected the parallel output to be the serial input ticks2load shifted Ntimes
      vObtained = out;            //obtained parallel output is the real dataOut from shiftreg
      sync_check;                    //TASK. checks if vExpected = vObteined
    end
  endtask

  //N restas
  task test_timer;
    input [SIZE-1:0] Ntimes;
    begin
      start = 1'b0;                   //enable desplacament
      stop = 1'b0;

      repeat(Ntimes) begin            //repeats the loop Ntimes
        test_counter_timeout(ticks2load);        //increase by 1 the bit counter. Usat per recorrer la dada serie d'entrada
        $display("[Info- %t] Deteccio de pols", $time);
      end
      vExpected = 1'b0; //fancy baixada del pols
      vObtained = 1'b0;
    end
  endtask

  task check_stop;
    input [SIZE-1:0] data;

    begin
      bitCntr = data;                    //bit counter set to 0
      stop = 1'b0;

      repeat(data) begin            //repeats the loop Ntimes
        bitCntr = bitCntr - 1;
        if (bitCntr == data/4'd2) begin
          stop = 1'b1;
          wait_cycles(5);
          stop = 1'b0;
        end
        else begin
        end
          vExpected = 1'b0;
	  vObtained = out;
	  wait_cycles(1);
      end

      vExpected = 1'b1;     //expected the parallel output to be the serial input ticks2load shifted Ntimes
      vObtained = out;            //obtained parallel output is the real dataOut from shiftreg
      sync_check;                    //TASK. checks if vExpected = vObteined
      vExpected = 1'b0; //nomes per fer el bache cleaen, que no es quedi a 1 tot el rato. synch chekc ja te un wait cycles
      vObtained = 1'b0;
    end

  endtask

  //load
  task load_timer;
    input [SIZE-1:0] data;

    begin
      if (data == 4'b0) begin
         $display("[Info- %t] Ticks loaded is %d, out stays stuck at 1", $time, data);
      end
      else begin
         $display("[Info- %t] Ticks loaded is %d", $time, data);
      end
      ticks = data;
      start = 1'b1;
      wait_cycles(1);      //waits 1 clock cycle
      start = 1'b0;
      wait_cycles(1);      //waits 1 clock cycle
    end

  endtask

  //___________________________________________________________________________
  //Basic tasks

  //Generation of reset pulse. Reset is active low
  task reset;
    begin
      $display("[Info- %t] Reset", $time);
      rst_n = 1'b0;   //reset
      wait_cycles(3); //during 3 clock cycles
      rst_n = 1'b1;   //stop reset
    end
  endtask

  //Wait for N clock cycles
  task wait_cycles;
    input [32-1:0] Ncycles;

    begin
      repeat(Ncycles) begin
        @(posedge clk);
          #`DELAY;
      end
    end
  endtask

  //Synchronous output check. if vExpected is not equal to vObtained an error occurred
  //                          if vExpected is equal to vObtained no errors occurred
  task sync_check;
    begin
      wait_cycles(1);
      if (vExpected != vObtained) begin
        $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
        errors = errors + 1;
      end else begin                   
        $display("[Info- %t] Successful check at time", $time);
      end
    end
  endtask

  //Asynchronous output check. if vExpected is not equal to vObtained an error occurred
  //                           if vExpected is equal to vObtained no errors occurred
  task async_check;
    begin
      #`DELAY;
      if (vExpected != vObtained) begin
        $display("[Error! %t] The value is %h and should be %h", $time, vObtained, vExpected);
        errors = errors + 1;
      end else begin
        $display("[Info- %t] Successful check at time", $time);
      end
    end
  endtask

  //Check for errors during the simulation
  task check_errors;
    begin
      if (errors == 0) begin
        $display("********** TEST PASSED **********");
      end else begin
        $display("********** TEST FAILED **********");
      end
    end
  endtask

endmodule

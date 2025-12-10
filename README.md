# Nano119 CPU programmable with SPI

## CPU features
-	4 K byte ROM for code space
-	2 K word RAM for data space
-	256 words stack
-	Direct addressing operation
-	ALU with 16 bits operands and 32-bit result
-	119 instructions
-	Dedicated IO busses to communicate with generic peripherals 
-	Interrupt capability
-	SPI interface to program the code space and access the data space
-	Configurable operating speed

## How it works

A simple architecture for practical implementation of a central processing unit (CPU) is proposed as teaching resource, to experiment and verify the fundamental concepts of a simple computer architecture with its instruction set (in this case, 119 instructions). A block diagram for the proposed architecture is presented in the following figure  

![Figure-1](Nano_mux_architecture.png)

The auxiliary modules are presented in the following figure  

![Figure-2](Nano_peripherical.png)

To enable user access to both code and data memory spaces, before and after the execution of any program, the processing system includes a slave SPI communication block. The multiplexors are controlled by MODE signal to set the operation mode (programmingexecution). Additionally, RUN signal is dedicated to start the code execution. 

In practice, to work with the input and output ports of a Basys3 board, the entire system has been packaged in the Nano_mcsys_cnfg module, which is represented schematically below

![Figure-3](Nano_mcsys_cnfg_module.png)

Within the Nano_mcsys_cnfg module, the parameter CPU_CLK_SEL is used to select, by means a multiplexor, the CPU clock signal that will be used to drive the machine cycles (fetch-decode-execute). Assuming a 100 MHz system clock, the possible CPU frequencies are showed in the following table

![Figure-4]( CPU_SCK_Sel_Table.png)

For more details on system implementation, see the Nano_mcsys_cnfg.vhd file.

### Architectural overview
The proposed CPU uses a Harvard architecture in which program, data and IO are accessed from separate busses. The data word size is 16 bits while the code word size is 8 bits. The 16-bit ALU is a general-purpose arithmetic and logic unit and its result is always stored in the 32-bit R register. 
The arithmetic instructions affect the values of the following flags
-	Z16 16 bits Zero  Equal
-	N16 16 bits negative  Less tan
-	O16 16 bits overflow
-	CO16 16 bits catastrophic overflow
-	Z32 32 bits Zero
-	N32 32 bits negative
-	O32 32 bits overflow
-	CO32 32 bits catastrophic overflow
Z16, N16, O16 and CO16 flags are set based on the 16 least significant bits of R register, while Z32, N32, O32 and CO32 flags are set based on the whole R register. The catastrophic overflow is set when the result sign does not correspond with the expected. The logic instructions only affect the Z16 and Z32 flags.

The architecture includes the following registers
-	State register To track the CPU micro-states
-	IP register 12-bit Instruction Pointer, to access the code space     
-	DP register 11-bit Data Pointer, to access the data space
-	SP register 8-bit Stack Pointer, to access the stack space by means push and pop instructions
-	USP register 8-bit User Stack Pointer, to access the stack space in a random way
-	PP register 8-bit Peripheral Pointer, to access the IO space
-	A and B registers Generic 16-bit operand registers
-	R register Generic 32-bit result register
-	Acc register 32-bit result register for AC and MAC instructions
-	I and J registers 16-bit counting registers for iteration loops
-	N and M registers 16-bit target count registers for iteration loops
Additionally, the architecture includes the following internal registers that are not directly accessible by the user
-	F register 8-bit Flags register
-	Instruction, H and L registers 8-bit registers, used at instruction decode process to store op code and parameters values

### Program memory organization
The CPU has 12-bit instruction pointer capable of addressing a 4k x 8 program. The reset vector is at 0x0000, while the interrupt vectors are at 0xFF7, 0xFFA and 0xFFD, for Int2, Int1 and Int0, respectively.

![Figure-5](Program_memory_map.png)

### Stack
The CPU has a 256- level deep x 16-bit wide stack. The push instruction first stores the data and later increment de SP. The pop instruction first decrements de SP and later restore the data.
The user can access the stack space by means pushpop instructions or with data transfers by means the USP pointer. The instruction call automatically pushes the IP in the stack and the ret instruction pops it to continue the program Flow. 
In the case of an interruption, if it is detected while running a program, the system automatically pushes the IP, R and F registers, while reti instruction pops all these.

### IO interface
The CPU provides dedicated buses to access generic peripherals by means In and out instructions. The user can add a required peripheral with this interface. In the current implementation, it has been reserved the first two locations of IO space, i.e. 0x00 and 0x01, to control the 3 available interrupts.

### Interrupts
The CPU has 3 external sources of interrupt, denoted as Int0, Int1 and Int2. The highest priority is assigned to Int0, while the lowest priority is assigned to Int2. If it is enabled, an interruption can be served while a program is executed, but also if the CPU is at stop status. When the interrupt service is required while a program is executed, it implies the usual context saving process. On the other hand, when the interrupt service is required while a program is stopped, it does not save the context.  The registers to control these interrupts are mapped in the first two locations of the IO space
-	IE reg Interrupt Enable register, mapped at 0x00 of IO space
-	IF reg Interrupt Flags register, mapped at 0x01 of IO space

![Figure-6]( Interrupt_control_regs.png)

To enable an interruption, it is necessary to set the corresponding bit in IE register. When an interruption is enabled and it occurs (a positive edge is detected in the interrupt pin), the system automatically set the corresponding interruption flag in IF register and no other interrupt can be attended. Then, when the interrupt service routine finishes its task, before reti instruction, the interrupt flag must be cleaned.

### Instruction set
The proposed instruction set is can be conveniently codified with bytes. The following tables summarizes the proposed instruction codification

![Figure-7](Instruction_Set_01.png)
![Figure-8](Instruction_Set_02.png)
![Figure-9](Instruction_Set_03.png)
![Figure-10](Instruction_Set_04.png)
![Figure-11](Instruction_Set_05.png)
![Figure-12](Instruction_Set_06.png)
![Figure-13](Instruction_Set_07.png)
![Figure-14](Instruction_Set_08.png)
![Figure-15](Instruction_Set_09.png)
![Figure-16](Instruction_Set_10.png)
![Figure-17](Instruction_Set_11.png)

The following is a demo program

![Figure-18]( Demo01_program.png)

## How to test

The CPU system must be programed before a code execution. The RAM and ROM loads are enabled with signal MODE=0. With signal MODE=1, the code execution starts with signal RUN=1.  

To program the code space and access the data space, SPI transfers are used. In the following figure, the SPI pinout for the JA Pmod interface of the Basys3 is presented
 
![Figure-19]( PMOD_SPI_pinout.png)

The SPI word size is 32 bits with the following format

![Figure-20](Nano_SPI_transfer_words.png)

The bit 31 (MSB) is set to specify a read operation. The address field specifies the location being accessed and de data field contains the information to be written or read. In the following figure, the SPI addressing map is presented

![Figure-21](Nano_SPI_Address_MAP.png)
  
For SPI transfers, the following specification is assumed
- CS signal is active low, and it idles high. 
- SCK signal is active low, and it idles high.
- Data is valid on the second SCK edge (rising or falling) after CS has been asserted. 
- The most significant bit is the first to be transmitted.

In the case of a read sequence, the read command must be followed by a stuff SPI word (let's say, all ones or all zeros word). The read information will be in the data field of the SPI word transmitted by the slave SPI.  

Within the slave_spi4nano module, the SCK frequency is assumed as CLK8. For example, if the CLK frequency is 50 MHz, the SCK frequency is 6.25 MHz. SPI interface also works with low frequency, for example, if CLK frequency is 1525.879 Hz, the SCK frequency is 190.8 Hz. Additionally, within the nano_spictrl module, the SPI base frequency is selected by the parameter CLK_DIVISOR and one multiplexor. According with the code, and assuming a 100 MHz system clock, the possible SCK frequencies are showed in the following table

![Figure-22]( SPI_SCK_Sel_Table.png)


## Additional hardware

As practical reference, also a master SPI project is attached in this repository.

## HOW TO CITE

If you mention this project in a publication, I ask that you include the following citation for it

 Laguna-Sanchez, G.A. (2025). Nano119 CPU programmable with SPI.  
  httpsgithub.comgalagunaNano119-CPU-programmable-with-SPI.

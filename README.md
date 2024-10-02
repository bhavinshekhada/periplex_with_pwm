
# AMBA APB Protocol with UART, GPIO, and PWM Integration

## Project Overview

This project showcases the integration of UART, GPIO, and PWM protocols with the AMBA APB (Advanced Peripheral Bus) protocol on an FPGA platform. The primary goal is to implement multiple peripherals (UART, GPIO, and PWM) operating in parallel and controlled by an APB master. Additionally, the next phase of the project aims to make the design parametric, enabling users to extend and call any number of peripherals dynamically through a parameterized APB master.

## Features

- **AMBA APB Protocol**: Implements a versatile communication interface for connecting low-bandwidth peripherals.
- **UART, GPIO, PWM as APB Slaves**: All three peripherals (UART, GPIO, PWM) function as independent APB slaves, each receiving commands from the APB master.
- **Parallel Peripheral Control**: UART, GPIO, and PWM work in parallel, independently controlled by the APB master.
- **Verilog/VHDL Design**: Developed in Verilog for FPGA synthesis and simulation.
- **Parametric Design (Future)**: In future iterations, users will be able to extend the number of protocols by parameterizing the APB master-slave interface.

## Block Diagram

```
+-----------------+      +------------------+
|                 |      |                  |
|   APB Master    |<---->|  UART APB Slave   |
|                 |      |                  |
+-----------------+      +------------------+
      |
      |
      V
+-----------------+      +------------------+
|                 |      |                  |
|   APB Master    |<---->|  GPIO APB Slave   |
|                 |      |                  |
+-----------------+      +------------------+
      |
      |
      V
+-----------------+      +------------------+
|                 |      |                  |
|   APB Master    |<---->|  PWM APB Slave    |
|                 |      |                  |
+-----------------+      +------------------+
```

### Functional Components

1. **APB Master**: Controls the UART, GPIO, and PWM slaves via read and write operations.
2. **UART Slave**: Provides asynchronous serial communication.
3. **GPIO Slave**: Provides general-purpose input/output functionality.
4. **PWM Slave**: Provides Pulse Width Modulation (PWM) signals for controlling devices like motors or LEDs.

## Future Work: Parametric Extension

The next step is to make the APB interface parametric, allowing users to configure and extend the number of APB peripherals easily. By introducing a parameterized design, users will be able to instantiate any number of peripheral devices (UART, GPIO, PWM, etc.) without modifying the core design.

- **Parametric APB Master**: A single APB master that dynamically supports multiple peripherals based on user-defined parameters.
- **Scalable Design**: The system can be easily scaled to include additional peripherals (SPI, I2C, etc.) using the same APB framework.
- **User Configurable**: End-users can specify the number of peripherals and their respective types via parameters.

## Getting Started

### Prerequisites

To get started with this project, you'll need the following:

- **FPGA Board**: Any FPGA board that supports Verilog/VHDL synthesis (e.g., Xilinx, Altera).
- **Vivado/Quartus**: For synthesizing and implementing the design on the FPGA.
- **UART Terminal**: For UART communication with the FPGA.
- **GPIO Pins**: Configurable as input or output for basic I/O tasks.
- **PWM Output Device**: For testing PWM signals, such as LEDs or motors.

### Project Structure

```plaintext
├── src/
│   ├── apb_master.v          # APB Master Design
│   ├── uart_apb_slave.v      # UART APB Slave Design
│   ├── gpio_apb_slave.v      # GPIO APB Slave Design
│   ├── pwm_apb_slave.v       # PWM APB Slave Design
│   ├── uart_tx.v             # UART Transmit Module
│   ├── uart_rx.v             # UART Receive Module
│   ├── apb_interface.v       # APB Interface between master and slaves
│   └── testbench.v           # Testbench for simulation
├── constraints/
│   └── constraints.xdc       # FPGA pin constraints for UART, GPIO, and PWM
├── sim/
│   └── testbench_tb.v        # Testbench to verify functionality
└── README.md                 # Project documentation
```

### How to Run

1. **Clone the Repository**:

    ```bash
    git clone https://github.com/your-username/amba-apb-uart-gpio-pwm-fpga.git
    cd amba-apb-uart-gpio-pwm-fpga
    ```

2. **Open the Project**:
   - Open your FPGA IDE (Vivado for Xilinx or Quartus for Intel FPGAs).
   - Create a new project and add the `src/` files to your project.
   - Add the constraints file located in `constraints/` to map UART, GPIO, and PWM pins.

3. **Synthesize and Implement**:
   - Run the synthesis and implementation process in the FPGA tool.
   - Ensure that the UART, GPIO, and PWM peripherals are mapped correctly to the FPGA pins as per the constraints file.

4. **Program the FPGA**:
   - Connect your FPGA to the host system.
   - Program the FPGA with the generated bitstream.

5. **Test UART, GPIO, and PWM**:
   - Use a UART terminal to communicate with the UART slave.
   - Control the GPIO pins and observe input/output behavior.
   - Test the PWM output by connecting a PWM-controlled device such as an LED or motor.

### Simulation

The project includes a testbench for functional simulation of all three peripherals. To run a simulation, use the following command in your simulator environment:

```bash
# Run simulation
vsim work.testbench_tb
```

### Parametric Design (Future)

In the future, this project will implement a parametric APB master that will dynamically instantiate any number of slaves (UART, GPIO, PWM, etc.) based on user inputs. This will allow users to create scalable systems without manually adding peripherals to the APB bus.

- **Parameters**: Users will be able to define the number and types of peripherals.
- **Dynamic Configuration**: The design will support dynamic peripheral addition/removal without changing the core APB architecture.

## FPGA Board

This project has been tested on a [Insert FPGA Board Name], but it can be adapted to other FPGA platforms by adjusting the I/O pin configurations in the constraints file.

## Future Work

- **Parametric APB Interface**: Extend the APB bus to support a dynamic number of peripherals.
- **Additional Peripherals**: Integrate SPI, I2C, and other protocols.
- **DMA Support**: Enable high-speed data transfers between peripherals.
- **Power Optimization**: Implement low-power design techniques.

## Contributing

Contributions are welcome! If you'd like to add new features or optimize the existing design, feel free to submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

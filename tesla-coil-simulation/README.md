# Tesla Coil RLC Simulation

This Python project simulates a Tesla coil as a coupled RLC circuit and optionally visualizes the magnetic field around the secondary coil.

## Features

- Command-line parameter input for circuit values (inductance, capacitance, resistance, etc.)
- Visualizes primary and secondary coil currents
- Optional magnetic field visualization around the secondary coil

## Usage

1. Install dependencies:

   ```
   pip install -r requirements.txt
   ```

2. Run with default parameters:

   ```
   python main.py
   ```

3. Customize parameters via command line (example):

   ```
   python main.py --L1 25e-6 --L2 90e-3 --C1 12e-9 --R2 1500 --V0 6000 --tmax 0.001
   ```

4. Add `--field` to visualize the magnetic field:

   ```
   python main.py --field
   ```

## Parameters

- `--L1`: Primary inductance (H)
- `--L2`: Secondary inductance (H)
- `--C1`: Primary capacitance (F)
- `--C2`: Secondary capacitance (F)
- `--R1`: Primary resistance (Ohm)
- `--R2`: Secondary resistance (Ohm)
- `--M`: Mutual inductance (H)
- `--V0`: Initial voltage on C1 (V)
- `--tmax`: Simulation time (s)
- `--field`: Plot magnetic field visualization

## License

MIT License

# π and Golden Ratio (φ) Exploration

This mini-project demonstrates geometric relationships between π (pi ≈ 3.14159) and the golden ratio (φ ≈ 1.61803) using Python visualizations.

## Features

- **Golden Rectangle Visualization**: Plots a golden rectangle, an inscribed square, and an arc.
- **Fibonacci Spiral Visualization**: Plots a spiral-like path built from Fibonacci step lengths.
- **Command-Line Input**: Choose visualizations and customize constants.

## Usage

1. Install requirements:

   ```bash
   pip install -r requirements.txt
   ```

2. Plot a golden rectangle with a π-labeled arc:

   ```bash
   python main.py --rectangle
   ```

3. Plot a Fibonacci spiral path:

   ```bash
   python main.py --spiral
   ```

4. Customize parameters:

   ```bash
   python main.py --rectangle --phi 1.61803398875 --pi 3.14159265359
   python main.py --spiral --terms 12
   ```

## Math Notes

- π is transcendental.
- φ is **not transcendental**; it is algebraic and satisfies `x² − x − 1 = 0`.

References provided:

1. [Simple proofs: Pi is transcendental « Math Scholar](https://mathscholar.org/2025/02/simple-proofs-pi-is-transcendental/)
2. [Proof π is transcendental without symmetric function theory](https://math.stackexchange.com/questions/4861927/proof-pi-is-transcendental-without-symmetric-function-theory)
3. [Section 9.26: Transcendence—The Stacks project](https://stacks.math.columbia.edu/tag/030D)

## License

MIT License

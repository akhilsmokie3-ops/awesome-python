import argparse

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Arc, Rectangle


def golden_rectangle_plot(phi: float, pi_val: float, width: float = 1.0) -> None:
    """Plot a golden rectangle, an inscribed square, and an arc."""
    height = width / phi
    fig, ax = plt.subplots()

    # Main rectangle
    rect = Rectangle((0, 0), width, height, fill=False, edgecolor="gold", linewidth=2)
    ax.add_patch(rect)

    # Square inside
    square = Rectangle((0, 0), height, height, fill=False, edgecolor="blue", linewidth=2)
    ax.add_patch(square)

    # Arc using pi in the title (arc geometry is based on the square)
    arc = Arc((height, height), 2 * height, 2 * height, angle=0, theta1=0, theta2=180, edgecolor="red", linewidth=2)
    ax.add_patch(arc)

    ax.set_xlim(-0.2, width + 0.2)
    ax.set_ylim(-0.2, height + 0.2)
    ax.set_aspect("equal")
    ax.set_title(f"Golden Rectangle (φ ≈ {phi:.5f}), Arc (π ≈ {pi_val:.5f})")
    plt.show()


def fibonacci_spiral_plot(n_terms: int = 10) -> None:
    """Plot a polyline using Fibonacci step lengths and quarter turns."""
    a, b = 1, 1
    x, y = 0.0, 0.0
    angle = 0
    pts = [(x, y)]

    for _ in range(n_terms):
        x += np.cos(np.deg2rad(angle)) * b
        y += np.sin(np.deg2rad(angle)) * b
        pts.append((x, y))
        a, b = b, a + b
        angle += 90

    pts = np.array(pts)
    plt.plot(pts[:, 0], pts[:, 1], marker="o")
    plt.title("Fibonacci Spiral (approaches golden ratio)")
    plt.axis("equal")
    plt.show()


def main() -> None:
    parser = argparse.ArgumentParser(description="π and Golden Ratio Visualizations")
    parser.add_argument("--rectangle", action="store_true", help="Plot golden rectangle with arc using π")
    parser.add_argument("--spiral", action="store_true", help="Plot Fibonacci spiral")
    parser.add_argument("--phi", type=float, default=(1 + np.sqrt(5)) / 2, help="Golden ratio value (default φ)")
    parser.add_argument("--pi", type=float, default=np.pi, help="Pi value (default π)")
    parser.add_argument("--terms", type=int, default=10, help="Terms in Fibonacci spiral")
    args = parser.parse_args()

    if args.rectangle:
        golden_rectangle_plot(args.phi, args.pi)
    if args.spiral:
        fibonacci_spiral_plot(args.terms)
    if not args.rectangle and not args.spiral:
        parser.print_help()


if __name__ == "__main__":
    main()

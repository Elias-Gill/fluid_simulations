# Fluid Simulation Project in Zig

## Overview

This project is a comprehensive exploration of fluid simulations, low-level programming, and
software engineering principles.

It serves as both a learning exercise and a showcase for efficient, scalable, and extensible
code design.

## Goals and Objectives

1. **Fluid Simulation Mastery**: 
- Implement various fluid simulation algorithms
- Explore different approaches to fluid dynamics modeling
- Achieve realistic visualizations of fluid behavior

2. **Low-Level Programming Expertise**:
- Leverage Zig's capabilities for fine-grained control over system resources
- Optimize performance through careful memory management and algorithm selection

3. **Software Engineering Excellence**:
- Design modular, extensible architecture for easy addition of new simulation techniques
- Implement robust testing frameworks to ensure reliability across different scenarios
- Develop intuitive APIs for seamless integration with other components

4. **Mathematical Understanding**:
- Apply advanced mathematical concepts to fluid dynamics problems
- Implement numerical methods for solving partial differential equations

5. **Performance Optimization**:
- Utilize Zig's compile-time evaluation capabilities for performance-critical sections
- Implement parallel processing techniques where applicable

## Technical Details

- **Rendering Engine**:
  Raylib for cross-platform rendering and input handling
- **Programming Language**:
  Zig for its balance of low-level control and high-level abstractions
- **Simulation Algorithms**: 
    - Smoothed Particle Hydrodynamics (SPH)
    - Lattice Boltzmann Methods (LBM)
    - Eulerian Grid-based methods

## Project Structure

```text
fluid-simulation/
├── src/
│   ├── main.zig
│   ├── simulation/
│   │   ├── sps.zig
│   │   ├── lbm.zig
│   │   └── eulerian.zig
│   ├── renderer/
│   │   └── raylib_wrapper.zig
│   └── utils/
│       ├── math.zig
│       └── performance.zig
├── tests/
└── docs/
```

## Contributing

Contributions are welcome!
Please see our [CONTRIBUTING.md](CONTRIBUTING.md) file for details.

## License

[MIT License](LICENSE)

## Acknowledgments

- Special thanks to the Raylib community for their excellent documentation and support.
- Appreciation to the Zig language developers for creating such an exciting platform for
  systems programming.

# A* Sandbox
By Trevor Maze ([trevormaze@oakland.edu](mailto:trevormaze@oakland.edu))

## Overview:
A* Sandbox is an interactive visualization for the A* graph traversal algorithm, frequently used in video games for pathfinding. My implementation simplifies the arbitrary graph to a grid, where every node is connected to the eight around it (movement weights being equal to sqrt(2) for the diagonals and 1 for the cardinal directions).

## Instructions:
A* Sandbox is written in Swift. To compile the code, [Swift must be installed](https://www.swift.org/install/). Once installed, the code can be run with ``swift run`` or by running the generated executable ``./.build/debug/A-Star``. The latter method can be used to include an initfile (such as the provided test files) and optionally specify ``--nointeract`` to disable the interactive environment and display the raw output of the algorithm.

If Swift cannot be installed, I have included binaries in the ``Binaries/`` folder that can be run via the terminal.

> [!WARNING]  
> __Windows users:__ This project was developed on a Unix-based system. While support for Windows terminals has been tested, the experience is noticeably degraded. I recommend using a Linux or macOS system to run this project.

## Video: 

## AI Usage Declaration:
I used AI for assistance with implementing cross-platform terminal input. Everything related to "terminal raw mode" and the readKey() function were created based on AI-generated solutions, tailored for my project's needs.

__No AI-generated code was used in the implementation of the core algorithm (the pathfind() function).__


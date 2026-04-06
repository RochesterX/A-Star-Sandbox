# A* Sandbox
By Trevor Maze ([trevormaze@oakland.edu](mailto:trevormaze@oakland.edu))

## Overview:
A* Sandbox is an interactive visualization for the A* graph traversal algorithm, frequently used in video games for pathfinding. My implementation simplifies the arbitrary graph to a grid, where every node is connected to the eight around it (movement weights being equal to sqrt(2) for the diagonals and 1 for the cardinal directions).

### Instructions:
A* Sandbox is written in Swift. To compile the code, [Swift must be installed](https://www.swift.org/install/). Once installed, the code can be run with ``swift run`` or by running the generated executable ``./.build/debug/A-Star``. The latter method can be used to include an initfile (such as the provided test files) and optionally specify ``--nointeract`` to disable the interactive environment and display the raw output of the algorithm.

If Swift cannot be installed, I have included binaries in the ``Binaries/`` folder that can be run via the terminal.

> [!WARNING]  
> __Windows users:__ This project was developed on a Unix-based system. While support for Windows terminals has been tested, the experience is noticeably degraded. I recommend using a Linux or macOS system to run this project.

### Video: 

### AI Usage Declaration:
I used AI for assistance with implementing cross-platform terminal input. Everything related to "terminal raw mode" and the readKey() function were created based on AI-generated solutions, tailored for my project's needs.

__No AI-generated code was used in the implementation of the core algorithm (the pathfind() function) or the creation of any documentation.__

## Analysis:
This algorithms is typically used for pathfinding in computer simulations, since it is relatively easy to run and always provides the fastest available path. The problem that it solves is finding the most efficient path around (possibly) dynamically places obstacles from a start locaion to a goal location.

The A* algorithm works by expanding out from a start node and keeping track of key "scores" for each node. The G-score is the actual cost that it took to reach that node (addition of the weights of all previously taken edges), and the F-score is the current best guess as to what the total score (from start to finish) would be by utilizing the heuristic function. These scores are related like this:

```
F-score[n] = G-score[n] + h(n)
```

for any given node ``n``. The heuristic function, ``h(n)`` is the estimated cost it would take to reach the goal from node ``n``, but it notably __must not__ be an overestimate. If it were an overestimate, it could convinve A* to take a nonoptimal path. This property is known as being _admissible_. Notably, if ``h(n) = 0``, A* collapses to just be Dijkstra's algorithm.

The core loop goes as follows (with worst-case time complexities for each component denoted [O(n)] for a graph ``G = { V, E }``):
- While unexplored nodes remain: [O(V)]
    - Find the unexplored node with lowest F-score [O(V) using my naive implementation; could be O[1] with priority queue]
    - If this node is the goal node:
        - Reconstruct the path taken to arrive there
        - Return the result
    - Otherwise, remove it from the set of unexplored nodes
    - For each of its neighboring nodes [O(E)]:
        - Calculate its G-score
        - If this G-score is the best (lowest) yet found:
            - Mark that this neighbor comes after the initial node in the current best path
            - Update the G-score for this neighbor
            - Calculate and update the F-score for this neighbor
            - If this neighbor hasn't yet been added to the unexplored nodes set, add it.

This implementation (excluding the priority queue implementation) has a time complexity of ``O(V^2)`` due to its outer loop that can loop through each node and several searches through (possibly) all nodes that occur inside the loop.

## Testing
Several test cases have been provided in the ``Tests/`` folder. Include one's path as an argument when running the program to initialize it with the provided grid. Optionally, include the ``--nointeract`` flag at the end to skip the simulation and print out the raw path taken. Test files must be plain text files with a grid of symbols. Valid symbols are as follows:
- ``.``: Traversable node
- ``#``: Blocked node
- ``S``: Start symbol (one per file)
- ``F``: Goal symbol (one per file)

For example:
```
.......
...#...
S..#..F
...#...
.......
```


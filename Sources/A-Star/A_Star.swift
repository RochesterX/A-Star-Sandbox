import Foundation

#if os(macOS)
import Darwin
#elseif os(Linux)
import Glibc
#elseif os(Windows)
import ucrt
#endif


@main
struct A_Star {
    static func main() {
        var initfilePath = "-"
        var noInteract = false

        if CommandLine.arguments.count == 2 {
            initfilePath = CommandLine.arguments[1]
        } else if CommandLine.arguments.count == 3 && CommandLine.arguments[2] == "--nointeract" {
            initfilePath = CommandLine.arguments[1]
            noInteract = true
        } else if (CommandLine.arguments.count != 1) {
            print("""
Improper syntax.

Usage:
    binary-path [initfile-path [--nointeract]]

Example:
    ./A-Star Tests/Test1 --nointeract
""")
            return
        }

        var grid: [[Int]] = [[]]
        var start: Vector2 = Vector2(x: -1, y: -1)
        var goal: Vector2 = Vector2(x: -1, y: -1)

        parseInitfile(initfilePath, grid: &grid, start: &start, goal: &goal)

        // Hide cursor
        print("\u{1B}[?25l")

        Terminal.enableRawMode()

        var cursorPosition = Vector2(x: 0, y: 0)

        defer {
            quit(clear: !noInteract)
        }

        var aStar = A_Star()

        var path = aStar.pathfind(grid: grid, start: start, goal: goal)

        if noInteract {
            aStar.display(path, on: grid)

            // If noInteract, print full path
            if path.count == 2 {
                print("\n\(Color.Red)No non-trivial path found.\(Color.Default)")
            } else {
                print("\nFull path: ")
                for vector in path {
                    let index = path.firstIndex(of: vector)!
                    print("(\(vector.x), \(vector.y))\(index != path.count - 1 ? (index % 5 == 4 ? " ⏎ " : " →  \t") : "")\(index % 5 == 4 ? "\n" : "")", terminator: "")
                }
            }
            print()

            quit(clear: false)
        }

        while true {
            aStar.display(path, on: grid, cursorPosition: cursorPosition)
            let key = Terminal.readKey()
            switch key {
            case .Left:
                cursorPosition += Vector2(x: -1, y: 0)
            case .Right:
                cursorPosition += Vector2(x: 1, y: 0)
            case .Up:
                cursorPosition += Vector2(x: 0, y: -1)
            case .Down:
                cursorPosition += Vector2(x: 0, y: 1)
            default:
                switch key {
                case .Quit:
                    quit(clear: true)
                case .Start:
                    start = cursorPosition
                case .Finish:
                    goal = cursorPosition
                case .Wall:
                    if cursorPosition != goal && cursorPosition != start {
                        grid[cursorPosition.y][cursorPosition.x] = grid[cursorPosition.y][cursorPosition.x] == 1 ? 0 : 1
                    }
                case .NW:
                    aStar.directions[0] = !aStar.directions[0]
                case .N:
                    aStar.directions[1] = !aStar.directions[1]
                case .NE:
                    aStar.directions[2] = !aStar.directions[2]
                case .W:
                    aStar.directions[3] = !aStar.directions[3]
                case .E:
                    aStar.directions[4] = !aStar.directions[4]
                case .SW:
                    aStar.directions[5] = !aStar.directions[5]
                case .S:
                    aStar.directions[6] = !aStar.directions[6]
                case .SE:
                    aStar.directions[7] = !aStar.directions[7]
                default:
                    break
                }

                path = aStar.pathfind(grid: grid, start: start, goal: goal)
                continue
            }

            if cursorPosition.x < 0 { cursorPosition.x = 0 }
            if cursorPosition.y < 0 { cursorPosition.y = 0 }
            if cursorPosition.x > grid[0].count - 1 { cursorPosition.x = grid[0].count - 1 }
            if cursorPosition.y > grid.count - 1 { cursorPosition.y = grid.count - 1 }
        }
    }

    var directions: [Bool] = Array(repeating: true, count: 8)

    // The main algorithm function
    func pathfind(grid: [[Int]], start: Vector2, goal: Vector2) -> [Vector2] {
        // For keeping track of yet-unexplored relevant nodes
        var openSet: [Vector2] = [start]

        // For keeping track of all the nodes previously traversed to reconstruct the optimal path
        var cameFrom: Dictionary<Vector2, Vector2> = [:]
        
        // A map keeping track of the G-score (actual cost from start to a given node) for every node on the grid
        var gScore: Dictionary<Vector2, Float> = [:]
        gScore[start] = 0

        // A map keeping track of the F-score (estimated cost from any given node to the goal, composed of the actual score from the start to the node and the estimated score from there to the goal) for every node on the grid
        var fScore: Dictionary<Vector2, Float> = [:]
        fScore[start] = h(current: start, goal: goal)

        // Loop until all relevant nodes have been explored [O(width * height) worst-case]
        while openSet.count != 0 {
            // Get the next relevant node with the lowest F-score (preditced total cost) [O(width * height) worst-case]
            var current: Vector2 = getLowest(openSet, map: fScore)

            // If this node is the goal...
            if current == goal {
                // ...reconstruct the path taken by going back through the nodes previously chosen and reversing, returning the resulting path
                var totalPath: [Vector2] = [current]
                while cameFrom.keys.contains(current) {
                    current = cameFrom[current]!
                    totalPath.append(current)
                }
                totalPath.reverse()
                return totalPath
            }

            // Otherwise, remove the current node from the set of unexplored nodes
            openSet.remove(at: openSet.firstIndex(of: current)!)

            // Since A* technically works on graphs, not grids, we construct all the "edges" that need checking
            let neighbors: [Vector2] = [
                Vector2(x: current.x - 1, y: current.y - 1),
                Vector2(x: current.x, y: current.y - 1),
                Vector2(x: current.x + 1, y: current.y - 1),

                Vector2(x: current.x - 1, y: current.y),
                Vector2(x: current.x + 1, y: current.y),

                Vector2(x: current.x - 1, y: current.y + 1),
                Vector2(x: current.x, y: current.y + 1),
                Vector2(x: current.x + 1, y: current.y + 1),
            ]

            // Loop through each of these neighbors...
            for i: Int in 0..<neighbors.count {
                // ...remove it if that direction is turned off...
                if !directions[i] { 
                    continue
                }
                // ...ignore it if it's outside the bounds of the grid...
                let neighbor: Vector2 = neighbors[i]
                if neighbor.x >= grid[0].count || neighbor.x < 0 || neighbor.y >= grid.count || neighbor.y < 0 {
                    continue
                }

                // ...disregard it if it's a wall (represented by a 1)...
                if grid[neighbor.y][neighbor.x] == 1 {
                    continue
                }

                // ...and calculate it's G-score (true score it took to get to the current node, plus the actual weight of the edge from current to neighbor)
                let tentative_gScore: Float = gScore[current]! + d(current: current, neighbor: neighbor)

                // If this G-score sets a new record for this node (meaning it's on a lower scoring, more optimal path), update all the maps to reflect this discovery
                if tentative_gScore < gScore[neighbor, default: Float.infinity] {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentative_gScore
                    fScore[neighbor] = tentative_gScore + h(current: neighbor, goal: goal)
                    // Worst-case O(width * height) lookup
                    if !openSet.contains(neighbor) {
                        openSet.append(neighbor)
                    }
                }
            }
        }

        // If the goal was never found, return a "path" with just the start and goal, which indicates to the rest of the program that a non-trivial path was not found
        return [start, goal]
    }

    // The heuristic function (which has to NEVER overestimate the real cost, otherwise A* may traverse a nonoptimal path); here using octile distance, where the goal must be reached by traversing nodes and taking a diagonal path involves a cost of sqrt(2)
    func h(current: Vector2, goal: Vector2) -> Float {
        let x = Float(abs(current.x - goal.x))
        let y = Float(abs(current.y - goal.y))
        return abs(x - y) + 1.4142 * min(x, y)
    }

    // The true weight of the edge from current to neighbor (just it's distance on the cartesian plane)
    func d(current: Vector2, neighbor: Vector2) -> Float {
        if current.x == neighbor.x || current.y == neighbor.y {
            return 1
        }
        return 1.4142
    }

    // A naive algorithm to get the node with the lowest value in the map [O(map.keys.count) worst-case]
    func getLowest(_ set: [Vector2], map: Dictionary<Vector2, Float>) -> Vector2 {
        var tentativeLowest = set[0]
        for item in set {
            if map[item]! < map[tentativeLowest]! {
                tentativeLowest = item
            }
        }
        return tentativeLowest
    }

    func display(_ path: [Vector2], on: [[Int]], cursorPosition: Vector2 = Vector2(x: -1, y: -1)) {
        let draw: Dictionary<String, String> = [
            "nw": "┏",
            "ne": "┓",
            "sw": "┗",
            "se": "┛",
            "n": "━",
            "e": "┃",
            "s": "━",
            "w": "┃",
            "start": "S",
            "goal": "F",
            "path": "*",
            "empty": "·",
            "wall": "▓",
            "clear": "\u{1B}[2J",
            "clearLine": "\u{1B}[2K",
            "home": "\u{1B}[H",
            "hide": "\u{1B}[?25l",
            "show": "\u{1B}[?25h",
        ]

        var output: String = ""
        output += draw["nw"] ?? "?"
        output += String(repeating: draw["n"] ?? "?", count: on[0].count + 2)
        output += draw["ne"] ?? "?"
        output += "\n"

        for y: Int in 0..<on.count {
            output += "\(draw["w"] ?? "?") "
            for x: Int in 0..<on[0].count {
                output += cursorPosition == Vector2(x: x, y: y) ? "\u{1B}[7m" : "\u{1B}[27m"
                let position: Vector2 = Vector2(x: x, y: y)
                if position == path.first {
                    output += "\(Color.Yellow)\(draw["start"] ?? "?")\(Color.Default)"
                    continue
                }
                if position == path.last {
                    output += "\(Color.Cyan)\(draw["goal"] ?? "?")\(Color.Default)"
                    continue
                }
                if path.contains(position) {
                    let nodeIndex: Int = path.firstIndex(of: position) ?? 0
                    let positionAfter = path[nodeIndex + 1]
                    let deltaX = positionAfter.x - position.x
                    let deltaY = positionAfter.y - position.y
                    var arrow = ""
                    switch (deltaX, deltaY) {
                    case (-1, -1):
                        arrow = "↖"
                    case (0, -1):
                        arrow = "↑"
                    case (1, -1):
                        arrow = "↗"
                    case (-1, 0):
                        arrow = "←"

                    case (1, 0):
                        arrow = "→"
                    case (-1, 1):
                        arrow = "↙"
                    case (0, 1):
                        arrow = "↓"
                    case (1, 1):
                        arrow = "↘"
                    default:
                        arrow = "?"
                    }
                    output += "\(Color.Green)\(arrow)\(Color.Default)"
                    continue
                }
                output += on[y][x] == 1 ? draw["wall"] ?? "?" : draw["empty"] ?? "?"
            }
            output += "\u{1B}[27m"
            output += " \(draw["e"] ?? "?")"
            output += "\n"
        }

        output += draw["sw"] ?? "?"
        output += String(repeating: draw["s"] ?? "?", count: on[0].count + 2)
        output += draw["se"] ?? "?"

        output += "\n\n"

        output += draw["nw"] ?? "?"
        output += String(repeating: draw["n"] ?? "?", count: 7)
        output += draw["ne"] ?? "?"
        output += "\n\(draw["w"] ?? "?")"
        output += directions[0] ? " ↖" : "  "
        output += directions[1] ? " ↑" : "  "
        output += directions[2] ? " ↗" : "  "
        output += " \(draw["e"] ?? "?") Path length: \(path.count <= 2 ? "\(Color.Red)Not found\(Color.Default)" : "\(Color.Green)\(String(path.count - 1))\(Color.Default)")\n\(draw["w"] ?? "?")"
        output += directions[3] ? " ←" : "  "
        output += "  "
        output += directions[4] ? " →" : "  "
        output += " \(draw["e"] ?? "?")\n\(draw["w"] ?? "?")"
        output += directions[5] ? " ↙" : "  "
        output += directions[6] ? " ↓" : "  "
        output += directions[7] ? " ↘" : "  "
        output += " \(draw["e"] ?? "?") Press [Q] to quit\n"
        output += draw["sw"] ?? "?"
        output += String(repeating: draw["s"] ?? "?", count: 7)
        output += draw["se"] ?? "?"

        print(draw["clear"] ?? "?", terminator: "")
        print(draw["home"] ?? "?", terminator: "")
        print(output)
    }

    static func parseInitfile(_ initfilePath: String, grid: inout [[Int]], start: inout Vector2, goal: inout Vector2) {
        if initfilePath != "-" {
            do {
                let fileURL = URL(fileURLWithPath: initfilePath)
                let text = try String(contentsOf: fileURL, encoding: .utf8)

                var starts = 0
                var goals = 0

                grid = text.split(whereSeparator: \.isNewline).enumerated().map({ y, line in
                    return line.enumerated().map({ x, char in 
                        if char == "S" {
                            starts += 1
                            start = Vector2(x: x, y: y)
                        }
                        else if char == "F" {
                            goals += 1
                            goal = Vector2(x: x, y: y)
                        }
                        return char == "#" ? 1 : 0
                    })
                })

                if starts == 0 {
                    throw InitfileError.missingStart
                } else if goals == 0 {
                    throw InitfileError.missingGoal
                }

                if starts != 1 {
                    throw InitfileError.multipleStarts
                } else if goals != 1 {
                    throw InitfileError.multipleGoals
                }

                if grid.count == 0 || grid[0].count == 0 { throw InitfileError.emptyFile }
                for row in grid {
                    if row.count != grid[0].count {
                        throw InitfileError.unevenRowLengths
                    }
                }

                return
            } catch InitfileError.missingStart {
                print("No start symbol \"S\" found in initfile.\nPress enter to continue...")
                _ = readLine()
            } catch InitfileError.missingGoal {
                print("No goal symbol \"F\" found in initfile.\nPress enter to continue...")
                _ = readLine()
            } catch InitfileError.multipleStarts {
                print("Multiple start symbols (\"S\") found in initfile.\nPress enter to continue...")
                _ = readLine()
            } catch InitfileError.multipleGoals {
                print("Multiple goal symbols (\"F\") found in initfile.\nPress enter to continue...")
                _ = readLine()
            } catch InitfileError.emptyFile {
                print("Initfile is empty.\nPress enter to continue...")
                _ = readLine()
            } catch InitfileError.unevenRowLengths {
                print("Uneven row lengths in initfile.\nPress enter to continue...")
                _ = readLine()
            } catch {
                print("Error processing initfile.\nPress enter to continue...")
                _ = readLine()
            }
        }

        // Clear screen and go home
        print("\u{1B}[2J", terminator: "")
        print("\u{1B}[H", terminator: "")

        // From https://patorjk.com/software/taag
        print(#"""
 $$$$$$\                  $$$$$$\                            $$\ $$\                           
$$  __$$\  $$\$$\        $$  __$$\                           $$ |$$ |                          
$$ /  $$ | \$$$  |       $$ /  \__| $$$$$$\  $$$$$$$\   $$$$$$$ |$$$$$$$\   $$$$$$\  $$\   $$\ 
$$$$$$$$ |$$$$$$$\       \$$$$$$\   \____$$\ $$  __$$\ $$  __$$ |$$  __$$\ $$  __$$\ \$$\ $$  |
$$  __$$ |\_$$$ __|       \____$$\  $$$$$$$ |$$ |  $$ |$$ /  $$ |$$ |  $$ |$$ /  $$ | \$$$$  / 
$$ |  $$ | $$ $$\        $$\   $$ |$$  __$$ |$$ |  $$ |$$ |  $$ |$$ |  $$ |$$ |  $$ | $$  $$<  
$$ |  $$ | \__\__|       \$$$$$$  |\$$$$$$$ |$$ |  $$ |\$$$$$$$ |$$$$$$$  |\$$$$$$  |$$  /\$$\ 
\__|  \__|                \______/  \_______|\__|  \__| \_______|\_______/  \______/ \__/  \__|

Welcome to the A* Sandbox, an interactive terminal-based visualizer for the A* graph traversal
algorithm. You can enter a width and height for the grid, then use the following controls to
experiment with the algorithm. The optimal path will refresh every time you make a change to
the grid.

Controls:
- Cursor movement: WASD, HJKL, or Arrow Keys
- Place wall: Space
- Place start: [
- Place goal: ]
- Restrict valid movement options: number keys (directions based on number pad)

"""#)
        print("Enter the grid width: ", terminator: "")
        let width: Int = Int(readLine() ?? "") ?? 16
        print("Enter the grid height: ", terminator: "")
        let height: Int = Int(readLine() ?? "") ?? 8

        grid = Array(repeating: Array(repeating: 0, count: width), count: height)
        start = Vector2(x: 0, y: 0)
        goal = Vector2(x: width - 1, y: 0)
    }

    static func noUI(_ path: String) {
        do {
            let fileURL = URL(fileURLWithPath: path)
            let text = try String(contentsOf: fileURL, encoding: .utf8)

            var start: Vector2 = Vector2(x: 0, y: 0)
            var goal: Vector2 = Vector2(x: 0, y: 0)

            let grid = text.split(whereSeparator: \.isNewline).enumerated().map({ y, line in
                return line.enumerated().map({ x, char in 
                    if char == "S" { start = Vector2(x: x, y: y) }
                    else if char == "F" { goal = Vector2(x: x, y: y) }
                    return char == "#" ? 1 : 0
                })
            })

            let aStar = A_Star()

            let path = aStar.pathfind(grid: grid, start: start, goal: goal)
            aStar.display(path, on: grid)
        } catch {
            print("Error processing input file.")
        }
    }

    static func clamp(_ value: Int, low: Int, high: Int) -> Int {
        if value < low {
            return low
        }
        if value > high {
            return high
        }
        return value
    }
}

enum Key {
    case Up
    case Down
    case Left
    case Right
    case Wall
    case Start
    case Finish

    case NW
    case N
    case NE
    case E
    case SE
    case S
    case SW
    case W

    case Quit
    case Unknown
}

struct Terminal {
#if os(macOS) || os(Linux)
    nonisolated(unsafe) static var originalTerm = termios()
#endif

    static func readKey() -> Key {
        var byte: UInt8 = 0
#if os(Windows)
        let ch = _getch()
        if ch == 224 || ch == 0 {
            let nextCh = _getch()
            switch nextCh {
            case 72: return .Up
            case 80: return .Down
            case 75: return .Left
            case 77: return .Right
            default: return .Unknown
            }
        }
        byte = UInt8(ch)
#else
        read(STDIN_FILENO, &byte, 1)

        if byte == 27 {
            var seq1: UInt8 = 0
            var seq2: UInt8 = 0

            read(STDIN_FILENO, &seq1, 1)
            read(STDIN_FILENO, &seq2, 1)

            if seq1 == 91 {
                switch seq2 {
                case 65: return .Up
                case 66: return .Down
                case 67: return .Right
                case 68: return .Left
                default: return .Unknown
                }
            }
        }
#endif
        let character = String(UnicodeScalar(byte))
        switch character {
        case "w":
            return .Up
        case "k":
            return .Up
        case "a":
            return .Left
        case "h":
            return .Left
        case "s":
            return .Down
        case "j":
            return .Down
        case "d":
            return .Right
        case "l":
            return .Right
        case " ":
            return .Wall
        case "[":
            return .Start
        case "]":
            return .Finish
        case "7":
            return .NW
        case "8":
            return .N
        case "9":
            return .NE
        case "4":
            return .W
        case "6":
            return .E
        case "1":
            return .SW
        case "2":
            return .S
        case "3":
            return .SE
        case "q":
            return .Quit
        default:
            return .Unknown
        }
    }

    static func enableRawMode() {
#if os(macOS) || os(Linux)
        tcgetattr(STDIN_FILENO, &originalTerm)

        var rawTerm = originalTerm
        rawTerm.c_lflag &= ~tcflag_t(ICANON | ECHO)
        tcsetattr(STDIN_FILENO, TCSANOW, &rawTerm)

        signal(SIGINT, quitHandler)
#endif
    }

    static func disableRawMode() {
#if os(macOS) || os(Linux)
        tcsetattr(STDIN_FILENO, TCSANOW, &originalTerm)
#endif
    }
}

func quitHandler(_ signal: Int32) {
    quit(clear: true)
}

func quit(clear: Bool = true) {
    Terminal.disableRawMode()

    // Show cursor
    print("\u{1B}[?25h", terminator: "")

    // Clear + return home
    if clear {
        print("\u{1B}[2J", terminator: "")
        print("\u{1B}[H", terminator: "")
    }
    exit(0)
}

struct Vector2: Hashable {
    var x: Int
    var y: Int

    static func == (lhs: Vector2, rhs: Vector2) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    static func += (lhs: inout Vector2, rhs: Vector2) {
        lhs = Vector2(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}

struct Color {
    static let Black = "\u{1B}[90m"
    static let Red = "\u{1B}[91m"
    static let Green = "\u{1B}[92m"
    static let Yellow = "\u{1B}[93m"
    static let Blue = "\u{1B}[94m"
    static let Magenta = "\u{1B}[95m"
    static let Cyan = "\u{1B}[96m"
    static let White = "\u{1B}[97m"
    static let Default = "\u{1B}[39m"
}

enum InitfileError: Error {
    case emptyFile
    case missingStart
    case missingGoal
    case multipleStarts
    case multipleGoals
    case unevenRowLengths
}


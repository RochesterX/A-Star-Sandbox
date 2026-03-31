@main
struct A_Star {
    static func main() {
        print("Hello, world!")
    }

    func A_Star(start: Vector2, goal: Vector2) {
        var openSet: [Vector2] = [start]

        var cameFrom: Dictionary<Vector2, Vector2> = [:]
        
        var gScore: Dictionary<Vector2, Int> = [:]
        gScore[start] = 0

        var fScore: Dictionary<Vector2, Int> = [:]
        fScore[start] = h(start)

        while openSet.count != 0 {
            var current: Vector2 = getLowest(openSet)
        }
    }

    func h(_: Vector2) -> Int {
        return 0
    }

    func getLowest(_: [Vector2]) -> Vector2 {
        for 
    }
}

struct Vector2: Hashable {
    var x: Int
    var y: Int

    static func == (lhs: Vector2, rhs: Vector2) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}


import struct
import sys


def read_knn_graph(filename, num_points, k):
    graph = []
    with open(filename, 'rb') as f:
        for i in range(num_points):
            neighbors = []
            for j in range(k):
                distance, label = struct.unpack('fi', f.read(8))  # float + int
                neighbors.append(label)
            graph.append(neighbors)
    return graph


def dump_graph_txt(graph, filename):
    with open(filename, 'w') as f:
        for i, neighbors in enumerate(graph):
            f.write(f"node {i}: {' '.join(map(str, neighbors))}\n")


def compare_graphs(g1, g2):
    assert len(g1) == len(g2), "Graphs have different number of nodes"
    total = len(g1)
    equal = 0
    for i in range(total):
        if set(g1[i]) == set(g2[i]):
            equal += 1
        else:
            print(f"Node {i} differs:")
            print(f"Graph1: {g1[i]}")
            print(f"Graph2: {g2[i]}")
    print(f"\nSummary: {equal}/{total} nodes have the same neighbors.")


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python compare_knngraph.py graph0.kgraph graph1.kgraph num_points k")
        exit(1)

    file0 = sys.argv[1]
    file1 = sys.argv[2]
    num_points = int(sys.argv[3])
    k = int(sys.argv[4])

    g1 = read_knn_graph(file0, num_points, k)
    g2 = read_knn_graph(file1, num_points, k)

    dump_graph_txt(g1, 'graph0.txt')
    dump_graph_txt(g2, 'graph1.txt')

    print("TXT dumped as graph0.txt and graph1.txt")
    print("Comparing...")
    compare_graphs(g1, g2)

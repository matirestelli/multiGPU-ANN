import sys

def load_knn_txt(filename):
    knn = []
    with open(filename, 'r') as f:
        for line in f:
            numbers = list(map(int, line.strip().split()))
            neighbors = set(numbers[1:])  # skip the first number (usually k)
            knn.append(neighbors)
    return knn

def jaccard_distance(set1, set2):
    intersection = len(set1 & set2)
    union = len(set1 | set2)
    return 1 - intersection / union if union > 0 else 0.0

if len(sys.argv) != 3:
    print("Usage: python3 compare_knn.py <file1.txt> <file2.txt>")
    sys.exit(1)

file1, file2 = sys.argv[1], sys.argv[2]
print(f" Comparing:\n  File 1: {file1}\n  File 2: {file2}")

knn1 = load_knn_txt(file1)
knn2 = load_knn_txt(file2)

if len(knn1) != len(knn2):
    print("ERROR: The files have a different number of lines (points)!")
    sys.exit(1)

same = 0
different = 0
diff_ids = []
total_jaccard = 0.0
total_common_neighbors = 0
k = len(knn1[0])  # assume fixed size

per_point_reports = []

for i in range(len(knn1)):
    common = knn1[i] & knn2[i]
    common_count = len(common)

    total_common_neighbors += common_count
    total_jaccard += jaccard_distance(knn1[i], knn2[i])

    if knn1[i] == knn2[i]:
        same += 1
    else:
        different += 1
        diff_ids.append(i)
        per_point_reports.append(
            f"Point {i} differs:\n"
            f"  File1: {sorted(knn1[i])}\n"
            f"  File2: {sorted(knn2[i])}\n"
            f"  Common neighbors: {common_count} / {k}\n"
        )

avg_jaccard = total_jaccard / len(knn1)
avg_common = total_common_neighbors / len(knn1)

# Write report
with open("comparison_report_please.txt", 'w') as report:
    report.write("===== KNN COMPARISON SUMMARY =====\n")
    report.write(f"DIFFERENT POINTS: {different} out of {len(knn1)}\n")
    report.write("Different Point IDs: " + ', '.join(map(str, diff_ids)) + "\n")
    report.write(f"Average Jaccard Distance: {avg_jaccard:.4f}\n")
    report.write(f"Average Common Neighbors: {avg_common:.2f} / {k}\n")
    report.write("\n===== DETAILED DIFFERENCES =====\n")
    report.writelines(per_point_reports)

# Console summary
print("Comparison complete!")
print(f"Same: {same}")
print(f"Different: {different}")
print(f"Average Jaccard Distance: {avg_jaccard:.4f}")
print(f"Average Common Neighbors: {avg_common:.2f} / {k}")
print("See 'comparison_report.txt' for details.")

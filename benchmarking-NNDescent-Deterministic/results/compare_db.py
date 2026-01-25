import sys

if len(sys.argv) != 3:
    print("Usage: python3 compare_vectors.py <file1.txt> <file2.txt>")
    sys.exit(1)

file1 = sys.argv[1]
file2 = sys.argv[2]

print(f"Comparing files:\n  File 1: {file1}\n  File 2: {file2}")

with open(file1, 'r') as f1, open(file2, 'r') as f2:
    lines1 = [line.strip() for line in f1.readlines()]
    lines2 = [line.strip() for line in f2.readlines()]

if len(lines1) != len(lines2):
    print("ERROR: The files have a different number of lines!")
    sys.exit(1)

different = 0
diff_ids = []

with open("compare_vectors_report.txt", 'w') as report:
    for i, (l1, l2) in enumerate(zip(lines1, lines2)):
        if l1 != l2:
            different += 1
            diff_ids.append(i)
            report.write(f"Line {i} differs:\n")
            report.write(f"File1: {l1}\n")
            report.write(f"File2: {l2}\n\n")

    summary = f"DIFFERENT LINES: {different} out of {len(lines1)}\n"
    summary += "Different Line IDs: " + ', '.join(map(str, diff_ids)) + "\n"
    report.write(summary)

print("Comparison complete!")
print(f"Different Lines: {different} out of {len(lines1)}")
print("See 'compare_vectors_report.txt' for details.")

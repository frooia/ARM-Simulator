cd tests1000
for f in input_*.txt; do
	./../ARMsim $f
	diff -w -B disassembly.txt disassembly-$f.txt
	diff -w -B simulation.txt simulation-$f.txt
done

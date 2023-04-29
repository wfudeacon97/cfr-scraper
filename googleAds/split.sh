grep "far/FAR-" indexed.txt > removals.txt
grep "/FAR-i" indexed.txt | grep -v  "far/FAR-" >> removals.txt

grep -v "https://openthefar.com/far/FAR" indexed.txt | grep -v "far/FAR-" | grep -v "/FAR-i" > valid.txt

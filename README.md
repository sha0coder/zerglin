# Zergling GA


This PoC geneates perl code that sovle a dataset, generaging the proper output for the given inputs.
So act like a neural network, but instead generating a model generates a working perl code.


## Usage
perl zergling.pl dataset_sum.csv 2>/dev/null

perl zergling.pl dataset_xor.csv 2>/dev/null

## TODO
- for now it gets 2 inputs and 1 output, adaptive architecture.


## Output
```bash
** Generation 28  population size 100 error 6
E0,B1,E0
$a+=$a;

** Generation 29  population size 100 error 0
E0,B1,E1
$a+=$b;

________________________________________________________
Executed in  248.52 millis    fish           external 
   usr time  240.61 millis  234.00 micros  240.38 millis 
   sys time    7.96 millis   77.00 micros    7.88 millis 

```


Example of how the code evolves:
```bash
** Generation 70  population size 100 error 9
9 E0,B3,D4-E4,B1,E3,A0,E5-E5,B5,E4-E2,B0,E8,A6,E1-E1,B0,E9,A5,E1-E4,B6,E3
$a*=4;$e+=$d+$f;$f**=$e;$c=$i**$b;$b=$j^$b;$e%=$d;

** Generation 71  population size 100 error 9
9 E0,B3,D4-E4,B1,E3,A0,E5-E5,B6,E4-E2,B0,E1,A6,E0-E4,B0,E9,A5,E1-E9,B6,E8
$a*=4;$e+=$d+$f;$f%=$e;$c=$b**$a;$e=$j^$b;$j%=$i;

** Generation 72  population size 100 error 4
4 E0,B1,E0,A2,E1
$a+=$a*$b;

** Generation 73  population size 100 error 4
4 E0,B1,E0,A2,E1
$a+=$a*$b;

** Generation 74  population size 100 error 4
4 E0,B1,E0,A2,E1
$a+=$a*$b;

** Generation 75  population size 100 error 4
4 E0,B1,E0,A2,E1
$a+=$a*$b;

** Generation 76  population size 100 error 0
0 E0,B0,E0,A2,E1
$a=$a*$b;

Optimized result:
E0,B0,E0,A2,E1
$a=$a*$b;

```




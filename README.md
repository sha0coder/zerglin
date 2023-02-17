# Zerglin GA


This PoC geneates perl code that sovle a dataset, generaging the proper output for thegibven inputs.
So act like a neural network, but instead generating a model generates a working perl code.



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

## Usage
perl zerglin.pl dataset.csv 2>/dev/null

## TODO
- For now it gets 2 inputs and 1 output, adaptive architecture.

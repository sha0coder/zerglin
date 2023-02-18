use List::Util qw(shuffle);
use Data::Dumper;
use POSIX;


@dataset = load_dataset($ARGV[0]);
$max_generations = 1000000;
$population_size = 100;
$mutation_prob = 20; # 1 very 20 gens
$extension_prob = 100;
$compression_prob = 200;
$debug_crossover = 0;
$debug_population = 0;
$debug_validation = 0;

%gram = (
    'A' => [
        '+',
        '-',
        '*',
        '/',
        '%',
        '^',
        '**',
    ],

    'B' => [
        '=',
        '+=',
        '-=',
        '*=',
        '/=',
        '**=',
        '%=',
        '^=',
    ],

    'C' => [
        '==',
        '<',
        '>',
        '<=',
        '>=',
    ],

    'D' => [split(//,'0123456789')],
    'E' => [map {'$'.$_} split(//,'abcdefghij')],
);


@gram_combos = (
    ["E","B","D"], # $a += 1
    ["E","B","E"], # $a += b
    ["E","B","E","A","E"] # $a = $b + $c
);

sub load_dataset {
    my ($dataset) = @_;
    my @data=();

    open(IN, $dataset);
    foreach $l (<IN>) {
        chop($l);
        @fields = split(/,/, $l);
        push(@data, [@fields]);
    }
    close(IN);
    return @data;
}


sub parse_genome {
    my @genomes = split(/-/, shift);
    my $code = '';

    foreach $genome (@genomes) {
        my @gens = split(/,/, $genome);

        foreach $gen (@gens) {
            my @g = split(//, $gen); 
            if ($g[0] eq 'F') {
                $code .= ' if('.$gram{'E'}->[int($g[1])].$gram{'C'}->[int($g[2])].$gram{'E'}->[int($g[3])].')';
            } else {
                $code .= $gram{$g[0]}->[int($g[1])];
            }
        }
        $code .= ';';
    }

    return $code;
}


sub create_random_gen {
    my @pos = ('A'..'E');
    my $g = @pos[rand(@pos)];
    my $l = scalar(@{$gram{$g}});
    my $n = int(rand($l));
    return "$g$n";
}

sub create_random_if {
    my $g = 'F';
    my $a = scalar(@{$gram{'C'}});
    my $b = scalar(@{$gram{'E'}});
    my $n1=int(rand($a));
    my $n2=int(rand($b));
    my $n3=int(rand($a));
    return "F$n1$n2$n3";
}

sub create_random_genome {
    my $genome = '';
    my ($a,$b,$c,$d,$e);
    
    @combo = @{$gram_combos[int(rand(@gram_combos))]};
    foreach $c (@combo) {
        $genome.=$c.int(rand(@{$gram{$c}}));
        $genome.=',';
    }
    chop($genome);

    if (int(rand(15))==1) {
        $genome.= ",".create_random_if();
    }

    return $genome;
}

sub create_random_genomes {
    my $genome = '';
    my $n = int(rand(8))+2;
    foreach (0..$n) {
        $genome.= create_random_genome()."-";
    }
    chop $genome;
    return $genome;
}

sub create_random_population {
    @population = ();
    foreach (0..$population_size) {
        push(@population, create_random_genomes());
    }
    return @population;
}

sub print_population {
    my @population = @_;
    foreach $ind (@population) {
        $code = parse_genome($ind);
        print "$ind $code\n"; 
    }
}

sub evaluate_individual {
    my ($genome) = @_;
    my $err = 0;

    foreach my $j_index (0..$#dataset) {
        my $a=$dataset[$j_index][0];
        my $b=$dataset[$j_index][1];
        my $expected_output=$dataset[$j_index][2];
        if ($expected_output eq "") {
            last;
        }

        $code = parse_genome($genome);
        $code =~ s/<>//g;
        eval($code);
        if ($@) {
            $err += 100_000;
        } else {
            if (not $a==$a || !$a) {
                $err += 10_000;
            } else {
                $err += abs($expected_output-int($a));
            }
        }
    }

    return $err;
}

sub evaluate_population {
    my @population = @_;
    my @scored_popu = ();
    my ($a,$b);

    foreach $i_index (0..$#population) {
        my $err = evaluate_individual($population[$i_index]);
        push(@scored_popu, [$err, $population[$i_index]]) if ($population[$i_index]);
    }

    foreach $i (0..$#scored_popu-1) {
        foreach $j ($i+1..$#scored_popu) {
            if ($scored_popu[$i][0] > $scored_popu[$j][0]) {
                $tmps = $scored_popu[$i][0];
                $tmpv = $scored_popu[$i][1];
                $scored_popu[$i][0] = $scored_popu[$j][0];
                $scored_popu[$i][1] = $scored_popu[$j][1];
                $scored_popu[$j][0] = $tmps;
                $scored_popu[$j][1] = $tmpv; 
            }
        }
    }

    return @scored_popu;
}

sub get_topten {
    my @sorted_popu = @_;
    my @topten = ();
    foreach $i (0..9) {
        push(@topten, $sorted_popu[$i]);
    }
    return @topten;
}

# deprecated
sub do_crossover_raw {
    my @topten = @_;
    my @new_generation = ();

    foreach $i (0..9) {
        $j=$i;
        while ($i == $j) {
            $j=int(rand(10));
        }
        $father = $topten[$i][1];
        $mother = $topten[$j][1];
        $middle_father = int(length($father)/2);
        $middle_mother = int(length($mother)/2);

        $child1 = substr($father,0,$middle_father).substr($mother,$middle_mother,length($mother)-$middle_mother);
        $child2 = substr($mother,0,$middle_mother).substr($father,$middle_father,length($father)-$middle_father);
        print("father: $father  mother: $mother\n  child1: $child1 child2: $child2\n") if ($debug_crossover);
        push(@new_generation, $child1);
        push(@new_generation, $child2);
    }

    return @new_generation;
}

sub do_crossover {
    my @topten = @_;
    my @new_generation = ();

    foreach $i (0..5) {
        $j=$i;
        while ($i == $j) {
            $j=int(rand(5)+5);
        }
        @father = split(/-/, $topten[$i][1]);
        @mother = split(/-/, $topten[$j][1]);
        $child1 = '';
        $child2 = '';
        $child3 = '';
        $child4 = '';
        foreach $i (0..$#father) {
            if ($i % 2 == 0) {
                $child1 .= $father[$i];
                $child2 .= $mother[$i] if (i<=$#mother);
            } else {
                $child1 .= $mother[$i] if (i<=$#mother);
                $child2 .= $father[$i];
            }
            if ($i % 4 == 0) {
                $child3 .= $father[$i];
                $child4 .= $mother[$i] if (i<=$#mother);
            } else {
                $child3 .= $mother[$i] if (i<=$#mother);
                $child4 .= $father[$i];
            }

            $child1.= "-";
            $child2.= "-";
            $child3.= "-";
            $child4.= "-";
        }
        chop($child1);
        chop($child2);
        chop($child3);
        chop($child4);

        push(@new_generation, mutate_individual($child1));
        push(@new_generation, mutate_individual($child2));
        push(@new_generation, mutate_individual($child3));
        push(@new_generation, mutate_individual($child4));
    }

    return @new_generation;
}

sub mutate_individual {
    my $individual = shift;
    my $mutated = '';

    #TODO: add the posibility not very likely to add and remove chunks.

    @genotypes = split(/-/, $individual);
    foreach $genotype (@genotypes) {
        @gens = split(/,/, $genotype);
        foreach $gen (@gens) {
            if (int(rand($mutation_prob)) == 1) {
                $l = substr($gen,0,1);
                $mutated.=$l.int(rand(@{$gram{$l}}));
            } else {
                $mutated.=$gen;
            }
            $mutated.=",";
        }
        chop($mutated);
        $mutated.="-";
        last if (int(rand($compression_prob)) == 0);
    }
    chop($mutated);

    if (int(rand($extension_prob)) == 0) {
        if (int(rand(2)) == 1) {
            $mutated.= '-'.create_random_gen();   
        } else {
            $mutated.= '-'.create_random_if();
        }
    }

    return $mutated;
}

sub optimize {
    my ($genotype) = @_;
    my $optimized = '';

    my @blocks = split /-/, $genotype;
    my @combo = ([shift @blocks]);
    foreach my $bloque (@blocks) {
        my @new_combo = ();
        foreach my $comb (@combo) {
            push @new_combo, [@{$comb}, $bloque];
        }
        push @combo, [$bloque], @new_combo;
    }

    @combo = sort { scalar(@$a) <=> scalar(@$b) } @combo;

    foreach my $comb (@combo) {
        my $genot = join "-", @$comb;
        $err = evaluate_individual($genot);
        return $genot if ($err == 0);
    }

    return $genotype;
}

sub main {
    my @population = create_random_population();
    my @sorted_popu = ();

    foreach $gen (1..$max_generations) {

        @sorted_popu = evaluate_population(@population);

        if ($debug_population) {
            foreach $i (0..$#sorted_popu) {
                print($sorted_popu[$i][0]." ".$sorted_popu[$i][1]."  ".
                    parse_genome($sorted_popu[$i][1])."\n");
            }
        }

        @topten = get_topten(@sorted_popu);
        @new_generation = do_crossover(@topten);
        push(@new_generation, $topten[0][1]);

        foreach ($#new_generation..$population_size-6) {
            $i = int(rand($#sorted_popu));
            $diversity = $sorted_popu[$i][1];
            push(@new_generation, $diversity);
        }

        push(@new_generation, $sorted_popu[0][1]);
        push(@new_generation, mutate_individual($sorted_popu[0][1]));
        push(@new_generation, create_random_genome());
        push(@new_generation, create_random_genome());
        push(@new_generation, create_random_genome());

        #@population = shuffle(@new_generation);
        @population = @new_generation;
        $min_err = $topten[0][0];
        print("\n");
        print("** Generation $gen  population size $#population error $min_err\n");
        print($sorted_popu[0][0]." ".$sorted_popu[0][1]."\n");
        print(parse_genome($sorted_popu[0][1])."\n");
        #<>;
        last if ($min_err == 0);
    }

    $optimized = optimize($sorted_popu[0][1]);
    print("\nOptimized result:\n");
    print("$optimized\n".parse_genome($optimized)."\n");
}

main();



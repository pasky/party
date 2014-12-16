#!/usr/bin/perl
use warnings;
use strict;
use Term::ANSIColor;

no warnings;
my $space = [
# 	[ split '', qw/##############################################################################################/ ],
# 	[ split '', qw/#...###===###...#...............................#.....##.......##..##===#.....====...........#/ ],
# 	[ split '', qw/#..................##########################...##.##....##.##............###......###===##..#/ ],
# 	[ split '', qw/#...###...######.####.==.###.===.###.===.###.......##....##.##.....##...#.##########.######..#/ ],
# 	[ split '', qw/######.....#####.................................#....##.......##==##...#....................#/ ],
# 	[ split '', qw/##############################################################################################/ ],
	[ split '', qw/###########################################################################!!#################/ ],
	[ split '', qw/#........####....####....#####.....######............####....####....####.....####...##......#/ ],
	[ split '', qw/#..P.........................................................................................#/ ],
	[ split '', qw/#.........................................................................................P..#/ ],
	[ split '', qw/#........====....====....=%==.....=%==....=%%%....%%%=.......===%....====.....====...##......#/ ],
	[ split '', qw/##############!!##############################################################################/ ],
];
use warnings;
my $pspace = [];
my $hspace = @{$space};
my $wspace = @{$space->[0]};
my $nspace = [];

sub wall_at { my ($x, $y) = @_; return ($space->[$y]->[$x] eq '#' or $space->[$y]->[$x] eq '!'); }
sub free_at { my ($x, $y) = @_; return ($space->[$y]->[$x] ne '#' and $space->[$y]->[$x] ne '!' and $space->[$y]->[$x] ne 'P' and $space->[$y]->[$x] ne '%' and not defined $pspace->[$y]->[$x]); }

sub tile_direction {
	my ($cx, $cy, $tile, $name) = @_;
	# BFS in space
	my @bq = ([$cx, $cy]);
	my $sspace = [];
	$sspace->[$cy]->[$cx] = 1;
	while (@bq) {
		my $t = shift @bq;
		# print "seeking beer: @$t\n";
		if ($space->[$t->[1]]->[$t->[0]] eq $tile) {
			my $dx = $cx - $t->[0];
			my $dy = $cy - $t->[1];
			if (abs($dx) > abs($dy)) {
				return (-abs($dx)/$dx, 0);
			} else {
				return (0, -abs($dy)/$dy);
			}
		}
		for my $d ([-1, 0], [1, 0], [0, -1], [0, 1]) {
			my $t2 = [$t->[0] + $d->[0], $t->[1] + $d->[1]];
			next if $sspace->[$t2->[1]]->[$t2->[0]];
			next if wall_at(@$t2) and $space->[$t2->[1]]->[$t2->[0]] ne $tile;
			$sspace->[$t2->[1]]->[$t2->[0]] = 1;
			push(@bq, $t2);
		}
	}
	print "no $name :(\n";
	return (0, 0);
}

sub itoa {
	my ($i) = @_;
	my @a = split '', qw(0123456789abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqrstuvwxyz);
	return $a[$i];
}

sub printi {
	my $i = shift;
	print itoa($i) . " ($i): " . join(" ", @_) . "\n";
}

my $npeople = 36;
my @people;
for my $i (0..$npeople-1) {
	while (1) {
		$people[$i]->{x} = int rand($wspace);
		$people[$i]->{y} = int rand($hspace);
		print "x $i $people[$i]->{x}, $people[$i]->{y}\n";
		last if free_at($people[$i]->{x}, $people[$i]->{y});
	}
	$pspace->[$people[$i]->{y}]->[$people[$i]->{x}] = $i;
	$people[$i]->{state} = 'roaming';
	$people[$i]->{beers} = 0;
	$people[$i]->{popularity} = rand() * rand();
	for my $j (0..$#people) {
		next if $i == $j;
		if (rand() < 0.5 * $people[$i]->{popularity}) {
			$people[$i]->{knows}->[$j] = 1;
			$people[$j]->{knows}->[$i] = 1;
		}
	}
}
$people[0]->{popularity} = 1;

my @nomplaces;
my $nomcap = 4;
for my $y (0..$hspace-1) {
	for my $x (0..$wspace-1) {
		if ($space->[$y]->[$x] eq '%') {
			push @nomplaces, [$x, $y];
			$nspace->[$y]->[$x] = $nomcap;
		}
	}
}
my $nomcounter = 0;

while (1) {
	use Time::HiRes;
	Time::HiRes::usleep(100000);

	print "[H[2J";

	for my $y (0..$hspace-1) {
		for my $x (0..$wspace-1) {
			if (defined $pspace->[$y]->[$x]) {
				my $i = $pspace->[$y]->[$x];
				if ($i == 0) {
					print color("bright_white");
				} elsif ($people[$i]->{state} eq 'toilet') {
					print color("bright_yellow");
				} elsif ($people[$i]->{state} eq 'beer') {
					print color("bright_blue");
				} elsif ($people[$i]->{state} eq 'nom') {
					print color("bright_cyan");
				} elsif ($people[$i]->{popularity} > 0.5) {
					print color("red");
				} else {
					print color("green");
				}
				print itoa($pspace->[$y]->[$x]);
				print color("white");
			} else {
				print $space->[$y]->[$x];
			}
		}
		print "\n";
	}

	person: for my $i (0..$#people) {
		my ($dx, $dy);

		if ($people[$i]->{state} eq 'dead') {
			printi($i, "dead");
			next person;
		}

		if ($people[$i]->{state} eq 'beer') {
			if (rand() < 0.05) {
				$people[$i]->{state} = 'roaming';
				goto roaming;
			}
beer:
			for my $dy (-1, 0, 1) {
				for my $dx (-1, 0, 1) {
					if ($space->[$people[$i]->{y} + $dy][$people[$i]->{x} + $dx] eq 'P') {
						$people[$i]->{beers}++;
						$people[$i]->{state} = 'roaming';
						goto roaming;
					}
				}
			}
			($dx, $dy) = tile_direction($people[$i]->{x}, $people[$i]->{y}, 'P', 'beer');
			if (not free_at($people[$i]->{x} + $dx, $people[$i]->{y} + $dy)) {
				# Wait in queue.
				printi($i, "beer queue");
				next person;
			}

		} elsif ($people[$i]->{state} eq 'nom') {
			if (rand() < 0.05) {
				$people[$i]->{state} = 'roaming';
				goto roaming;
			}
nom:
			for my $dy (-1, 0, 1) {
				for my $dx (-1, 0, 1) {
					if ($space->[$people[$i]->{y} + $dy][$people[$i]->{x} + $dx] eq '%') {
						if (--$nspace->[$people[$i]->{y} + $dy][$people[$i]->{x} + $dx] <= 0) {
							$space->[$people[$i]->{y} + $dy][$people[$i]->{x} + $dx] = '-';
						}
						if (rand() < 0.25) {
							$people[$i]->{state} = 'beer';
							goto beer;
						}
						$people[$i]->{state} = 'roaming';
						goto roaming;
					}
				}
			}
			($dx, $dy) = tile_direction($people[$i]->{x}, $people[$i]->{y}, '%', 'nom');
			unless ($dx or $dy) {
				printi($i, "no nom");
				$people[$i]->{state} = 'roaming';
				goto roaming;
			}
			if (not free_at($people[$i]->{x} + $dx, $people[$i]->{y} + $dy)) {
				# Wait in queue.
				printi($i, "nom queue");
				next person;
			}

		} elsif ($people[$i]->{state} eq 'toilet') {
toilet:
			for my $dy (-1, 0, 1) {
				for my $dx (-1, 0, 1) {
					if ($space->[$people[$i]->{y} + $dy][$people[$i]->{x} + $dx] eq '!') {
						$people[$i]->{beers} -= 0.05;
						if ($people[$i]->{beers} <= 0) {
							$people[$i]->{state} = 'roaming';
							goto roaming_no_toilet;
						} else {
							printi($i, "relieving... " . $people[$i]->{beers});
							next person;
						}
					}
				}
			}
			$people[$i]->{beers} += 0.005;
			if ($people[$i]->{beers} > 5) {
				if (rand() < 0.01) {
					# OMG DIE!
					$people[$i]->{state} = 'dead';
					undef $pspace->[$people[$i]->{y}]->[$people[$i]->{x}];
					$space->[$people[$i]->{y}]->[$people[$i]->{x}] = '+';
					next person;
				} else {
					printi($i, "in deadly danger: " . $people[$i]->{beers});
				}
			}
			# if (rand() < 0.05) {
			# 	$people[$i]->{state} = 'roaming';
			# 	goto roaming_no_toilet;
			# }
			($dx, $dy) = tile_direction($people[$i]->{x}, $people[$i]->{y}, '!', 'toilet');
			my $y2 = $people[$i]->{y} + $dy;
			my $x2 = $people[$i]->{x} + $dx;
			if (not free_at($x2, $y2)) {
				# Wait in queue.
				my $j = $pspace->[$y2]->[$x2];
				if (rand() < (defined $j ? 0.75 : 0.3)) {
					# Flip to roaming for a little to stumble around.
					$people[$i]->{state} = 'roaming';
					goto roaming_no_toilet;
				} elsif (defined $j and $people[$i]->{beers} > 4 and rand() < 0.5) {
					# If it's a person in the way, swap positions if we are
					# already desperate.
					my $x = $people[$i]->{x};
					my $y = $people[$i]->{y};
					$people[$i]->{x} = $x2;
					$people[$i]->{y} = $y2;
					$people[$j]->{x} = $x;
					$people[$j]->{y} = $y;
					$pspace->[$y2]->[$x2] = $i;
					$pspace->[$y]->[$x] = $j;
				}
				printi($i, "toilet queue: " . $people[$i]->{beers});
				next person;
			}

		} elsif ($people[$i]->{state} eq 'roaming') {
			my $dog = $i == 0;
			if (not $dog and rand() < 0.01) {
				$people[$i]->{state} = 'beer';
				goto beer;
			}
			if (not $dog and rand() < 0.01) {
				$people[$i]->{state} = 'nom';
				goto nom;
			}
roaming:
			if (not $dog and $people[$i]->{beers} >= 3 and rand() < 0.8) {
				$people[$i]->{state} = 'toilet';
				goto toilet;
			}
roaming_no_toilet:
			for my $dy (-1, 0, 1) {
				for my $dx (-1, 0, 1) {
					my $j = $pspace->[$people[$i]->{y} + $dy]->[$people[$i]->{x} + $dx];
					if ((defined $j and $j == 0) or $i == 0) {
						# dog, stay!
						next person unless rand() < 0.01;
					} elsif (defined $j and $people[$i]->{knows}->[$j]) {
						# printi($i, " -- $j");
						next person unless rand() < 0.05;
					}
				}
			}

			$dx = $people[$i]->{dx}; $dx ||= (int rand(3)) - 1;
			$dy = $people[$i]->{dy}; $dy ||= (int rand(3)) - 1;
			if (not free_at($people[$i]->{x} + $dx, $people[$i]->{y} + $dy)) {
				$people[$i]->{dx} = 0; $people[$i]->{dy} = 0;
				# Wait in queue.
				# printi($i, "stuck");
				next person;
			}
=brm
			while (not free_at($people[$i]->{x} + $dx, $people[$i]->{y} + $dy)) {
				printi($i, "$dx $dy retargetting");
				$dx = (int rand(3)) - 1;
				$dy = (int rand(3)) - 1;
			}
=cut
		}

		undef $pspace->[$people[$i]->{y}]->[$people[$i]->{x}];
		$people[$i]->{x} += $dx; $people[$i]->{y} += $dy;
		$people[$i]->{dx} = $dx; $people[$i]->{dy} = $dy;
		$pspace->[$people[$i]->{y}]->[$people[$i]->{x}] = $i;
	}

	if ($nomcounter++ > 1000) {
		print "replenishing nom\n";
		$nomcounter = 0;
		for (@nomplaces) {
			$space->[$_->[1]][$_->[0]] = '%';
			$nspace->[$_->[1]]->[$_->[0]] = $nomcap;
		}
	}
}

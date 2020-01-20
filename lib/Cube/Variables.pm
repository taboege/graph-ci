use Modern::Perl;
use bignum;

package Cube::Variables;

# Construct a Cube::Variables object. This receives a hash which
# describes in some way the dimension of the cube. Using C<< dim => $n >>
# specifies the dimension directly. With C<< vars => $m >> one gives
# the dimension implicitly by the number C<$m> of 2-faces of the cube.
# Lastly, a ground set can be given as C<< set => [...] >>, where the
# value is an arrayref of single characters.
#
# Precedence is C<dim> > C<set> > C<vars>. Once the dimension is known,
# the other properties can be computed. Inconsistent settings, including
# when there is no $n such that the cube has $m 2-faces, are an error.
sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;

    my $n = $self->{dim} //= scalar(@{$self->{set}}) || _compute_dimension(
        $self->{vars} // die "at least one of dim, vars or set argument must be given"
    );
    $self->{vars} //= _compute_vars($n);

    # Generate a default set
    unless ($self->{set}) {
        # Do not go the extra mile to DWIM. If you supply the
        # set yourself, you can go higher than dim 9.
        die "dimension is too high to use 1..9" if $n > 9;
        $self->{set} = [map { "$_" } 1 .. $n];
    }
    $self->{set} = [sort @{$self->{set}}];

    for (@{$self->{set}}) {
        die "variables in set must stringify to length 1"
            unless length == 1;
    }

    die "vars and dim are inconsistent" unless $self->{vars} == _compute_vars($n);
    die "set and dim are inconsistent"  unless @{$self->{set}} == $n;

    # Build caches for all methods on this object right now.
    #
    # The autoritative numbering of variables requires the
    # following pattern:
    #   (12|), (12|3), (12|4), (12|5),
    #   (12|34), (12|35), (12|45),
    #   (12|345),
    #   (13|), (13|2), ...
    # which is a bit hard to get with the binary counter
    # implementation of subsets in Algorithm::Combinatorics.
    #
    # DANGER: If the implementation of subsets is changed,
    # this will suddenly produce wrong axioms!
    use Algorithm::Combinatorics qw(subsets);

    $self->{faces}   = \my @faces;
    $self->{names}   = \my @names;
    $self->{numbers} = \my %numbers;

    $faces[0] = $names[0] = "(NaV)";
    my $v = 1;
    for my $i (1 .. $n) {
        for my $j (($i+1) .. $n) {
            my @M = grep { $_ != $i and $_ != $j } 1 .. $n;
            for my $k (0 .. @M) {
                for my $L (subsets([@M], $k)) {
                    my $face = [$i,$j,sort @$L];
                    $faces[$v] = $face;
                    $names[$v] = "$i$j|" . join('', @$L);
                    $numbers{join '', @$face} = $v;
                    $v++;
                }
            }
        }
    }

    $self
}

# Solve $vars == ($n choose 2) * 2 ** ($n - 2).
sub _compute_dimension {
    my $vars = shift;
    my $n = 2;

    while (1) {
        my $nvars = _compute_vars($n);
        return $n if $nvars == $vars;
        last if $nvars > $vars;
        $n++;
    }
    die "don't know dimension of $vars variables";
}

sub _compute_vars {
    my $n = shift;
    $n * ($n - 1) * 2 ** ($n - 3)
}

sub list {
    my $self = shift;
    @{$self->{faces}}[1 .. $self->{vars}]
}

# Convert between a 1-based variable number and flattened arrayref [i,j,K]
# and stringified name, according to the Authoritative Ordering.

sub unpack {
    my $self = shift;
    my $v = shift;
    $self->{faces}->[$v] // die "lookup failed on $v";
}

sub pack {
    my $self = shift;
    my $ijK = join '', @{+shift};
    $self->{numbers}->{$ijK} // die "lookup failed on $ijK";
}

sub name {
    my $self = shift;
    my $v = shift;
    $self->{names}->[$v] // die "lookup failed on $v";
}

":wq"

use Modern::Perl;
use bignum;

package Simplex::Variables;

# Construct a Simplex::Variables object. This receives a hash which
# describes in some way the dimension of the simplex. Using C<< dim => $n >>
# specifies the dimension directly. With C<< vars => $m >> one gives
# the dimension implicitly by the number C<$m> of faces of the simplex.
# Lastly, a ground set can be given as C<< set => [...] >>, where the
# value is an arrayref of single characters.
#
# Precedence is C<dim> > C<set> > C<vars>. Once the dimension is known,
# the other properties can be computed. Inconsistent settings, including
# when there is no $n such that the simplex has $m faces, are an error.
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
    #   emptyset,
    #   1, 2, 3, ...
    #   12, 13, ..., 23, ...
    #   123, ...
    #   ...
    # i.e. by cardinality and then lexicographically.
    #
    # DANGER: If the implementation of subsets is changed,
    # this will suddenly produce wrong axioms! But we have
    # a test for the correct ordering in t/.
    use Algorithm::Combinatorics qw(subsets);

    $self->{faces}   = \my @faces;
    $self->{names}   = \my @names;
    $self->{numbers} = \my %numbers;

    $faces[0] = $names[0] = "(NaV)";
    my $v = 1;
    for my $k (0 .. $n) {
        for my $K (subsets([1 .. $n], $k)) {
            my $face = [map { $self->{set}->[$_-1] } sort @$K];
            my $name = _name($face);
            $faces[$v] = $face;
            $names[$v] = $name;
            $numbers{$name} = $v;
            $v++;
        }
    }

    $self
}

# Solve $vars == 2 ** $n.
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
    2 ** shift
}

sub _name {
    join '', sort @{+shift}
}

sub vars {
    shift->{vars}
}

sub list {
    my $self = shift;
    @{$self->{faces}}[1 .. $self->{vars}]
}

# Convert between a 1-based variable number and arrayref of the sorted
# elements and stringified name, according to the Authoritative Ordering.

sub unpack {
    my $self = shift;
    my $v = shift;
    $self->{faces}->[$v] // die "lookup failed on $v";
}

sub pack {
    my $self = shift;
    my $K = join '', sort @{+shift};
    $self->{numbers}->{$K} // die "lookup failed on $K";
}

sub name {
    my $self = shift;
    my $v = shift;
    $self->{names}->[$v] // die "lookup failed on $v";
}

":wq"

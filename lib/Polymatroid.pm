use Modern::Perl;
use bignum;

package Polymatroid;

# Add a clone method
use parent 'Clone';

sub new {
    my $class = shift;
    my $self = bless [], $class;

    my @ranks = split //, shift;
    $self->[0] = my $dom = shift;
    @{$self}[1 .. $dom->vars] = @ranks;

    $self
}

sub ci {
    my $self = shift;
    my $dom = $self->[0];

    my ($i, $j, @K) = @_;
    my $iK  = $dom->pack([$i, @K]);
    my $jK  = $dom->pack([$j, @K]);
    my $ijK = $dom->pack([$i, $j, @K]);
    my $K   = $dom->pack([@K]);

    #say $i, $j, "|", join('', @K), ": ",
    #    $self->[$iK],  " + ",
    #    $self->[$jK],  " - ",
    #    $self->[$ijK], " - ",
    #    $self->[$K],   " = ",
    #    $self->[$iK] + $self->[$jK] - $self->[$ijK] - $self->[$K];
    0 == $self->[$iK] + $self->[$jK] - $self->[$ijK] - $self->[$K]
}

":wq"

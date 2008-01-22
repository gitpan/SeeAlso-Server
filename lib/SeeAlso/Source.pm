package SeeAlso::Source;

use strict;
use Carp qw(croak);
use SeeAlso::Response;

use vars qw($VERSION);
$VERSION = "0.45";

=head1 NAME

SeeAlso::Source - a source of OpenSearch Suggestions reponses

=head1 SYNOPSIS

  my $source = SeeAlso::Source->new();
  my $source = SeeAlso::Source->new( sub { ... } );
  ...
  $source->description( "key" => "value" ... );
 ...
  $source->

=head2 new ( [ $query_method [, @description ] ] )

Create a new source. You can provide a query method (mQuery). The query method
gets a L<SeeAlso::Identifier> object and must return a L<SeeAlso::Response>.
The optional @description parameter is passed to the description method. Instead
of providing a query method by parameter you can also derive a subclass and define
the mQuery method.

=cut

sub new {
    my ($class, $query, @description) = @_;

    croak("parameter to SeeAlso::Source->new must be a method")
        if defined $query and ref($query) ne "CODE";

    my $self = bless {
        mQuery => $query || undef,
        errors => undef
    }, $class;
    $self->description( @description ) if @description;

    return $self;
}

=head2 description ( [ $key ] | $key => $value, $key => $value, ... )

Returns additional description about this source in a hash (no key provided)
or a specific element of the description. The elements are defined according
to elements in an OpenSearch description document. Up to now they are:

=over

=item ShortName

A short name with up to 16 characters.

=item LongName

A long name with up to 48 characters.

=item Description

A description with up to 1024 characters.

=item BaseURL

URL of the script. Will be set automatically via L<CGI> if not defined.

=item DateModified

Qualified Dublin Core element Date.Modified.

=item Source

Source of the data (dc:source)

=back

=cut

sub description {
    my $self = shift;
    my $key = $_[0];

    if (scalar @_ > 1) {
        my %param = @_;
        foreach my $key (keys %param) {
            my $value = $param{$key};
            $value =~ s/\s+/ /g;
            if ($self->{description}) {
                $self->{description}{$key} = $value;
            } else {
                my %description = ($key => $value);
                $self->{description} = \%description;
            }
        }
    } elsif ( $self->{description} ) {
        return $self->{description}{$key} if defined $key;
        return $self->{description};
    } else { # this is needed if no description was defined
        return if defined $key;
        my %hash;
        return \%hash;
    }
}

=head2 query ( $identifier )

Gets a L<SeeAlso::Identifier> object and returns a L<SeeAlso::Response> object.
If you override this method, make sure that errors get catched!

=cut

sub query {
    my $self = shift;
    my $identifier = shift;
    my $response;

    if ( $self->{mQuery} ) {
        #eval {
            $response = &{$self->{mQuery}}($identifier);
        #};
    } else {
        #eval {
            $response = $self->mQuery($identifier);
        #}
    }
    if ($@) {
        $self->errors($@);
    } else {
        if ( ! UNIVERSAL::isa($response, "SeeAlso::Response") ) {
            $self->errors("Query method did not return SeeAlso::Response!");
            undef $response;
        }
    }
    return $response = SeeAlso::Response->new( $identifier->normalized )
        unless defined $response;
    return $response;
}

=head2 errors ( [ $message [, $message ... ] ] )

Get/add error messages.

=cut

sub errors {
    my $self = shift;
    push @{ $self->{errors} }, @_ if @_;
    return $self->{errors};
}

=head2 hasErrors

Return whether errors have occured.

=cut

sub hasErrors {
    my $self = shift;
    return defined $self->{errors} and scalar @{ $self->{errors} };
}

1;
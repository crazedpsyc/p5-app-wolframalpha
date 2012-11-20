package App::WolframAlpha;
# ABSTRACT: A command-line tool for querying WolframAlpha.com

use Moose;
use WWW::WolframAlpha;
use Encode 'encode_utf8';

with 'MooseX::Getopt';

has wolframalpha => (
	metaclass => 'NoGetopt',
	isa => 'WWW::WolframAlpha',
	is => 'ro',
	default => sub {
        my $self = shift;
        WWW::WolframAlpha->new(appid => $self->appid);
    },
);

has query => (
	isa => 'Str',
	is => 'rw',
	predicate => 'has_query',
);

has appid => (
    isa => 'Str',
    is => 'ro',
    default => sub{''},
);

sub set_query_by_extra_argv {
	my ( $self ) = @_;
	$self->query(join(" ",@{$self->extra_argv})) if @{$self->extra_argv};
}

sub print_query_with_extra_argv {
	my ( $self ) = @_;
	$self->set_query_by_extra_argv;
	$self->print_query;
}

sub print_query {
	my ( $self ) = @_;
	return unless $self->has_query;
    unless ($self->appid) {
        print "No AppID given! Specify your Wolfram|Alpha ID with --appid=XXXX, or by editing $ENV{XDG_CONFIG_HOME}/app_wolframalpha.conf";
        exit 1;
    }
	eval {
		my $result = $self->wolframalpha->query(input => $self->query);
		$self->print_result($result);
	};
	if ($@) {
        print "An error was encountered! If this continues to happen, please report on https://github.com/crazedpsyc/p5-app-wolframalpha/issues/\n";
		exit 1;
	}
}

sub print_result {
    my ($self, $result) = @_;
    for my $pod (@{$result->pods}) {
        print "\033[32m" . $pod->title . ":\033[0m ";
        print "\n" if $pod->numsubpods > 1;
        for (@{$pod->subpods}) {
            if ($_->plaintext) { 
                my $plaintext = $_->plaintext;
                # if there are any newlines in this data, add an extra one at the beginning to make it look nicer
                #p $plaintext;
                $plaintext = "\n$plaintext" if $plaintext =~ /\n/ and $pod->numsubpods < 2; 
                print encode_utf8 $plaintext . "\n";
            } else {
                print "No plaintext form\n";
            }
        }
        print "\n";
    }
    if ($result->assumptions->count) {
        print 'Assuming "' . $_->word . '" is ' . @{$_->value}[0]->desc . "\n" for @{$result->assumptions->assumption};
    }
}

1;

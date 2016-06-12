package schwafenthaeler;
use Dancer ':syntax';
use Dancer::Plugin::Thumbnail;
use Path::Tiny;
use schwafenthaeler::Entry;

our $VERSION = '0.1';


get '/' => sub {
	my @entries = @{schwafenthaeler::Entry::getAllEntries()};

	my $paginator;
	$paginator->{page} = param('p') // 1;

	$paginator->{firstEntry} = ($paginator->{page} - 1) * config->{pagination}->{page_size};
	if($paginator->{firstEntry} > $#entries) {
		$paginator->{firstEntry} = 0;
		$paginator->{page} = 1;
	}
	$paginator->{lastEntry} = $paginator->{firstEntry} + config->{pagination}->{page_size} - 1;

	## Paginator im Template verfügbar machen
	var paginator => $paginator;

	my @shownEntries = @entries[$paginator->{firstEntry}..$paginator->{lastEntry}];

	template 'index', {
		entries => \@shownEntries,
	};
};

get '/:id' => sub {
	if(param('id') =~ /^\d+$/) {
		template 'entry', {
			entry => schwafenthaeler::Entry::getEntry(param('id'))
		}
	}
	else {
		send_error 500;
	}
};

# simple resize
get '/thumb/:entry/:image' => sub {
	my $image = path('entries', param('entry'), param('image'))->stringify;
    resize  $image => { w => 300 };
};


hook before => sub {
	my $recent = schwafenthaeler::Entry::getRecentEntries();
	var recent => $recent;
};

true;

package schwafenthaeler;
use Dancer ':syntax';
use Dancer::Plugin::Thumbnail;
use Path::Tiny;
use POSIX;
use schwafenthaeler::Entry;

our $VERSION = '0.1';


get '/' => sub {
	my @entries = @{schwafenthaeler::Entry::getAllEntries()};

	## Pagination-Daten erzeugen
	my $paginator;
	$paginator->{page} = param('p') // 1;
	if($paginator->{page} < 1) {
		$paginator->{page} = 1;
	}

	## ersten/letzten Eintrag der aktuellen Seite ermitteln
	$paginator->{firstEntry} = ($paginator->{page} - 1) * config->{pagination}->{page_size};
	if($paginator->{firstEntry} > $#entries) {
		$paginator->{firstEntry} = 0;
		$paginator->{page} = 1;
	}
	$paginator->{lastEntry} = $paginator->{firstEntry} + config->{pagination}->{page_size} - 1;

	## Seitenzahl ermitteln
	$paginator->{maxPages} = floor($#entries / config->{pagination}->{page_size}) + 1;

	## Größe des vor/nach der aktuellen Seite angezeigten Nav-Fensters ermitteln
	if($paginator->{page} == 1) {
		$paginator->{framePrevSize} = 0;
	}
	elsif($paginator->{page} <= config->{pagination}->{frame_size}) {
		$paginator->{framePrevSize} = $paginator->{page} - 1;
	}
	else {
		$paginator->{framePrevSize} = config->{pagination}->{frame_size};
	}

	if($paginator->{page} - $paginator->{framePrevSize} > 1) {
		$paginator->{framePrevSkipped} = true;
	}



	if($paginator->{page} == $paginator->{maxPages}) {
		$paginator->{frameNextSize} = 0;
	}
	elsif($paginator->{page} + config->{pagination}->{frame_size} > $paginator->{maxPages}) {
		$paginator->{frameNextSize} = $paginator->{maxPages} - $paginator->{page};
	}
	else {
		$paginator->{frameNextSize} = config->{pagination}->{frame_size};
	}

	if($paginator->{page} + $paginator->{frameNextSize} < $paginator->{maxPages}) {
		$paginator->{frameNextSkipped} = true;
	}


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

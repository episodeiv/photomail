package schwafenthaeler;
use Dancer ':syntax';
use Dancer::Plugin::Thumbnail;
use Path::Tiny;
use schwafenthaeler::Entry;

our $VERSION = '0.1';


get '/' => sub {
	my $page = param('p') // 1;
	my @entries = @{schwafenthaeler::Entry::getAllEntries()};

	my $firstEntry = ($page - 1) * config->{pagination}->{page_size};
	if($firstEntry > $#entries) {
		$firstEntry = 0;
	}
	my $lastEntry = $firstEntry + config->{pagination}->{page_size} - 1;

	my @shownEntries = @entries[$firstEntry..$lastEntry];

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

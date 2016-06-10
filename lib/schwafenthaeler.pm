package schwafenthaeler;
use Dancer ':syntax';
use Dancer::Plugin::Thumbnail;
use Path::Tiny;
use schwafenthaeler::Entry;

our $VERSION = '0.1';



get '/' => sub {
    template 'index', {
    	entries => schwafenthaeler::Entry::getAllEntries(),
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

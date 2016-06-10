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

# simple resize
get '/thumb/:entry/:image' => sub {
	my $image = path('entries', param('entry'), param('image'))->stringify;
    resize  $image => { w => 300 };
};

true;

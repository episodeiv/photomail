package schwafenthaeler;
use Dancer ':syntax';
use schwafenthaeler::Entry;

our $VERSION = '0.1';

get '/' => sub {
    template 'index', {
    	entries => schwafenthaeler::Entry::getAllEntries(),
	};
};

true;

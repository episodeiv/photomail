# Synopsis
This is photomail, a simple system which allows you to publish to your
photo blog by simply sending e-mails.

# Installing
* Download the current version by cloning the github repository.
* Install perl dependencies by running `carton install --deployment` from the checkout folder
* Install javascript dependencies by running `bower install -p` from the checkout folder

# Configuring
Either alter the configuration in `environments/production.yml` or create your own environment
file in that folder.

# Running
The backend is run by using plackup, for instance: `carton exec plackup bin/app.pl`. This defaults
to the *development* environment. Set the environment variable `DANCER_ENVIRONMENT` to override
this default.

The e-mail fetcher needs to be run periodically (for instance via *cron*), for instance
`carton exec bin/fetchmail.pl`. This also uses the *development* environment by default.

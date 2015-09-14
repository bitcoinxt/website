bitcoinxt.website
=============

This is the repository for bitcoinxt.website .


How do I install and run Jekyll?
-------------------------------

You must have Ruby installed in order to download and use Jekyll. The Ruby download
page provides instructions for getting Ruby setup on different platforms:

<http://www.ruby-lang.org/en/downloads/>

After you have Ruby installed, open up the command prompt on the project directory and type:

    gem install bundle
    bundle install

(OSX and Unix users may need to prefix the first command with `sudo`.)

After Jekyll is installed, you can start it up in a given directory like this:

    bundle exec jekyll serve

This will start Jekyll on port 4000. You can now view the prototype in your
Web browser at this URL:

<http://localhost:4000>


Exporting
---------

To export your project, use the "build" command:

    bundle exec jekyll build

The site will be generated under _site

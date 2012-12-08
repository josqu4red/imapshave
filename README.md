IMAPShave
=====

Bored to delete Nagios messages every now and then ?

imapshave is a quick script to remove mail in mailboxes (folders) based on its age.
Mailboxes are defined in a configuration file, along with server name and
credentials.

Usage
------

Config file:

    ---
    :server: imap.example.com
    :ssl: true
    :user: foo.bar@example.com
    :pass: s3cur3p4ss
    :folders:
      Nagios:
        :keep: 7
        :skip_flagged: true      # Keep flagged mail (Important or so)
      Chef:
        :keep: 1
        :skip_flagged: false

Run:

    $ ./imapshave -c config.yml

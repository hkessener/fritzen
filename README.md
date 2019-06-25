# NAME

fritzen.pl

# DESCRIPTION

Process FRITZ!Box configuration data using the TR-064 protocol.

# SYNOPSIS

    fritzen.pl --service <value> --action <value> [other options...]

    fritzen.pl --service <value> --task <value> [other options...]

## Options:

    -s,--service         deviceconfig | deviceinfo | ...
    -a,--action          getinfo | getsecurityport | ...
    -t,--task            backup | restore | ...

    -u,--username        SOAP username
    -p,--password        SOAP password
    -d,--deviceurl       UPnP URL of FRITZ!Box

    -c,--cfgfile         config filename
    -l,--logfile         log filename
    -v,--loglevel        debug | info | warn

    -w,--workdir         working directory
    -g,--git             git init/commit

    -q,--quiet           suppress screen messages
    -h,--help            show help screen

    --configpw           password for config file protection

    --serverproto        internal webserver protocol
    --serveraddr         internal webserver ip address
    --serverport         internal webserver tcp port
    --sslcertfile        internal webserver ssl certificate file
    --sslkeyfile         internal webserver ssl private key file

# OPTIONS

    -s, --service

        TR-064 service (mandatory): deviceconfig, deviceinfo or ontel

    -a, --action

        TR-064 action to perform. Either an action or a task must be given.

        List of actions for service deviceconfig:

            - factory-reset: Reset FRITZ!Box to factory settings. Use with care!

            - reboot: Reboot FRITZ!Box. Note: The FRITZ!Box will reboot itself automatically approx. 30 seconds after restore from file.

        List of actions for service deviceinfo:

            - getinfo: Get miscellaneous information about FRITZ!Box hardware and software.

            - getsecurityport: Get HTTPS port of FRITZ!Box for secure information.

        List of actions for service ontel:

            none

        List of actions for service wlandslinterfaceconfig:

            - getinfo: Get status information about current DSL connection

            - getstatisticstotal: Get statistics on current DSL connection

            - getdsldiagnoseinfo: Returns the state of a DSL diagnose

    -t, --task

        Task to perform. Either an action or a task must be given.

        List of tasks for service deviceconfig:

            - backup: Backup FRITZ!Box configuration to file.

            - restore: Restore FRITZ!Box configuration from file.

        List of tasks for service deviceinfo:

            none

        List of actions for service ontel:

            - backup : Backup all phonebooks to files.

            - backup:id : Backup phonebook from file by ID. For example "--action backup:1" will back up the phonebook with ID #1.

            - delete: Delete all phonebooks on the FRITZ!Box. The phonebooks will be deleted top-down, starting with the highest ID first.

            - delete:id : Delete phonebook identified by ID on the FRITZ!Box. Note that phonebooks with IDs above ID will "slide down" and the FRITZ!Box will reassign them new IDs. As a result, phonebook IDs on the FRITZ!Box and the respective backup file numbering will be out of sync and require manual rework.

            - list: List available phonebooks on the FRITZ!Box.

            - restore : Restore all phonebooks from files.

            - restore:id : Restore phonebook by ID from file.

    -u, --username

        SOAP username (better use config file)

    -p, --password

        SOAP password (better use config file)

    -d, --deviceurl

        UPnP URL of FRITZ!Box (default: http://fritz.box:49000)

    -c, --cfgfile

        Config filename (default: fritzen.cfg)

    -l, --logfile

        Log filename (default: fritzen.log)

    -v, --loglevel

        Log level: debug, info or warn (default: info).

    -w, --workdir

        Working directory (default: current directory). Must be writeable. This is where all backed up files will be stored and a git repository will be initialized (if option --git is set). It is ecommended to use distinct and different working directories for different devices and/or sets of configuration data.

    -g, --git

        Commit files to git repository (switch, default: false). Init git repository in working directory if not already done.

    -q, --quiet

        Suppress screen messages i. e. when running in cronjob (switch, default: false).

    --configpw

        Password for config file protection. If unset the SOAP passsord will be used.

    --serverproto

        Serve files for FRITZ!Box either with HTTP or HTTPS protocol (default: http). The module HTTP::Daemon::SSL is required for HTTPS. Use http if the installation of HTTP::Daemon::SSL fails on your system and edit Fritzen/Common.pm to set "SSL_AVAILABLE => 0".

    --serveraddr

        Serve files for FRITZ!Box with this IP address (default: auto-discovered IPv4 address of your system)

    --serverport

        Serve files for FRITZ!Box with this TCP port (default: 8888)

    --sslcertfile

        SSL certificate file for HTTPS server (default: ssl/ssl-cert-snakeoil.pem)

    --sslkeyfile

        SSL key file for HTTPS server (default: ssl/ssl-cert-snakeoil.key)

    -h, --help

        Print this help screen and exit.

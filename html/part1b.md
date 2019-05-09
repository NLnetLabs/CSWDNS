% Set up an Authoritative Name Server using NSD

We will start with setting up a single authoritative nameserver.  We will start with
installing an authoritative nameserver on: auth-*\<team nr\>*.do.dns-school.org.

1.  Log onto your master machine auth-*\<nr\>*.do.dns-school.org and Install
    the authoritative nameserver NSD:

        apt install nsd

2.  Configure the nsd-control authentication

    The NSD control ultility, called `nsd-control`, needs to be configured before
    we can use it. This is done in the same way as Unbound, the keys and
    certificates can be generated using the command:

        nsd-control-setup


<!-- 3   Also on this machine the /etc/resolv.conf needs modifying.  What IP
         address should be used? -->

## Configuration of the master server

1.  Take a look at the NSD configuration file at:

        /etc/nsd/nsd.conf
    
    Just like with Unbound, the default Ubuntu 19.04 nsd.conf just includes
    and processes files from the `/etc/nsd/nsd.conf.d` directory.

    For our class we prefer to start out with the example NSD configuration
    file.  This time it is compressed and located here:
    
        /usr/share/doc/nsd/examples/nsd.conf.sample.gz
    
    To uncompress and put it at the right location at the same time do:

        zcat /usr/share/doc/nsd/examples/nsd.conf.sample.gz > /etc/nsd/nsd.conf

2.  Read documentation for nsd.conf on how to set-up NSD, here is a sample:

        server:
	        server-count: 1
	        verbosity: 3
	        database: ""

        remote-control:
                control-enable: yes

3.  Verifying that the config file is syntactically correct is often a good
    idea before starting (or restarting) the nameserver.  You can check the
    configuration and restart NSD using:

        nsd-checkconf nsd.conf
        systemctl restart nsd

4.  You now have an authoritative nameserver, however no zone is served by it
    yet.  We'll use static configured zones. Each team can add one zone
    which will be registered as a subdomain of the `bangkok.lol` zone.

    Make up a good name for your team

        <name>.bangkok.lol

    To configure NSD to serve the zone add to nsd.conf:

    ```
	zone:
		name: <name>.bangkok.lol
		zonefile: /etc/nsd/<name>
    ```

    with *\<name\>* replaced with the name you made up.

    Intruct NSD to reload the nsd.conf configuration:

        nsd-control reconfig

    This command should return correctly, and changes have been applied then.
    But were all changes executed without problems?  Check /var/log/syslog!

5.  The zone file still needs to be put in place.  Use your favourite editor
    vi or nano to create and edit:

        /etc/nsd/<name>

    File contents:

        $ORIGIN <name>.bangkok.lol.
        $TTL 60
        @ IN SOA ns.<name>.bangkok.lol. admin.<name>.bangkok.lol. (
                 1    ; serial
                 360  ; refresh (6 minutes)
                 360  ; retry (6 minutes)
                 1800 ; expire (30 minutes)
                 60   ; minimum (1 minute)
                 )
        @   IN NS   ns.<name>.bangkok.lol.
        ns  IN A    <IPv4 of your auth-<team> machine>
            IN AAAA <IPv6 of your auth-<team> machine>

    You can find the IPv4 and IPv6 address of your master server here:

      * <http://bangkok.lol/teams.html>

    You can check the contens for this domain using:

        nsd-checkzone <name>.bangkok.lol /etc/nsd/<name>

    Reload the zone contents for this domain using:

        nsd-control reload <name>.bangkok.lol.

    Use dig to verify that your authoritative server is answering correctly.
    E.g. using

        dig @auth-<nr>.do.dns-school.org <name>.bangkok.lol. SOA

    This does not mean you zone exist yet.  The parent zone needs to delegate.
    Adding the delegation is normally part of the registration with your
    registrar.  The registrar will then submit the changes to the registry.
    Most of the time these updates do not yet happen as part of the DNS
    protocol.  Instead registries have often web-based pages where you can add
    the NS records.
    
    For these lab excercises you can go to Willem & Ralph and tell them
    about your team name, and they will add the delegation for you.

    You can check the delegations here:

      * <http://bangkok.lol/bangkok.lol.delegations.shtml>


6.  We can check that the delegation is working by debugging iterating
    the authoritative servers.  This can be done with `drill`.
    We need to install `ldnsutils` for this.
    
        apt install ldnsutils

    And then iterate the authoritative servers up to your domain from the
    root up:

        drill -T <name>.bangkok.lol SOA

7.  What happens if you point your browser to <http://www.team.bangkok.lol/>
    with *team* replaced by your team's *\<name\>*?

    Even though your domain is registered and reachable on the internet, we
    still do not have an IP address associated with it.

    Add your IP addresses to the zone file and also an `CNAME` that refers
    name `www` within you domain to the apex:

        @   IN A     <IPv4 of your auth-<team> machine>
            IN AAAA  <IPv6 of your auth-<team> machine>
        www IN CNAME @

    What is the apex of your domain?

    Because we changed something in the zone, we have to increment the serial
    number of the SOA record.  I.e.:
    
         @ IN SOA ns.<name>.bangkok.lol. admin.<name>.bangkok.lol. (
                 2    ; serial
                 360  ; refresh (6 minutes)
                 360  ; retry (6 minutes)
                 1800 ; expire (30 minutes)
                 60   ; minimum (1 minute)
                 )

    Check the zone and reload:

        nsd-checkzone <name>.bangkok.lol /etc/nsd/<name>
        nsd-control reload

    What do you see at <http://www.team.bangkok.lol/whoami>
    with *team* replaced by your team's *\<name\>*.

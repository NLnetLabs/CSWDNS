% Setup redundant authoritative name server for your domain

You can increase resilience of your domains by adding a secondary name server.
In this instruction we're going to team up with another team and ask them if
they could provide secondary DNS service for our zone.

1.  Coordinate, with the help of Willem and Ralph, which other team will
    slave your zone.

    We will do this for the first zone you created: *\<name\>*.bangkok.lol.
    If you finish early, you might consider to setup a secondary for your
    second domain (*\<new name\>*.*\<registry\>*.bangkok.lol) too.

    Willem and Ralph will add an NS entry for the secondary server to the
    bangkok.lol zone file.  The registered delegations can be viewed here:

      * <http://bangkok.lol/bangkok.lol.delegations.shtml>

2.  Create a new entry in `nsd.conf` for the TSIG key which will be used to
    authenticate the slave requesting a transfer.  Vice verse the slave
    authenticates the zone coming from the master, so no attacking middle
    box can interfere and infect the slave with a malicious version of
    the zone.

    1.  Make up a name.
      
        The key must have a name.  The name can be arbitrary, but it is
        recommended that it reflects the names of the hosts that
        share this key.  For example:
        2*\<other teams name\>*.*\<name\>*.bangkok.lol.

    2.  Decide on an algorithm.
    
        Have a look in the "Key Declarations" section of the manpage for
        `nsd.conf`.  The stronger the algorithm, the safer your transfer.
        Algorithm `hmac-md5.sig-alg.reg.int` is generally considered too weak.

        What would be a reason to pick anything weaker than hmac-sha512?

    3.  Create a secret.

        This is just a random value expressed as Base64.  You can use for
        example the openssl tool to create a random value and print it in
        Base64 format.

            openssl rand -base64 48

        This would create and print a secret for algorithm hmac-sha384.
        The length is expressed in octets (number of bits divided by eight).
        I.e. 384 / 8 = 48.

        For convenience you may also use the `ldns-keygen` command, which
        knows the number of bits for the algorithms and creates a file
        containing the name, algorithm and secret for safekeeping.

        If you haven't already installed `ldnsutils`, then:

            apt install ldnsutils

        Then create a key with:

            ldns-keygen -r /dev/urandom -a hmac-sha512 2<other teams name>.<name>.bangkok.lol

    Edit `/etc/nsd/nsd.conf` and add an entry for your key.

        key:
            name: 2<other team name>.<name>.bangkok.lol.
            algorithm: <algorithm>
            secret: "<secret>"
    
    With *\<algorithm\>* and *\<secret\>* replaced with the algorithm you
    picked and secret you created.

3.  Update `/etc/nsd/nsd.conf` to notify and allow transfer to the slave server.

    Provide `notify` and `provide-xfr` entries in the correct zone entry
    for the slave server:

        zone:
            name: <name>.bangkok.lol
            zonefile: /etc/nsd/<name>

            notify: <slave IPv6 address> NOKEY
            notify: <slave IPv4 address> NOKEY
            provide-xfr: <slave IPv6 address> 2<other team name>.<name>.bangkok.lol.
            provide-xfr: <slave IPv4 address> 2<other team name>.<name>.bangkok.lol.

    Check that the configuration is correct and `reconfig` NSD.

        nsd-checkconf /etc/nsd/nsd.conf
        nsd-control reconfig

    What is the benefit of using both IPv6 and IPv4?

4.  Bring the key to the other team confidentially.

    The other team that is going to slave your domain, should add this key
    exactly the same way too.  You have to give it to the other team
    confidentially because noone else may know your shared secret.

    Consider a way to do this.  Options might be e-mail, usb stick, paper,
    sharing it under a secret name on your webite.

    For the last method (via your website), you can create a file with a 
    *\<secret name\>* with the `key` entry to be added to `nsd.conf` in the
    `/var/www/html` directory.  The other team can then access your secret via

      * <https://name.bangkok.lol/secret-name>

5.  Let other team add zone entry for your zone.

    The entry should like something like this:

        zone:
            name: <name>.bangkok.lol
            allow-notify: <IPv6 of master server> NOKEY
            allow-notify: <IPv4 of master server> NOKEY
            request-xfr: <IPv6 of master server> 2<other team name>.<name>.bangkok.lol.
            request-xfr: <IPv4 of master server> 2<other team name>.<name>.bangkok.lol.

    You could make it really easy for them by providing both the `key:` entry
    and the `zone:` entry together in a file with a secret name in
    `/var/www/html` so they can get it from your website (with the secret name).

6.  Add to your `/etc/nsd/nsd.conf` a zone entry for the zone your team will
    be the slave server.

    Make sure you checked configuration and `reconfig`'ed NSD after adding
    the zone entry for them!

    Check the status of the slave zone with:

        nsd-control zonestatus

    Does is say `state: ok`?  Did the zone transfer?
    If not we must find out what went wrong.

7.  Is the secondary name server serving your team's zone correctly?

    Check if your authoritative's SOA is the same as the one on the slave:

        dig @<other team's auth> <name>.bangkok.nl SOA

    Check if updates propogate timely by changing the SOA serial number of
    your zone, reloading and looking at the `SOA` at the secondary.

8.  Add the NS entry for the secondary to your zone.

    Don't forget to increment SOA serial too and to reload your zone.

9.  Some more questions.

    Why did we configure the notify without a TSIG key?
    What would be the benefit of notifying with a TSIG key?

    What is the difference between master server and slave server, and
    primary server and secondary server?


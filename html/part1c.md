% Register a new zone within the zone of a fellow team

We will create another zone and register that, but now within the zone of
a fellow team.

1.  Coordinate, with the help of Willem and Ralph, in which fellow
    team you will register your new domain.  We will refer to the fellow
    team as *\<registry\>* and the domain which they registered as
    *\<registry\>*.bangkok.lol.

    Besides picking a fellow team (and their domain to register your new
    zone in), you have to make up a new name for the new zone.

    Your new zone will be *\<new name\>*.*\<registry\>*.bangkok.lol. where
    *\<new name\>* is prefably something different that *\<name\>*.

    Likewise, another team will register their new zone in your
    *\<name\>*.bangkok.lol domain as *\<their new zone\>*.*\<name\>*.bangkok.lol.


2.  Add a new zone to the NSD configuration for you new zone:

    ```
    zone:
        name: <new name>.<registry>.bangkok.lol
        zonefile: <new name>
    ```

    with *\<new name\>* replaced with the new name you just made up and
    *\<registry\>* with the zone of your fellow team.
    
    Intruct NSD to reload the nsd.conf configuration:

        nsd-control reconfig

    What does `/var/log/syslog` say?

3.  Create a zone file for the new zone.  It might be easiest to copy your
    first zone and adapt values.

    Your zone should look something like this:

    ```
    $ORIGIN <new name>.<registry>.bangkok.lol.
    $TTL 60
    @ IN SOA ns.<new name>.<registry>.bangkok.lol. admin.<new name>.<registry>.bangkok.lol. (
             2    ; serial
             360  ; refresh (6 minutes)
             360  ; retry (6 minutes)
             1800 ; expire (30 minutes)
             60   ; minimum (1 minute)
             )
    @   IN NS    ns.<new name>.<registry>.bangkok.lol.
    ns  IN A     <IPv4 of your auth-<team> machine>
        IN AAAA  <IPv6 of your auth-<team> machine>
    @   IN A     <IPv4 of your auth-<team> machine>
        IN AAAA  <IPv6 of your auth-<team> machine>
    www IN CNAME @
    ```

    Reload NSD

        nsd-control reload

    Test if the domain is loaded.

        dig @localhost <new name>.<registry>.bangkok.lol. SOA

5.  Now register your domain with the registry.

    With the above zone, they need to add `<new name> IN NS ns.<new name>`
    to their zone file.  They also need to add your glue records:

    ```
    <new name>     IN NS   ns.<new name>
    ns.<new name>  IN A    <IPv4 of your auth-<team> machine>
    ns.<new name>  IN AAAA <IPv6 of your auth-<team> machine>
    ```

    Once they are done, you should be able to iterate towards your new zone
    with drill:

        drill -T <new name>.<registry>.bangkok.lol SOA

    And see the identity of your own machine at

      * <http://<new name>.<registry>.bangkok.lol/whoami>

6.  Likewise, the other team that picked you as the registry will come to you
    and ask if you can put their NS record plus glue records in your zone.

    Don't forget to increment serial number and reload your NSD!

7.  Is it also possible to reuse ns.*\<name\>*.bangkok.lol as the authoritative
    nameserver for the new zone?

    Do you still need glue records then?

    What is the advantage of glue records?

    Can things go wrong without glue records?


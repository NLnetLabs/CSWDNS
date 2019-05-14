% Signing your zone the primitive way

This excercise takes place on your master server auth-*\<team nr\>*.do.dns-school.org or *\<name\>*.bangkok.lol.

1.  We will need the `ldnsutils`.

    Did you install them already?  If not...

       `apt install ldnsutils`

    This includes the `ldns-keygen` and `ldns-signzone` utilities that can be
    used to generate keys and sign the zone.
    
2.  We will create two keys, a Zone Signing Key (ZSK) and a Key Signing Key
    (KSK).  Which command generates which?

        cd /etc/nsd

        ldns-keygen -r /dev/urandom -a ECDSAP256SHA256 <name>.bangkok.lol

        ldns-keygen -r /dev/urandom -a ECDSAP256SHA256 -k <name>.bangkok.lol

    Unfortunately we have to use `/dev/urandom` here rather than a slightly
    better random number generator due to limitations of the lab environment.
    Don't do this for real.

    Both commands will output the base names of the files which have to be
    used next.  The basename will look like K<name>.bangkok.lol.+013+?????
    One of the base name is the ZSK and one is the KSK.  Note down the number
    (?????) for the ZSK and the one for the KSK.  We will refer to those
    numbers later with *\<ZSK\>* and *\<KSK\>*

3.  Sign your zone with both keys using their base names:

        ldns-signzone <name> K<name>.bangkok.lol.+013+<ZSK> K<name>.bangkok.lol.+013+<KSK>

    The sequence in which the keys are placed does not matter.
    `ldns-signzone` will write a new zonefile: *\<name\>*.signed

    You can validate all the signatures in the zone:

        ldns-verify-zone <name>.signed

    You can also verify using a trust anchor.

        ldns-verify-zone -k K<name>.bangkok.lol.+013+<ZSK>.key <name>.signed

    Did that validate?

    Does the command below validate?

        ldns-verify-zone -k K<name>.bangkok.lol.+013+<KSK>.key <name>.signed

    Why? What is the difference?

4.  Automate serial number updating

    Have a look at the serial number in the SOA of the <name> and the
    <name>.signed file.

    Are they different?

    Every time we sign the zone, the content changes and we have to update the
    serial number.  We can read the zone and change the serial number to
    unix time (# seconds since 1-1-1970) with `ldns-read-zone`.  Try it:

        ldns-read-zone -S unixtime <name>

    `make` is a utility that runs a set of commands to create a file, but only
    if the inputs on which it depends have changed.  Install `make`

        apt install make

    Create a file named `Makefile` with the following content:

        <name>.signed: <name>
        	ldns-read-zone -S unixtime <name> \
        	| ldns-signzone -f <name>.signed - K<name>.bangkok.lol.+013+<ZSK> K<name>.bangkok.lol.+013+<KSK>
        	nsd-control reload

    with *\<name\>* replaced with the name of your zone and *\<ZSK\>* and *\<KSK\>* replaced with
    the key ids.  Beware that the indentation needs to be a real \<Tab\>
    character not just spaces.

    The output from `ldns-read-zone` is fed into `ldns-signzone` with the
    pipe character and by using a dash (-) as the zone file to read with
    `ldns-signzone`.  Because `ldns-signzone` now doesn't know the original
    filename we have to let it write to *\<name\>*.signed explicitly.

    Now try it out

        make

    What did it say?

    And if you pretend you changed *\<name\>* by touching it?

        touch <name>
        make

4.  Let NSD serve the signed zonefile

    Edit `/etc/nsd/nsd.conf` and make sure your zonefile is read from the
    file suffixed with `.signed` (i.e. *\<name\>*.signed).

    Then, `reconfig` and `reload` NSD:

        nsd-control reconfig
        nsd-control reload

    Do you see an "unixtime" serial number in the SOA record for your zone?

        dig @localhost <name>.bangkok.lol SOA

    From your resolver machine (res-*\<team nr\>*.do.dns-school.org) you can 
    use drill to check the security:

        drill -k /var/lib/unbound/root.key -TD <name>.bangkok.lol

    Is the zone secure/trusted?

    Why not?

5.  Your zone cannot be validated yet until the chain of trust delegation
    is completed.  This means the DS record needs to be entered in
    the parent zone file.

    A DS record is available in `K<team>.bangkok.lol+013+<KSK>.ds`.
    `ldns-keygen` created it when creating the KSK.

    Optionally you can create a better DS (SHA384)

        ldns-key2ds -3 K<team>.bangkok.lol+013+<KSK>.key

    A new way to convey your DS to the registry, is to publish it in a CDS
    resource record.  Not many registries provide this service already, but we
    will use it in the class.

    Look at the content of `K<team>.bangkok.lol+013+<KSK>.ds` and add the
    record to your zone file, but change DS into CDS.

    Willem and Ralph will monitor your zone for CDS records and add them to
    the delegation.  You can check if it happened already by watching:

       * <http://bangkok.lol/bangkok.lol.delegations.shtml>

5.  Now try to resolve on your resolver machine
    (res-*\<team nr\>*.dn.dns-school.org).

        dig +dnssec <name>.bangkok.lol SOA

    Is the zone secure?

        drill -k /var/lib/unbound/root.key -TD <name>.bangkok.lol

    Is the zone trusted?

    Also have a look at

      * <http://dnsviz.net/d/name.bangkok.lol>

    With *name* replaced with your name. Is everything good?

    `ldns-verify-zone` can also hunt down the chain of trust.
    If you obtained the root anchor key (the resolver machine has it for sure
    ), you could have better checked the validity of the zone:

        ldns-verify-zone -k /var/lib/unbound/root.key <name>.signed

6.  Additional questions.

    What is the advantage of having both a KSK and ZSK?

    Does CDS make this different?

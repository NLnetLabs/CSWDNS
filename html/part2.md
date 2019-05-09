% Making your recursive resolver a validating resolver

The caching recursive resolver unbound we installed in the very first
lab wasn't installed properly.  By copying the example config file, we
disabled DNSSEC validation *which the default Ubuntu installation of Unbound
would have enabled via the inclusion of `/etc/unbound/unbound.conf.d/root-auto-trust-anchor-file.conf*

Recursive nameservers need to be primed by a list of initial root
servers.  In order for them to properly validate, they also need
to be primed with the initial trust anchor.

1.   Verify by using dig that indeed there was no validation.  Performing
     a lookup:

        dig bogus.rootcanary.net

     Returns the address for this domain, but in fact this domain is invalid
     and validation should have failed.

2.  Unbound comes with an utility that downloads the proper anchor.
    This is not part of the binary itself because it may be updated, but
    more over it is the operators responsibility to make sure the anchor
    is correct.  Therefore we let you install this anchor now using:

        unbound-anchor -v

    Also you need to specify the file where the anchor is stored in the
    unbound.conf configuration file.  In the "server:" section add:

        server:
            auto-trust-anchor-file: "/var/lib/unbound/root.key"

3.  Restart unbound or let it re-read its configuration.  Now validate that
    unbound will return DNSSEC data for domains that are signed.  Normally
    this output is suppressed, but can be seen using the +dnssec flag.

        dig +dnssec www.bangkok.lol

    Do you see the ad flag?

    And if you lookup your own domain?

        dig +dnssec <name>.bangkok.lol

4.  Again try resolving a domain where DNSSEC is broken.

        dig bogus.rootcanary.net

5.  But we can see that in fact the domain does contain the information
    if we bypass the DNSSEC validation:

        dig +cd +dnssec bogus.rootcanary.net

6.  Remember that we traced your domain from the root up with `drill`

    We can do that while validating too, like this:

        drill -T -D -k /var/lib/unbound/root.key <name>.bangkok.lol 

    What does the output show you?

# Equip your own laptop with your DNS resolver

We will try to point the nameserver of your laptop to your own configured
resolver.

1.  Check your connection

    Go to <https://en.internet.nl/> and start the connection test.

    Does the classroom network have IPv6?

    Does the classroom network have a DNSSEC validating DNS resolver?

2.  On the page is a section titled "Further connection testing"

    Click on [DNSSEC resolver algorithm test](https://rootcanary.org/test.html)

    How many DNSSEC algorithms does the classroom network DNS resolver support?

3.  Check if you can do queries to your own resolver.

    We have to be really sure you can use your own resolver from the classroom
    network, otherwise you cannot do anything with your laptop anymore.

    If you have a Windows laptop, [open Command Prompt](https://www.wikihow.com/Open-the-Command-Prompt-in-Windows) and run:

        nslookup bangkok.lol <IPv4 of your resolver>

    If you have a Mac, [open a Terminal Window](https://www.wikihow.com/Open-a-Terminal-Window-in-Mac) and do

        dig @<IPv4 of your resolver> bangkok.lol

    Is you resolver usable from the classroom network?

    If not, lookup the IP address of the laptop with

      * <https://duckduckgo.com/?q=ip&t=h_&ia=answer>

    and make sure there is an `access-control` entry for it in `unbound.conf`.

7.  Can you configure your laptop to use your own DNS resolver?

    Here are some pointers for Windows

      * <https://www.wikihow.com/Change-Your-Windows-DNS>

    and Mac

      * <http://osxdaily.com/2015/12/05/change-dns-server-settings-mac-os-x/>

8.  How many DNSSEC algorithms are supported now?

      * <https://rootcanary.org/test.html>

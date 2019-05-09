% Setup a Caching Recursive Resolver using Unbound

The purpose of the lab is to setup the resolver on the res-*\<team nr\>* server,
mostly to get acquainted to the environment but also to perform the
first few queries.

1.  Log in to the server `res-`*`<nr>`*`.do.dns-school.org`.
   

2.  Install Unbound as the resolver.

        apt install unbound

3.  Take a look at the configuration file is located at:

        /etc/unbound/unbound.conf

    The default configuration on a Ubuntu 19.04 machine is to include and
    process all the files that are suffixed with `.conf` in the
    `/etc/unbound/unbound.conf.d` directory.

    From a system administrator's point of view it can be convenient to have
    specific configurations organized in separate files, so specific settings
    can be modularized and moved around different resolver configurations.

    Are there files in the `/etc/unbound/unbound.conf.d` directory?

    How do they affect the Unbound configuration?

    For our lab environment we prefer to start out with the example Unbound
    configuration file, because it shows how Unbound can be configured and
    what the default values are.

    The example Unbound configuration file is located here

        /usr/share/doc/unbound/examples/unbound.conf

    and can be copied to the default location with the `cp` command:

        cp /usr/share/doc/unbound/examples/unbound.conf /etc/unbound

    Have a look at the example configuration file.

    Another good place to see how Unbound can be configured, and to read about
    the possibilities of Unbound is the manpage:

        man unbound.conf


4.  Note that currently only queries from the local host are allowed.
    This is the default, to prevent so called "open resolvers" on the
    internet. We want to be able to query Unbound from our local machines, so
    let's change the configuration to make this possible.

    Using your favorite editor (vi and nano are available) add the following
    entries to the `server` section of the Unbound configuration file:

        interface: 0.0.0.0
        interface: ::0
        access-control: 127.0.0.1/8 allow
        access-control: ::1 allow



    Is you resolver usable from the classroom network?

    If not, lookup the IP address of the laptop with

      * <https://duckduckgo.com/?q=ip&t=h_&ia=answer>

    and make sure there is an `access-control` entry for it in `unbound.conf`.

    You can check your configuration using

        unbound-checkconf

    This allows the server to also respond to queries from the class room
    network, but not to the internet at large.

5.  Configure Unbound control utility.

    Unbound comes with a control utility called `unbound-control` to issue
    instructions to the server.

    To be able to use unbound-control we have to create keys and certificates.
    These will be used to authenticate the server, for the server to
    authenticate the client and to encrypt the transmitted data. The certificate
    is most simply created by using the following command:

        unbound-control-setup

    Furthermore enable remote control by some modifications to unbound.conf.
```
       remote-control:
            control-enable: yes
            control-interface: 127.0.0.1
```    
6.  Start or restart Unbound

        systemctl restart unbound

    If you want to keep Unbound running, but want to make configuration
    changes, you can now also use the Unbound configuration utility:

        unbound-control reload

7.  Verify by using dig.

        dig @localhost www.bangkok.lol

    It should get an answer.  If not, something went wrong.  Remember that
    DNS servers run as daemons and thus cannot report back directly to the
    user.  Instead the syslog files need to be consulted.  This Unbound
    and syslog configuration will write messages to the file

        /var/log/syslog

    This file varies per Unix/Linux distribution.  Also try looking up
    something that does not exist, like the MX record for

        blahongasprongai.grungelgroubledork.mubolkargatom.com

    even though almost every name gets allocated nowadays, this still hasn't
    been claimed.

8.  Stub resolver configuration

    There is one more step remaining for applications on the machine to
    start using the recursive nameserver properly.  That is to refer it
    in the local resolver configuration, which is located in the file:

        /etc/resolv.conf

    Edit the /etc/resolv.conf file so that it refers to the recursive
    name server running on the local machine.  Replace the lines (the actual
    IP addresses may vary at this time):

        nameserver 67.207.67.2
        nameserver 67.207.67.3

    By your newly Unbound instance:

        nameserver 127.0.0.1

    You can now omit the "@localhost" for every command.  All other
    applications on this machine will also start using the Unbound instance.
    Try it out again:

        dig www.bangkok.lol

    With a `TXT` query for name `hostname.bind` with class `CH` you can be
    certain you are speaking to your own resolver.

        dig hostname.bind CH TXT


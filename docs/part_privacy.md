% DNS privacy lab

In this exercise we will have a look at the privacy implications of DNS resolution and will learn how to harden our DNS set-up against some of these issues.

## Resolver to authoritative name server privacy

We will first have a look at the data that is exposed in DNS transactions between the DNS resolver and the authoritative name server.

### QNAME minimisation
Unbound already has a privacy feature enable by default. To get a better understanding of the potential privacy impact of DNS transactions we will disable this feature for now:

1. Disable QNAME minimisation support in your Unbound configuration:
   `qname-minimisation: no`

We will use the logging functionality in Unbound to display all the outgoing query information. Unbound has to be configured with a `verbosity` of 3 or higher to log all outgoing queries.

2. Restart your Unbound instance to make sure the cache is empty
3. Monitor the Unbound log output for all outgoing queries (hint, grep for `sending`)
4. Send a DNS query to Unbound (replace `<team-number>` with the number of your team):
   `drill www.bangkok.lol @res-<team-number>.do.dns-school.org`
5. Observe which information from the query is exposed to which upstream name
   servers.

We will now repeat this exercise with QNAME minimisation enabled.

6. Enable QNAME minimisation support in your unbound configuration:
   `qname-minimisation: yes`
7. Restart your Unbound instance again to make sure the cache is empty
8. Send the same DNS query to Unbound:
   `drill www.bangkok.lol @res-<team-number>.do.dns-school.org`
5. Observe what information from the query is exposed to which upstream name
   servers. What are the differences?

### RFC7706
Another way to limit the queries that Unbound has to send upstream is by loading authoritative DNS data into Unbound. In this exercise we will do this for the root zone.

6. Add this to your Unbound configuration to have it transfer the root zone into the resolver, having this data already in the resolver means that we don't have to send DNS queries to get it anymore:

```
   auth-zone:
     name: "."
     master: 199.9.14.201         # b.root-servers.net
     master: 192.33.4.12          # c.root-servers.net
     master: 199.7.91.13          # d.root-servers.net
     master: 192.5.5.241          # f.root-servers.net
     master: 192.112.36.4         # g.root-servers.net
     master: 193.0.14.129         # k.root-servers.net
     master: 192.0.47.132         # xfr.cjr.dns.icann.org
     master: 192.0.32.132         # xfr.lax.dns.icann.org
     master: 2001:500:200::b      # b.root-servers.net
     master: 2001:500:2::c        # c.root-servers.net
     master: 2001:500:2d::d       # d.root-servers.net
     master: 2001:500:2f::f       # f.root-servers.net
     master: 2001:500:12::d0d     # g.root-servers.net
     master: 2001:7fd::1          # k.root-servers.net
     master: 2620:0:2830:202::132 # xfr.cjr.dns.icann.org
     master: 2620:0:2d0:202::132  # xfr.lax.dns.icann.org
     fallback-enabled: yes
     for-downstream: no
     for-upstream: yes
```
7. Restart Unbound and again send the same query:
   `drill www.bangkok.lol @res-<team-number>.do.dns-school.org`
   How do the queries that are send to the root name servers with the auth-zone compare to the earlier    queries for the same domain name?
   
### Aggressive NSEC
Yet another (and complimentary) way to reduce the number of outgoing queries is by using aggressive NSEC. Aggressive  NSEC is at the moment disabled by default in Unbound. We will first use this default to observe the traffic without
aggressive NSEC.

We first need to get some NSEC records in our cache.

8. Send a query for a non-existing domain. Observe the returned NSEC records.
   
       drill -D bangkok.nlnetlabs.nl @res-<team-number>.do.dns-school.org

   For above query this is one of the NSEC records we get back:
    
        balou.nlnetlabs.nl.	3600	IN	NSEC	bartok.nlnetlabs.nl.

9. Send a query for another domain that is covered by this NSEC record:

       drill -D banana.nlnetlabs.nl @res-<team-number>.do.dns-school.org

   If you now look at your Unbound log you will see that for both queries Unbound will contact the nlnetlabs.nl name server.

9. Enable aggressive NSEC in your Unbound configuration:

       aggressive-nsec: yes

10. Restart Unbound and send the same two queries:
    
        drill -D bangkok.nlnetlabs.nl @res-<team-number>.do.dns-school.org

        drill -D banana.nlnetlabs.nl @res-<team-number>.do.dns-school.org

    Can you see a difference in the queuries that are send to the nlnetlabs.nl name servers?

### Stubby
We will use Stubby to proxy the DNS queries originating from our laptop over an encrypted channel to Unbound.

11. Install stubby on your laptop
	- Linux: `apt install stubby`
	- OS X: `brew install stubby`
	- Windows binaries available

    Have a look at <https://dnsprivacy.org/wiki/display/DP/About+Stubby> for detailed installation instructions.

    Although the default stubby configuration is already privacy aware, we will start with an empty configuration file to get a better understanding of all the different options.

12. Create a stubby configuration file names `stubby-bangkok.yml` and add this configuration:

        listen_addresses:
          - 127.0.0.1
          - 0::1
        upstream_recursive_servers:
          - address_data: 206.189.38.51
        edns_client_subnet_private: 0

    Stubby will now listen on 127.0.0.1 and ::1 for DNS queries and send these queries upstream to our test resolver (ecs-resolver.do.dns-school.org). If your laptop already has a process listening on port 53 for this address try to use another local address, like 127.0.0.10.

***TODO: edit ACL for ecs resolver.***

13. Run stubby:
    
        stubby -C stubby-bangkok.yml -l

14. Test your configuration by sending a DNS query to stubby:
   
        drill dns-school.org @127.0.0.1

### EDNS client subnet, client information exposure
In the previous example we configured stubby to send all queries to a resolver that sends ECS information in queries going to the google.com name servers. We are now going to look at the privacy implications of ECS.

15. Query stubby for the TXT record of the `o-o.myaddr.l.google.com.` domain.
   
        drill o-o.myaddr.l.google.com. @127.0.0.1 txt

    This test domain returns the received ECS prefix as TXT record. You will now see the prefix of your IP address, even though this information is usually hidden by using the resolver!

    The [ECS RFC](https://tools.ietf.org/html/rfc7871) mandates that resolvers must use the received ECS option from the query if this is available and not override it themselves. This means that is we as client send a /0 option the ECS resolver should not reveal our address. It is possible to configure stubby to add the /0 option to every outgoing query.

16. Enable the `edns_client_subnet_private` option in your `stubby-bangkok.yml` by setting it to 1 (which is also the default):
   
        edns_client_subnet_private: 1

17. Query stubby again for the TXT record of the `o-o.myaddr.l.google.com.` domain.
    
        drill o-o.myaddr.l.google.com. @127.0.0.1 txt

18. Observe the difference in the information received at the google.com name server. Note that the google name servers will display the source address of the _resolver_ when receiving an ECS option without useful information (like a /0 prefix).

## Stub to resolver privacy
We are now going to have a look at the privacy implications between the stub and the resolver. We are going to do this using stubby and your own Unbound installation.

19. Change the stubby configuration to send all queries to your own Unbound resolver: 

        upstream_recursive_servers:
          - address_data: <your-Unbound-IP-address>

    Replace `<your-Unbound-IP-address>` with the IP address of the machine running Unbound.

### DNS traffic on the wire

To get a better understanding of the privacy implications between the stub and the resolver we will use wireshark to monitor the network traffic.

20. Install wireshark on your local machine (https://www.wireshark.org/download.html).
21. Start the capture on your network interface
22. Limit the displayed traffic to traffic that is going to and from your resolver, e.g. using the filter `ip.addr==<your-Unbound-IP-address>` where `<your-Unbound-IP-address>` the is replaced by address of your Unbound instance.
23. Send a DNS query via stubby to your Unbound resolver:
    
        drill bangkok.lol @127.0.0.1

24. Observe in wireshark the DNS information that is visible on the wire. This data will be visible to everybody that can somehow see the data that your machine is sending and receiving!

### DNS encryption
In this part of the exercise we will encrypt the DNS traffic between stubby on our laptop and Unbound on the experimentation server. This will be done by sending all the DNS transactions over TLS ([DoT](https://tools.ietf.org/html/rfc7858)).

We will start by configuring Unbound to be a TLS server. For this a TLS certificate is needed. In this exercise we will request a [Let's Encrypt](https://letsencrypt.org/) certificate using [certbot](https://certbot.eff.org/).

25. Install certbot on the resolver server:
    
        apt install python3-certbot

26. Request a certificate for the domain of your resolver:
    
        certbot certonly --standalone -d res-<team-number>.do.dns-school.org

    Replace *\<team-number\>* with your team number.
    
    Your newly generated CA signed certificate is now available at `/etc/letsencrypt/live/res-<team-number>.do.dns-school.org/fullchain.pem`. The key matching this certificate is located at `/etc/letsencrypt/live/res-<team-number>.do.dns-school.org/privkey.pem`. Time to tell Unbound where to find these files.

27. Add these lines to your Unbound configuration:
    
        tls-service-pem: "/etc/letsencrypt/live/res-<team-number>.do.dns-school.org/fullchain.pem"
        tls-service-key: "/etc/letsencrypt/live/res-<team-number>.do.dns-school.org/privkey.pem"
        port: 853

    Over TCP on port 853 only TLS connection are will be accepted by Unbound now. It is however still possible to send unencrypted queries over UDP to port 853, let's disable UDP to the client to make sure all our queries to Unbound will be encrypted.

28. In the Unbound configuration:

        do-udp: no
        udp-upstream-without-downstream: yes

    Now that Unbound (only) accepts DNS queries over TLS we should change the stubby configuration to use TLS for the outgoing queries.

29. Edit you stubby configuration to always send queries over a TLS connection:
    ```
    dns_transport_list:
      - GETDNS_TRANSPORT_TLS
    ```

Because we requested a certificate that is signed by a trusted CA we can use the CAs store that is (probably) already on your machine for the authentication.

30. Edit your stubby.conf to only send queries when the TLS connection is authenticated, and specify the location of the CAs you trust:
    ```
    tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
    tls_ca_path: "/etc/ssl/certs/"
    ```

31. Edit the `upstream_recursive_server` stubby configuration to specify the domain name in the certificate that will be used for authentication:
	```
	upstream_recursive_servers:
	 - address_data: <your-Unbound-IP-address>
	   tls_auth_name: "res-<team-number>.do.dns-school.org"
	```
32. Send a query to stubby and observe using whireshark the data on the wire between stubby and Unbound

<!---
***TODO, (as bonus?):***
 - better TCP performance
   - stubby: idle_timeout
   - unbound: incoming-num-tcp, tcp-idle-timeout
   - TCP fasty open
 - android Pie
 - Monitoring
 - Cert renewal**
-->


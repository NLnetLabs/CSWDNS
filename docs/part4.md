% OpenDNSSEC Lab

## Editing the OpenDNSSEC Configuration

The configuration needs to be adjusted to better fit this setup.

1. Open the configuration for editing:

        /etc/opendnssec/conf.xml

    The repository list was adjusted in a previous lab.

2. We will be rolling keys in a rapid pace, burning up a lot of keys in a
   year.  The default setting is to pre-generate keys for a year, which
   will take a long time with so many keys.  So we want to decrease this by
   modifying the setting AutomaticKeyGenerationPeriod to:

        <AutomaticKeyGenerationPeriod>P2D</AutomaticKeyGenerationPeriod>

3. There is only one core on the lab machine and the performance was not increased by using multiple threads. For this lab, will then only use one thread for the Signer in OpenDNSSEC.

        <WorkerThreads>1</WorkerThreads>
        <SignerThreads>1</SignerThreads>

4. Save the file and exit.

5. Setup the KASP database:

        ods-enforcer-db-setup

    And answer yes.

## Creating a Policy

We will use the provided KASP policy "lab". It uses very low values on the timing parameters, just so that key rollovers will go faster in this lab environment.

1. Open the kasp.xml file:

        /etc/opendnssec/kasp.xml

2. The policy we're going to use is called "lab", it is already defined beginning at the following statement:

        <Policy name="lab">

3. Signatures are set to have a short lifetime:

        <Signatures>
          <Resign>PT10M</Resign>
          <Refresh>PT30M</Refresh>
          <Validity>
            <Default>PT1H</Default>
            <Denial>PT1H</Denial>
          </Validity>
          <Jitter>PT1M</Jitter>
          <InceptionOffset>PT3600S</InceptionOffset>
          <MaxZoneTTL>PT300S</MaxZoneTTL>
        </Signatures>

4. The TTL and safety margins for the keys are also lower:

        <TTL>PT300S</TTL>
        <RetireSafety>PT360S</RetireSafety>
        <PublishSafety>PT360S</PublishSafety>

5. Set the KSK lifetime to 2 hours and the ZSK to 1 hours. Let's change the
   algorithms of both the KSK and ZSK to ECDSAP256SHA256 (algorithm 13):

        <KSK>
          <Algorithm length="256">13</Algorithm>
          <Lifetime>PT2H</Lifetime>
          <Repository>SoftHSM</Repository>
        </KSK>

        <ZSK>
          <Algorithm length="256">13</Algorithm>
          <Lifetime>PT1H</Lifetime>
          <Repository>SoftHSM</Repository>
        </ZSK>

6. The values for the SOA can be found in the zone we created earlier. We will use unixtime as the serial counter, like we did when signing using ldns.

        <Zone>
          <PropagationDelay>PT300S</PropagationDelay>
          <SOA>
            <TTL>PT60S</TTL>
            <Minimum>PT60S</Minimum>
            <Serial>unixtime</Serial>
          </SOA>  
        </Zone>

7. And these values are from the parent zone:

        <Parent>
          <PropagationDelay>PT5M</PropagationDelay>
          <DS>
            <TTL>PT5M</TTL>
          </DS>
          <SOA>
            <TTL>PT5M</TTL>
            <Minimum>PT1M</Minimum>
          </SOA>
        </Parent>

8. Save and exit.

9. Verify that the KASP looks ok. The database has not been created yet, you will thus get a warning about this.

        ods-kaspcheck

   OpenDNSSEC will warn you that when you use Y (for Year) in duration fields, it is interpreted as 365 days.

## Start OpenDNSSEC

1.  At this point we should start the OpenDNSSEC daemons.  Both enforcer and signer daemons are started using:

        ods-control start


2.  Be sure to monitor the system log for any error conditions, some problems can only be reported once the daemons are already in the background.

        tail /var/log/syslog

3.  Import the initial KASP in OpenDNSSEC:

        ods-enforcer policy import

## Add and sign the Zone

Zones can be added in two ways, either by command line or by editing the zonelist.xml.  The command line is the one for now. We will create a new zonfile for this exercise.

1.  Create a zonefile called `ods-<name>`. The domain name for this zone will
   be `ods-<name>.bangkok.lol`. It might be easiest to copy your first (unsigned!) zone and adapt values.

2.  Add the zone to the enforcer which will in turn inform the zone to be signed:

        ods-enforcer zone add --zone ods-<name>.bangkok.lol --policy lab \
                    --input /etc/nsd/ods-<name> \
                    --output /etc/nsd/ods-<name>.signed

3.  Check the syslog to see that the two daemons started, that the signconf was generated, and that Signer engine signed the zone:

        tail -n 100 /var/log/syslog

4.  Have a look on the signconf:

        /var/lib/opendnssec/signconf/ods-<name>.bangkok.lol.xml

5.  Have a look on the signed zone file:

        /etc/nsd/ods-<name>.signed

6.  Add the newly created signed zone to the NSD configuration:

```
	zone:
          name: "ods-<name>.bangkok.lol"
          zonefile: /etc/nsd/ods-<name>.signed
```

Instruct NSD to reload the nsd.conf configuration:

    	nsd-control reconfig

## Publishing the DS RR

The zone is now signed and we have verified that DNSSEC is working. It is then time to publish the DS RR.

1.  Wait until the KSK is ready to be published in the parent zone:

        ods-enforcer key list -v

2.  Show the DS RRs that we are about to publish. Notice that they share the key tag with the KSK:

        ods-enforcer key export --zone ods-<name>.bangkok.lol --ds

3.  Add the DS records to your unsigned zone (`ods-<name>`) and replace the DS
    type with `CDS`, like you did before when signing with ldns.

    Now resign our zone and instuct NSD to load the latest version:
    ```
    ods-signer sign ods-<name>.bangkok.lol
    nsd-control reload
    ```

4.  Wait until the DS has been updated. Check the DS with the following command:

        dig @ns.bangkok.lol. ods-<name>.bangkok.lol DS

5.  It is now safe to tell the Enforcer that it has been seen. Replace KEYTAG with the keytag of your current KSK.

        ods-enforcer key ds-seen --zone ods-<name>.bangkok.lol --keytag KEYTAG

6.  The KSK is now considered as active. Check the key list with the following command:

        ods-enforcer key list

7. Verify that we can query the zone from your Unbound resolver. The AD-flag should be set:

        dig +dnssec ods-<name>.bangkok.lol @res-<team>.do.dns-school.org

## KSK Rollover

The KSK rollover is usually done at the end of its lifetime. But a key rollover can be forced before that by issuing the rollover command.

1.  Check how much time is left before the KSK should be rolled:

        ods-enforcer key list

2.  We will now force a key rollover. If a key rollover has been initiated then this command will be ignored:

        ods-enforcer key rollover --zone ods-<name>.bangkok.lol --keytype KSK

3.  Wait until the new KSK is ready. It should be maximum 10 minutes. If it is longer than that, then you probably missed to adjust a value in your KASP. Update the KASP to match the LAB policy given here in the document.

        ods-enforcer key list -v

4.  The DS RRs can be exported to the parent once the new KSK is ready.

    Get the new DS record using:

        ods-enforcer key export --ds --zone ods-<name>.bangkok.lol

    Add the DS record to your unsigned zone, change the RR type to CDS. After
    that you have to resign your zone and reload NSD, like you did before.

5.  Wait until the DS has been updated.

        dig @ns.bangkok.lol. ods-<name>.bangkok.lol DS

6. It is now safe to tell the Enforcer that it has been seen:

        ods-enforcer key ds-seen --zone ods-<name>.bangkok.lol --keytag KEYTAG

7. The new KSK is now considered as active.

        ods-enforcer key list

8. Reload the zone contents in NSD to have the newly signed zone.

        nsd-control reload

9. Verify that we can query the zone from the *resolver* machine.

        dig +dnssec ods-<name>.bangkok.lol @res-<team>.do.dns-school.org

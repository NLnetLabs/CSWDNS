% SoftHSM

This excercise needs to be done on the machine auth-\<nr\>.do.dns-school.org.
Be sure you are on the right machine.

HSMs are used for storing the keys securely and for acceleration. SoftHSM
is a generic software-only HSM, which is perfectly suitable for us. This
material is based on SoftHSM version 2.

1.  Start with installing SoftHSM version 2.

        apt install softhsm2

2.  Have a look at SoftHSM's token configuration in:

        /etc/softhsm/softhsm2.conf

    There is no editing needed at this point but note that the storage path and options
    are specified here.  It is possible to configure multiple tokens, although this is not
    something we will utilize in this exercise.

3.  Next task is to initialize the token. The label should be unique
    for each token (e.g., "KSK" and "ZSK"). In the example below we will
    configure a single token (at slot 0) named "OpenDNSSEC".

        softhsm2-util --init-token --slot 0 --label OpenDNSSEC

    You will be asked for a user PIN and a security officer SO-PIN number.
    These are needed later and cannot be retrieved later from the system.

4.  Verify the initialization.

        softhsm2-util --show-slots

    Note that SoftHSM will always show an uninitialized token in addition
    to the one you initialized. This is deliberate.  Depending on the exact
    version of SoftHSM2 there may also be another security feature happening
    with the slot ID.

# Install OpenDNSSEC

We won't immediately start using OpenDNSSEC, but some utilities packaged
with OpenDNSSEC can be useful.  Also we need to configure SoftHSM in
OpenDNSSEC.

1.  Install OpenDNSSEC on auth-\<nr\>.do.dns-school.org. using;

        apt install opendnssec opendnssec-doc opendnssec-enforcer-sqlite3

# HSM Testing and Benchmarking

It is always good to verify the functionality of the HSM before starting
to sign your zone. There are some tools available with OpenDNSSEC which
will verify the interoperability.

1.  OpenDNSSEC cannot access your tokens, which you will see with this command.

        ods-hsmutil info

2.  You need to configure your tokens in OpenDNSSEC. The repository name
    is what OpenDNSSEC uses to identify the tokens internally. Note that
    the repository name is not the same as the HSM token label.

        /etc/opendnssec/conf.xml

    This file already contains a respository with `OpenDNSSEC` as token label.
    Set the PIN here to the User PIN set used when initializing the token.

        <Repository name="SoftHSM">
          <Module>/usr/lib/softhsm/libsofthsm2.so</Module>
          <TokenLabel>OpenDNSSEC</TokenLabel>
          <PIN>XXXX</PIN>
          <SkipPublicKey/>
        </Repository>

3.  Now it is possible for OpenDNSSEC to access the tokens.

        ods-hsmutil info

4.  Try generating keys and signatures.

        ods-hsmutil test SoftHSM

5.  There is also a tool which will perform speed tests on the HSM.

        ods-hsmspeed -r SoftHSM -i 1000 -s 2048 -t 1

Real "hardware" HSM do several throusands sigatures per second.

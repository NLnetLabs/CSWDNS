#!/usr/bin/bash

#
# Create bangkok.lol.delegations
# Run ~/virtual-school/mk-bangkok.lol.delegations.sh > /etc/nsd/zones/bangkok.lol.delegations
# Then edit /etc/nsd/zones/bangkok.lol.delegations and do nsd-control reload
#
cat << ENTRY
\$ORIGIN bangkok.lol
\$TTL 60

ENTRY
for n in $(eval echo {0..$(awk '/^num_vms/{print$3-1}' ${0%/*}/terraform.tfvars)})
do
	AUTH_A=`dig auth-$n.do.dns-school.org A +short`
	AUTH_AAAA=`dig auth-$n.do.dns-school.org AAAA +short`
cat << ENTRY
team-$n		NS	ns.team-$n
ns.team-$n	A	$AUTH_A
ns.team-$n	AAAA	$AUTH_AAAA
ENTRY
done

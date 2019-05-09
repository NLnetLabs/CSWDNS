#!/usr/bin/bash

#
# Create teams.html
# Run ~/virtual-school/mk-teams.html.sh > /var/www/html/teams.shtml
# Then edit /var/www/html/teams.shtml
#
cat << HEADER
<html>
<head>
<title>Teams!</title>
<style>
.resips { visibility: hidden; }
table {
	border-spacing: 0;
	border-collapse: collapse;
}
th {
	border-bottom: 2px solid black;
}
td {
	border-top: 1px solid black;
}
.odd { background-color: #F0F0F0; }
.even { background-color: #F8F8F8; }
</style>
</head>
<body>
    <!--#include virtual="/menu.html" -->
<table>
<colgroup>
<col style="width: 5em" />
<col style="width: 10em" />
<col style="width: 11.5em" />
<col style="width: 11.5em" />
<col style="width: 10em" />
</colgroup>
<thead>
<tr class="header">
<th style="text-align: center;">Team</th>
<th style="text-align: center;">Members</th>
<th style="text-align: left;">Resolver</th>
<th style="text-align: left;">Authoritative</th>
<th style="text-align: right;">Domains</th>
</tr>
</thead>
<tbody>
HEADER
for n in $(eval echo {0..$(awk '/^num_vms/{print$3-1}' ${0%/*}/terraform.tfvars)})
do
	RES_A=`dig res-$n.do.dns-school.org A +short`
	RES_AAAA=`dig res-$n.do.dns-school.org AAAA +short`
	AUTH_A=`dig auth-$n.do.dns-school.org A +short`
	AUTH_AAAA=`dig auth-$n.do.dns-school.org AAAA +short`
	if [ "$ODD" = "odd" ]
	then
		ODD=even
	else
		ODD=odd
	fi
cat << ENTRY
<tr class="$ODD">
<td style="text-align: center;">team-$n</td>
<td style="text-align: center;">&nbsp;</td>
<td style="text-align: left; vertical-align: top;">res-$n.do.dns-school.org <span class="resips">$RES_A $RES_AAAA</span></td>
<td style="text-align: left; vertical-align: top;">auth-$n.do.dns-school.org $AUTH_A $AUTH_AAAA</td>
<td style="text-align: right;">.bangkok.lol</td>
</tr>
ENTRY
done
cat << FOOTER
</tbody></table></body>
FOOTER


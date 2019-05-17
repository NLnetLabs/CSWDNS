% Introduction and access to lab environment

Participants to this course are divided into teams of 2 to 3 participants,
in order to have 10 to 15 teams.  Teams are numbered from 0 till 15,
team-0 is reserved for demonstration purposes and is used
throughout this description.  Each team is given access to its own
set of servers, which is suffixed with -*\<team nr\>* .

Each of the servers is given a specific role, one should not mix these
roles.  Two of these servers are:

- res-0.do.dns-school.org
- auth-0.do.dns-school.org

The machine `res-0` will play the role of a caching recursive DNS
resolver.  The `auth-0` machine will
play the role of the authoritative DNS server for your team.

You can see the addresses and names of the servers of your team on the [teams
page](teams.shtml).

To which team you belong will be determined during the course.
You will also be working with a domain of your liking within the `bangkok.lol`
domain.

## Connecting to your servers

Use an SSH client (such as OpenSSH or [PuTTY](https://www.chiark.greenend.org.uk/~sgtatham/putty/)) to connect to the res-*\<team nr\>* 
and auth-*<team nr *> machines.  As username you should use `root`. 
The password will be shared with you in the class room.

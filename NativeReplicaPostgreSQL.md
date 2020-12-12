# Tutorial Set Up Physical Streaming Replication with PostgreSQL 12 on Ubuntu 16.04/20.04

## Prerequisites

- Two separate machines Ubuntu 16.04/20.04 machines;
  one referred to as the **primary** and the other referred to as the **replica**.
  (Tutorial [Initial Server Setup with Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-20-04).
- Your firewalls configured to allow HTTP/HTTPS and traffic on port 5432-the default port used by PostgreSQL 12.
- PostgreSQL 12 running on both Ubuntu Servers. You can follow steps by steps in install.sh file.

## Step 1 - Set up Hostname

Assume, the **master server** with IP address '10.0.2.7', hostname 'server-01'. And the **slave server** with IP address '10.0.2.8', hostname 'server-02'.

On the **master server**(include **primary** database), append address of the replica configuration to the /etc/hosts file:

```conf
<slave_ip_addess> <slave_host_name>
## eg: 10.0.2.8    server-02
```

Same on **slave server** (include **replica** database):

```conf
<master_ip_address> <slave_host_name>
## eg: 10.0.2.7    server-01
```

## Step 2 - Configuring the Primary Database to Accept Connections

Configue the **primary** database to allow your **replica** database(s) to connect.
Edit the listen_address configuration parameter on /etc/postgresql/12/main/postgresql.conf on the primary database.

```conf
# /etc/postgresql/12/main/postgresql.conf
...
listen_address = '<primary_ip_address>' ## eg: listen_address = '10.0.2.7'
...
```

## Step 3 - Create a Special Role with Replication Permissions

Create a role in **primary** database that has permission to replicate the database.
In **slave server**, **replica** will use this role when connecting to the **primary**.
**Replica** won't be able to manipulate any data on the **primary**; it will only be able to replicate the data.

First, connect to the database cluster as the `postgres` user:

```bash
sudo -u postgres psql
```

To create a role, use `CREATE ROLE` command:

```conf
postgres=# CREATE ROLE <name_role> WITH REPLICATION PASSWORD '<password>' LOGIN;
// Output: CREATE ROLE
// eg: CREATE ROLE replica WITH REPLICATION PASSWORD  'replica@' LOGIN;
// create role name is replica, and role password is replica@
```

Edit the `/etc/postgresql/12/main/pg_hba.conf` configuration file to allow your **replica** to access cluster. Before, exit the PostgreSQL command prompt:

```
postgres=# \q
```

Now, open the `/etc/postgresql/12/main/pg_hba.conf` configuration file and edit:

```conf
# /etc/postgresql/12/main/pg_hba.conf
...
host 	replication		<name_role>		<replica_ip>/32		md5
# eg:
# host	replication 	replica			10.0.2.8/32			md5
...
```

This ensure the `host` value means to accept non-lobal connections via plain or SSL-encrypted TCP/IP sockets.
`replication` is the name of the special pseudo-database that PostgreSQL uses for replication.
If you want to have more than one **replica**, just add the same line again to the end of the file with the IP addess of your other **replica**.

Restart the **primary** to ensure theses changes has applied:

```bash
$ sudo systemctl restart postgresql
```

### Step 4 - Backing Up the Primary Cluster on the Replica

Perform a physical backup of the **primary** cluster's data files into the **replica's** data directory.
To do this, you'll first clear out all the files in the **replica's** data directory(default directory for PostgreSQL on Ubuntu is `/var/lib/postgresql/12/main/`.

Find PostgreSQL's data directory by running the following command on the **replica's** database:

```bash
$ sudo -u postgres psql
postgres=# SHOW data_directory;
postgres=# \q
```

Clear data directory:

```bash
$ sudo -u postgres rm -rf /var/lib/postgresql/12/main/*
## if this command not regulary run, please manualy clear them with postgres permission
```

Data directory will own by postgres user and is empty. Next step, you can perform a physical backup of the **primary's** data files.
Using the utility `pg_basebackup` on the **replica**:

```bash
$ sudo -u postgres pg_basebackup -h <primary_ip> -p 5432 -U <name_role> -D /var/lib/postgresql/12/main/ -Fp -Xs -R
eg: sudo -u postgres pg_basebackup -h 10.0.2.7 -p 5432 -U replica -D /var/lib/postgresql/12/main/ -Fp -Xs -R
```

- The `-h` option specifies a non-local host. Here, you need to enter the IP addess of your server with the **primary** cluster
- The `-p` option specifies the port number it connets to on the **primary** server(default is 5432).
- The `-U` option allows you to specify the user you connect to the **primary** cluster as(role name that created in the previous step).
- The `-D` flag is the output directory of the backup. This is your **replica's** data directory that you emptied just before.
- The `-Fp` specifies the data to be the outputted in the plain format instead of as a `tar` file.
- The `-Xs` strams the contents of the WAL log as the backup of the **primary** is performed.
- The -R creates an empty file, named `standby.signal`, in the **replica's** data directory, and allow **replica** cluster know that it should operate as a standby server. The -R option also adds the connection information about the **primary** server to the postgresql.auto.conf file(this is a special configuration file that is read whenever the regular `postgresql.conf` file is read, but the values in the `.auto` file override the values in the regular configuration file.

The `pg_basebackup` command connects to the **primary** that it requires to begin replication. Next, you'll be putting the **replica** into standby mode and start replicating.

## Step 5 - Restarting and Testing the Clusters

Restart the **replica** database cluster to put it into standby mode:

```bash
$ sudo systemctl restart postgresql
```

Check the **replica** has connected to the **primary** and the **primary** is streaming, connect to the **primary** database cluster by running:

```bash
$ sudo -u postgres psql
postgres=# SELECT client_addr, state FROM pg_stat_replication;
```

Running this query on the **primary** cluster will output something similar to the following:

```bash
Output
    client          |    state
--------------------+--------------
   <replica_IP>     |   streaming
```

## References

- [Tutorial reference](https://www.digitalocean.com/community/tutorials/how-to-set-up-physical-streaming-replication-with-postgresql-12-on-ubuntu-20-04)

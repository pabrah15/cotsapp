# caltech

This repo contains the habitat package for Calltech server. This package is intended to facilitate the automated install of tec software . This repo also contains a [Vagrant](https://www.vagrantup.com/docs/) directory which can be used to test the package in a developer's local environment.


## Maintainers



## Type of Package

Service Package.

## Usage

This package is meant to be installed in a standalone service, and not to act as as dependency for other services.

## Topologies

This plan is intended to use the `standalone` topology.

### Standalone

*(This is only required for service packages, not [binary wrapper packages](https://www.habitat.sh/docs/best-practices/#binary-wrapper-packages))*

Check out [the Habitat docs on standalone](https://www.habitat.sh/docs/using-habitat/#standalone) for more details on what the standalone topology is and what it does.

If this plan can be used with the standalone topology, how do you do it?

Checkout [the core/postgresql](https://github.com/habitat-sh/core-plans/tree/master/postgresql) README for a good example of this.

## Update Strategies

Checkout [the update strategy documentation](https://www.habitat.sh/docs/using-habitat/#update-strategy) for information on the strategies Habitat supports.

Currently this package has not been tested to work with any update strategy other than `none`

### Configuration Updates

See the `default.toml` file in this repository to understand all of the possible configuration values for this package. Descriptions of each variable purpose are defined below.

```
# Use this file to templatize your application's native configuration files.
# See the docs at https://www.habitat.sh/docs/create-packages-configure/.
# You can safely delete this file if you don't need it.

user         = "altec"                      <----- The user who owns the accurev install directory and executes the installation script
userid       = 9999252                          <----- The user's unix id
group        = "altec"                      <----- The group who owns the accurev install directory and executes the installation script
#INSTALL_DIR = "/proj/fccaltec/tmp[VERSION]"  <----- Path to store install files during install

[caltec]
port         = 6599 <----- The port the report server listens on
orgname      = "Git"
dbtype       = "oracle" <----- The type of the DB (Oracle, MSSQL etc)


[db]
client_dir   = "oraclnt"
client_number= "client_1"
dbUser       = "tec" <----- The global administrator username for Caltec's Oracle database
dbPort       = 1555 <----- The port that the database listens on
dbVersion    = "12.2.0"
dbPassword   = "" 
dbHost       = ""
fqdn         = ""
dbName       = "dfXXXXS"
tspacedir    = "tspacedir"



```

## Scaling

This service is not intended to scale at this time.

## Monitoring

This package has been equipped with health checks that are fed to the supervisor log output. Aggregation of these logs is dependent on Ford policies which are as of today, unknown.

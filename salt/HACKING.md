# Hacking

Site specific deployment values
===============================

The default site configuration is detailed in the `/root/opensds-installer/salt/srv/pillar/site.j2` file. This is the primary interface for customizing the deployment experience for OpenSDS installer on Salt. Typically you may want to modify ip addresses, or more rarely set a specific release (urls, hashsums, revisions). This `site.j2` file is consumed by [saltstack-formulas/opensds-formula](https://github.com/saltstack-formulas/opensds-formula) during deployments. Please take care not to corrupt the file with bad syntax if you need to make updates.

The secondary interface for customizations is the `/root/opensds-installer/salt/srv/pillar/opensds.sls` yaml file. Again caution should be exercised if you make any updates.

All other files should be left alone.

Flexible Deployments
=====================

You can install OpenSDS in a more modular fashion. By default all components are installed on the local machine; however Salt has powerful features for distributed deployment management so the shipped solution could be extend for flexible deployments (salt integration knowledge is useful).

The following commands are provided (or -r for removal).
```
 vi ./srv/pillar/opensds.sls       ### Tweak something

 vi site.js                        ### Tweak IP Addresses

 ./install.sh -i infra             ### docker, packages, etc

 ./install.sh -i database

 ./install.sh -i sushi

 ./install.sh -i let

 ./install.sh -i gelato

 ./install.sh -i hotpot

 ./install.sh -i dock

 ./install.sh -i gelato

 ./install.sh -i dashboard

```
However the fastest, verified, and recommend approach remains the `./install.sh -i opensds` command.

Upstream support
================

The upstream [saltstack-formulas/opensds-formula](https://github.com/saltstack-formulas/opensds-formula) is specifically designed for extensibility.

To request upstream enhancements or bug fixes please raise a github issue for consideration.

Code contributions are welcome!


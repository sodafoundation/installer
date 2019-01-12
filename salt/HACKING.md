# Hacking

## Install OpenSDS with Salt in modular fashion

Modular commands-
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

COP5615 Project 2 – Gossip Simulator

Please use the following format to run the application:
./my_program numNodes topology algorithm

# Team members:
Ramchandra Kulkarni 	- 98930922
Tongyu Wang 		    - 88941679

# What is working:
topology: full, line, rand2D, 3Dtorus, honeycomb and randhoneycomb
algorithm: gossip, push-sum.

# What is the largest network that is managed to deal with for each type of topology and algorithm:

Gossip:

Topology | Size | Messages to convergence
--- | ---:| ---:
Full | 16384 | 359373
Line | 4096 | 2212317
Rand2D | 16384 | 370808
3Dtorus | 16384 | 6237405
Honeycomb | 16384 | 6293364
Randhoneycomb | 16384 | 2093724



Push-Sum:

Topology | Size | Messages to convergence
--- | ---:| ---:
Full | 10000 | 461912
Line | 1024 | 121469
Rand2D | 16384 | 736094
3Dtorus | 16384 | 1340708
Honeycomb | 16384 | 1595401
Randhoneycomb | 16384 | 1122944
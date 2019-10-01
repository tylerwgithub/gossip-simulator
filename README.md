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
Full | 16,384 | 330,318
Line | 4,096 | 2,195,643
Rand2D | 32,768 | 889,462
3Dtorus | 16,384 | 5,185,458
Honeycomb
Randhoneycomb



Push-Sum:

Topology | Size | Messages to convergence
--- | ---:| ---:
Full | 10,000 | 478,433
Line | 1,024 | 110,897
Rand2D | 16,384 | 727,928
3Dtorus | 32,768 | 2,543,005
Honeycomb
Randhoneycomb
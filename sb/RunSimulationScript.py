print "********************************************";
print "*                                          *";
print "*             TOSSIM Script                *";
print "*                                          *";
print "********************************************";

import sys;
import time;

from TOSSIM import *;

t = Tossim([]);

if len(sys.argv) != 4: 
	print "Usage: <serial_forwarder> <stop_mote> <number_of_ticks>"
	print "\t<serial_forwarder>: Y to use the serial forwarder, N otherwise"
	print "\t<stop_mote>: Y to stop mote 3, N otherwise"
	sys.exit()


sf = SerialForwarder(9001);
throttle = Throttle(t, 10);

sf_process=True;
sf_throttle=True;
stop_mote=True;
number_of_ticks = 150; 

if sys.argv[1] == "N": 
	sf_process = False
	sf_throttle = False
	
if sys.argv[2] == "N":
	stop_mote = False 
	

try: 
	number_of_ticks = int(sys.argv[3])
except e:
	pass

topofile="topology.txt";
modelfile="meyer-heavy.txt";


print "Initializing mac....";
mac = t.mac();
print "Initializing radio channels....";
radio=t.radio();
print "    using topology file:",topofile;
print "    using noise file:",modelfile;
print "Initializing simulator....";
t.init();


#simulation_outfile = "simulation.txt";
#print "Saving sensors simulation output to:", simulation_outfile;
#simulation_out = open(simulation_outfile, "w");

#out = open(simulation_outfile, "w");
out = sys.stdout;

#Add debug channel
print "Activate debug message on channel init"
t.addChannel("init",out);
print "Activate debug message on channel boot"
t.addChannel("boot",out);
print "Activate debug message on channel kinetic_sensor"
t.addChannel("kinetic_sensor",out);
print "Activate debug message on channel position_sensor"
t.addChannel("position_sensor",out);
print "Activate debug message on channel complete_sensor"
t.addChannel("complete_sensor",out);
print "Activate debug message on channel app_kin_sensor"
t.addChannel("app_kin_sensor",out);
print "Activate debug message on channel app_sensor"
t.addChannel("app_sensor",out);
print "Activate debug message on channel app_pos_sensor"
t.addChannel("app_pos_sensor",out);
print "Activate debug message on channel radio"
t.addChannel("radio",out);
print "Activate debug message on channel control"
t.addChannel("control",out);
print "Activate debug message on channel alert"
t.addChannel("alert",out);
print "Activate debug message on channel serial"
t.addChannel("serial",out);

print "Creating node 1...";
node1 =t.getNode(1);
time1 = 0*t.ticksPerSecond(); #instant at which each node should be turned on
node1.bootAtTime(time1);
print ">>>Will boot at time",  time1/t.ticksPerSecond(), "[sec]";

print "Creating node 2...";
node2 = t.getNode(2);
time2 = 0*t.ticksPerSecond();
node2.bootAtTime(time2);
print ">>>Will boot at time", time2/t.ticksPerSecond(), "[sec]";

print "Creating node 3...";
node3 = t.getNode(3);
time3 = 0*t.ticksPerSecond();
node3.bootAtTime(time3);
print ">>>Will boot at time", time3/t.ticksPerSecond(), "[sec]";

print "Creating node 4...";
node4 = t.getNode(4);
time4 = 0*t.ticksPerSecond();
node4.bootAtTime(time4);
print ">>>Will boot at time", time4/t.ticksPerSecond(), "[sec]";


print "Creating radio channels..."
f = open(topofile, "r");
lines = f.readlines();
for line in lines:
  s = line.split();
  if (len(s) > 0):
    print ">>>Setting radio channel from node ", s[0], " to node ", s[1], " with gain ", s[2], " dBm"
    radio.add(int(s[0]), int(s[1]), float(s[2]))


#creation of channel model
print "Initializing Closest Pattern Matching (CPM)...";
noise = open(modelfile, "r")
lines = noise.readlines()
compl = 0;
mid_compl = 0;

print "Reading noise model data file:", modelfile;
print "Loading:",
for line in lines:
    str = line.strip()
    if (str != "") and ( compl < 10000 ):
        val = int(str)
        mid_compl = mid_compl + 1;
        if ( mid_compl > 5000 ):
            compl = compl + mid_compl;
            mid_compl = 0;
            sys.stdout.write ("#")
            sys.stdout.flush()
        for i in range(1, 5):
            t.getNode(i).addNoiseTraceReading(val)
print "Done!";

for i in range(1, 5):
    print ">>>Creating noise model for node:",i;
    t.getNode(i).createNoiseModel()

print "Start simulation with TOSSIM! \n\n\n";

starting_time = t.time()
turn_off_time = t.time()
turn_off = False
done = False

if sf_process: sf.process();
if sf_throttle: throttle.initialize();

while(t.time() < (starting_time + number_of_ticks*t.ticksPerSecond())):
	t.runNextEvent();
	if sf_throttle: throttle.checkThrottle();
	if sf_process: sf.process();
	if(stop_mote and (t.time() > starting_time + 60*t.ticksPerSecond()) and turn_off == False):
		print "Turning mote 3 off."; 
		turn_off_time = t.time()
		node3.turnOff()
		turn_off = True
	if(stop_mote and t.time() > turn_off_time + 90*t.ticksPerSecond() and turn_off == True and done == False):
		print "Turning mote 3 on."; 
		node3.turnOn()
		print "Node 3 turned on"
		done = True


print "\n\n\nSimulation finished!";

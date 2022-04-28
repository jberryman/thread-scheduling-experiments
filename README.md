Scheduling/migration experiments

### descheduling2.hs

compile and run:

```
ghc-9.2.1 -O2 -threaded -fforce-recomp -eventlog -rtsopts -with-rtsopts="-l-asu" descheduling2.hs
./descheduling2 +RTS -N4 -C0.0005
threadscope descheduling2.eventlog
```

The only odd thing I see here is that (looking at “Raw events”) a thread
(numbers 8 and 9 in attached eventlog) is descheduled after its time slice is
up only to be rescheduled again on the same capability (because there is no
other work to be done). If the time stamps are accurate this cycle takes only
1us which is very small compared to the default `-C` of 20ms; But I wonder
whether an optimization for this case (don’t deschedule when nothing else to
do) would be beneficial when trying to use a very small context switch
interval?

### fairness.hs

```
ghc-9.2.1 -O2 -threaded -fforce-recomp -eventlog -rtsopts fairness.h
```

Here I'm trying to  simulate a simple web server that forks a thread per
request. We do one unit of work between each “incoming request” (Basically just
for the purpose of spacing them out), and each forked thread does two units of
work. So in the ideal case this could run with stable latency on 3
capabilities, and we expect in practice it to work that way with 4 capabilities
(where we’re no longer at theoretical max throughput).

One thing I noticed: it appears the scheduler uses a heuristic something like:
when `+RTS -Nx` , Once we have forked `x` threads, pause and migrate those
threads to other capabilities (This might happen far before the context switch
time limit has been reached). Can I get confirmation on that?

Interestingly by default with 4 capabilities we get high tail latency and work
accumulating (it seems). Threads in-flight at time that this thread was
started:

```
❯ ./fairness 10000 +RTS -N4 -l-asu  | grep START | datamash --field-separator=" " max 3 min 3 mean 3
7165 0 3536.1802
```

We can see inflight threads accumulating above. We also see the expected bad tail latencies:

```
❯ ./fairness 10000 +RTS -N4 -l-asu  | grep END | datamash --field-separator=" " max 3 min 3 mean 3
2.605889 0.001624 1.5178726752387
```

We can improve tail latency by bumping up the number of capabilities…

```
❯ ./fairness 10000 +RTS -N6 -l | grep END | datamash --field-separator=" " max 3 min 3 mean 3
0.00888 0.001019 0.0022005178
```

…But the odd thing is when we look at the event log for 4 capabilities and zoom
in on the graph, it looks very sparse (see `fairness_10000_+RTS_-N4_-l-asu.eventlog`), 
as though we're not making very good use of the capabilities for some reason
(could OS thread descheduling Or even processor sleep states have something to
do with it?) 

Using a much tighter context switch interval also greatly improves tail
latency:

```
❯ ./fairness 10000 +RTS -N4 -C0.0001 -l | grep END | datamash --field-separator=" " max 3 min 3 mean 3
0.002867 0.001062 0.0011733116
```

This graph is certainly denser, but I'm not sure exactly why that would be; It
seems as though with the default context switch interval, capabilities are
simply not picking up work promptly. See attached
`fairness_10000_+RTS_-N4_-l_-C0.0001.eventlog`


### descheduling.hs

Nothing to see here I think. Scheduling  and migration of threads all look
normal here for different combinations of context switch interval (-C)  and
capabilities (-N)

### cooperative_blocking.hs

Nothing to see here I think. I wanted to make sure that socket communication
was cooperative, so that recv could yield right away  without relying on the
context switch interval (This is the case, since it's backed by threadWaitRead)



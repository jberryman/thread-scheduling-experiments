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

module Main where

-- ghc-9.2.1 -O2 -threaded -fforce-recomp -eventlog -with-rtsopts="-C0.01 -I0 -l-asu" descheduling.hs 

import GHC.Clock
import Payload
import Text.Printf
import Control.Concurrent
import Data.IORef
import Debug.Trace
import Control.Monad

main :: IO ()
main = do
  counter <- newIORef 1
  done <- newEmptyMVar
  replicateM_ 100 $
    forkIO $ thread done counter
  takeMVar done

thread :: MVar () -> IORef Int -> IO ()
thread done counter = do
    n <- fmap tidInt myThreadId
    traceEventIO $ "START "<> (show n)
    payload 20 -- ~1ms
    traceEventIO $ "END "<> (show n)
    bef <- atomicModifyIORef' counter (\x-> (x+1,x))
    when (bef == 100) $ putMVar done ()

tidInt :: ThreadId -> Int
tidInt = read . last . words . show

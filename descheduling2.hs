module Main where

import GHC.Clock
import Payload
import Text.Printf
import Control.Concurrent
import Data.IORef
import Debug.Trace
import Control.Monad

main :: IO ()
main = do
  done1 <- newEmptyMVar
  done2 <- newEmptyMVar
  forkIO $ thread done1
  forkIO $ thread done2
  takeMVar done1
  takeMVar done2

thread :: MVar () -> IO ()
thread done = do
    n <- fmap tidInt myThreadId
    traceEventIO $ "START "<> (show n)
    payload 200 -- ~10ms
    traceEventIO $ "END "<> (show n)
    putMVar done ()

tidInt :: ThreadId -> Int
tidInt = read . last . words . show

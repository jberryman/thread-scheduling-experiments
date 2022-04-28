module Main where

import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.IORef
import Debug.Trace
import GHC.Clock
import Payload
import Text.Printf
import System.Environment

main :: IO ()
main = do
  counter <- newIORef 0

  [cnt] <- getArgs
  forM_ [1..(read cnt :: Int)] $ \_ -> do
    timeForked <- getMonotonicTime
    forkIO $ thread timeForked counter
    -- one unit of work pause
    payload_1ms

  threadDelay $ 1000*1000*2

payload_1ms :: IO ()
payload_1ms = void $ payload 20

thread :: Double -> IORef Int -> IO ()
thread timeForked inFlight = do
    n <- fmap tidInt myThreadId
    inflight <- atomicModifyIORef' inFlight (\x-> (x+1,x))
    putStrLn $ "START "<> show n<>" "<>show inflight

    -- two units of work:
    payload_1ms
    payload_1ms

    timeEnd <- getMonotonicTime
    let dur = printf "%.6f" $ timeEnd-timeForked

    putStrLn $ "END "<> show n<>" "<>dur
    atomicModifyIORef' inFlight (\x-> (x-1, ()))

tidInt :: ThreadId -> Int
tidInt = read . last . words . show

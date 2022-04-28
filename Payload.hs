{-# LANGUAGE BangPatterns #-}
module Payload (payload) where

import Control.Exception
import Data.List
import Control.Monad

-- tuned so `payload 20` is ~1ms on my machine:
--
-- ❯ for b in {1..1000}; do ./Main ; done | datamash max 1 min 1 mean 1
-- 0.001266	0.00051	0.00087263
--
-- should allocate n times (for yields)
payload :: Int -> IO Int
{-# NOINLINE payload #-}
payload n = do
    ns <- replicateM n (work 50000)
    evaluate $ sum ns

-- Allocates just an Int, w/ -O2
work :: Int -> IO Int
{-# NOINLINE work #-}
work timesN = evaluate $ sum [1..timesN]

{-# LANGUAGE CPP #-}
#if MIN_VERSION_transformers(0,5,6)
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Monad.RWS.Strict
-- Copyright   :  (c) Andy Gill 2001,
--                (c) Oregon Graduate Institute of Science and Technology, 2001
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  libraries@haskell.org
-- Stability   :  experimental
-- Portability :  non-portable (multi-param classes, functional dependencies)
--
-- Strict RWS monad that uses continuation-passing-style to achieve constant
-- space usage.
--
--      Inspired by the paper
--      /Functional Programming with Overloading and Higher-Order Polymorphism/,
--        Mark P Jones (<http://web.cecs.pdx.edu/~mpj/>)
--          Advanced School of Functional Programming, 1995.
--
-- /Since: mtl-2.3, transformers-0.5.6/
-----------------------------------------------------------------------------

module Control.Monad.RWS.CPS (
    -- * The RWS monad
    RWS,
    rws,
    runRWS,
    evalRWS,
    execRWS,
    mapRWS,
    withRWS,
    -- * The RWST monad transformer
    RWST,
    runRWST,
    evalRWST,
    execRWST,
    mapRWST,
    withRWST,
    -- * Strict Reader-writer-state monads
    module Control.Monad.RWS.Class,
    module Control.Monad.Trans,
    module Data.Monoid,
  ) where

import Control.Monad.RWS.Class

import Control.Monad.Trans
import Control.Monad.Trans.RWS.CPS (
    RWS, rws, runRWS, evalRWS, execRWS, mapRWS, withRWS,
    RWST, runRWST, evalRWST, execRWST, mapRWST, withRWST)

import Control.Monad
import Control.Monad.Fix
import Data.Monoid

#else
-- | This module ordinarily re-exports @Control.Monad.Trans.RWS.CPS@ from
-- @transformers >= 0.5.6@, which is not currently installed. Therefore, this
-- module currently provides nothing; use "Control.Monad.RWS.Lazy" or
-- "Control.Monad.RWS.Strict" instead.
module Control.Monad.RWS.CPS () where
#endif

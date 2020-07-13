{-# LANGUAGE CPP #-}
#if MIN_VERSION_transformers(0,5,6)
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Monad.Writer.Strict
-- Copyright   :  (c) Andy Gill 2001,
--                (c) Oregon Graduate Institute of Science and Technology, 2001
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  libraries@haskell.org
-- Stability   :  experimental
-- Portability :  non-portable (multi-param classes, functional dependencies)
--
-- Strict writer monads that use continuation-passing-style to achieve constant
-- space usage.
--
--      Inspired by the paper
--      /Functional Programming with Overloading and Higher-Order Polymorphism/,
--        Mark P Jones (<http://web.cecs.pdx.edu/~mpj/pubs/springschool.html>)
--          Advanced School of Functional Programming, 1995.
--
-- /Since: mtl-2.3, transformers-0.5.6/
-----------------------------------------------------------------------------

module Control.Monad.Writer.CPS (
    -- * MonadWriter class
    MonadWriter(..),
    listens,
    censor,
    -- * The Writer monad
    Writer,
    runWriter,
    execWriter,
    mapWriter,
    -- * The WriterT monad transformer
    WriterT,
    execWriterT,
    mapWriterT,
    module Control.Monad.Trans,
    module Data.Monoid,
  ) where

import Control.Monad.Writer.Class

import Control.Monad.Trans
import Control.Monad.Trans.Writer.CPS (
        Writer, runWriter, execWriter, mapWriter,
        WriterT, execWriterT, mapWriterT)

import Control.Monad
import Control.Monad.Fix
import Data.Monoid

#else
-- | This module ordinarily re-exports @Control.Monad.Trans.Writer.CPS@ from
-- @transformers >= 0.5.6@, which is not currently installed. Therefore, this
-- module currently provides nothing; use "Control.Monad.Writer.Lazy" or
-- "Control.Monad.Writer.Strict" instead.
module Control.Monad.Writer.CPS () where
#endif

{-# LANGUAGE CPP #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE UndecidableInstances #-}

{- |
Module      :  Control.Monad.Error.Class
Copyright   :  (c) Michael Weber <michael.weber@post.rwth-aachen.de> 2001,
               (c) Jeff Newbern 2003-2006,
               (c) Andriy Palamarchuk 2006
               (c) Edward Kmett 2012
License     :  BSD-style (see the file LICENSE)

Maintainer  :  libraries@haskell.org
Stability   :  experimental
Portability :  non-portable (multi-parameter type classes)

[Computation type:] Computations which may throw exceptions.

[Binding strategy:] Failure records information about the cause\/location
of the failure. Failure values bypass the bound function,
other values are used as inputs to the bound function.

[Useful for:] Building computations from sequences of functions that may fail
or using exception handling to structure error handling.

[Zero and plus:] Zero is represented by an empty error and the plus operation
executes its second argument if the first fails.

[Example type:] @'Either' 'String' a@

The Error monad (also called the Exception monad).
-}

{-
  Rendered by Michael Weber <mailto:michael.weber@post.rwth-aachen.de>,
  inspired by the Haskell Monad Template Library from
    Andy Gill (<http://web.cecs.pdx.edu/~andy/>)
-}
module Control.Monad.Error.Class (
    Error(..),
    MonadError(..),
    liftEither,
    tryError,
  ) where

import Control.Applicative (Applicative(pure))
import Control.Monad.Trans.Except (Except, ExceptT)
import Control.Monad.Trans.Error (Error(..), ErrorT)
import qualified Control.Monad.Trans.Except as ExceptT (throwE, catchE)
import qualified Control.Monad.Trans.Error as ErrorT (throwError, catchError)
import Control.Monad.Trans.Identity as Identity
import Control.Monad.Trans.List as List
import Control.Monad.Trans.Maybe as Maybe
import Control.Monad.Trans.Reader as Reader
import Control.Monad.Trans.RWS.Lazy as LazyRWS
import Control.Monad.Trans.RWS.Strict as StrictRWS
import Control.Monad.Trans.State.Lazy as LazyState
import Control.Monad.Trans.State.Strict as StrictState
import Control.Monad.Trans.Writer.Lazy as LazyWriter
import Control.Monad.Trans.Writer.Strict as StrictWriter

import Control.Monad.Trans.Class (lift)
import Control.Exception (IOException, catch, ioError)
import Control.Monad

#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ < 707
import Control.Monad.Instances ()
#endif

import Data.Monoid
import Prelude (Either(..), Maybe(..), either, (.), IO)

-- | Monads with a notion of exceptions which can be thrown and caught.
--
-- === Laws
--
-- @
-- 'catchError' ('throwError' e) h   = h e
-- 'catchError' ('catchError' m k) h = 'catchError' m (\\e -> 'catchError' (k e) h)
-- 'catchError' ('pure' a) h         = 'pure' a
-- 'catchError' (m '>>=' k) h        = 'tryError' m '>>=' 'either' h (\\x -> 'catchError' (k x) h)
--
-- 'catchError' m 'throwError'       = m
-- 'throwError' e '>>=' k            = 'throwError' e
-- @
class (Monad m) => MonadError e m | m -> e where
    -- | Throw an exception.
    throwError :: e -> m a

    {- | Handle an exception and return to normal execution.
    A common idiom is:

    > do { action1; action2; action3 } `catchError` handler

    where the @action@ functions can call 'throwError'.
    Note that @handler@ and the do-block must have the same return type.
    -}
    catchError :: m a -> (e -> m a) -> m a
#if __GLASGOW_HASKELL__ >= 707
    {-# MINIMAL throwError, catchError #-}
#endif

{- |
Lifts an @'Either' e@ into any @'MonadError' e@.

> do { val <- liftEither =<< action1; action2 }

where @action1@ returns an 'Either' to represent errors.

@since 2.2.2
-}
liftEither :: MonadError e m => Either e a -> m a
liftEither = either throwError return

-- | Catch an exception and return it in 'Left', or return a successful result
-- in 'Right'.
tryError :: (MonadError e m, Applicative m) => m a -> m (Either e a)
tryError m = catchError (fmap Right m) (pure . Left)

instance MonadError IOException IO where
    throwError = ioError
    catchError = catch

{- | @since 2.2.2 -}
instance MonadError () Maybe where
    throwError ()        = Nothing
    catchError Nothing f = f ()
    catchError x       _ = x

-- ---------------------------------------------------------------------------
-- Our parameterizable error monad

instance MonadError e (Either e) where
    throwError             = Left
    Left  l `catchError` h = h l
    Right r `catchError` _ = Right r

instance (Monad m, Error e) => MonadError e (ErrorT e m) where
    throwError = ErrorT.throwError
    catchError = ErrorT.catchError

{- | @since 2.2 -}
instance Monad m => MonadError e (ExceptT e m) where
    throwError = ExceptT.throwE
    catchError = ExceptT.catchE

-- ---------------------------------------------------------------------------
-- Instances for other mtl transformers
--
-- All of these instances need UndecidableInstances,
-- because they do not satisfy the coverage condition.

instance MonadError e m => MonadError e (IdentityT m) where
    throwError = lift . throwError
    catchError = Identity.liftCatch catchError

instance MonadError e m => MonadError e (ListT m) where
    throwError = lift . throwError
    catchError = List.liftCatch catchError

instance MonadError e m => MonadError e (MaybeT m) where
    throwError = lift . throwError
    catchError = Maybe.liftCatch catchError

instance MonadError e m => MonadError e (ReaderT r m) where
    throwError = lift . throwError
    catchError = Reader.liftCatch catchError

instance (Monoid w, MonadError e m) => MonadError e (LazyRWS.RWST r w s m) where
    throwError = lift . throwError
    catchError = LazyRWS.liftCatch catchError

instance (Monoid w, MonadError e m) => MonadError e (StrictRWS.RWST r w s m) where
    throwError = lift . throwError
    catchError = StrictRWS.liftCatch catchError

instance MonadError e m => MonadError e (LazyState.StateT s m) where
    throwError = lift . throwError
    catchError = LazyState.liftCatch catchError

instance MonadError e m => MonadError e (StrictState.StateT s m) where
    throwError = lift . throwError
    catchError = StrictState.liftCatch catchError

instance (Monoid w, MonadError e m) => MonadError e (LazyWriter.WriterT w m) where
    throwError = lift . throwError
    catchError = LazyWriter.liftCatch catchError

instance (Monoid w, MonadError e m) => MonadError e (StrictWriter.WriterT w m) where
    throwError = lift . throwError
    catchError = StrictWriter.liftCatch catchError

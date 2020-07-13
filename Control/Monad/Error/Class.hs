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

[Computation type:] Computations which may fail or throw exceptions.

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
    withError,
    handleError,
    mapError,
  ) where

import qualified Control.Exception
import Control.Monad.Trans.Except (Except, ExceptT)
import Control.Monad.Trans.Error (Error(..), ErrorT)
import qualified Control.Monad.Trans.Except as ExceptT (throwE, catchE)
import qualified Control.Monad.Trans.Error as ErrorT (throwError, catchError)
import Control.Monad.Trans.Identity as Identity
import Control.Monad.Trans.Cont as Cont
import Control.Monad.Trans.List as List
import Control.Monad.Trans.Maybe as Maybe
import Control.Monad.Trans.Reader as Reader
import Control.Monad.Trans.RWS.Lazy as LazyRWS
import Control.Monad.Trans.RWS.Strict as StrictRWS
import Control.Monad.Trans.State.Lazy as LazyState
import Control.Monad.Trans.State.Strict as StrictState
import Control.Monad.Trans.Writer.Lazy as LazyWriter
import Control.Monad.Trans.Writer.Strict as StrictWriter

#if MIN_VERSION_transformers(0,5,6)
import Control.Monad.Trans.RWS.CPS as CPSRWS
import Control.Monad.Trans.Writer.CPS as CPSWriter
#endif

import Control.Monad.Trans.Class (lift)
import Control.Exception (IOException, catch, ioError)
import Control.Monad

#if defined(__GLASGOW_HASKELL__) && __GLASGOW_HASKELL__ < 707
import Control.Monad.Instances ()
#endif

import Data.Monoid
import Prelude (Either(..), Maybe(..), const, either, flip, ($), (.), IO)

{- |
The strategy of combining computations that can throw exceptions
by bypassing bound functions
from the point an exception is thrown to the point that it is handled.

Is parameterized over the type of error information and
the monad type constructor.
It is common to use @'Either' String@ as the monad type constructor
for an error monad in which error descriptions take the form of strings.
In that case and many other common cases the resulting monad is already defined
as an instance of the 'MonadError' class.
You can also define your own error type and\/or use a monad type constructor
other than @'Either' 'String'@ or @'Either' 'IOError'@.
In these cases you will have to explicitly define instances of the 'MonadError'
class.
(If you are using the deprecated "Control.Monad.Error" or
"Control.Monad.Trans.Error", you may also have to define an 'Error' instance.)
-}
class (Monad m) => MonadError e m | m -> e where
    -- | Is used within a monadic computation to begin exception processing.
    throwError :: e -> m a

    {- |
    A handler function to handle previous errors and return to normal execution.
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

instance {-# OVERLAPPING #-} Monad m => MonadError e (Cont.ContT e (Cont.ContT r m)) where
  throwError e = Cont.ContT (const (return e))
  catchError c recover = Cont.ContT $ \successHandler -> Cont.ContT $ \errorHandler ->
    runContT (runContT c successHandler)
      $ \e -> runContT (runContT (recover e) successHandler) errorHandler

instance MonadError e m => MonadError e (ContT r m)  where
  throwError e = Cont.ContT (const (throwError e))
  catchError c recover =
    Cont.ContT $ \k -> catchError (runContT c k) $ \e -> Cont.runContT (recover e) k

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

#if MIN_VERSION_transformers(0,5,6)
-- | @since 2.3
instance (Monoid w, MonadError e m) => MonadError e (CPSRWS.RWST r w s m) where
    throwError = lift . throwError
    catchError = CPSRWS.liftCatch catchError

-- | @since 2.3
instance (Monoid w, MonadError e m) => MonadError e (CPSWriter.WriterT w m) where
    throwError = lift . throwError
    catchError = CPSWriter.liftCatch catchError
#endif

-- | 'MonadError' analogue to the 'Control.Exception.try' function.
tryError :: MonadError e m => m a -> m (Either e a)
tryError action = (liftM Right action) `catchError` (return . Left)

-- | 'MonadError' analogue to the 'withExceptT' function.
-- Modify the value (but not the type) of an error.  The type is
-- fixed because of the functional dependency @m -> e@.  If you need
-- to change the type of @e@ use 'mapError'.
withError :: MonadError e m => (e -> e) -> m a -> m a
withError f action = tryError action >>= either (throwError . f) return

-- | As 'handle' is flipped 'Control.Exception.catch', 'handleError'
-- is flipped 'catchError'.
handleError :: MonadError e m => (e -> m a) -> m a -> m a
handleError = flip catchError

-- | 'MonadError' analogue of the 'mapExceptT' function.  The
-- computation is unwrapped, a function is applied to the @Either@, and
-- the result is lifted into the second 'MonadError' instance.
mapError :: (MonadError e m, MonadError e' n) => (m (Either e a) -> n (Either e' b)) -> m a -> n b
mapError f action = f (tryError action) >>= liftEither

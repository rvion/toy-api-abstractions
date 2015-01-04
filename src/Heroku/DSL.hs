{-# LANGUAGE DeriveFunctor             #-}
{-# LANGUAGE FlexibleContexts          #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE TemplateHaskell           #-}

module Heroku.DSL where

import           Control.Monad.Free    (Free, MonadFree, iterM, liftF)
import           Control.Monad.Free.TH (makeFree)

import           API.Rest
import qualified Heroku.API            as API
import           Heroku.Types



data HerokuF next
    = Connect String String next
    | Target [AppName] next
    | RestartApp AppName next
    | RestartDyno AppName DynoName next
    | GetAppInfo App (AppInfo -> next)
    deriving (Functor)

type Heroku a = Free HerokuF a
makeFree ''HerokuF

run :: Auth -> Heroku a -> IO a
run auth = iterM eval where
    eval action = case action of
        (RestartApp app next)   -> API.restartApp app auth           >> next
        (RestartDyno app dyno next) -> API.restartDyno app dyno auth >> next
        (GetAppInfo dynos next) -> 
            API.fetchDetails "test" auth >>
                return (AppInfo "test") >>= next

-- Remi: I'm wondering what is the `pure` function
-- generated by above functor automatic deriving !?
-- TODO: above comment is a reminder to test later


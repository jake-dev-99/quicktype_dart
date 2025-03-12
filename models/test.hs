{-# LANGUAGE StrictData #-}
{-# LANGUAGE OverloadedStrings #-}

module QuickType
    ( Test (..)
    , Convert (..)
    , decodeTopLevel
    ) where

import Data.Aeson
import Data.Aeson.Types (emptyObject)
import Data.ByteString.Lazy (ByteString)
import Data.HashMap.Strict (HashMap)
import Data.Text (Text)
import Data.Vector (Vector)

data Test = Test
    { asdfTest :: Text
    , asdf2Test :: Text
    } deriving (Show)

data Convert = Convert
    {
    } deriving (Show)

decodeTopLevel :: ByteString -> Maybe Test
decodeTopLevel = decode

decodeTopLevel :: ByteString -> Maybe Convert
decodeTopLevel = decode

instance ToJSON Test where
    toJSON (Test asdfTest asdf2Test) =
        object
        [ "asdf" .= asdfTest
        , "asdf2" .= asdf2Test
        ]

instance FromJSON Test where
    parseJSON (Object v) = Test
        <$> v .: "asdf"
        <*> v .: "asdf2"

instance ToJSON Convert where
    toJSON = \_ -> emptyObject

instance FromJSON Convert where
    parseJSON emptyObject = return Convert

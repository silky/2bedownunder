module Helper.Admin where

import Import

import Text.Markdown (Markdown)
import Data.Time.Calendar
import Data.Time.LocalTime
import Yesod.Text.Markdown (markdownField)

newEntryForm :: Form (Text, Bool, Markdown)
newEntryForm = renderDivs $ (,,)
    <$> areq textField titleSettings Nothing
    <*> areq boolField publishNowSettings Nothing
    <*> areq markdownField contentSettings Nothing

updateEntryForm :: Maybe Entry -> Form (Text, Maybe Day, Maybe TimeOfDay, Markdown)
updateEntryForm mEntry = renderDivs $ (,,,)
    <$> areq textField titleSettings (entryTitle <$> mEntry)
    <*> aopt dayField "Date" (entryDate <$> mEntry)
    <*> aopt timeFieldTypeTime "Time" (entryTime <$> mEntry)
    <*> areq markdownField contentSettings (entryContent <$> mEntry)

mUpdateEntryForm :: Maybe Entry -> Html -> MForm Handler (FormResult Entry, Widget)
mUpdateEntryForm mEntry _ = do
    (titleRes, titleView)     <- mreq textField titleSettings (entryTitle <$> mEntry)
    (dayRes, dayView)         <- mopt dayField dateSettings (entryDate <$> mEntry)
    (timeRes, timeView)       <- mopt timeFieldTypeTime timeSettings (entryTime <$> mEntry)
    (contentRes, contentView) <- mreq markdownField contentSettings (entryContent <$> mEntry)
    now <- liftIO getCurrentTime

    let posted = case (dayRes, timeRes) of
            (FormSuccess (Just day), FormSuccess (Just time)) ->
                FormSuccess (Just (UTCTime day (timeOfDayToTime time)))

            (FormSuccess (Just _), FormSuccess Nothing) ->
                FormFailure ["Missing publication time"]

            (FormSuccess Nothing, FormSuccess (Just _)) ->
                FormFailure ["Missing publication date"]

            (FormSuccess Nothing, FormSuccess Nothing) ->
                FormSuccess Nothing

            _ -> FormFailure ["This should not happen"]
        created = FormSuccess (maybe now entryCreated mEntry)
        res = Entry <$> titleRes <*> contentRes <*> posted <*> created
        widget = do
            toWidget
                [lucius|
                    ##{fvId dayView} {
                        width: 10em;
                    }
                    ##{fvId timeView} {
                        width: 6em;
                    }
                |]
            [whamlet|
                <div ##{fvId titleView}>
                    <label>#{fvLabel titleView}
                    ^{fvInput titleView}
                <div>
                    Publish on <span ##{fvId dayView}>^{fvInput dayView}
                    \ at <span ##{fvId timeView}>^{fvInput timeView}
                <div ##{fvId contentView}>
                    <div>
                        ^{fvInput contentView}

            |]

    return (res, widget)

entryDate :: Entry -> Maybe Day
entryDate e = utctDay <$> entryPosted e
entryTime :: Entry -> Maybe TimeOfDay
entryTime e = (timeToTimeOfDay . utctDayTime) <$> entryPosted e

titleSettings, publishNowSettings, dateSettings, timeSettings, contentSettings :: FieldSettings App
titleSettings = FieldSettings
    { fsLabel = "Title"
    , fsTooltip = Nothing
    , fsId = Just "title"
    , fsName = Just "title"
    , fsAttrs = []
    }
publishNowSettings = FieldSettings
    { fsLabel = "Publish immediately"
    , fsTooltip = Nothing
    , fsId = Just "posted"
    , fsName = Just "posted"
    , fsAttrs = []
    }
dateSettings = FieldSettings
    { fsLabel = "Date"
    , fsTooltip = Nothing
    , fsId = Just "date"
    , fsName = Just "date"
    , fsAttrs = [("placeholder", "yyyy-mm-dd")]
    }
timeSettings = FieldSettings
    { fsLabel = "Time"
    , fsTooltip = Nothing
    , fsId = Just "time"
    , fsName = Just "time"
    , fsAttrs = [("placeholder", "hh:mm")]
    }
contentSettings = FieldSettings
    { fsLabel = "Content"
    , fsTooltip = Nothing
    , fsId = Just "content"
    , fsName = Just "content"
    , fsAttrs = []
    }

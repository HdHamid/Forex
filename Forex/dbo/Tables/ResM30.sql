﻿CREATE TABLE [dbo].[ResM30] (
    [RowNo]                        BIGINT           NULL,
    [Time]                         DATETIME2 (7)    NULL,
    [Open]                         FLOAT (53)       NULL,
    [High]                         FLOAT (53)       NULL,
    [Low]                          FLOAT (53)       NULL,
    [Close]                        FLOAT (53)       NULL,
    [CandleCeiling]                FLOAT (53)       NULL,
    [CandleFloor]                  FLOAT (53)       NULL,
    [Volume]                       INT              NULL,
    [DateID]                       INT              NULL,
    [MaxBetween]                   FLOAT (53)       NULL,
    [MinBetween]                   FLOAT (53)       NULL,
    [Endt]                         DATE             NULL,
    [MX]                           INT              NULL,
    [Min]                          INT              NULL,
    [EnDay]                        CHAR (2)         NULL,
    [EnMonthName]                  NVARCHAR (50)    NULL,
    [EnYear]                       CHAR (4)         NULL,
    [lgMax]                        FLOAT (53)       NULL,
    [LgMin]                        FLOAT (53)       NULL,
    [ClosePriceDiffLgMin]          FLOAT (53)       NULL,
    [ClosePriceDiffLgMax]          FLOAT (53)       NULL,
    [HighPriceDiffLgMin]           FLOAT (53)       NULL,
    [HighPriceDiffLgMax]           FLOAT (53)       NULL,
    [LowPriceDiffLgMin]            FLOAT (53)       NULL,
    [LowPriceDiffLgMax]            FLOAT (53)       NULL,
    [CandleDiffFromLagMaxPivot]    BIGINT           NULL,
    [CandleDiffFromLagMinPivot]    BIGINT           NULL,
    [PivotToPivotMaxDegree]        FLOAT (53)       NULL,
    [PivotToPivotMinDegree]        FLOAT (53)       NULL,
    [PivotToCurrentMaxDegree]      FLOAT (53)       NULL,
    [PivotToCurrentMinDegree]      FLOAT (53)       NULL,
    [VolLagPercent]                DECIMAL (38, 4)  NULL,
    [RSI14]                        DECIMAL (38, 23) NULL,
    [RSI5]                         DECIMAL (38, 23) NULL,
    [ID]                           INT              NULL,
    [OBV]                          INT              NULL,
    [CCI]                          NUMERIC (38, 6)  NULL,
    [+Di14]                        FLOAT (53)       NULL,
    [-Di14]                        FLOAT (53)       NULL,
    [ADX]                          FLOAT (53)       NULL,
    [IsBiggerThanMaxPrice3]        INT              NOT NULL,
    [IsBiggerThanMaxPrice5]        INT              NOT NULL,
    [IsBiggerThanMaxPrice8]        INT              NOT NULL,
    [IsBiggerThanMaxPrice13]       INT              NOT NULL,
    [IsBiggerThanMaxPrice34]       INT              NOT NULL,
    [IsLessThanMinPrice3]          INT              NOT NULL,
    [IsLessThanMinPrice5]          INT              NOT NULL,
    [IsLessThanMinPrice8]          INT              NOT NULL,
    [IsLessThanMinPrice13]         INT              NOT NULL,
    [IsLessThanMinPrice34]         INT              NOT NULL,
    [ResistantDistanceMaxPrice3]   FLOAT (53)       NULL,
    [ResistantDistancePrice5]      FLOAT (53)       NULL,
    [ResistantDistancePrice8]      FLOAT (53)       NULL,
    [ResistantDistancePrice13]     FLOAT (53)       NULL,
    [ResistantDistancePrice34]     FLOAT (53)       NULL,
    [SupportDistanceMinPrice3]     FLOAT (53)       NULL,
    [SupportDistanceMinPrice5]     FLOAT (53)       NULL,
    [SupportDistanceMinPrice8]     FLOAT (53)       NULL,
    [SupportDistanceMinPrice13]    FLOAT (53)       NULL,
    [SupportDistanceMinPrice34]    FLOAT (53)       NULL,
    [SMA]                          DECIMAL (38, 5)  NULL,
    [EMA]                          DECIMAL (38, 5)  NULL,
    [DiffSmaEmaOverClosePrcnt]     DECIMAL (38, 5)  NULL,
    [IsSmaOveEma]                  BIT              NULL,
    [SmaDegree]                    DECIMAL (6, 4)   NULL,
    [EmaDegree]                    DECIMAL (6, 4)   NULL,
    [IsRed]                        INT              NOT NULL,
    [IsGreen]                      INT              NOT NULL,
    [_PriceRange]                  FLOAT (53)       NULL,
    [PriceRangeWidthPrcnt]         FLOAT (53)       NULL,
    [MiddleBodyPrice]              FLOAT (53)       NULL,
    [MiddleFullPrice]              FLOAT (53)       NULL,
    [ResistantDistancePrcnt]       FLOAT (53)       NULL,
    [SupportDistancePrcnt]         FLOAT (53)       NULL,
    [FloorToCieling]               FLOAT (53)       NULL,
    [CandleBodyRangeWidthPrcnt]    FLOAT (53)       NULL,
    [_CloseOpenPrcnt]              FLOAT (53)       NULL,
    [_HighCielingPrcnt]            FLOAT (53)       NULL,
    [_FloorLowPrcnt]               FLOAT (53)       NULL,
    [OneLagIsRed]                  INT              NULL,
    [OneLagIsGreen]                INT              NULL,
    [OneLagCandleCeiling]          FLOAT (53)       NULL,
    [OneLagCandleFloor]            FLOAT (53)       NULL,
    [OneLagHigh]                   FLOAT (53)       NULL,
    [OneLagLow]                    FLOAT (53)       NULL,
    [OneCandleBodyRangeWidthPrcnt] FLOAT (53)       NULL,
    [OneFloorToCieling]            FLOAT (53)       NULL,
    [MonsterCandle_Bullish]        INT              NOT NULL,
    [MonsterCandle_Bearish]        INT              NOT NULL,
    [UHAMMER]                      INT              NOT NULL,
    [LHAMMER]                      INT              NOT NULL,
    [IsSharkZone]                  INT              NOT NULL
);


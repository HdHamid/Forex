CREATE TABLE [Operation].[WeeklyInfo] (
    [MxShortPrediction]   DECIMAL (38, 5) NULL,
    [MxShortCor]          DECIMAL (38, 5) NULL,
    [MinPrediction]       DECIMAL (38, 5) NULL,
    [MinCor]              DECIMAL (38, 5) NULL,
    [MxLongPrediction]    DECIMAL (38, 5) NULL,
    [MxLongcor]           DECIMAL (38, 5) NULL,
    [MinLongPrediction]   DECIMAL (38, 5) NULL,
    [MinLongCor]          DECIMAL (38, 5) NULL,
    [PredictionFullReg]   DECIMAL (38, 5) NULL,
    [FullRegCor]          DECIMAL (38, 5) NULL,
    [MaxSharkZone]        DECIMAL (38, 5) NULL,
    [MinSharkZone]        DECIMAL (38, 5) NULL,
    [MxDte1Short]         DATE            NULL,
    [MxDte2Short]         DATE            NULL,
    [MinDte1Short]        DATE            NULL,
    [MinDte2Short]        DATE            NULL,
    [LongReggressionDate] DATE            NULL,
    [LongReggressionType] CHAR (3)        NULL
);


CREATE TABLE [dbo].[CheckResult] (
    [PivotDateTime]        DATETIME        NULL,
    [PivotHigh]            DECIMAL (38, 5) NULL,
    [RowNo]                BIGINT          NULL,
    [FirstSignalDateTime]  DATETIME        NULL,
    [TIME]                 DATETIME        NULL,
    [Close]                DECIMAL (38, 5) NULL,
    [High]                 DECIMAL (38, 5) NULL,
    [CCI]                  NUMERIC (38, 6) NULL,
    [Endt]                 DATE            NULL,
    [RN]                   BIGINT          NULL,
    [SellTriggerPrice]     NUMERIC (38, 5) NULL,
    [StopLoss]             NUMERIC (38, 5) NULL,
    [FClose]               DECIMAL (38, 5) NULL,
    [Diff]                 NUMERIC (38, 5) NULL,
    [CandlesLaterDateTime] DATETIME        NULL,
    [Pip]                  NUMERIC (38, 5) NULL,
    [OprType]              VARCHAR (8)     NOT NULL,
    [TradeType]            VARCHAR (6)     NOT NULL
);


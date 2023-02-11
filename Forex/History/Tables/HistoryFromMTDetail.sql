CREATE TABLE [History].[HistoryFromMTDetail] (
    [Type]         NVARCHAR (50)   NULL,
    [Volume]       NVARCHAR (50)   NULL,
    [OpenDate]     DATE            NULL,
    [OpenDateTime] DATETIME        NULL,
    [Position PnL] DECIMAL (38, 2) NULL,
    [Comment]      NVARCHAR (50)   NULL,
    [sumOver]      DECIMAL (38, 2) NULL
);


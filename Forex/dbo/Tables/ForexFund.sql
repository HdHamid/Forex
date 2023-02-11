CREATE TABLE [dbo].[ForexFund] (
    [Id]        INT             NULL,
    [Date]      DATE            NULL,
    [Cur]       NVARCHAR (50)   NULL,
    [Event]     NVARCHAR (500)  NULL,
    [Previous]  NUMERIC (38, 5) NULL,
    [Actual]    NUMERIC (38, 5) NULL,
    [Forecast]  NUMERIC (38, 5) NULL,
    [EventCode] NVARCHAR (4000) NULL,
    [Type]      VARCHAR (3)     NULL,
    [Stars]     TINYINT         NULL
);


GO
CREATE CLUSTERED INDEX [ix]
    ON [dbo].[ForexFund]([Id] ASC);


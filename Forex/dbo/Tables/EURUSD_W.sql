CREATE TABLE [dbo].[EURUSD_W] (
    [Time]   VARCHAR (50)    NULL,
    [OPEN]   DECIMAL (38, 5) NULL,
    [HIGH]   DECIMAL (38, 5) NULL,
    [LOW]    DECIMAL (38, 5) NULL,
    [CLOSE]  DECIMAL (38, 5) NULL,
    [VOLUME] INT             NULL,
    [DateId] INT             NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [IX]
    ON [dbo].[EURUSD_W]([Time] ASC);


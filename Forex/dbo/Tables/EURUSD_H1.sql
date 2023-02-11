CREATE TABLE [dbo].[EURUSD_H1] (
    [Time]    DATETIME        NULL,
    [Open]    DECIMAL (38, 5) NULL,
    [High]    DECIMAL (38, 5) NULL,
    [Low]     DECIMAL (38, 5) NULL,
    [Close]   DECIMAL (38, 5) NULL,
    [Volume]  BIGINT          NULL,
    [DateId]  INT             NULL,
    [RegDate] DATETIME        DEFAULT (getdate()) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ix]
    ON [dbo].[EURUSD_H1]([Time] ASC);


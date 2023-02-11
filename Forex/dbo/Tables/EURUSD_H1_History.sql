CREATE TABLE [dbo].[EURUSD_H1_History] (
    [Time]    DATETIME        NULL,
    [Open]    DECIMAL (38, 5) NULL,
    [High]    DECIMAL (38, 5) NULL,
    [Low]     DECIMAL (38, 5) NULL,
    [Close]   DECIMAL (38, 5) NULL,
    [Volume]  BIGINT          NULL,
    [DateId]  INT             NULL,
    [RegDate] DATETIME        NULL,
    CONSTRAINT [UnqTim_History] UNIQUE NONCLUSTERED ([Time] ASC)
);


CREATE TABLE [dbo].[EURUSD_M30] (
    [Time]   DATETIME2 (7) NOT NULL,
    [Open]   FLOAT (53)    NOT NULL,
    [High]   FLOAT (53)    NOT NULL,
    [Low]    FLOAT (53)    NOT NULL,
    [Close]  FLOAT (53)    NOT NULL,
    [Volume] INT           NOT NULL,
    [DateID] INT           NULL
);


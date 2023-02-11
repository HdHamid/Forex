CREATE TABLE [dbo].[GroupsToReggression] (
    [ID]          INT             IDENTITY (1, 1) NOT NULL,
    [Type]        VARCHAR (50)    NULL,
    [MinDte]      DATETIME        NULL,
    [MaxDte]      DATETIME        NULL,
    [Correlation] DECIMAL (38, 5) NULL,
    [MSE]         DECIMAL (38, 5) NULL,
    [MAE]         DECIMAL (38, 5) NULL,
    [Degree]      DECIMAL (38, 2) NULL,
    [DayCount]    INT             NULL,
    [MaxDiffRegY] DECIMAL (38, 5) NULL,
    [yBigger]     DECIMAL (8, 2)  NULL,
    [yhatBigger]  DECIMAL (8, 2)  NULL,
    [yEqual]      DECIMAL (38, 5) NULL
);


GO
CREATE CLUSTERED INDEX [IX]
    ON [dbo].[GroupsToReggression]([ID] ASC);


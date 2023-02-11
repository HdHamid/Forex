﻿CREATE TABLE [dbo].[DimDate] (
    [ID]                  INT            NOT NULL,
    [Endt]                DATE           NULL,
    [EnYear]              CHAR (4)       NULL,
    [EnMonth]             CHAR (2)       NULL,
    [EnDay]               CHAR (2)       NULL,
    [Frdt]                CHAR (10)      NULL,
    [FrYear]              CHAR (4)       NULL,
    [FrMonth]             CHAR (2)       NULL,
    [FrDay]               CHAR (2)       NULL,
    [Hjdt]                CHAR (10)      NULL,
    [HjYear]              CHAR (4)       NULL,
    [HjMonth]             CHAR (2)       NULL,
    [HjDay]               CHAR (2)       NULL,
    [EnMonthName]         NVARCHAR (50)  NULL,
    [EnDayOfWeek]         NVARCHAR (50)  NULL,
    [FrMonthName]         NVARCHAR (50)  NULL,
    [FrDayOfWeek]         NVARCHAR (50)  NULL,
    [EnNoDayOfWeek]       SMALLINT       NULL,
    [FrNoDayOfWeek]       SMALLINT       NULL,
    [WeekOfYr]            INT            NULL,
    [WeekOfMnth]          INT            NULL,
    [EnWeekOfYr]          INT            NULL,
    [SrlWeekOfYr]         INT            NULL,
    [SeqID]               INT            NULL,
    [FrSrlWeekOfYr]       INT            NULL,
    [FrFrstWkDayID]       INT            NULL,
    [Qrtr]                TINYINT        NULL,
    [QrtrName]            NVARCHAR (50)  NULL,
    [IsHoliday]           BIT            NULL,
    [HolidayDesc]         NVARCHAR (100) NULL,
    [EnDtFormat101]       VARCHAR (50)   NULL,
    [IsEndOfMonth]        BIT            NULL,
    [MaxFrDayInMonth]     INT            NULL,
    [FrIsLeap]            BIT            NULL,
    [EnIsLeap]            BIT            NULL,
    [SeqPersianYearMonth] INT            NULL,
    [EnFullDate]          DATETIME       NULL,
    [SeqWeekEn]           INT            NULL
);


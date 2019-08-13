/*
Procedure:	ReportDIG08_Detail (copied from KPI_Renewals_Export)
Purpose:	Produce KPI Renewals

History:
04/02/2009 - CCM        - SD-2514 Need to change how RV1/RV2, R14/D10, and IS7 records are counted as per the JIRA issue
25/02/2009 - PJC        - SD-2649 Added categories to show "Lost" and "Billed Cancels" totals
09/03/2009 - PJC        - SD-2649 Added more categories within "C/C Failed" to show breakdown
25/06/2010 - SXQ        - SD-545, Add XSW quote type
30/11/2010 - Yemi Ogunsanya - added the following agent codes to international BAH,KUW,QAT,UAE
20/12/2011 - PJC        - INS-1615 Added product set code to output for breakdown by product
04/01/2012 - Yemi Ogunsanya - Send all output to the extracts DB
07/09/2012 - Jon Giles  - Added OMN to international
16/11/2012 - Jon Giles  - As per https://www.tcgnws.com/browse/INS-3496 :
                        - Added new company 'Columbus Middle East' for ('BAH', 'KUW', 'QAT', 'UAE', 'OMN') and added these to the TRQUT.AGTCO clauses.
19/11/2012 - Jon Giles  - As per https://www.tcgnws.com/browse/INS-3496 :
                        - Added new company 'Pref Direct' for 'PDL' by unioning LeoCTI.CERTT_Imported to LeoCTI.TRQUT in a CTE.
23/11/2012 - Jon Giles  - As per https://www.tcgnws.com/browse/INS-3496 : 
                        - Added IFA (by adding 'CA' in several QUTYPE clauses), and replaced some references to QUTYPE with POLTYPE
27/11/2012 - Jon Giles  - Changed join to PRODT from INNER to LEFT OUTER, and updated MonthNo to accept a 3-digit month number.
12/12/2012 - Jon Giles  - Replaced multiple 'ACTNA like C_1' and 'ACTNA like C_2' clauses, to be based on specific names only (i.e. 'CU1', 'CP1', 'CU2', 'CP2')
20/12/2012 - Jon Giles	- Added 'CC1' and 'CC2' to the ACTNA clauses.
01/02/2013 - Jon Giles  - Added Agent Code AIT, due to https://www.tcgnws.com/browse/INS-4279
                          Also added 'MVS','BEN' to the LeoCTI where clause.
01/05/2013 - Jon Giles - Replaced 'INSERT INTO Extracts.dbo.' with 'INSERT INTO Utility.dbo.'
16/01/2017 - Paul C    - Created ReportDIG08_Detail routine and added several columns (INS-21043)
*/
ALTER PROCEDURE [dbo].[ReportDIG08_Detail]
AS

-- Added this next statement to prevent db locks from occurring
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


	DECLARE @vFROMDT datetime
	DECLARE @vTODT datetime
	DECLARE @vMTHDT datetime

	-- Changes to selection criteria (INS-21043)
	SET @vFROMDT = CAST('01-May-2014 00:00:00' as datetime)
	SET @vTODT = CAST(CAST(GETDATE() as char(11)) + ' 23:59:59' as datetime)
	--SET @vFROMDT = DATEADD(YEAR, -2, @vTODT)
	SET @vTODT = DATEADD(DAY, -DAY(@vTODT), @vTODT)
	SET @vMTHDT = DATEADD(MONTH, -1, @vFROMDT)

	CREATE TABLE #ReportDIG08_Detail(
		RPTGRP VARCHAR(15),
		AGTGRP  VARCHAR(15),
		MTHNO	INT,
		HISTYR	INT,
		HISTMO	INT,
		CLINO	INT,
		QUNO	SMALLINT,
		RENQUNO	SMALLINT,
		ENDDOT	DATETIME,
		RQP	SMALLINT,
		CU1	SMALLINT,
		CU2	SMALLINT,
		CALLSLD	SMALLINT,
		CM1	SMALLINT,
		CM2	SMALLINT,
		CMSLD	SMALLINT,
		RV1	SMALLINT,
		AUTOSLD	SMALLINT,
		CH1	SMALLINT,
		CCFAILEXP	SMALLINT,
		CCFAILOTH	SMALLINT,
		DNR	SMALLINT,
		DNA	SMALLINT,
		R14	SMALLINT,
		REN	SMALLINT,
		RN7	SMALLINT,
		RNX	SMALLINT,
		RENSLD	SMALLINT,
		MANSLD	SMALLINT,
		CCSLD	SMALLINT,
		R65	SMALLINT,
		R65SLD	SMALLINT,
		GWP	MONEY,
		LOST SMALLINT,
		LOSTDNR SMALLINT,
		LOSTDNA SMALLINT,
		ABCANX SMALLINT,
		ABCANXDNR SMALLINT,
		ABCANXDNA SMALLINT,
		FAILCANX SMALLINT,
		FAILREISS SMALLINT,
		FAILPENDING SMALLINT,
		FAILOTH SMALLINT,
		PRODSET VARCHAR(10),
		--added INS-21043
		CALLSLDWEB	SMALLINT,
		CALLSLDCC	SMALLINT,
		CMSLDWEB	SMALLINT,
		CMSLDCC		SMALLINT,
		AUTOSLDWEB	SMALLINT,
		AUTOSLDCC	SMALLINT,
		RENSLDWEB	SMALLINT,
		RENSLDCC	SMALLINT,
		MANSLDWEB	SMALLINT,
		MANSLDCC	SMALLINT,
		CCSLDWEB	SMALLINT,
		CCSLDCC		SMALLINT,
		R65SLDWEB	SMALLINT,
		R65SLDCC	SMALLINT,
		RV1VAL		SMALLINT,
		RV1EXP		SMALLINT,
		VALSLD		SMALLINT,
		VALCH1		SMALLINT,
		VALCH1SLD	SMALLINT,
		VALCH1SLDWEB SMALLINT,
		VALCH1SLDCC	SMALLINT,
		EXPSLD		SMALLINT,
		EXPSLDWEB	SMALLINT,
		EXPSLDCC	SMALLINT,
		CH1AUTOCANX	SMALLINT,
		RV1LOST		SMALLINT,
		RVSLDCANX	SMALLINT,
		CANX		SMALLINT,
		RV1AB1		SMALLINT,
		VALPAID		SMALLINT
	)
		INSERT INTO #ReportDIG08_Detail
		SELECT RPTGRP = CASE WHEN TRQUT.AGTCO IN ('INT', 'GEC', 'ESC', 'NLC', 'ITA', 'FRA', 'MVS', 'AIT') THEN 'Columbus Intl'      --20130201: Added AIT  --20121116: Removed ('BAH', 'KUW', 'QAT', 'UAE', 'OMN')
					WHEN TRQUT.AGTCO IN ('BAH', 'KUW', 'QAT', 'UAE', 'OMN') THEN 'COL Middle East' --20121116: Added 'COL Middle East'
					WHEN TRQUT.AGTCO = 'PDL' THEN 'Pref Direct' --20121119: Added 'Pref Direct'
					WHEN TRQUT.AGTCO IN ('HIW', 'TIW', 'IFA', 'ODT', 'COS') THEN 'Astrenska'
					WHEN TRQUT.AGTCO IN ('MQC', 'ITS') THEN 'MediQuote'
					WHEN TRQUT.AGTCO = 'TRI' THEN 'Trinity'
					ELSE 'Columbus UK' END,
			AGTGRP = CASE WHEN TRQUT.AGTCO = 'BEN' AND TRQUT.QUTYPE IN ('CA', 'CS') THEN 'COL Aff Classic'
					WHEN TRQUT.AGTCO = 'COL' AND SRCET.SRCLINO <> '' THEN 'COL Affinity'
					WHEN TRQUT.AGTCO = 'COL' AND TRQUT.QUTYPE IN ('CA', 'CS') THEN 'COL Classic'
					WHEN TRQUT.AGTCO IN ('MSB', 'NWS', 'TGA', 'BLD', 'BEN') THEN 'COL Affinity'
					WHEN TRQUT.AGTCO IN ('INT', 'GEC', 'ESC', 'NLC', 'ITA', 'FRA') AND SRCET.SRCLINO <> '' THEN 'INT Affinity'
					WHEN TRQUT.AGTCO IN ('INT', 'GEC', 'ESC', 'NLC', 'ITA', 'FRA') THEN 'INT'
					WHEN TRQUT.AGTCO = 'CMS' THEN 'COL Money Sup'
					WHEN TRQUT.AGTCO = 'HAS' THEN 'Hastings'
					WHEN TRQUT.AGTCO = 'CDI' AND TRQUT.QUTYPE IN ('CA', 'CS') THEN 'CDI Classic'
					ELSE TRQUT.AGTCO END,
			MTHNO = DATEDIFF(MONTH, @vMTHDT, QUALT.BORNDT),
			HISTYR = YEAR(QUALT.BORNDT),
			HISTMO = MONTH(QUALT.BORNDT),
			TRQUT.CLINO,
			TRQUT.QUNO,
			TRQUT.RENQUNO,
			TRQUT.ENDDOT,
			RQP = CAST(CASE WHEN QUALT.ACTNA = 'RQP' THEN 1 ELSE 0 END as smallint),
			CU1 = CAST(CASE WHEN QUALT.ACTNA in ('CU1', 'CP1', 'CC1') THEN 1 ELSE 0 END as smallint), --20121220: Added 'CC1'  --20121212: replaced: QUALT.ACTNA like 'C_1' --20121123: replaced: QUALT.ACTNA = 'CU1'
			CU2 = CAST(0 as smallint),
			CALLSLD = CAST(0 as smallint),
			CM1 = CAST(0 as smallint),
			CM2 = CAST(0 as smallint),
			CMSLD = CAST(0 as smallint),
			RV1 = CAST(0 as smallint),
			AUTOSLD = CAST(0 as smallint),
			CH1 = CAST(0 as smallint),
			CCFAILEXP = CAST(0 as smallint),
			CCFAILOTH = CAST(0 as smallint),
			DNR = CAST(0 as smallint),
			DNA = CAST(0 as smallint),
			R14 = CAST(0 as smallint),
			REN = CAST(0 as smallint),
			RN7 = CAST(0 as smallint),
			RNX = CAST(0 as smallint),
			RENSLD = CAST(0 as smallint),
			MANSLD = CAST(0 as smallint),
			CCSLD = CAST(0 as smallint),
			R65 = CAST(CASE WHEN QUALT.ACTNA = 'R65' THEN 1 ELSE 0 END as smallint),
			R65SLD = CAST(0 as smallint),
			TRQUT.GWP,
			LOST = CAST(0 as smallint),
			LOSTDNR = CAST(0 as smallint),
			LOSTDNA = CAST(0 as smallint),
			ABCANX = CAST(0 as smallint),
			ABCANXDNR = CAST(0 as smallint),
			ABCANXDNA = CAST(0 as smallint),
			FAILCANX = CAST(0 as smallint),
			FAILREISS = CAST(0 as smallint),
			FAILPENDING = CAST(0 as smallint),
			FAILOTH = CAST(0 as smallint),
			PRODSET = ISNULL(PRODT.PRODSET, 'Unknown'), --20121127: Added isnull clause
			--added INS-21043
			CALLSLDWEB	= CAST(0 as smallint),
			CALLSLDCC	= CAST(0 as smallint),
			CMSLDWEB	= CAST(0 as smallint),
			CMSLDCC		= CAST(0 as smallint),
			AUTOSLDWEB	= CAST(0 as smallint),
			AUTOSLDCC	= CAST(0 as smallint),
			RENSLDWEB	= CAST(0 as smallint),
			RENSLDCC	= CAST(0 as smallint),
			MANSLDWEB	= CAST(0 as smallint),
			MANSLDCC	= CAST(0 as smallint),
			CCSLDWEB	= CAST(0 as smallint),
			CCSLDCC	= CAST(0 as smallint),
			R65SLDWEB	= CAST(0 as smallint),
			R65SLDCC	= CAST(0 as smallint),
			RV1VAL		= CAST(0 as smallint),
			RV1EXP		= CAST(0 as smallint),
			VALSLD		= CAST(0 as smallint),
			VALCH1		= CAST(0 as smallint),
			VALCH1SLD	= CAST(0 as smallint),
			VALCH1SLDWEB = CAST(0 as smallint),
			VALCH1SLDCC	= CAST(0 as smallint),
			EXPSLD		= CAST(0 as smallint),
			EXPSLDWEB	= CAST(0 as smallint),
			EXPSLDCC	= CAST(0 as smallint),
			CH1AUTOCANX	= CAST(0 as smallint),
			RV1LOST		= CAST(0 as smallint),
			RVSLDCANX	= CAST(0 as smallint),
			CANX		= CAST(0 as smallint),
			RV1AB1		= CAST(0 as smallint),
			VALPAID		= CAST(0 as smallint)
		FROM dbo.TRQUT AS TRQUT
			INNER JOIN dbo.QUALT AS QUALT 
			    ON TRQUT.CLINO = QUALT.CLINO
			        AND TRQUT.QUNO = QUALT.QUNO
			INNER JOIN dbo.SRCET AS SRCET
		        ON TRQUT.AGTCO = SRCET.AGTCO
			        AND TRQUT.SRCECO = SRCET.SRCECO
			LEFT OUTER JOIN dbo.PRODT AS PRODT --20121127: Changed from INNER to LEFT OUTER
		        ON TRQUT.AGTCO = PRODT.AGTCO
			        AND TRQUT.PRODNA = PRODT.PRODNA
		-- Changes to selection criteria (INS-21043)
		WHERE TRQUT.AGTCO IN ('COL', 'CMS', 'CDI', 'IFA', 'INT', 'AIT')
		--WHERE TRQUT.AGTCO IN ('COL', 'MSB', 'NWS', 'TGA', 'BLD', 'INT', 'GEC', 'ESC', 'NLC', 'CMS', 'ITA', 'FRA', 'HAS', 'DML', 'XSW',
		--        'BAH', 'KUW', 'QAT', 'UAE', 'OMN', 'PDL', 'AIT', 'MVS', 'BEN')    --20130201: Added 'AIT','MVS','BEN'  --20121116: Added ('BAH', 'KUW', 'QAT', 'UAE', 'OMN') --20121119: Added 'PDL'
			AND TRQUT.POLTYPE = 'MT'
			--AND TRQUT.POLTYPE in ('MT', 'MX') --20121123: replaced: QUTYPE in ('MT, 'MX')
			AND QUALT.ACTNA in ('CU1', 'CP1', 'CC1', 'RQP', 'R65') --20121220: Added 'CC1' --20121212: replaced: QUALT.ACTNA like 'C_1' --20121123: Added QUALT.ACTNA like 'C_1' --20121119: Added 'CP1'
			AND QUALT.BORNDT BETWEEN @vFROMDT AND @vTODT

		UPDATE #ReportDIG08_Detail
		SET CU2 = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.QUNO = QUALT.QUNO
			AND #ReportDIG08_Detail.CU1 > 0
			AND QUALT.ACTNA in ('CU2', 'CP2', 'CC2')  --20121220: Added 'CC2' --20121212: replaced: QUALT.ACTNA like 'C_2' --20121123: Replaced: QUALT.ACTNA in ('CU2', 'CP2')

		UPDATE #ReportDIG08_Detail
		SET CALLSLD = 1,
			CALLSLDWEB = CASE WHEN COMNA = 'WEB' THEN 1 ELSE 0 END, -- added INS-21043
			CALLSLDCC = CASE WHEN COMNA = 'WEB' THEN 0 ELSE 1 END -- added INS-21043
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO < TRQUT.QUNO
			AND TRQUT.POLTYPE IN ('MT', 'MX') --20121123: added 'MX'
			AND TRQUT.QUTSTAT = 'ISSUED'
			AND ABS(DATEDIFF(DAY, #ReportDIG08_Detail.ENDDOT, TRQUT.STDOT)) <= 31
			AND #ReportDIG08_Detail.CU1 > 0

		UPDATE #ReportDIG08_Detail
		SET CM1 = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND #ReportDIG08_Detail.RQP > 0
			AND QUALT.ACTNA in ('CM1')

		UPDATE #ReportDIG08_Detail
		SET CM2 = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND #ReportDIG08_Detail.CM1 > 0
			AND QUALT.ACTNA in ('CM2')

		UPDATE #ReportDIG08_Detail
        SET CMSLD = 1,
            CMSLDWEB = CASE WHEN COMNA = 'WEB' THEN 1 ELSE 0 END, -- added INS-21043
            CMSLDCC = CASE WHEN COMNA = 'WEB' THEN 0 ELSE 1 END -- added INS-21043
        FROM dbo.QUALT AS QUALT
        INNER JOIN dbo.TRQUT AS TRQUT
            ON QUALT.CLINO = TRQUT.CLINO
                AND QUALT.QUNO = TRQUT.QUNO
        WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
            AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
            AND QUALT.ACTNA = 'IS7'
            AND TRQUT.QUTSTAT = 'ISSUED'
            AND QUALT.ACTNO NOT IN (SELECT SYQUT.ACTNO
                                    FROM SYQUT
                                    WHERE SYQUT.CLINO = QUALT.CLINO
                                    AND SYQUT.QUNO = QUALT.QUNO
                                    AND SYQUT.SYQSTAT = 'H')
            AND #ReportDIG08_Detail.CM1 > 0

		UPDATE #ReportDIG08_Detail
		SET RV1 = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA IN ('RV1', 'RV2');

		UPDATE #ReportDIG08_Detail
		SET AUTOSLD = 1,
			AUTOSLDWEB = CASE WHEN COMNA = 'WEB' THEN 1 ELSE 0 END, -- added INS-21043
			AUTOSLDCC = CASE WHEN COMNA = 'WEB' THEN 0 ELSE 1 END -- added INS-21043
		FROM dbo.QUALT AS QUALT
		INNER JOIN dbo.TRQUT AS TRQUT
			ON QUALT.CLINO = TRQUT.CLINO
				AND QUALT.QUNO = TRQUT.QUNO
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA = 'IS7'
			AND TRQUT.QUTSTAT = 'ISSUED'
			AND QUALT.ACTNO NOT IN (SELECT SYQUT.ACTNO
									FROM SYQUT
									WHERE SYQUT.CLINO = QUALT.CLINO
									AND SYQUT.QUNO = QUALT.QUNO
									AND SYQUT.SYQSTAT = 'H')
			AND #ReportDIG08_Detail.RV1 > 0;

		UPDATE #ReportDIG08_Detail
		SET AUTOSLD = 1,
			AUTOSLDWEB = CASE WHEN COMNA = 'WEB' THEN 1 ELSE 0 END, -- added INS-21043
			AUTOSLDCC = CASE WHEN COMNA = 'WEB' THEN 0 ELSE 1 END -- added INS-21043
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = TRQUT.QUNO
			AND TRQUT.QUTSTAT = 'ISSUED'
			AND DATEDIFF(DAY, #ReportDIG08_Detail.ENDDOT, GETDATE()) > 16
			AND #ReportDIG08_Detail.RV1 > 0
			AND AUTOSLD = 0;

		UPDATE #ReportDIG08_Detail
		SET CH1 = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND QUALT.ACTNA = 'CH1'

		UPDATE #ReportDIG08_Detail
		SET CCFAILEXP = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 > 0
			AND QUALT.MEMO = 'FAILED CDT CARD:Card has already expired'

		UPDATE #ReportDIG08_Detail
		SET CCFAILOTH = 1
		WHERE RV1 > 0 AND CH1 > 0 AND CCFAILEXP = 0

		UPDATE #ReportDIG08_Detail
		SET CCSLD = 1,
			CCSLDWEB = CASE WHEN COMNA = 'WEB' THEN 1 ELSE 0 END, -- added INS-21043
			CCSLDCC = CASE WHEN COMNA = 'WEB' THEN 0 ELSE 1 END -- added INS-21043
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = TRQUT.QUNO
			AND RV1 > 0 AND CH1 > 0 AND AUTOSLD > 0

		UPDATE #ReportDIG08_Detail
		SET R14 = 1
		FROM dbo.QUALT AS QUALT
			INNER JOIN dbo.TRQUT AS TRQUT
				ON QUALT.CLINO = TRQUT.CLINO
					AND QUALT.QUNO = TRQUT.QUNO
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 > 0
			AND #ReportDIG08_Detail.CCSLD = 0
			AND QUALT.ACTNA IN ('R14', 'D10')
			AND TRQUT.QUTSTAT = 'CANCELLED'

		UPDATE #ReportDIG08_Detail
		SET ABCANX = 1
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = TRQUT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 = 0
			AND TRQUT.QUTSTAT = 'CANCELLED';

		UPDATE #ReportDIG08_Detail
		SET ABCANXDNR = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.ABCANX > 0
			AND QUALT.ACTNA = 'DNR'
			AND QUALT.HSTSTAT = 'O'

		UPDATE #ReportDIG08_Detail
		SET ABCANXDNA = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.ABCANX > 0
			AND #ReportDIG08_Detail.ABCANXDNR = 0
			AND QUALT.ACTNA = 'DNA'
			AND QUALT.HSTSTAT = 'O'

		UPDATE #ReportDIG08_Detail
		SET LOST = 1
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = TRQUT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 = 0
			AND TRQUT.QUTSTAT = 'LOST';

		UPDATE #ReportDIG08_Detail
		SET LOST = 1
		WHERE RV1 > 0
			AND (LOST = 0 AND ABCANX = 0 AND CH1 = 0 AND AUTOSLD = 0)

		UPDATE #ReportDIG08_Detail
		SET LOSTDNR = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.LOST > 0
			AND QUALT.ACTNA = 'DNR'
			AND QUALT.HSTSTAT = 'O'

		UPDATE #ReportDIG08_Detail
		SET LOSTDNA = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.LOST > 0
			AND #ReportDIG08_Detail.LOSTDNR = 0
			AND QUALT.ACTNA = 'DNA'
			AND QUALT.HSTSTAT = 'O'

		UPDATE #ReportDIG08_Detail
		SET FAILCANX = 1
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = TRQUT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 > 0
			AND #ReportDIG08_Detail.R14 = 0
			AND TRQUT.QUTSTAT = 'CANCELLED';

		UPDATE #ReportDIG08_Detail
		SET DNR = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 > 0
			AND #ReportDIG08_Detail.FAILCANX > 0
			AND QUALT.ACTNA = 'DNR'
			AND QUALT.HSTSTAT = 'O'

		UPDATE #ReportDIG08_Detail
		SET DNA = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 > 0
			AND #ReportDIG08_Detail.FAILCANX > 0
			AND #ReportDIG08_Detail.DNR = 0
			AND QUALT.ACTNA = 'DNA'
			AND QUALT.HSTSTAT = 'O'

		UPDATE #ReportDIG08_Detail
		SET FAILREISS = 1
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = TRQUT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 > 0
			AND #ReportDIG08_Detail.FAILCANX = 0
			AND #ReportDIG08_Detail.R14 = 0
			AND #ReportDIG08_Detail.CCSLD = 0
			AND TRQUT.QUTSTAT = 'REISSUED';

		UPDATE #ReportDIG08_Detail
		SET FAILPENDING = 1
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = TRQUT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 > 0
			AND #ReportDIG08_Detail.FAILCANX = 0
			AND #ReportDIG08_Detail.R14 = 0
			AND #ReportDIG08_Detail.CCSLD = 0
			AND #ReportDIG08_Detail.FAILREISS = 0
			AND TRQUT.QUTSTAT = 'ISSUED'
			AND DATEDIFF(DAY, #ReportDIG08_Detail.ENDDOT, GETDATE()) <= 16;

		UPDATE #ReportDIG08_Detail
		SET FAILOTH = CH1 - (FAILCANX + R14 + CCSLD + FAILREISS + FAILPENDING)
		WHERE RV1 > 0
			AND CH1 > 0

		UPDATE #ReportDIG08_Detail
		SET REN = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA = 'REN'
			AND #ReportDIG08_Detail.RV1 = 0

		UPDATE #ReportDIG08_Detail
		SET RN7 = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA = '7DP'
			AND #ReportDIG08_Detail.REN > 0

		UPDATE #ReportDIG08_Detail
		SET RNX = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
		AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
		AND QUALT.ACTNA = '7DX'
		AND #ReportDIG08_Detail.REN > 0;

		UPDATE #ReportDIG08_Detail
		SET RENSLD = 1,
			RENSLDWEB = CASE WHEN COMNA = 'WEB' THEN 1 ELSE 0 END, -- added INS-21043
			RENSLDCC = CASE WHEN COMNA = 'WEB' THEN 0 ELSE 1 END -- added INS-21043
		FROM dbo.QUALT AS QUALT
			INNER JOIN TRQUT
				ON QUALT.CLINO = TRQUT.CLINO
					AND QUALT.QUNO = TRQUT.QUNO
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA = 'IS7'
			AND TRQUT.QUTSTAT = 'ISSUED'
			AND #ReportDIG08_Detail.REN > 0

		UPDATE #ReportDIG08_Detail
		SET MANSLD = 1,
			MANSLDWEB = CASE WHEN COMNA = 'WEB' THEN 1 ELSE 0 END, -- added INS-21043
			MANSLDCC = CASE WHEN COMNA = 'WEB' THEN 0 ELSE 1 END -- added INS-21043
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.QUNO < TRQUT.QUNO
			AND TRQUT.POLTYPE in ('MT', 'MX')  --20121123: Replaced: TRQUT.QUTYPE in ('MT', 'MX', 'CA')  --20121123: Added 'CA'
			AND TRQUT.QUTSTAT = 'ISSUED'
			AND #ReportDIG08_Detail.AUTOSLD = 0
			AND #ReportDIG08_Detail.RENSLD = 0
			AND #ReportDIG08_Detail.CALLSLD = 0
			AND #ReportDIG08_Detail.R65SLD = 0
			AND DATEDIFF(DAY, #ReportDIG08_Detail.ENDDOT, TRQUT.STDOT) <= 31 

		UPDATE #ReportDIG08_Detail
		SET R65SLD = 1,
			R65SLDWEB = CASE WHEN COMNA = 'WEB' THEN 1 ELSE 0 END, -- added INS-21043
			R65SLDCC = CASE WHEN COMNA = 'WEB' THEN 0 ELSE 1 END -- added INS-21043
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO < TRQUT.QUNO
			AND TRQUT.POLTYPE in ('MT', 'MX')  --20121123: Added: 'MX'
			AND TRQUT.QUTSTAT = 'ISSUED'
			AND ABS(DATEDIFF(DAY, #ReportDIG08_Detail.ENDDOT, TRQUT.STDOT)) <= 31
			AND #ReportDIG08_Detail.R65 > 0

		---------------------------------------
		---- start of code added INS-21043 ----
		---------------------------------------

		---- auto renewal counts ----

		UPDATE #ReportDIG08_Detail
		SET RV1VAL = CASE WHEN ISNULL(EXPCARD.ACTNA, '') = '' THEN 1 ELSE 0 END,
			RV1EXP = CASE WHEN ISNULL(EXPCARD.ACTNA, '') = 'CE1' THEN 1 ELSE 0 END
		FROM dbo.QUALT AS QUALT
		LEFT JOIN dbo.QUALT AS EXPCARD
			ON QUALT.CLINO = EXPCARD.CLINO
			AND QUALT.QUNO = EXPCARD.QUNO
			AND EXPCARD.ACTNA = 'CE1'
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA IN ('RV1', 'RV2')

		UPDATE #ReportDIG08_Detail
		SET RV1AB1 = 1,
			VALPAID = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA = 'AB1'

		UPDATE #ReportDIG08_Detail
		SET VALCH1 = 1
		FROM dbo.QUALT AS QUALT
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND #ReportDIG08_Detail.RV1VAL > 0
			AND QUALT.ACTNA = 'CH1'

		UPDATE #ReportDIG08_Detail
		SET VALCH1SLD = 1,
			VALCH1SLDWEB = CASE WHEN COMNA = 'WEB' THEN 1 ELSE 0 END,
			VALCH1SLDCC = CASE WHEN COMNA = 'WEB' THEN 0 ELSE 1 END
		FROM dbo.QUALT AS QUALT
		INNER JOIN dbo.TRQUT AS TRQUT
			ON QUALT.CLINO = TRQUT.CLINO
				AND QUALT.QUNO = TRQUT.QUNO
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA = 'IS7'
			AND TRQUT.QUTSTAT = 'ISSUED'
			AND QUALT.ACTNO NOT IN (SELECT SYQUT.ACTNO
									FROM SYQUT
									WHERE SYQUT.CLINO = QUALT.CLINO
									AND SYQUT.QUNO = QUALT.QUNO
									AND SYQUT.SYQSTAT = 'H')
			AND #ReportDIG08_Detail.RV1VAL > 0
			AND #ReportDIG08_Detail.VALCH1 > 0

		UPDATE #ReportDIG08_Detail
		SET VALSLD = 1,
			VALPAID = 1
		FROM dbo.QUALT AS QUALT
		INNER JOIN dbo.TRQUT AS TRQUT
			ON QUALT.CLINO = TRQUT.CLINO
				AND QUALT.QUNO = TRQUT.QUNO
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA = 'IS7'
			AND TRQUT.QUTSTAT = 'ISSUED'
			AND QUALT.ACTNO NOT IN (SELECT SYQUT.ACTNO
									FROM SYQUT
									WHERE SYQUT.CLINO = QUALT.CLINO
									AND SYQUT.QUNO = QUALT.QUNO
									AND SYQUT.SYQSTAT = 'H')
			AND #ReportDIG08_Detail.RV1VAL > 0
			AND #ReportDIG08_Detail.VALCH1 = 0

		UPDATE #ReportDIG08_Detail
		SET VALPAID = 1
		FROM dbo.QUALT AS QUALT
		INNER JOIN dbo.TRQUT AS TRQUT
			ON QUALT.CLINO = TRQUT.CLINO
				AND QUALT.QUNO = TRQUT.QUNO
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA = 'IS7'
			AND TRQUT.QUTSTAT = 'CANCELLED'
			AND QUALT.ACTNO NOT IN (SELECT SYQUT.ACTNO
									FROM SYQUT
									WHERE SYQUT.CLINO = QUALT.CLINO
									AND SYQUT.QUNO = QUALT.QUNO
									AND SYQUT.SYQSTAT = 'H')
			AND #ReportDIG08_Detail.RV1VAL > 0
			AND #ReportDIG08_Detail.VALCH1 = 0

		UPDATE #ReportDIG08_Detail
		SET EXPSLD = 1,
			EXPSLDWEB = CASE WHEN COMNA = 'WEB' THEN 1 ELSE 0 END,
			EXPSLDCC = CASE WHEN COMNA = 'WEB' THEN 0 ELSE 1 END
		FROM dbo.QUALT AS QUALT
		INNER JOIN dbo.TRQUT AS TRQUT
			ON QUALT.CLINO = TRQUT.CLINO
				AND QUALT.QUNO = TRQUT.QUNO
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND QUALT.ACTNA = 'IS7'
			AND TRQUT.QUTSTAT = 'ISSUED'
			AND QUALT.ACTNO NOT IN (SELECT SYQUT.ACTNO
									FROM SYQUT
									WHERE SYQUT.CLINO = QUALT.CLINO
									AND SYQUT.QUNO = QUALT.QUNO
									AND SYQUT.SYQSTAT = 'H')
			AND #ReportDIG08_Detail.RV1EXP > 0

		---- cancellation counts ----

		UPDATE #ReportDIG08_Detail
		SET CH1AUTOCANX = 1
		FROM dbo.QUALT AS QUALT
			INNER JOIN dbo.TRQUT AS TRQUT
				ON QUALT.CLINO = TRQUT.CLINO
					AND QUALT.QUNO = TRQUT.QUNO
		WHERE #ReportDIG08_Detail.CLINO = QUALT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = QUALT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 > 0
			AND QUALT.ACTNA IN ('R14', 'D10')
			AND TRQUT.QUTSTAT = 'CANCELLED'

		UPDATE #ReportDIG08_Detail
		SET RV1LOST = 1
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = TRQUT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.CH1 = 0
			AND TRQUT.QUTSTAT = 'LOST'

		UPDATE #ReportDIG08_Detail
		SET RVSLDCANX = 1
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = TRQUT.QUNO
			AND #ReportDIG08_Detail.RV1 > 0
			AND #ReportDIG08_Detail.RV1AB1 > 0
			AND TRQUT.QUTSTAT = 'CANCELLED'

		UPDATE #ReportDIG08_Detail
		SET CANX = 1
		FROM dbo.TRQUT AS TRQUT
		WHERE #ReportDIG08_Detail.CLINO = TRQUT.CLINO
			AND #ReportDIG08_Detail.RENQUNO = TRQUT.QUNO
			AND TRQUT.QUTSTAT = 'CANCELLED'

		-------------------------------------
		---- end of code added INS-21043 ----
		-------------------------------------

SELECT * FROM #ReportDIG08_Detail

--Clean up
DROP TABLE #ReportDIG08_Detail

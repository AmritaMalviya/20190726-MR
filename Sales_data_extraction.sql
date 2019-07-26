Select Channel, 
Case
		Mon When 1 then 'January'
			When 2 then 'February'
			When 3 then 'March'
			When 4 then 'April'
			When 5 then 'May'
			When 6 then 'June'
			When 7  then 'July'
			When 8 then 'August'
			When 9 then 'September'
			When 10 then 'October'
			When 11 then 'November'
			when 12 then 'December'
			end Month
, Year, count(status) as Total_sales
From
	( 
		SELECT TRQ.qutstat as Status,  Month(trq.borndt) as Mon, Year(trq.borndt) Year, 
			CASE   
						when SOR.srcetype in ('WEB AFFINITY', 'AFFINITY    ', 'AGENT       ') then 'AFFINITY'
						when SOR.srcetype in ('WEBSITE     ', 'MISC        ') then 'WEBSITE' 
						ELSE 'AFILIATE' 
			END Channel
			From leocti_rz.leoctidb_leocti_dbo_trqut as TRQ
			INNER JOIN leocti_rz.leoctidb_leocti_dbo_srcet as SOR on TRQ.srceco = SOR.srceco
			WHERE TRQ.QUTSTAT IN ('ISSUED   ', 'REISSUED ','CANCELLED')
			AND SOR.srcetype in ('AFILIATE    ', 'WEB AFFINITY', 'AFFINITY    ', 'AGENT       ', 'WEBSITE     ', 'MISC        ')
			AND TRQ.BORNDT > '2018-05-01'
			AND TRQ.BORNDT < '2019-05-01'
	) as tempTable
	group by Channel,Mon, Year
	order by Year, Mon, Channel
/*
qSold_and_AuctionResults

1.  The volume and maximum value of licences that have been issued and have
    a legal effective date in FTA in the reporting period.
    In this and other BCTS Reports, these criteria define 'Sold'
    licences. The auction date can be any date.

    Sold criteria:
        i.  Legal Effective Date (FTA) is in the reporting period,
        ii. Licence has been issued, so its FTA licence state is
            one of the following:
                'HI',  -- Issued
                'HC',  -- Closed
                'LC',  -- Logging Complete
                'HX',  -- Cancelled
                'HS',  -- Suspended
                'HRS'  -- Harvesting Rights Surrendered

and

2.  Auctions results for auctions during the reporting period,
    including the volume of licences, the maximum value of awarded licences,
    and no sale rationale for unsuccessful sales. BCTS Admin data only.

    Some of these auctioned licences may have legal effective dates in FTA, but
    they are not considered 'Sold' until the licence has been issued.

This query includes a row for each of the 12 BC Timber Sales business areas
with null values for all columns except the business area columns:
Business_Area_Region_Category, Business_Area_Region, Business_Area, Business_Area_Code.
The purpose of these rows is to ensure all business areas are
included in output tables and charts, even if they do not have
any licences that are sold or auctioned during the report period.
*/

select distinct
    case
        when
            ou.org_unit_code in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            ou.org_unit_code in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as Business_Area_Region_Category,
    case
        when
            ou.org_unit_code in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            ou.org_unit_code in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            ou.org_unit_code in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as Business_Area_Region,
    decode(
        ou.org_unit_code,
        null,
        null,
        replace(
            decode(
                ou.org_unit_name,
                'Seaward Timber Sales Office',
                'Seaward-Tlasta',
                ou.org_unit_name
            ) || ' (' || ou.org_unit_code || ')',
            ' Timber Sales Office',
            ''
        )
    ) as Business_Area,
    ou.org_unit_code as Business_Area_Code,
    ts.forest_file_id,
    pfu.file_type_code,
    case
        when
            cc.description is null
        then
            ts.bcts_category_code
        else
            cc.description || ' (' || ts.bcts_category_code || ')'
        end as BCTS_Category,
    ts.auction_date as BCTS_Admin_Auction_Date,
    tt.legal_effective_dt as FTA_Legal_Effective_Date,
    sold_licence_bid_info.sale_volume as sold_licence_volume,
    decode(
        ts.bcts_category_code,
        'A',
        sold_licence_bid_info.sale_volume
    ) as cat_a_sold_licence_volume,
    decode(
        ts.bcts_category_code,
        '2',
        sold_licence_bid_info.sale_volume
    ) as cat_2_sold_licence_volume,
    decode(
        ts.bcts_category_code,
        '4',
        sold_licence_bid_info.sale_volume
    ) as cat_4_sold_licence_volume,
    sold_licence_bid_info.sold_licence_maximum_value,
    decode(
        ts.bcts_category_code,
        'A',
        sold_licence_bid_info.sold_licence_maximum_value
    ) as cat_a_sold_licence_maximum_value,
    decode(
        ts.bcts_category_code,
        '2',
        sold_licence_bid_info.sold_licence_maximum_value
    ) as cat_2_sold_licence_maximum_value,
    decode(
        ts.bcts_category_code,
        '4',
        sold_licence_bid_info.sold_licence_maximum_value
    ) as cat_4_sold_licence_maximum_value,
    fc_sold.client_number as sold_licence_client_number,
    (
        decode(fc_sold.legal_first_name, null, null, fc_sold.legal_first_name || ' ')
        || decode(fc_sold.legal_middle_name, null, null, fc_sold.legal_middle_name || ' ')
        || fc_sold.client_name
    ) as sold_licence_client_name,
    awarded_sale_info.sale_volume as awarded_licence_volume,
    decode(
        ts.bcts_category_code,
        'A',
        awarded_sale_info.sale_volume
    ) as cat_a_awarded_licence_volume,
    decode(
        ts.bcts_category_code,
        '2',
        awarded_sale_info.sale_volume
    ) as cat_2_awarded_licence_volume,
    decode(
        ts.bcts_category_code,
        '4',
        awarded_sale_info.sale_volume
    ) as cat_4_awarded_licence_volume,
    awarded_sale_info.awarded_licence_maximum_value,
    fc_awarded.client_number as awarded_licence_client_number,
    (
        decode(fc_awarded.legal_first_name, null, null, fc_awarded.legal_first_name || ' ')
        || decode(fc_awarded.legal_middle_name, null, null, fc_awarded.legal_middle_name || ' ')
        || fc_awarded.client_name
    ) as awarded_licence_client_name,
    no_sale_sale_info.no_sale_rationale,
    decode(
        ts.bcts_category_code,
        'A',
        no_sale_sale_info.no_sale_rationale
    ) as cat_a_no_sale_rationale,
    decode(
        ts.bcts_category_code,
        '2',
        no_sale_sale_info.no_sale_rationale
    ) as cat_2_no_sale_rationale,
    decode(
        ts.bcts_category_code,
        '4',
        no_sale_sale_info.no_sale_rationale
    ) as cat_4_no_sale_rationale,
    no_sale_sale_info.sale_volume as no_sale_volume,
    decode(
        ts.bcts_category_code,
        'A',
        no_sale_sale_info.sale_volume
    ) as cat_a_no_sale_volume,
    decode(
        ts.bcts_category_code,
        '2',
        no_sale_sale_info.sale_volume
    ) as cat_2_no_sale_volume,
    decode(
        ts.bcts_category_code,
        '4',
        no_sale_sale_info.sale_volume
    ) as cat_4_no_sale_volume,
    case
        when
            pfu.file_status_st is not NULL
        THEN
            tfsc.description || ' (' || pfu.file_status_st || ')'
        ELSE
            NULL
        end as FTA_File_Status,
    pfu.file_status_date as FTA_File_Status_Date,
    -- extract(year from(add_months(tt.legal_effective_dt, 9))) as Legal_Effective_Fiscal,
    -- decode(tt.legal_effective_dt, null, null, 'Q' || Ceil((EXTRACT(Month From Add_Months(tt.legal_effective_dt, -3)))/3)) AS Legal_Effective_Quarter,
    case
        when
            ts.no_sale_rationale_code is null

            AND pfu.file_status_st IN (
                'HI',  -- Issued
                'HC',  -- Closed
                'LC',  -- Logging Complete
                'HX',  -- Cancelled
                'HS',  -- Suspended
                'HRS'  -- Harvesting Rights Surrendered
            )

            /* Tenure term legal effective date in reporting period*/
            and tt.legal_effective_dt
                between To_Date('2023-11-25', 'YYYY-MM-DD')  -- Date: beginning of reporting period
                and To_Date('2023-12-08', 'YYYY-MM-DD')  -- Date: end of reporting period
        then
            'Y'
        end as QA_Sold_in_Report_Period,
    case
        when
            ts.auction_date
                between To_Date('2023-11-25', 'YYYY-MM-DD')  -- Date: beginning of reporting period
                and To_Date('2023-12-08', 'YYYY-MM-DD')  -- Date: end of reporting period
        then
            'Y'
        end as QA_Auction_in_Report_Period,
    decode(ou.org_unit_code, null, 'BCTS Org not in FTA') as qa_missing_bcts_org_fta,
    decode(pfu.file_type_code, 'B20', null, pfu.file_type_code) as QA_non_B20_licence,
    case
        when
            ts.auction_date > sysdate
        then
            'Future auction (BCTS Admin)'
        when
            (
                sold_licence_maximum_value is null
                or sold_licence_maximum_value = 0
            )
            and
            (
                awarded_licence_maximum_value is null
                or awarded_licence_maximum_value = 0
            )
            and ts.no_sale_rationale_code is null
        then
            'Auction result data missing (BCTS Admin)'
        end as QA_auction_results_missing_bcts_admin,
    case
        when
            (
                sold_licence_maximum_value is null
                or sold_licence_maximum_value = 0
            )
            and
            (
                awarded_licence_maximum_value is null
                or awarded_licence_maximum_value = 0
            )
            and ts.no_sale_rationale_code is null
        then
            'select * from the.bcts_tenure_bidder where forest_file_id = '''
            || ts.forest_file_id
            || ''' and auction_date = to_date('''
            || to_char(ts.auction_date, 'YYYY-MM-DD')
            || ''', ''YYYY-MM-DD'') order by sale_awarded_ind desc, bonus_bid desc, bonus_offer desc;'
        end as QA_BCTS_Admin_Tenure_Bidder__Sale_Awarded_Ind,
    case
        when
            (
                sold_licence_maximum_value is null
                or sold_licence_maximum_value = 0
            )
            and
            (
                awarded_licence_maximum_value is null
                or awarded_licence_maximum_value = 0
            )
            and ts.no_sale_rationale_code is null
        then
            'select * from the.bcts_timber_sale where forest_file_id = '''
            || ts.forest_file_id
            || ''' order by auction_date desc;'
        end as QA_BCTS_Admin__No_Sale_Rationale_Code,
    case
        when
            (
                sold_licence_maximum_value is null
                or sold_licence_maximum_value = 0
            )
            and
            (
                awarded_licence_maximum_value is null
                or awarded_licence_maximum_value = 0
            )
            and ts.no_sale_rationale_code is null
        then
            'select * from the.prov_forest_use pfu left join the.tenure_term tt on pfu.forest_file_id = tt.forest_file_id where pfu.forest_file_id = '''
            || ts.forest_file_id
            || ''''
        end as QA_FTA_Licence_Info,
    case
        when
            (
                sold_licence_maximum_value is null
                or sold_licence_maximum_value = 0
            )
            and
            (
                awarded_licence_maximum_value is null
                or awarded_licence_maximum_value = 0
            )
            and ts.no_sale_rationale_code is null
        then
            'select * from forestview.v_licence_activity_all where licence_id = '''
            || ts.forest_file_id
            || ''' order by activity_date desc;'
        end as QA_Licence_Activity_LRM,
    case
        when
            (
                sold_licence_maximum_value is null
                or sold_licence_maximum_value = 0
            )
            and
            (
                awarded_licence_maximum_value is null
                or awarded_licence_maximum_value = 0
            )
            and ts.no_sale_rationale_code is null
        then
            'https://bcbid.gov.bc.ca/page.aspx/en/rfp/request_browse_public'
        end as QA_BC_Bid_Website

FROM
    the.tenure_term tt,
    the.bcts_timber_sale ts,
    the.bcts_category_code cc,
    the.prov_forest_use pfu,
    the.tenure_file_status_code tfsc,
    the.org_unit ou,
    the.forest_client fc_sold,
    the.forest_client fc_awarded,

    /* Bid Info for Sold Licences (Licences issued within reporting period) */
    (
        select
            ts0.forest_file_id,
            ts0.auction_date,
            ts0.total_upset_value as cruise_total_upset_value,
            ts0.UPSET_RATE as scale_upset_rate,
            ts0.sale_volume as sale_volume,
            tb.bonus_bid AS sold_licence_bonus_bid,
            tb.bonus_offer AS sold_licence_bonus_offer,
            case
                when
                    ts0.TOTAL_UPSET_VALUE > 0
                then
                        round(
                            ts0.TOTAL_UPSET_VALUE + tb.bonus_offer,  -- Cruise-based licence pricing
                            2
                        )
                else
                        round(
                            (ts0.UPSET_RATE + tb.BONUS_BID) * ts0.sale_volume,  -- Scale-based licence pricing
                            2
                        )
                end as sold_licence_maximum_value,
            tb.client_number as sold_licence_client_number

        from
            the.bcts_timber_sale ts0,
            the.bcts_tenure_bidder tb,
            the.prov_forest_use pfu,
            the.tenure_term tt

        where
            pfu.forest_file_id = ts0.forest_file_id
            and pfu.forest_file_id = tt.forest_file_id
            and ts0.forest_file_id = tb.forest_file_id
            and ts0.auction_date = tb.auction_date
            and upper(tb.sale_awarded_ind) = 'Y'  -- Only look at the winning bid
            and ts0.no_sale_rationale_code is null

            AND pfu.file_status_st IN (
                'HI',  -- Issued
                'HC',  -- Closed
                'LC',  -- Logging Complete
                'HX',  -- Cancelled
                'HS',  -- Suspended
                'HRS'  -- Harvesting Rights Surrendered
            )

            /* Tenure term legal effective date in reporting period*/
            AND tt.legal_effective_dt
                between To_Date('2023-11-25', 'YYYY-MM-DD')  -- Date: beginning of reporting period
                and To_Date('2023-12-08', 'YYYY-MM-DD')  -- Date: end of reporting period
    ) sold_licence_bid_info,


    /* Bid Info for Successful Auctions (Licences awarded within reporting period) */
    (
        select
            ts1.forest_file_id,
            ts1.auction_date,
            ts1.total_upset_value as cruise_total_upset_value,
            ts1.UPSET_RATE as scale_upset_rate,
            ts1.sale_volume as sale_volume,
            tb.bonus_bid AS awarded_sale_bonus_bid,
            tb.bonus_offer AS awarded_sale_bonus_offer,
            case
                when
                    ts1.TOTAL_UPSET_VALUE > 0
                then
                        round(
                            ts1.TOTAL_UPSET_VALUE + tb.bonus_offer,  -- Cruise-based licence pricing
                            2
                        )
                else
                        round(
                            (ts1.UPSET_RATE + tb.BONUS_BID) * ts1.sale_volume,  -- Scale-based licence pricing
                            2
                        )
                end as awarded_licence_maximum_value,
            tb.client_number as awarded_licence_client_number

        from
            the.bcts_timber_sale ts1,
            the.bcts_tenure_bidder tb

        where
            ts1.forest_file_id = tb.forest_file_id
            and ts1.auction_date = tb.auction_date
            and upper(tb.sale_awarded_ind) = 'Y'  -- Only look at the winning bid
            and ts1.auction_date
                between To_Date('2023-11-25', 'YYYY-MM-DD')  -- Date: beginning of reporting period
                and To_Date('2023-12-08', 'YYYY-MM-DD')  -- Date: end of reporting period
    ) awarded_sale_info,

    /* No Bid Sale Info */
    (
        select
            ts2.forest_file_id,
            ts2.auction_date,
            ts2.sale_volume,
            case
                when
                    nsrc.description is null
                then
                    ts2.no_sale_rationale_code
                else
                    nsrc.description || ' (' || ts2.no_sale_rationale_code || ')'
                end as no_sale_rationale
        from
            the.bcts_timber_sale ts2,
            the.no_sale_rationale_code nsrc

        where
            ts2.no_sale_rationale_code = nsrc.no_sale_rationale_code (+)
            and ts2.no_sale_rationale_code is not null
            and ts2.auction_date
                between to_date('2023-11-25', 'YYYY-MM-DD')  -- Date: beginning of reporting period
                and to_date('2023-12-08', 'YYYY-MM-DD')  -- Date: end of reporting period
    ) no_sale_sale_info

WHERE
    ts.forest_file_id = tt.forest_file_id (+)
    AND ts.forest_file_id = pfu.forest_file_id (+)
    AND pfu.bcts_org_unit = ou.org_unit_no (+)
    AND pfu.file_status_st = tfsc.tenure_file_status_code (+)
    and ts.bcts_category_code = cc.bcts_category_code (+)
    AND ts.forest_file_id = sold_licence_bid_info.forest_file_id (+)
    AND ts.auction_date = sold_licence_bid_info.auction_date (+)
    and ts.forest_file_id = awarded_sale_info.forest_file_id (+)
    and ts.auction_date = awarded_sale_info.auction_date (+)
    and ts.forest_file_id = no_sale_sale_info.forest_file_id (+)
    and ts.auction_date = no_sale_sale_info.auction_date (+)
    and sold_licence_bid_info.sold_licence_client_number = fc_sold.client_number (+)
    and awarded_sale_info.awarded_licence_client_number = fc_awarded.client_number (+)
    and (
        /* Criteria for Licences Sold in reporting period*/
        (
            ts.no_sale_rationale_code is null

            AND pfu.file_status_st IN (
                'HI',  -- Issued
                'HC',  -- Closed
                'LC',  -- Logging Complete
                'HX',  -- Cancelled
                'HS',  -- Suspended
                'HRS'  -- Harvesting Rights Surrendered
            )

            /* Tenure term legal effective date in reporting period*/
            AND tt.legal_effective_dt
                between to_date('2023-11-25', 'YYYY-MM-DD')  -- Date: beginning of reporting period
                and to_date('2023-12-08', 'YYYY-MM-DD')  -- Date: end of reporting period
        )
        /* Criteria for auctions within the reporting period */
        or ts.auction_date
            between to_date('2023-11-25', 'YYYY-MM-DD')  -- Date: beginning of reporting period
            and to_date('2023-12-08', 'YYYY-MM-DD')  -- Date: end of reporting period
    )

/*
This UNION query adds a row for each of the 12 business areas
with null values for all columns except the business area columns:
Business_Area_Region_Category, Business_Area_Region, Business_Area, Business_Area_Code.
The purpose of these rows is to ensure all business areas are
included in output tables and charts, even if they do not have
any licences that are sold or auctioned during the report period.
*/
union select
    case
        when
            ou.org_unit_code in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            ou.org_unit_code in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as Business_Area_Region_Category,
    case
        when
            ou.org_unit_code in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            ou.org_unit_code in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            ou.org_unit_code in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as Business_Area_Region,
    decode(
        ou.org_unit_code,
        null,
        null,
        replace(
            decode(
                ou.org_unit_name,
                'Seaward Timber Sales Office',
                'Seaward-Tlasta',
                ou.org_unit_name
            ) || ' (' || ou.org_unit_code || ')',
            ' Timber Sales Office',
            ''
        )
    ) as Business_Area,
    ou.org_unit_code as Business_Area_Code,
    null as forest_file_id,
    null as file_type_code,
    null as BCTS_Category,
    null as BCTS_Admin_Auction_Date,
    null as FTA_Legal_Effective_Date,
    null as sold_licence_volume,
    null as cat_a_sold_licence_volume,
    null as cat_2_sold_licence_volume,
    null as cat_4_sold_licence_volume,
    null as sold_licence_maximum_value,
    null as cat_a_sold_licence_maximum_value,
    null as cat_2_sold_licence_maximum_value,
    null as cat_4_sold_licence_maximum_value,
    null as sold_licence_client_number,
    null as sold_licence_client_name,
    null as awarded_licence_volume,
    null as ,
    null as ,
    null as ,
    null as awarded_licence_maximum_value,
    null as ,
    null as ,
    null as ,
    null as awarded_licence_client_number,
    null as awarded_licence_client_name,
    null as no_sale_rationale,
    null as ,
    null as ,
    null as ,
    null as no_sale_volume,
    null as ,
    null as ,
    null as ,
    null as FTA_File_Status,
    null as FTA_File_Status_Date,
    null as QA_Sold_in_Report_Period,
    null as QA_Auction_in_Report_Period,
    null as qa_missing_bcts_org_fta,
    null as QA_non_B20_licence,
    null as QA_auction_results_missing_bcts_admin,
    null as QA_BCTS_Admin_Tenure_Bidder__Sale_Awarded_Ind,
    null as QA_BCTS_Admin__No_Sale_Rationale_Code,
    null as QA_FTA_Licence_Info,
    null as QA_Licence_Activity_LRM,
    null as QA_BC_Bid_Website

    from
        org_unit ou

    where
        /* BCTS Business Area org unit numbers in the org_unit table */
        ou.org_unit_no in (
            1808,
            1812,
            1816,
            1813,
            1815,
            1814,
            1810,
            1811,
            1817,
            1807,
            1809,
            1818
        )

ORDER BY
    business_area_region_category desc,
    business_area_region,
    business_area,
    bcts_category,
    forest_file_id,
    bcts_admin_auction_date desc
;


/*
qSold_detail
Licences issued legal effective in report period.
*/
SELECT business_area AS [Business Area], forest_file_id AS Licence, BCTS_Category, bcts_admin_auction_date AS Auction, fta_legal_effective_date AS Issued, Format(sold_licence_volume, "#,###") AS [Volume (cubic metres)], Format(sold_licence_maximum_value, "$#,###") AS [Max Value], sold_licence_client_name AS [Client Name]
FROM qSold_and_AuctionResults
WHERE qa_sold_in_report_period = 'Y';

/*
qAwarded_detail
Auctions in report period with a successful bidder.
*/
SELECT business_area AS [Business Area], forest_file_id AS Licence, BCTS_Category, bcts_admin_auction_date AS Auction, Format(awarded_licence_volume, "#,###") AS [Volume (cubic metres)], Format(awarded_licence_maximum_value, "$#,###") AS [Max Value], awarded_licence_client_name AS [Client Name]
FROM qSold_and_AuctionResults
WHERE QA_Auction_in_Report_Period = 'Y'     and no_sale_rationale is null;

/*
qNotAwarded_detail
Auctions in report period with no successful bidder.
*/
SELECT business_area_region AS Region, business_area AS [Business Area], forest_file_id AS Licence, BCTS_Category, bcts_admin_auction_date AS Auction, Format(no_sale_volume, "#,###") AS [Volume (cubic metres)], no_sale_rationale AS [No Sale Rationale]
FROM qSold_and_AuctionResults
WHERE QA_Auction_in_Report_Period = 'Y'     and no_sale_rationale is not null;




/*
qSold_and_AuctionResults_byBA

This query aggregates results of the qSold_and_AuctionResults
query by business area.

This query is not required if aggregating qSold_and_AuctionResults in another
tool, such as an Excel pivot table.
*/
SELECT *
FROM
    (
        SELECT
            iif(
                d.divi_short_code in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC'),
                'Interior',
                iif(
                    d.divi_short_code in ('TCH', 'TST', 'TSG'),
                    'Coast',
                    Null
                )
            ) AS Business_Area_Region_Category,
            iif(
                d.divi_short_code in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN'),
                'North Interior',
                iif(
                    d.divi_short_code in ('TCC', 'TKA', 'TKO', 'TOC'),
                    'South Interior',
                    iif(
                        d.divi_short_code in ('TCH', 'TST', 'TSG'),
                        'Coast',
                        Null
                    )
                )
            ) AS Business_Area_Region,
            iif(
                d.divi_division_name = 'Seaward',
                'Seaward-Tlasta',
                d.divi_division_name
            ) & ' (' & d.divi_short_code & ')' AS Business_Area,
            iif(count(sold_licence_maximum_value) = 0, null, count(sold_licence_maximum_value)) AS Number_Licences_Sold,
            sum(sold_licence_volume) AS Sold_Licences_Volume,
            sum(sold_licence_maximum_value) AS Sold_Licences_Maximum_Value,
            iif(count(awarded_licence_maximum_value) = 0, null, count(awarded_licence_maximum_value)) AS Number_Licences_Awarded,
            sum(awarded_licence_volume) as Awarded_Licences_Volume,
            sum(awarded_licence_maximum_value) AS Awarded_Licences_Maximum_Value,
            iif(count(no_sale_rationale) = 0, null, count(no_sale_rationale)) AS Number_No_Sale_Auctions,
            sum(no_sale_volume) as No_Sales_Volume,
            iif(count(qa_missing_bcts_org_fta) = 0, null, count(qa_missing_bcts_org_fta)) AS QA_Number_Licences_Without_BCTS_Org_Unit_FTA,
            iif(count(QA_non_B20_licence) = 0, null, count(QA_non_B20_licence)) AS QA_Number_Non_B20_Licences_Included,
            iif(count(QA_auction_results_missing_bcts_admin) = 0, null, count(QA_auction_results_missing_bcts_admin)) AS QA_Number_Auctions_Missing_Data_BCTS_Admin
        FROM
            forest_division AS d
            LEFT JOIN qSold_and_AuctionResults AS smvar
            ON d.divi_short_code = smvar.Business_Area_Code
        GROUP BY
            d.divi_short_code,
            d.divi_division_name
        ) AS sold_max_value_all_business_areas
ORDER BY
    len(business_area_region) DESC,
    business_area_region,
    business_area
;
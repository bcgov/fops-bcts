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
    replace(
        decode(
            ou.org_unit_name,
            'Seaward Timber Sales Office',
            'Seaward-Tlasta',
            ou.org_unit_name
        ) || ' (' || ou.org_unit_code || ')',
        ' Timber Sales Office',
        ''
    ) as Business_Area,
    ou.org_unit_code as Business_Area_Code,
    pfu.mgmt_unit_type,
    pfu.mgmt_unit_id,
    ta.description,
    ts.forest_file_id,
    ts.BCTS_CATEGORY_CODE,
    c.DESCRIPTION AS Category,
    ts.auction_date,
    ts.sale_volume,
    hs.sale_volume AS FTA_VOLUME,
    Nvl(ads.net_cruise_volume, 0) + Nvl(ads.decked_volume, 0)
        + Nvl(ads.rw_volume, 0) + Nvl(ads.OBLIGATORY_DECIDUOUS_VOLUME, 0) AS ECAS_TOTAL_VOLUME,
    ads.net_cruise_volume AS ECAS_cruise_volume,
    ads.OBLIGATORY_DECIDUOUS_VOLUME AS ECAS_DECIDUOUS_VOLUME,
    ads.decked_volume AS ECAS_decked_volume,
    ads.rw_volume AS ECAS_rw_volume,
    bid_info.client_count,
    ts.no_sale_rationale_code,
    /*Extract(Year From Add_Months(ts.auction_date, 9)) AS Fiscal_Advertised,*/
    'Q' || Ceil(EXTRACT(Month From Add_Months(ts.auction_date, -3))/3) AS Quarter,
    TE.TENURE_TERM,
    TE.INITIAL_EXPIRY_DT,
    TE.CURRENT_EXPIRY_DT,
    bid_info.awarded_ind,
    pfu.FILE_STATUS_ST,
    au_cnt.First_Auction_Date,
    au_cnt.Last_Auction_Date,
    AU_CNT.Auction_Count,
    decode(ts.auction_date, au_cnt.first_auction_date, 'Y', 'N') as First_Auction,
    decode(ts.auction_date, au_cnt.last_auction_date, 'Y', 'N') as Last_Auction,
    case
        when
            ts.auction_date = au_cnt.last_auction_date
            and ts.no_sale_rationale_code is not null
        then
            'This auction is the last auction for the licence in the report period and is a no sale.'
        end as last_auction_no_sale,
    --DECODE(NVL(AU_CNT.Auction_Count, 1), 1, 'N', 'Y') AS READVERTISED,
    ads.ECAS_ID,
    ads.appraisal_effective_date,
    CASE
        WHEN
            ads.ecas_id is not null
        THEN
            a_st_code.description || ' (' || ads.appraisal_status_code || ')'
        ELSE
            null
        END AS ECAS_Status,
    ecas_id.total_non_scenario_appraisals_same_effective_date

from
    the.bcts_timber_sale ts,
    the.harvest_sale hs,
    the.BCTS_CATEGORY_CODE c,
    the.prov_forest_use pfu,
    the.org_unit ou,
    THE.TENURE_TERM TE,
    the.tsa_number_code ta,
    the.tfl_number_code tf,
    (
        select
            ts.forest_file_id,
            count(ts.auction_date) as auction_count,
            min(ts.auction_date) as first_auction_date,
            max(ts.auction_date) as last_auction_date
        from
            bcts_timber_sale ts,
            (
                select
                forest_file_id,
                auction_date
                from bcts_timber_sale
                where
                    Nvl(no_sale_rationale_code, ' ') <> 'TB'
                    and auction_date <= to_date('2024-01-05', 'YYYY-MM-DD')  -- Date: end of reporting period
            ) auction_filter
        where
            ts.forest_file_id = auction_filter.forest_file_id
            and ts.auction_date = auction_filter.auction_date
        group by
            ts.forest_file_id
    Order By
1
    ) AU_CNT,
    (
        SELECT
            b.forest_file_id,
            b.auction_date,
            Count(b.client_number) AS client_count,
            Max(b.sale_awarded_ind) AS awarded_ind
        FROM
            the.bcts_tenure_bidder b
        WHERE
            b.auction_date
                    BETWEEN To_Date('2023-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal
                    AND To_Date('2024-01-05', 'YYYY-MM-DD')  -- Date: end of reporting period
    GROUP BY
        b.forest_file_id,
        b.auction_date
    ) bid_info,

    /* Find the maximum appraisal effective date for the licence
    where the appraisal status is not Scenario (SCN).
    If there are multiple non-scenario appraisals on the same date for the licence,
    choose the one with the largest ecas_id. */
    (
        select
            ads0.forest_file_id,
            max(ads0.ecas_id) as ecas_id,
            count(*) as total_non_scenario_appraisals_same_effective_date
        from
            the.appraisal_data_submission ads0
            join (
                select
                    ads_no_scn.forest_file_id,
                    max(ads_no_scn.appraisal_effective_date) as max_appraisal_effective_date
                from
                    /* ECAS data without scenario status */
                    (
                        select
                            *
                        from
                            the.appraisal_data_submission
                        WHERE
                            appraisal_status_code not in ('SCN')  -- Scenario
                    ) ads_no_scn
                group by
                    ads_no_scn.forest_file_id

            ) ads1
                on ads0.forest_file_id = ads1.forest_file_id
                and ads0.appraisal_effective_date = ads1.max_appraisal_effective_date
        where
            /* Again, remove scenario status for cases when there are
            multiple appraisals on the max_appraisal_effective_date. */
            ads0.appraisal_status_code not in ('SCN')
        group by ads0.forest_file_id
    ) ECAS_ID,

    the.appraisal_data_submission ads,
    the.appraisal_status_code a_st_code

where
    ts.auction_date
        BETWEEN To_Date('2023-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal
        AND To_Date('2024-01-05', 'YYYY-MM-DD')  -- Date: end of reporting period
    AND ts.forest_file_id = hs.forest_file_id(+)
    AND ts.BCTS_CATEGORY_CODE = c.BCTS_CATEGORY_CODE(+)
    AND ts.forest_file_id = pfu.forest_file_id
    AND pfu.bcts_org_unit = ou.org_unit_no
    AND TS.FOREST_FILE_ID = TE.FOREST_FILE_ID(+)
    and pfu.MGMT_UNIT_ID = ta.TSA_NUMBER(+)
    and pfu.mgmt_unit_id = tf.tfl_number(+)
    AND ts.forest_file_id = AU_CNT.forest_file_id(+)
    AND ts.forest_file_id = bid_info.forest_file_id(+)
    AND ts.auction_date = bid_info.auction_date(+)
    AND ts.forest_file_id = ECAS_ID.forest_file_id (+)
    AND ECAS_ID.forest_file_id = ads.forest_file_id (+)
    AND ECAS_ID.ECAS_ID = ads.ECAS_ID (+)
    AND ads.appraisal_status_code = a_st_code.appraisal_status_code (+)
    AND Nvl(ts.no_sale_rationale_code, ' ') <> 'TB'

order by
    length(business_area_region) desc,
    business_area_region,
    business_area,
    ts.forest_file_id,
    ts.auction_date
;

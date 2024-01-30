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
    pfu.MGMT_UNIT_TYPE,
    pfu.mgmt_unit_id,
    decode(
        pfu.mgmt_unit_type,
        'U',
        ta.DESCRIPTION,
        tf.DESCRIPTION
    ) AS DESCRIPTION,
    ts.forest_file_id,
    ts.BCTS_CATEGORY_CODE,
    c.DESCRIPTION AS Category,
    ts.auction_date,
    ts.sale_volume,
    hs.sale_volume AS FTA_VOLUME,
    (
        Nvl(ads.net_cruise_volume, 0)
        + Nvl(ads.decked_volume, 0)
        + Nvl(ads.rw_volume, 0)
        + Nvl(ads.OBLIGATORY_DECIDUOUS_VOLUME, 0)
    ) AS ECAS_TOTAL_VOLUME,
    ads.net_cruise_volume AS ECAS_cruise_volume,
    ads.OBLIGATORY_DECIDUOUS_VOLUME AS ECAS_DECIDUOUS_VOLUME,
    ads.decked_volume AS ECAS_decked_volume,
    ads.rw_volume AS ECAS_rw_volume,
    bid_info.client_count,
    bid_info.awarded_ind,
    ts.no_sale_rationale_code,
    case
        when
            pfu.file_status_st is not NULL
        THEN
            tfsc.description || ' (' || pfu.file_status_st || ')'
        ELSE
            NULL
        end as FTA_File_Status,
    pfu.file_status_date,
    tt.legal_effective_dt,
    extract(year from(add_months(tt.legal_effective_dt, 9))) as Legal_Effective_Fiscal,
    'Q' || Ceil((EXTRACT(Month From Add_Months(tt.legal_effective_dt, -3)))/3) AS Quarter,
    TT.TENURE_TERM,
    TT.INITIAL_EXPIRY_DT,
    TT.CURRENT_EXPIRY_DT,
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
FROM
    the.tenure_term tt,
    the.bcts_timber_sale ts,
    the.harvest_sale hs,
    the.BCTS_CATEGORY_CODE c,
    the.prov_forest_use pfu,
    the.tenure_file_status_code tfsc,
    the.org_unit ou,
    the.tsa_number_code ta,
    the.tfl_number_code tf,
    (
        SELECT
            forest_file_id,
            auction_date,
            client_count,
            awarded_ind,
            Rank() Over (Partition By forest_file_id Order By auction_date Desc) Auction_Rank
        From
            (
                SELECT
                    tb.forest_file_id,
                    tb.auction_date,
                    Count(DISTINCT tb.client_number) AS client_count,
                    Max(tb.sale_awarded_ind) awarded_ind
                FROM
                    the.bcts_tenure_bidder tb
                WHERE
                    /*
                    Successful sales have ineligible_ind = 'N'.
                    This query uses this value to help identify successful sales,
                    and count the number of eligible bidders.
                    There are 6 legacy sales for which this criteria is not true:

                    select
                        forest_file_id,
                        auction_date,
                        client_number,
                        sale_awarded_ind,
                        ineligible_ind
                    from
                        the.bcts_tenure_bidder
                    where
                        upper(sale_awarded_ind) = 'Y'
                        and upper(ineligible_ind) <> 'N'
                    order by
                        auction_date
                     */
                    INELIGIBLE_IND = 'N'
                GROUP BY
                    tb.forest_file_id,
                    tb.auction_date
            )
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
                            appraisal_status_code not in ('SCN')  -- not Scenario status
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

WHERE
    tt.forest_file_id = ts.forest_file_id
    AND tt.forest_file_id = pfu.forest_file_id (+)
    AND pfu.bcts_org_unit = ou.org_unit_no
    AND pfu.mgmt_unit_id = ta.tsa_number (+)
    AND pfu.mgmt_unit_id = tf.tfl_number (+)
    AND pfu.file_status_st = tfsc.tenure_file_status_code (+)
    AND ts.forest_file_id = hs.forest_file_id (+)
    AND ts.forest_file_id = ECAS_ID.forest_file_id (+)
    AND ECAS_ID.forest_file_id = ads.forest_file_id (+)
    AND ECAS_ID.ECAS_ID = ads.ECAS_ID (+)
    AND ts.forest_file_id = bid_info.forest_file_id (+)
    AND ts.auction_date = bid_info.auction_date (+)
    AND ts.BCTS_CATEGORY_CODE = c.BCTS_CATEGORY_CODE (+)
    AND ads.appraisal_status_code = a_st_code.appraisal_status_code (+)

    AND pfu.file_status_st IN ('HI', 'HC', 'LC', 'HX', 'HS', 'HRS')

    /* Tenure term legal effective date between
    beginning of fiscal (April 1st) to end of reporting period. */
    AND tt.legal_effective_dt BETWEEN
        To_Date('2023-04-01', 'YYYY-MM-DD')  -- Date: beginning of current fiscal (XXXX-04-01)
        AND To_Date('2024-01-05', 'YYYY-MM-DD')  -- Date: end of reporting period
    AND ts.no_sale_rationale_code IS NULL  -- There are two legacy unsuccessful sales that otherwise would appear in the results. (A88217, A85983)
    AND bid_info.Auction_Rank = 1

ORDER BY
    length(business_area_region) desc,
    business_area_region,
    business_area,
    description,
    ts.forest_file_id
;

select
    case
        when
            D.DIVI_SHORT_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN', 'TCC', 'TKA', 'TKO', 'TOC')
        then
            'Interior'
        when
            D.DIVI_SHORT_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION_CATEGORY,
    case
        when
            D.DIVI_SHORT_CODE in ('TBA', 'TPL', 'TPG', 'TSK', 'TSN')
        then
            'North Interior'
        when
            D.DIVI_SHORT_CODE in ('TCC', 'TKA', 'TKO', 'TOC')
        then
            'South Interior'
        when
            D.DIVI_SHORT_CODE in ('TCH', 'TST', 'TSG')
        then
            'Coast'
        end as BUSINESS_AREA_REGION,
    decode(
        D.DIVI_DIVISION_NAME,
        'Seaward', -- See https://apps.nrs.gov.bc.ca/int/jira/projects/SD/queues/issue/SD-74878 to track whether this DECODE statement still needs to be in this report
        'Seaward/Tlasta',
        D.DIVI_DIVISION_NAME
    ) || ' (' || L.TSO_CODE || ')' AS BUSINESS_AREA,
    L.TSO_CODE as business_area_code,
    L.NAV_NAME,
    L.FIELD_TEAM,
    L.LICENCE_ID,
    L.TENURE,
    l.licn_category_id as LRM_Category_Code,
    l.category as LRM_Category_Description,
    case
        when
            l.category is null
        then
            l.licn_category_id
        else
            L.CATEGORY || ' (' || L.licn_category_id || ')'
        end as LRM_CATEGORY,
    TENPOST.LRM_Tender_Posted_Done_Status,
    TENPOST.LRM_Tender_Posted_Done_Date,
    HA.LRM_Licence_Awarded_Done_Date,
    AUC.LRM_Auction_Done_Date,
    LV.LRM_TOTAL_VOLUME,
    L.LICN_SEQ_NBR

from
    forest.division d,
    FORESTVIEW.V_LICENCE L,

    /* Tender Posted Activity Done Date (TENPOST) */
    (
        SELECT
            a.LICN_SEQ_NBR,
            Max(DECODE(atype.actt_key_ind, 'TENPOST', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) AS LRM_Tender_Posted_Done_Status,
            Max(DECODE(atype.actt_key_ind, 'TENPOST', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null)) AS LRM_Tender_Posted_Done_Date

        FROM
            forest.activity_class ac,
            forest.activity_type atype,
            forest.activity a

        WHERE
            ac.accl_seq_nbr = atype.accl_seq_nbr
            AND ac.divi_div_nbr = atype.divi_div_nbr
            AND atype.actt_seq_nbr =  a.actt_seq_nbr
            AND atype.actt_key_ind IN (
                'TENPOST'
            )
            AND ac.accl_key_ind IN ('CML')

        GROUP BY
            a.LICN_SEQ_NBR

        HAVING
            Max(DECODE(atype.actt_key_ind, 'TENPOST', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) = 'D'

        ORDER BY 1
    ) TENPOST,

    /* Licence Awarded Activity Done Date (HA) */
    (
        SELECT
            a.LICN_SEQ_NBR,
            Max(DECODE(atype.actt_key_ind, 'HA', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) AS LRM_Licence_Awarded_Status,
            Max(DECODE(atype.actt_key_ind, 'HA', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null)) AS LRM_Licence_Awarded_Done_Date

        FROM
            forest.activity_class ac,
            forest.activity_type atype,
            forest.activity a

        WHERE
            ac.accl_seq_nbr = atype.accl_seq_nbr
            AND ac.divi_div_nbr = atype.divi_div_nbr
            AND atype.actt_seq_nbr =  a.actt_seq_nbr
            AND atype.actt_key_ind IN (
                'HA'
            )
            AND ac.accl_key_ind IN ('CML')

        GROUP BY
            a.LICN_SEQ_NBR

        HAVING
            Max(DECODE(atype.actt_key_ind, 'HA', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) = 'D'

        ORDER BY 1
    ) HA,

    /* Auction Activity Done Date (AUC) */
    (
        SELECT
            a.LICN_SEQ_NBR,
            Max(DECODE(atype.actt_key_ind, 'AUC', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) AS LRM_Auction_Status,
            Max(DECODE(atype.actt_key_ind, 'AUC', decode(a.acti_status_ind, 'D', a.acti_status_date, Null), Null)) AS LRM_Auction_Done_Date

        FROM
            forest.activity_class ac,
            forest.activity_type atype,
            forest.activity a

        WHERE
            ac.accl_seq_nbr = atype.accl_seq_nbr
            AND ac.divi_div_nbr = atype.divi_div_nbr
            AND atype.actt_seq_nbr =  a.actt_seq_nbr
            AND atype.actt_key_ind IN (
                'AUC'
            )
            AND ac.accl_key_ind IN ('CML')

        GROUP BY
            a.LICN_SEQ_NBR

        HAVING
            Max(DECODE(atype.actt_key_ind, 'AUC', decode(a.acti_status_ind, 'D', a.acti_status_ind, Null), Null)) = 'D'

        ORDER BY 1
    ) AUC,


    /* Licence Volumes (LV) */
    (
        SELECT
            B.LICN_SEQ_NBR,
            Sum(B.CRUISE_VOL) AS LRM_CRUISE_VOLUME,
            Sum(B.BLAL_RW_VOL) AS LRM_RW_VOLUME,  -- Right of Way volume
            Sum(Nvl(CRUISE_VOL, 0) + Nvl(BLAL_RW_VOL, 0)) AS LRM_TOTAL_VOLUME  -- LRM Total Volume is the sum of cruise and right-of-way volumes.
        FROM
            FORESTVIEW.V_BLOCK B
        GROUP BY
            B.LICN_SEQ_NBR
        ORDER BY
            B.LICN_SEQ_NBR
    ) LV

    WHERE
        d.divi_short_code = L.TSO_CODE (+)
        and L.LICN_SEQ_NBR = TENPOST.LICN_SEQ_NBR (+)
        and L.LICN_SEQ_NBR = HA.LICN_SEQ_NBR (+)
        and l.LICN_SEQ_NBR = auc.licn_seq_nbr (+)
        AND L.LICN_SEQ_NBR = LV.LICN_SEQ_NBR (+)
        and TENPOST.licn_seq_nbr is not null  -- TENPOST (CML) must be Done. If a licence does not sell at auction, TENPOST must be set back to Planned.
        and (
                HA.LICN_SEQ_NBR is null  -- HA (CML) must not be Done; the licence has not been awarded.
                or HA.LRM_Licence_Awarded_Done_Date > to_date('2024-01-05', 'YYYY-MM-DD')  -- Date: report period end. Licences not yet awarded at time of interest.
        )
        and tenpost.LRM_Tender_Posted_Done_Date <= to_date('2024-01-05', 'YYYY-MM-DD')  -- Date: report period end. Tender posted before the time of interest.

    ORDER BY
        length(BUSINESS_AREA_REGION) desc,  -- List 'North Interior' (14 characters) and 'South Interior' (14 characters) ahead of 'Coast' (5 characters)
        BUSINESS_AREA_REGION,  -- List 'North Interior' ahead of 'South Interior' (alphabetical)
        BUSINESS_AREA,  -- List business areas alphabetically within larger region
        L.NAV_NAME,
        L.FIELD_TEAM,
        L.LICENCE_ID
;

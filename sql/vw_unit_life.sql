/* =============================================================================
   Unit Life - vista en vivo del "Assurant Shipment Master File" (hoja Raw Data)
   Una fila por GCN. Servidor: Microsoft SQL Server, base AirlinkDR.

   Fuentes:
     u   AirlinkDR.dbo.Receiving       por GCN  -> imei, po        (tabla base)
     un  AirlinkDR.dbo.Unit            por IMEI -> model, color, capacity, carrier
     sk  AirlinkDR.dbo.PRD_JV_Skus              -> itemnumber (Partnumber), item_description
     c   condiciones de enclosure / backglass / lcd  (regla pendiente)
     rt  AirlinkDR.dbo.PRD_JV_ROUTING  por (Enclosure, BackGlass, LCD) -> route

   Columnas aun sin origen salen como NULL marcadas /* PENDIENTE #n */,
   para que la vista tenga desde ya la misma forma que el Excel.
   ============================================================================= */
CREATE OR ALTER VIEW dbo.vw_unit_life AS
WITH rcv AS (
    SELECT r.*,
           ROW_NUMBER() OVER (PARTITION BY r.GCN
                              ORDER BY (SELECT NULL)) AS rn  -- TODO: si hay varios receiving por GCN, ordenar por fecha DESC
    FROM AirlinkDR.dbo.Receiving AS r
    -- TODO: filtro del proyecto (p.ej. WHERE r.PO = 'NPI')
)
SELECT

    /* ===== 01 Identificacion ===== */
    CAST(NULL AS bigint) AS [no],  /* PENDIENTE #1 */
    u.GCN AS [gcn],
    u.IMEI AS [imei],
    un.Model AS [model],
    un.Color AS [color],
    un.Capacity AS [capacity],
    un.Carrier AS [carrier],
    sk.Partnumber AS [itemnumber],
    sk.item_description AS [item_description],
    u.PO AS [po],

    /* ===== 02 Build / partes ===== */
    c.backglass_condition AS [backglass_condition],  /* TODO: regla pendiente */
    c.enclosure_condition AS [enclosure_condition],  /* TODO: regla pendiente */
    c.lcd_condition AS [lcd_condition],  /* TODO: regla pendiente */
    'NEW' AS [battery_condition],
    'NEW' AS [wptlcd_condition],
    'NEW' AS [wptbackglass_condition],
    'NEW' AS [pentalobe_condition],
    'USED (POP & SWAP)' AS [speaker_condition],
    'USED (POP & SWAP)' AS [vibrator_condition],
    'USED (POP & SWAP)' AS [earpiece_condition],
    rt.Route AS [route],
    CAST(NULL AS nvarchar(255)) AS [backglass_sku],  /* PENDIENTE #22 */
    CAST(NULL AS nvarchar(255)) AS [enclosure_sku],  /* PENDIENTE #23 */
    CAST(NULL AS nvarchar(255)) AS [lcd_sku],  /* PENDIENTE #24 */
    CAST(NULL AS nvarchar(255)) AS [battery_sku],  /* PENDIENTE #25 */
    CAST(NULL AS nvarchar(255)) AS [wptlcd_sku],  /* PENDIENTE #26 */
    CAST(NULL AS nvarchar(255)) AS [wptbackglass_sku],  /* PENDIENTE #27 */
    CAST(NULL AS nvarchar(255)) AS [pentalobe_sku],  /* PENDIENTE #28 */
    CAST(NULL AS nvarchar(255)) AS [speaker_sku],  /* PENDIENTE #29 */
    CAST(NULL AS nvarchar(255)) AS [vibrator_sku],  /* PENDIENTE #30 */
    CAST(NULL AS nvarchar(255)) AS [earpiece_sku],  /* PENDIENTE #31 */
    CAST(NULL AS nvarchar(255)) AS [enclosure_qr],  /* PENDIENTE #32 */
    CAST(NULL AS nvarchar(255)) AS [lcd_qr],  /* PENDIENTE #33 */
    CAST(NULL AS nvarchar(255)) AS [backglass_qr],  /* PENDIENTE #34 */
    CAST(NULL AS nvarchar(255)) AS [battery_qr],  /* PENDIENTE #35 */

    /* ===== 03 Ensamble / rework Airlink ===== */
    CAST(NULL AS nvarchar(255)) AS [REWORK DEVICE AT AIRLINK],  /* PENDIENTE #36 */
    CAST(NULL AS nvarchar(255)) AS [airlink_rework_date],  /* PENDIENTE #37 */
    CAST(NULL AS nvarchar(255)) AS [REWORK REASON AT AIRLINK],  /* PENDIENTE #38 */
    CAST(NULL AS nvarchar(255)) AS [BACKGLASS ASSEMBLED BY],  /* PENDIENTE #39 */
    CAST(NULL AS nvarchar(255)) AS [PCB + HOUSING ASSEMBLED BY],  /* PENDIENTE #40 */
    CAST(NULL AS nvarchar(255)) AS [BATTERY + LCD ASSEMBLED BY],  /* PENDIENTE #41 */
    CAST(NULL AS nvarchar(255)) AS [CLOSED BY],  /* PENDIENTE #42 */
    CAST(NULL AS nvarchar(255)) AS [Reworked Evidence Picture Count],  /* PENDIENTE #43 */

    /* ===== 04 Envio ARL->Assurant ===== */
    CAST(NULL AS datetime2) AS [ARL TO ASSU_shipped_date],  /* PENDIENTE #44 */
    CAST(NULL AS bigint) AS [tracking_dr_shipment],  /* PENDIENTE #45 */
    CAST(NULL AS datetime2) AS [ASSU_delivered_date],  /* PENDIENTE #46 */

    /* ===== 05 Assurant / FAI AT&T ===== */
    CAST(NULL AS nvarchar(255)) AS [Rework at assurant],  /* PENDIENTE #47 */
    CAST(NULL AS nvarchar(255)) AS [Rework Reason],  /* PENDIENTE #48 */
    CAST(NULL AS datetime2) AS [Last Rework Date at Assurant],  /* PENDIENTE #49 */
    CAST(NULL AS datetime2) AS [ASSU to AT&T Shipping Date],  /* PENDIENTE #50 */
    CAST(NULL AS nvarchar(255)) AS [FAI DEVICE_305 Pieces],  /* PENDIENTE #51 */
    CAST(NULL AS nvarchar(255)) AS [devices_tested_AT&T_100_pieces],  /* PENDIENTE #52 */
    CAST(NULL AS nvarchar(255)) AS [AT&T WPT ROXER RESULTS],  /* PENDIENTE #53 */
    CAST(NULL AS nvarchar(255)) AS [fai_fail_devices],  /* PENDIENTE #54 */
    CAST(NULL AS nvarchar(255)) AS [fai_fail_defect],  /* PENDIENTE #55 */
    CAST(NULL AS datetime2) AS [Assurant to DR Return Date],  /* PENDIENTE #56 */

    /* ===== 06 Evidencia ===== */
    CAST(NULL AS bigint) AS [Reworked Evidence Picture Count2],  /* PENDIENTE #57 */
    CAST(NULL AS nvarchar(255)) AS [Reworked Evidence Picture Count3],  /* PENDIENTE #58 */

    /* ===== 07 X-Ray ===== */
    CAST(NULL AS nvarchar(255)) AS [X-Ray Elegible],  /* PENDIENTE #59 */
    CAST(NULL AS nvarchar(255)) AS [X-Ray LOT],  /* PENDIENTE #60 */
    CAST(NULL AS nvarchar(255)) AS [Xray Results],  /* PENDIENTE #61 */
    CAST(NULL AS nvarchar(255)) AS [Xray Defect],  /* PENDIENTE #62 */

    /* ===== 08 Roxer post FAI fail ===== */
    CAST(NULL AS nvarchar(255)) AS [ARL_Roxer After FAI Fail (TEST 1)],  /* PENDIENTE #63 */
    CAST(NULL AS datetime2) AS [ARL_Roxer After FAI Fail (TEST 1) DATE],  /* PENDIENTE #64 */
    CAST(NULL AS nvarchar(255)) AS [Severity],  /* PENDIENTE #65 */
    CAST(NULL AS nvarchar(255)) AS [Unit Disassembled for Analysis],  /* PENDIENTE #66 */
    CAST(NULL AS bigint) AS [Peak Deformation (µm)],  /* PENDIENTE #67 */
    CAST(NULL AS bigint) AS [Hold Drift (µm)],  /* PENDIENTE #68 */
    CAST(NULL AS nvarchar(255)) AS [Residual After (µm)],  /* PENDIENTE #69 */
    CAST(NULL AS nvarchar(255)) AS [ARL_Roxer After FAI Fail (TEST 2)],  /* PENDIENTE #70 */
    CAST(NULL AS datetime2) AS [ARL_Roxer After FAI Fail (TEST 2) DATE],  /* PENDIENTE #71 */
    CAST(NULL AS nvarchar(255)) AS [Peak Deformation (µm)2],  /* PENDIENTE #72 */
    CAST(NULL AS nvarchar(255)) AS [Hold Drift (µm)3],  /* PENDIENTE #73 */
    CAST(NULL AS nvarchar(255)) AS [Residual After (µm)4],  /* PENDIENTE #74 */

    /* ===== 09 Analisis de falla ===== */
    CAST(NULL AS nvarchar(255)) AS [insulation Results_Zone],  /* PENDIENTE #75 */
    CAST(NULL AS nvarchar(255)) AS [WPT ENCLOSURE LEAK %],  /* PENDIENTE #76 */
    CAST(NULL AS bigint) AS [WPT LCD LEAK %],  /* PENDIENTE #77 */
    CAST(NULL AS nvarchar(255)) AS [Bonding_Surface_Defect],  /* PENDIENTE #78 */
    CAST(NULL AS nvarchar(255)) AS [Zone 1_adhesive_Presence],  /* PENDIENTE #79 */
    CAST(NULL AS nvarchar(255)) AS [Zone 2_adhesive_Presence],  /* PENDIENTE #80 */
    CAST(NULL AS nvarchar(255)) AS [Zone 3_adhesive_Presence],  /* PENDIENTE #81 */
    CAST(NULL AS nvarchar(255)) AS [Zone 4_adhesive_Presence],  /* PENDIENTE #82 */
    CAST(NULL AS nvarchar(255)) AS [Zone 5_adhesive_Presence],  /* PENDIENTE #83 */
    CAST(NULL AS nvarchar(255)) AS [Zone 6_adhesive_Presence],  /* PENDIENTE #84 */
    CAST(NULL AS nvarchar(255)) AS [Zone 1_Condition],  /* PENDIENTE #85 */
    CAST(NULL AS nvarchar(255)) AS [Zone 2_Condition],  /* PENDIENTE #86 */
    CAST(NULL AS nvarchar(255)) AS [Zone 3_Condition2],  /* PENDIENTE #87 */
    CAST(NULL AS nvarchar(255)) AS [Zone 4_Condition3],  /* PENDIENTE #88 */
    CAST(NULL AS nvarchar(255)) AS [Zone 5_Condition],  /* PENDIENTE #89 */
    CAST(NULL AS nvarchar(255)) AS [Zone 6_Condition],  /* PENDIENTE #90 */
    CAST(NULL AS nvarchar(255)) AS [Physical Finding],  /* PENDIENTE #91 */
    CAST(NULL AS nvarchar(255)) AS [Root Cause],  /* PENDIENTE #92 */

    /* ===== 10 Re-tests Roxer / rework CA nuevo ===== */
    CAST(NULL AS nvarchar(255)) AS [RAY 1st Lot (115 Units) Roxer Results (after Xray)],  /* PENDIENTE #93 */
    CAST(NULL AS datetime2) AS [RAY 1st Lot (115 Units) Roxer Results (after Xray) DATE],  /* PENDIENTE #94 */
    CAST(NULL AS nvarchar(255)) AS [LCD Polished],  /* PENDIENTE #95 */
    CAST(NULL AS nvarchar(255)) AS [Rework With New CA],  /* PENDIENTE #96 */
    CAST(NULL AS nvarchar(255)) AS [REWORK REASON2],  /* PENDIENTE #97 */
    CAST(NULL AS datetime2) AS [Rework With New CA DATE],  /* PENDIENTE #98 */
    CAST(NULL AS nvarchar(255)) AS [Roxer Results NEW CA],  /* PENDIENTE #99 */
    CAST(NULL AS datetime2) AS [Roxer Results 2 Date],  /* PENDIENTE #100 */
    CAST(NULL AS nvarchar(255)) AS [Roxer Results 2],  /* PENDIENTE #101 */
    CAST(NULL AS nvarchar(255)) AS [Roxer Results 3],  /* PENDIENTE #102 */
    CAST(NULL AS datetime2) AS [Roxer Results 3 Date],  /* PENDIENTE #103 */
    CAST(NULL AS nvarchar(255)) AS [Roxer Results 4],  /* PENDIENTE #104 */
    CAST(NULL AS datetime2) AS [Roxer Results 4 Date],  /* PENDIENTE #105 */
    CAST(NULL AS nvarchar(255)) AS [Roxer Results 5],  /* PENDIENTE #106 */
    CAST(NULL AS datetime2) AS [Roxer Results 5 Date],  /* PENDIENTE #107 */
    CAST(NULL AS datetime2) AS [Last Day Rework],  /* PENDIENTE #108 */
    CAST(NULL AS nvarchar(255)) AS [Rework Reason 3],  /* PENDIENTE #109 */
    CAST(NULL AS nvarchar(255)) AS [Roxer Results 6],  /* PENDIENTE #110 */
    CAST(NULL AS datetime2) AS [Roxer Results 6 Date],  /* PENDIENTE #111 */
    CAST(NULL AS nvarchar(255)) AS [Roxer Results 7],  /* PENDIENTE #112 */
    CAST(NULL AS datetime2) AS [Roxer Results 7 Date],  /* PENDIENTE #113 */
    CAST(NULL AS nvarchar(255)) AS [Rework Times after last closing],  /* PENDIENTE #114 */
    CAST(NULL AS nvarchar(255)) AS [Rework Reason after last closing],  /* PENDIENTE #115 */

    /* ===== 11 Re-ensamble / cambio de partes ===== */
    CAST(NULL AS nvarchar(255)) AS [BACKGLASS ASSEMBLED BY2],  /* PENDIENTE #116 */
    CAST(NULL AS nvarchar(255)) AS [PCB + HOUSING ASSEMBLED BY2],  /* PENDIENTE #117 */
    CAST(NULL AS nvarchar(255)) AS [BATTERY + LCD ASSEMBLED BY2],  /* PENDIENTE #118 */
    CAST(NULL AS nvarchar(255)) AS [CLOSED BY2],  /* PENDIENTE #119 */
    CAST(NULL AS nvarchar(255)) AS [PARTS CHANGE],  /* PENDIENTE #120 */
    CAST(NULL AS nvarchar(255)) AS [backglass_condition2],  /* PENDIENTE #121 */
    CAST(NULL AS nvarchar(255)) AS [enclosure_condition2],  /* PENDIENTE #122 */
    CAST(NULL AS nvarchar(255)) AS [lcd_condition2],  /* PENDIENTE #123 */
    CAST(NULL AS nvarchar(255)) AS [enclosure_qr2],  /* PENDIENTE #124 */
    CAST(NULL AS nvarchar(255)) AS [lcd_qr2],  /* PENDIENTE #125 */
    CAST(NULL AS nvarchar(255)) AS [backglass_qr2],  /* PENDIENTE #126 */
    CAST(NULL AS nvarchar(255)) AS [battery_qr2],  /* PENDIENTE #127 */

    /* ===== 12 Envio final / resultados Assurant ===== */
    CAST(NULL AS nvarchar(255)) AS [Shipping ARL TO ASSURANT Tracking],  /* PENDIENTE #128 */
    CAST(NULL AS datetime2) AS [Shipping ARL TO ASSURANT Date],  /* PENDIENTE #129 */
    CAST(NULL AS nvarchar(255)) AS [ASSURANT TEST RESULTS],  /* PENDIENTE #130 */
    CAST(NULL AS nvarchar(255)) AS [ASSURANT TEST RESULTS DEFECT],  /* PENDIENTE #131 */
    CAST(NULL AS nvarchar(255)) AS [Reworked at Airlnk_Final],  /* PENDIENTE #132 */
    CAST(NULL AS nvarchar(255)) AS [Reworked at Airlnk_Final Date],  /* PENDIENTE #133 */
    CAST(NULL AS nvarchar(255)) AS [Device Build with Plasma Process],  /* PENDIENTE #134 */
    CAST(NULL AS nvarchar(255)) AS [Second FAI Submission]  /* PENDIENTE #135 */
FROM rcv AS u
OUTER APPLY (
    SELECT TOP 1 x.Model, x.Color, x.Capacity, x.Carrier
    FROM AirlinkDR.dbo.Unit AS x
    WHERE x.IMEI = u.IMEI
) AS un
OUTER APPLY (
    SELECT TOP 1 x.Partnumber, x.item_description
    FROM AirlinkDR.dbo.PRD_JV_Skus AS x
    WHERE 1 = 0  -- TODO: llave de union con la unidad (model/color/capacity/carrier?)
) AS sk
CROSS APPLY (
    -- TODO: reglas de las 3 condiciones (en mayusculas, igual que el Excel)
    SELECT CAST(NULL AS nvarchar(50)) AS enclosure_condition,
           CAST(NULL AS nvarchar(50)) AS backglass_condition,
           CAST(NULL AS nvarchar(50)) AS lcd_condition
) AS c
OUTER APPLY (
    SELECT TOP 1 x.Route
    FROM AirlinkDR.dbo.PRD_JV_ROUTING AS x
    WHERE x.Status    = 'Active'
      AND x.Enclosure = c.enclosure_condition
      AND x.BackGlass = c.backglass_condition
      AND x.LCD       = c.lcd_condition
) AS rt
WHERE u.rn = 1;

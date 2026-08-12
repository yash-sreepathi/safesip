import pcbnew


def create_interdigitated_sensor():

    board = pcbnew.GetBoard()

    if board is None:
        print("ERROR: No PCB is currently open.")
        return

    # ============================================================
    # SAFESIP SENSOR SETTINGS
    # ============================================================

    TRACE_WIDTH_MM = 0.20
    TRACE_SPACING_MM = 0.20
    FINGER_GAP_MM = 0.50

    SENSOR_WIDTH_MM = 30.0
    SENSOR_HEIGHT_MM = 30.0

    # Position of sensor in KiCad workspace
    START_X_MM = 100.0
    START_Y_MM = 100.0

    PAD_SIZE_MM = 2.50
    DRILL_SIZE_MM = 1.00

    # Bottom area reserved for connections/pads
    BOTTOM_MARGIN_MM = 5.0

    # ============================================================
    # CONVERT MM TO KICAD INTERNAL UNITS
    # ============================================================

    TRACE_WIDTH = pcbnew.FromMM(TRACE_WIDTH_MM)
    TRACE_SPACING = pcbnew.FromMM(TRACE_SPACING_MM)
    FINGER_GAP = pcbnew.FromMM(FINGER_GAP_MM)

    SENSOR_WIDTH = pcbnew.FromMM(SENSOR_WIDTH_MM)
    SENSOR_HEIGHT = pcbnew.FromMM(SENSOR_HEIGHT_MM)

    START_X = pcbnew.FromMM(START_X_MM)
    START_Y = pcbnew.FromMM(START_Y_MM)

    PAD_SIZE = pcbnew.FromMM(PAD_SIZE_MM)
    DRILL_SIZE = pcbnew.FromMM(DRILL_SIZE_MM)

    BOTTOM_MARGIN = pcbnew.FromMM(BOTTOM_MARGIN_MM)

    # ============================================================
    # SENSOR CALCULATIONS
    # ============================================================

    pitch = TRACE_WIDTH + TRACE_SPACING

    active_height = SENSOR_HEIGHT - BOTTOM_MARGIN

    num_fingers = int(active_height / pitch)

    right_rail_x = START_X + SENSOR_WIDTH

    bottom_y = START_Y + active_height

    print("Creating SafeSip sensor...")
    print("Number of electrode fingers:", num_fingers)

    # ============================================================
    # CREATE SENSOR FOOTPRINT
    # ============================================================
    #
    # KiCad 10 requires pads to belong to a FOOTPRINT.
    # They cannot be placed directly onto BOARD.
    #

    sensor_fp = pcbnew.FOOTPRINT(board)

    sensor_fp.SetReference("SENSOR1")
    sensor_fp.SetValue("SafeSip_Interdigitated_Sensor")

    board.Add(sensor_fp)

    # ============================================================
    # LEFT ELECTRODE RAIL
    # ============================================================

    left_rail = pcbnew.PCB_TRACK(board)

    left_rail.SetStart(
        pcbnew.VECTOR2I(
            START_X,
            START_Y
        )
    )

    left_rail.SetEnd(
        pcbnew.VECTOR2I(
            START_X,
            bottom_y
        )
    )

    left_rail.SetWidth(TRACE_WIDTH)
    left_rail.SetLayer(pcbnew.F_Cu)

    board.Add(left_rail)

    # ============================================================
    # RIGHT ELECTRODE RAIL
    # ============================================================

    right_rail = pcbnew.PCB_TRACK(board)

    right_rail.SetStart(
        pcbnew.VECTOR2I(
            right_rail_x,
            START_Y
        )
    )

    right_rail.SetEnd(
        pcbnew.VECTOR2I(
            right_rail_x,
            bottom_y
        )
    )

    right_rail.SetWidth(TRACE_WIDTH)
    right_rail.SetLayer(pcbnew.F_Cu)

    board.Add(right_rail)

    # ============================================================
    # INTERDIGITATED ELECTRODE FINGERS
    # ============================================================

    for i in range(num_fingers):

        y_pos = START_Y + (i * pitch)

        finger = pcbnew.PCB_TRACK(board)

        finger.SetWidth(TRACE_WIDTH)
        finger.SetLayer(pcbnew.F_Cu)

        # --------------------------------------------------------
        # Even finger = starts from LEFT electrode
        # --------------------------------------------------------

        if i % 2 == 0:

            start_point = pcbnew.VECTOR2I(
                START_X,
                y_pos
            )

            end_point = pcbnew.VECTOR2I(
                right_rail_x - FINGER_GAP,
                y_pos
            )

        # --------------------------------------------------------
        # Odd finger = starts from RIGHT electrode
        # --------------------------------------------------------

        else:

            start_point = pcbnew.VECTOR2I(
                START_X + FINGER_GAP,
                y_pos
            )

            end_point = pcbnew.VECTOR2I(
                right_rail_x,
                y_pos
            )

        finger.SetStart(start_point)
        finger.SetEnd(end_point)

        board.Add(finger)

    # ============================================================
    # PAD 1 - LEFT ELECTRODE
    # ============================================================

    pad_a = pcbnew.PAD(sensor_fp)

    pad_a.SetNumber("1")

    pad_a.SetAttribute(
        pcbnew.PAD_ATTRIB_PTH
    )

    pad_a.SetShape(
        pcbnew.PAD_SHAPE_CIRCLE
    )

    pad_a.SetLayerSet(
        pad_a.PTHMask()
    )

    pad_a.SetSize(
        pcbnew.VECTOR2I(
            PAD_SIZE,
            PAD_SIZE
        )
    )

    pad_a.SetDrillSize(
        pcbnew.VECTOR2I(
            DRILL_SIZE,
            DRILL_SIZE
        )
    )

    pad_a_position = pcbnew.VECTOR2I(
        START_X,
        bottom_y + pcbnew.FromMM(2.0)
    )

    pad_a.SetPosition(
        pad_a_position
    )

    sensor_fp.Add(
        pad_a
    )

    # ============================================================
    # CONNECT LEFT RAIL TO PAD 1
    # ============================================================

    conn_a = pcbnew.PCB_TRACK(board)

    conn_a.SetStart(
        left_rail.GetEnd()
    )

    conn_a.SetEnd(
        pad_a.GetPosition()
    )

    conn_a.SetWidth(
        TRACE_WIDTH
    )

    conn_a.SetLayer(
        pcbnew.F_Cu
    )

    board.Add(
        conn_a
    )

    # ============================================================
    # PAD 2 - RIGHT ELECTRODE
    # ============================================================

    pad_b = pcbnew.PAD(sensor_fp)

    pad_b.SetNumber("2")

    pad_b.SetAttribute(
        pcbnew.PAD_ATTRIB_PTH
    )

    pad_b.SetShape(
        pcbnew.PAD_SHAPE_CIRCLE
    )

    pad_b.SetLayerSet(
        pad_b.PTHMask()
    )

    pad_b.SetSize(
        pcbnew.VECTOR2I(
            PAD_SIZE,
            PAD_SIZE
        )
    )

    pad_b.SetDrillSize(
        pcbnew.VECTOR2I(
            DRILL_SIZE,
            DRILL_SIZE
        )
    )

    pad_b_position = pcbnew.VECTOR2I(
        right_rail_x,
        bottom_y + pcbnew.FromMM(2.0)
    )

    pad_b.SetPosition(
        pad_b_position
    )

    sensor_fp.Add(
        pad_b
    )

    # ============================================================
    # CONNECT RIGHT RAIL TO PAD 2
    # ============================================================

    conn_b = pcbnew.PCB_TRACK(board)

    conn_b.SetStart(
        right_rail.GetEnd()
    )

    conn_b.SetEnd(
        pad_b.GetPosition()
    )

    conn_b.SetWidth(
        TRACE_WIDTH
    )

    conn_b.SetLayer(
        pcbnew.F_Cu
    )

    board.Add(
        conn_b
    )

    # ============================================================
    # SOLDER MASK OPENING
    # ============================================================
    #
    # This exposes the copper electrodes instead of covering them
    # with the green solder mask.
    #

    MASK_MARGIN = pcbnew.FromMM(0.50)

    mask_opening = pcbnew.PCB_SHAPE(
        board,
        pcbnew.SHAPE_T_RECTANGLE
    )

    mask_opening.SetLayer(
        pcbnew.F_Mask
    )

    mask_opening.SetStart(
        pcbnew.VECTOR2I(
            START_X - MASK_MARGIN,
            START_Y - MASK_MARGIN
        )
    )

    mask_opening.SetEnd(
        pcbnew.VECTOR2I(
            right_rail_x + MASK_MARGIN,
            bottom_y + MASK_MARGIN
        )
    )

    mask_opening.SetFilled(
        True
    )

    mask_opening.SetWidth(
        0
    )

    board.Add(
        mask_opening
    )

    # ============================================================
    # REFRESH PCB EDITOR
    # ============================================================

    pcbnew.Refresh()

    print("-------------------------------------")
    print("SafeSip sensor created successfully!")
    print("-------------------------------------")
    print("Sensor width: 30 mm")
    print("Sensor height: 30 mm")
    print("Trace width: 0.20 mm")
    print("Trace spacing: 0.20 mm")
    print("Finger tip gap: 0.50 mm")
    print("Pad 1 = Electrode A")
    print("Pad 2 = Electrode B")
    print("-------------------------------------")


# ================================================================
# RUN SCRIPT
# ================================================================

create_interdigitated_sensor()
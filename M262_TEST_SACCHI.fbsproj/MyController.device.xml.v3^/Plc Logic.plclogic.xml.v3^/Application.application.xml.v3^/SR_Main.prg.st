__METADATA__
{
  "v3Meta": {
    "objectGuid": "afc9279e-333f-462a-a772-3cabcdc59851",
    "objectTypeGuid": "6f9dac99-8de1-4efc-8465-68ac443b7d08",
    "embeddedObjectTypeGuids": [
      "a9ed5b7e-75c5-4651-af16-d2c27e98cb94",
      "3b83b776-fb25-43b8-99f2-3c507c9143fc"
    ],
    "properties": {},
    "subObjects": {}
  }
}
__DECLARATION__
PROGRAM SR_Main
VAR
    fb_CsvWriter: FFU.FB_CsvWrite;
    x_StartWrite: BOOL;
    x_ResetError: BOOL;
    a_CsvHeader: ARRAY[0..0, 0..Gc_uiNumOfColumns - 1] OF STRING(Gc_uiLengthOfValue) := ['Date', 'Time', 'Event-Type', 'Event', '', '', ''];
    a_CsvData: ARRAY[0..Gc_uiNumOfRows - 1, 0..Gc_uiNumOfColumns - 1] OF STRING(Gc_uiLengthOfValue);
    st_CsvTable: FFU.ST_CsvTable;
    udi_RowsToWrite: UDINT := 3;
    x_Initialized: BOOL := FALSE;
    x_CreateWithHeader: BOOL := FALSE;
    i_CurrentState: INT := 0;
END_VAR
VAR CONSTANT
    Gc_uiNumOfRows: UINT := 8;
    Gc_uiNumOfColumns: UINT := 7;
    Gc_uiLengthOfValue: UINT := 80;
END_VAR
__IMPLEMENTATION__
IF NOT x_Initialized THEN
    x_Initialized := TRUE;
    SysMem.SysMemSet(ADR(a_CsvData), 0, SIZEOF(a_CsvData));
    a_CsvData[0, 0] := '2023-10-10';
    a_CsvData[0, 1] := '08:00:00';
    a_CsvData[0, 2] := 'Start';
    a_CsvData[0, 3] := 'System Initialization';

    a_CsvData[1, 0] := '2023-10-10';
    a_CsvData[1, 1] := '08:05:00';
    a_CsvData[1, 2] := 'Status';
    a_CsvData[1, 3] := 'System Running';

    a_CsvData[2, 0] := '2023-10-10';
    a_CsvData[2, 1] := '08:10:00';
    a_CsvData[2, 2] := 'Warning';
    a_CsvData[2, 3] := 'Low Battery';
END_IF

CASE i_CurrentState OF
    0: // Waiting for write command
        IF x_StartWrite THEN
            i_CurrentState := 10;
            x_StartWrite := FALSE;
        END_IF
    10: // Prepare writing
        IF x_CreateWithHeader THEN
            fb_CsvWriter.i_stTableWriteValues.pbyTable := ADR(a_CsvHeader);
            fb_CsvWriter.i_stTableWriteValues.uiNumOfRows := 1;
            fb_CsvWriter.i_stTableWriteValues.uiNumOfColumns := Gc_uiNumOfColumns;
            fb_CsvWriter.i_stTableWriteValues.udiSizeOfTable := SIZEOF(a_CsvHeader);

            fb_CsvWriter.i_stWriteParameter.sDelimiter := ';';
            fb_CsvWriter.i_stWriteParameter.etModeFileOpen := FFU.ET_ModeFileOpen.Create;
            fb_CsvWriter.i_stWriteParameter.udiNumOfRow := 1;
            fb_CsvWriter.i_stWriteParameter.udiNumOfColumn := Gc_uiNumOfColumns;
        ELSE
            fb_CsvWriter.i_stTableWriteValues.pbyTable := ADR(a_CsvData);
            fb_CsvWriter.i_stTableWriteValues.uiNumOfRows := Gc_uiNumOfRows;
            fb_CsvWriter.i_stTableWriteValues.uiNumOfColumns := Gc_uiNumOfColumns;
            fb_CsvWriter.i_stTableWriteValues.udiSizeOfTable := SIZEOF(a_CsvData);

            fb_CsvWriter.i_stWriteParameter.sDelimiter := ';';
            fb_CsvWriter.i_stWriteParameter.etModeFileOpen := FFU.ET_ModeFileOpen.Append;
            fb_CsvWriter.i_stWriteParameter.udiNumOfRow := udi_RowsToWrite;
            fb_CsvWriter.i_stWriteParameter.udiNumOfColumn := Gc_uiNumOfColumns;
        END_IF
        fb_CsvWriter(i_xExecute := FALSE);
        i_CurrentState := 20;
    20: // Execute writing
        fb_CsvWriter(
            i_xExecute := TRUE,
            i_sFilePath := './myfiles/MotionControllerLog.csv'
        );

        IF fb_CsvWriter.q_xError THEN
            i_CurrentState := -1;
        ELSIF fb_CsvWriter.q_xDone THEN
            IF x_CreateWithHeader THEN
                x_CreateWithHeader := FALSE;
                i_CurrentState := 10;
            ELSE
                i_CurrentState := 0;
            END_IF
        END_IF
    -1: // Error handling
        IF fb_CsvWriter.q_etResult = FFU.ET_Result.FileNotExists THEN
            x_CreateWithHeader := TRUE;
            i_CurrentState := 10;
        ELSIF x_ResetError THEN
            x_ResetError := FALSE;
            i_CurrentState := 0;
        END_IF
END_CASE

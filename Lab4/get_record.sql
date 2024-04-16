CREATE OR REPLACE FUNCTION get_record_from_xml(
    xml_string  IN VARCHAR2, 
    xpath       IN VARCHAR2
) RETURN xml_record 
AS
    i               NUMBER       := 1;
    records_length  NUMBER       := 0; 
    
    current_record  VARCHAR2(50) := ' '; 
    xml_property    xml_record    := xml_record(); 
BEGIN
    SELECT EXTRACTVALUE(XMLTYPE(xml_string), xpath || '[' || i || ']') 
        INTO current_record FROM dual;

    WHILE current_record IS NOT NULL 
    LOOP 
        i := i + 1;
        records_length := records_length + 1;
        xml_property.extend;
        xml_property(records_length) := TRIM(current_record);

        SELECT EXTRACTVALUE(XMLTYPE(xml_string), xpath || '[' || i || ']') 
            INTO current_record FROM dual; 
    END LOOP;

    RETURN xml_property; 
END get_record_from_xml;


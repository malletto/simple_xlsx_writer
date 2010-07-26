module SimpleXlsx

class Serializer

  def initialize to
    @to = to
    Zip::ZipFile.open(to, Zip::ZipFile::CREATE) do |zip|
      @zip = zip
      add_doc_props
      add_worksheets_directory
      add_relationship_part
      add_styles
      @doc = Document.new(self)
      yield @doc
      add_workbook_relationship_part
      add_content_types
      add_workbook_part
    end
  end

  def add_workbook_part
    @zip.get_output_stream "xl/workbook.xml" do |f|
      f.puts <<-ends
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets>
ends
      @doc.sheets.each_with_index do |sheet, ndx|
        f.puts "<sheet name=\"#{sheet.name}\" sheetId=\"#{ndx + 1}\" r:id=\"#{sheet.rid}\"/>"
      end
      f.puts "</sheets></workbook>"
    end
  end

  def add_worksheets_directory
    @zip.mkdir "xl"
    @zip.mkdir "xl/worksheets"
  end

  def open_stream_for_sheet ndx
    @zip.get_output_stream "xl/worksheets/sheet#{ndx + 1}.xml" do |f|
      yield f
    end
  end

  def add_content_types
    @zip.get_output_stream "[Content_Types].xml" do |f|
      f.puts '<?xml version="1.0" encoding="UTF-8"?>'
      f.puts '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      f.puts <<-ends
  <Override PartName="/_rels/.rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/_rels/workbook.xml.rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
ends
      if @doc.has_shared_strings?
        f.puts '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
      end
      @doc.sheets.each_with_index do |sheet, ndx|
        f.puts "<Override PartName=\"/xl/worksheets/sheet#{ndx+1}.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>"
      end
      f.puts '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
      f.puts "</Types>"
    end
  end

  def add_workbook_relationship_part
    @zip.mkdir "xl/_rels"
    @zip.get_output_stream "xl/_rels/workbook.xml.rels" do |f|
      f.puts <<-ends
<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
ends
      cnt = 0
      f.puts "<Relationship Id=\"rId#{cnt += 1}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>"
      @doc.sheets.each_with_index do |sheet, ndx|
        sheet.rid = "rId#{cnt += 1}"
        f.puts "<Relationship Id=\"#{sheet.rid}\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet#{ndx + 1}.xml\"/>"
      end
      if @doc.has_shared_strings?
        f.puts '<Relationship Id="rId#{cnt += 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="xl/sharedStrings.xml"/>'
      end
      f.puts "</Relationships>"
    end
  end

  def add_relationship_part
    @zip.mkdir "_rels"
    @zip.get_output_stream "_rels/.rels" do |f|
      f.puts <<-ends
<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
ends
      f.puts "</Relationships>"
    end
  end

  def add_doc_props
    @zip.mkdir "docProps"
    @zip.get_output_stream "docProps/core.xml" do |f|
      f.puts <<-ends
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
   <dcterms:created xsi:type="dcterms:W3CDTF">2010-07-20T14:30:58.00Z</dcterms:created>
   <cp:revision>0</cp:revision>
</cp:coreProperties>
ends
    end
    @zip.get_output_stream "docProps/app.xml" do |f|
      f.puts <<-ends
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <TotalTime>0</TotalTime>
</Properties>
ends
    end
  end

  def add_styles
    @zip.get_output_stream "xl/styles.xml" do |f|
      f.puts <<-ends
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><numFmts count="7"><numFmt formatCode="GENERAL" numFmtId="164"/><numFmt formatCode="MM/DD/YYYY\ HH:MM:SS" numFmtId="165"/><numFmt formatCode="MMM\ D&quot;, &quot;YYYY" numFmtId="166"/><numFmt formatCode="0" numFmtId="167"/><numFmt formatCode="0.00" numFmtId="168"/><numFmt formatCode="@" numFmtId="169"/><numFmt formatCode="&quot;TRUE&quot;;&quot;TRUE&quot;;&quot;FALSE&quot;" numFmtId="170"/></numFmts><fonts count="5"><font><name val="Mangal"/><family val="2"/><sz val="10"/></font><font><name val="Arial"/><family val="0"/><sz val="10"/></font><font><name val="Arial"/><family val="0"/><sz val="10"/></font><font><name val="Arial"/><family val="0"/><sz val="10"/></font><font><name val="Arial"/><family val="2"/><sz val="10"/></font></fonts><fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills><borders count="1"><border diagonalDown="false" diagonalUp="false"><left/><right/><top/><bottom/><diagonal/></border></borders><cellStyleXfs count="20"><xf applyAlignment="true" applyBorder="true" applyFont="true" applyProtection="true" borderId="0" fillId="0" fontId="0" numFmtId="164"><alignment horizontal="general" indent="0" shrinkToFit="false" textRotation="0" vertical="bottom" wrapText="false"/><protection hidden="false" locked="true"/></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="1" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="1" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="2" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="2" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="0" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="0" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="0" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="0" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="0" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="0" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="0" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="0" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="0" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="0" numFmtId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="1" numFmtId="43"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="1" numFmtId="41"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="1" numFmtId="44"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="1" numFmtId="42"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="1" numFmtId="9"></xf></cellStyleXfs><cellXfs count="7"><xf applyAlignment="false" applyBorder="false" applyFont="false" applyProtection="false" borderId="0" fillId="0" fontId="4" numFmtId="164" xfId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="4" numFmtId="165" xfId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="4" numFmtId="166" xfId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="false" applyProtection="false" borderId="0" fillId="0" fontId="4" numFmtId="167" xfId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="false" applyProtection="false" borderId="0" fillId="0" fontId="4" numFmtId="168" xfId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="true" applyProtection="false" borderId="0" fillId="0" fontId="4" numFmtId="169" xfId="0"></xf><xf applyAlignment="false" applyBorder="false" applyFont="false" applyProtection="false" borderId="0" fillId="0" fontId="4" numFmtId="170" xfId="0"></xf></cellXfs><cellStyles count="6"><cellStyle builtinId="0" customBuiltin="false" name="Normal" xfId="0"/><cellStyle builtinId="3" customBuiltin="false" name="Comma" xfId="15"/><cellStyle builtinId="6" customBuiltin="false" name="Comma [0]" xfId="16"/><cellStyle builtinId="4" customBuiltin="false" name="Currency" xfId="17"/><cellStyle builtinId="7" customBuiltin="false" name="Currency [0]" xfId="18"/><cellStyle builtinId="5" customBuiltin="false" name="Percent" xfId="19"/></cellStyles></styleSheet>
ends
    end
  end

end

end

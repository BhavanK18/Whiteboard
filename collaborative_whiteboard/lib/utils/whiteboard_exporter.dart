import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;

import '../models/drawing.dart';
import '../models/whiteboard_page.dart';
import '../widgets/drawing_canvas.dart';

class RenderedWhiteboardPage {
  const RenderedWhiteboardPage({
    required this.pngBytes,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.pageName,
  });

  final Uint8List pngBytes;
  final double pixelWidth;
  final double pixelHeight;
  final String pageName;
}

class WhiteboardExporter {
  WhiteboardExporter({
    required this.documentTitle,
    required this.sanitizedFileName,
    this.pixelRatio = 2.0,
    this.minimumWidth = 1920,
    this.minimumHeight = 1080,
  });

  final String documentTitle;
  final String sanitizedFileName;
  final double pixelRatio;
  final double minimumWidth;
  final double minimumHeight;

  Future<List<RenderedWhiteboardPage>> renderPages(List<WhiteboardPage> pages) async {
    final List<RenderedWhiteboardPage> rendered = <RenderedWhiteboardPage>[];
    for (final WhiteboardPage page in pages) {
      rendered.add(await _renderPage(page));
    }
    return rendered;
  }

  Future<bool> exportAsPdf(List<RenderedWhiteboardPage> pages) async {
    if (pages.isEmpty) return false;
    final fs.FileSaveLocation? location = await fs.getSaveLocation(
      suggestedName: '$sanitizedFileName.pdf',
      acceptedTypeGroups: const [
        fs.XTypeGroup(
          label: 'PDF document',
          extensions: <String>['pdf'],
          mimeTypes: <String>['application/pdf'],
        ),
      ],
    );
    if (location == null) {
      return false;
    }

    final pw.Document document = pw.Document();
    for (final RenderedWhiteboardPage page in pages) {
      final pw.MemoryImage image = pw.MemoryImage(page.pngBytes);
      final double pdfWidth = _pointsFromPixels(page.pixelWidth);
      final double pdfHeight = _pointsFromPixels(page.pixelHeight);
      document.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat(pdfWidth, pdfHeight),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    final Uint8List bytes = Uint8List.fromList(await document.save());
    final String resolvedPath = _ensureExtension(location.path, '.pdf');
    final fs.XFile file = fs.XFile.fromData(
      bytes,
      name: p.basename(resolvedPath),
      mimeType: 'application/pdf',
    );
    await file.saveTo(resolvedPath);
    return true;
  }

  Future<bool> exportAsPptx(List<RenderedWhiteboardPage> pages) async {
    if (pages.isEmpty) return false;
    final fs.FileSaveLocation? location = await fs.getSaveLocation(
      suggestedName: '$sanitizedFileName.pptx',
      acceptedTypeGroups: const [
        fs.XTypeGroup(
          label: 'PowerPoint presentation',
          extensions: <String>['pptx'],
          mimeTypes: <String>['application/vnd.openxmlformats-officedocument.presentationml.presentation'],
        ),
      ],
    );
    if (location == null) {
      return false;
    }

    final Uint8List pptxBytes = await _buildPptxArchive(pages);
    final String resolvedPath = _ensureExtension(location.path, '.pptx');
    final fs.XFile file = fs.XFile.fromData(
      pptxBytes,
      name: p.basename(resolvedPath),
      mimeType: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    );
    await file.saveTo(resolvedPath);
    return true;
  }

  Future<RenderedWhiteboardPage> _renderPage(WhiteboardPage page) async {
    final Rect? contentBounds = _calculateContentBounds(page.elements);
    final double padding = 80.0;
    final Rect effectiveBounds = contentBounds ?? const Rect.fromLTWH(0, 0, 1280, 720);

    final double contentWidth = effectiveBounds.width + padding * 2;
    final double contentHeight = effectiveBounds.height + padding * 2;

    final double canvasWidth = math.max(contentWidth, minimumWidth);
    final double canvasHeight = math.max(contentHeight, minimumHeight);

    final double centerOffsetX = (canvasWidth - contentWidth) / 2;
    final double centerOffsetY = (canvasHeight - contentHeight) / 2;

    final Offset panOffset = Offset(
      padding + centerOffsetX - effectiveBounds.left,
      padding + centerOffsetY - effectiveBounds.top,
    );

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final DrawingPainter painter = DrawingPainter(
      elements: page.elements,
      scale: 1.0,
      panOffset: panOffset,
      backgroundColor: page.backgroundColor,
      gridColor: const Color(0xFFE9ECF5).withOpacity(0.12),
    );
    painter.paint(canvas, Size(canvasWidth, canvasHeight));
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(
      (canvasWidth * pixelRatio).round(),
      (canvasHeight * pixelRatio).round(),
    );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to render whiteboard page to image data');
    }
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    return RenderedWhiteboardPage(
      pngBytes: pngBytes,
      pixelWidth: canvasWidth,
      pixelHeight: canvasHeight,
      pageName: page.name,
    );
  }

  Rect? _calculateContentBounds(List<DrawElement> elements) {
    Rect? bounds;
    for (final DrawElement element in elements) {
      final Rect? elementBounds = _boundsForElement(element);
      if (elementBounds == null) continue;
      bounds = bounds == null ? elementBounds : bounds.expandToInclude(elementBounds);
    }
    return bounds;
  }

  Rect? _boundsForElement(DrawElement element) {
    const double padding = 24.0;
    if (element is PathElement) {
      final List<Offset> points = _extractOffsets(element.points);
      if (points.isEmpty) return null;
      return _rectFromPoints(points, element.strokeWidth + padding);
    }
    if (element is LineElement) {
      return _rectFromPoints(<Offset>[element.start, element.end], element.strokeWidth + padding);
    }
    if (element is ArrowElement) {
      return _rectFromPoints(<Offset>[element.start, element.end], element.strokeWidth + padding);
    }
    if (element is RectangleElement) {
      final Rect rect = Rect.fromPoints(element.topLeft, element.bottomRight).inflate(element.strokeWidth + padding);
      return rect;
    }
    if (element is CircleElement) {
      return Rect.fromCircle(center: element.center, radius: element.radius + element.strokeWidth + padding);
    }
    if (element is TriangleElement) {
      final List<Offset> points = <Offset>[element.p1, element.p2, element.p3];
      return _rectFromPoints(points, element.strokeWidth + padding);
    }
    if (element is TextElement) {
      final TextPainter painter = TextPainter(
        text: TextSpan(
          text: element.text,
          style: TextStyle(
            color: element.color,
            fontSize: element.fontSize,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: null,
      )..layout();
      final Rect rect = Rect.fromLTWH(
        element.position.dx,
        element.position.dy,
        painter.width,
        painter.height,
      ).inflate(padding);
      return rect;
    }
    return null;
  }

  List<Offset> _extractOffsets(List<dynamic> rawPoints) {
    final List<Offset> points = <Offset>[];
    for (final dynamic entry in rawPoints) {
      if (entry is Offset) {
        points.add(entry);
      } else if (entry is DrawingPoint) {
        points.add(entry.offset);
      } else if (entry is Map<String, dynamic>) {
        final double? x = entry['x'] as double?;
        final double? y = entry['y'] as double?;
        if (x != null && y != null) {
          points.add(Offset(x, y));
        }
      }
    }
    return points;
  }

  Rect _rectFromPoints(List<Offset> points, double strokePadding) {
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;
    for (final Offset point in points.skip(1)) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY).inflate(strokePadding);
  }

  Future<Uint8List> _buildPptxArchive(List<RenderedWhiteboardPage> pages) async {
    final Archive archive = Archive();
    final int slideCount = pages.length;
    final int cx = (pages.first.pixelWidth * _emuPerPixel).round();
    final int cy = (pages.first.pixelHeight * _emuPerPixel).round();

    archive.addFile(_stringFile('[Content_Types].xml', _buildContentTypesXml(slideCount)));
    archive.addFile(_stringFile('_rels/.rels', _buildPackageRelsXml()));
    archive.addFile(_stringFile('docProps/core.xml', _buildCorePropertiesXml(documentTitle)));
    archive.addFile(_stringFile('docProps/app.xml', _buildAppPropertiesXml(slideCount)));
    archive.addFile(_stringFile('ppt/_rels/presentation.xml.rels', _buildPresentationRelsXml(slideCount)));
    archive.addFile(_stringFile('ppt/presentation.xml', _buildPresentationXml(slideCount, cx, cy)));
    archive.addFile(_stringFile('ppt/slideMasters/slideMaster1.xml', _buildSlideMasterXml()));
    archive.addFile(_stringFile('ppt/slideMasters/_rels/slideMaster1.xml.rels', _buildSlideMasterRelsXml()));
    archive.addFile(_stringFile('ppt/slideLayouts/slideLayout1.xml', _buildSlideLayoutXml()));
    archive.addFile(_stringFile('ppt/slideLayouts/_rels/slideLayout1.xml.rels', _buildSlideLayoutRelsXml()));
    archive.addFile(_stringFile('ppt/theme/theme1.xml', _buildThemeXml()));

    for (int index = 0; index < pages.length; index++) {
      final int slideNumber = index + 1;
      final RenderedWhiteboardPage page = pages[index];
      archive.addFile(
        _stringFile('ppt/slides/slide$slideNumber.xml', _buildSlideXml(slideNumber, page.pageName, cx, cy)),
      );
      archive.addFile(
        _stringFile('ppt/slides/_rels/slide$slideNumber.xml.rels', _buildSlideRelsXml(slideNumber)),
      );
      archive.addFile(
        ArchiveFile('ppt/media/image$slideNumber.png', page.pngBytes.length, page.pngBytes),
      );
    }

    final ZipEncoder encoder = ZipEncoder();
    final List<int> encoded = encoder.encode(archive)!;
    return Uint8List.fromList(encoded);
  }

  ArchiveFile _stringFile(String path, String contents) {
    final List<int> data = utf8.encode(contents);
    return ArchiveFile(path, data.length, data);
  }

  String _buildContentTypesXml(int slideCount) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..writeln('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">')
      ..writeln('  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>')
      ..writeln('  <Default Extension="xml" ContentType="application/xml"/>')
      ..writeln('  <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>')
      ..writeln('  <Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>')
      ..writeln('  <Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>')
      ..writeln('  <Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>')
      ..writeln('  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>')
      ..writeln('  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>');
    for (int i = 1; i <= slideCount; i++) {
      buffer.writeln('  <Override PartName="/ppt/slides/slide$i.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>');
    }
    buffer.writeln('</Types>');
    return buffer.toString();
  }

  String _buildPackageRelsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
  }

  String _buildCorePropertiesXml(String title) {
    final DateTime now = DateTime.now().toUtc();
    final String isoDate = now.toIso8601String();
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>${_xmlEscape(title)}</dc:title>
  <dc:creator>Collaborative Whiteboard</dc:creator>
  <cp:lastModifiedBy>Collaborative Whiteboard</cp:lastModifiedBy>
  <cp:revision>1</cp:revision>
  <dcterms:created xsi:type="dcterms:W3CDTF">$isoDate</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">$isoDate</dcterms:modified>
</cp:coreProperties>''';
  }

  String _buildAppPropertiesXml(int slideCount) {
    final String titlesVector = List<String>.generate(
      slideCount,
      (int i) => '<vt:lpstr>Slide ${i + 1}</vt:lpstr>',
    ).join();

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Collaborative Whiteboard</Application>
  <Slides>$slideCount</Slides>
  <PresentationFormat>Custom</PresentationFormat>
  <DocSecurity>0</DocSecurity>
  <ScaleCrop>false</ScaleCrop>
  <HeadingPairs><vt:vector size="2" baseType="variant">
    <vt:variant><vt:lpstr>Slides</vt:lpstr></vt:variant>
    <vt:variant><vt:i4>$slideCount</vt:i4></vt:variant>
  </vt:vector></HeadingPairs>
  <TitlesOfParts><vt:vector size="$slideCount" baseType="lpstr">$titlesVector</vt:vector></TitlesOfParts>
</Properties>''';
  }

  String _buildPresentationRelsXml(int slideCount) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..writeln('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">')
      ..writeln('  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>');
    for (int i = 1; i <= slideCount; i++) {
      buffer.writeln('  <Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide$i.xml"/>');
    }
    buffer.writeln('</Relationships>');
    return buffer.toString();
  }

  String _buildPresentationXml(int slideCount, int cx, int cy) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..writeln('<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"')
      ..writeln('  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"')
      ..writeln('  xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">')
      ..writeln('  <p:sldMasterIdLst>')
      ..writeln('    <p:sldMasterId r:id="rId1"/>')
      ..writeln('  </p:sldMasterIdLst>')
      ..writeln('  <p:sldIdLst>');
    for (int i = 0; i < slideCount; i++) {
      buffer.writeln('    <p:sldId id="${256 + i}" r:id="rId${i + 2}"/>');
    }
    buffer
      ..writeln('  </p:sldIdLst>')
  ..writeln('  <p:sldSz cx="$cx" cy="$cy" type="screen16x9"/>')
  ..writeln('  <p:notesSz cx="6858000" cy="9144000"/>')
  ..writeln('</p:presentation>');
    return buffer.toString();
  }

  String _buildSlideMasterXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld name="Master">
    <p:bg>
      <p:bgPr>
        <a:solidFill>
          <a:schemeClr val="bg1"/>
        </a:solidFill>
      </p:bgPr>
    </p:bg>
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
          <a:chOff x="0" y="0"/>
          <a:chExt cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr>
    <a:masterClrMapping/>
  </p:clrMapOvr>
  <p:sldLayoutIdLst>
    <p:sldLayoutId id="1" r:id="rId1"/>
  </p:sldLayoutIdLst>
</p:sldMaster>''';
  }

  String _buildSlideMasterRelsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>
</Relationships>''';
  }

  String _buildSlideLayoutXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank" preserve="1">
  <p:cSld name="Blank">
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
          <a:chOff x="0" y="0"/>
          <a:chExt cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr>
    <a:masterClrMapping/>
  </p:clrMapOvr>
</p:sldLayout>''';
  }

  String _buildSlideLayoutRelsXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>''';
  }

  String _buildThemeXml() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Theme">
  <a:themeElements>
    <a:clrScheme name="Office">
      <a:dk1><a:srgbClr val="000000"/></a:dk1>
      <a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="1F497D"/></a:dk2>
      <a:lt2><a:srgbClr val="EEECE1"/></a:lt2>
      <a:accent1><a:srgbClr val="4F81BD"/></a:accent1>
      <a:accent2><a:srgbClr val="C0504D"/></a:accent2>
      <a:accent3><a:srgbClr val="9BBB59"/></a:accent3>
      <a:accent4><a:srgbClr val="8064A2"/></a:accent4>
      <a:accent5><a:srgbClr val="4BACC6"/></a:accent5>
      <a:accent6><a:srgbClr val="F79646"/></a:accent6>
      <a:hlink><a:srgbClr val="0000FF"/></a:hlink>
      <a:folHlink><a:srgbClr val="800080"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="Office">
      <a:majorFont>
        <a:latin typeface="Calibri"/>
      </a:majorFont>
      <a:minorFont>
        <a:latin typeface="Calibri"/>
      </a:minorFont>
    </a:fontScheme>
    <a:fmtScheme name="Office">
      <a:fillStyleLst>
        <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
        <a:gradFill rotWithShape="1">
          <a:gsLst>
            <a:gs pos="0"><a:schemeClr val="phClr"/></a:gs>
            <a:gs pos="100000"><a:schemeClr val="phClr"/></a:gs>
          </a:gsLst>
        </a:gradFill>
      </a:fillStyleLst>
      <a:lnStyleLst>
        <a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln>
      </a:lnStyleLst>
      <a:effectStyleLst>
        <a:effectStyle><a:effectLst/></a:effectStyle>
      </a:effectStyleLst>
      <a:bgFillStyleLst>
        <a:solidFill><a:schemeClr val="phClr"/></a:solidFill>
      </a:bgFillStyleLst>
    </a:fmtScheme>
  </a:themeElements>
</a:theme>''';
  }

  String _buildSlideXml(int slideNumber, String pageName, int cx, int cy) {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld name="${_xmlEscape(pageName)}">
    <p:spTree>
      <p:nvGrpSpPr>
        <p:cNvPr id="1" name=""/>
        <p:cNvGrpSpPr/>
        <p:nvPr/>
      </p:nvGrpSpPr>
      <p:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="0" cy="0"/>
          <a:chOff x="0" y="0"/>
          <a:chExt cx="0" cy="0"/>
        </a:xfrm>
      </p:grpSpPr>
      <p:pic>
        <p:nvPicPr>
          <p:cNvPr id="2" name="Image $slideNumber"/>
          <p:cNvPicPr>
            <a:picLocks noChangeAspect="1"/>
          </p:cNvPicPr>
          <p:nvPr/>
        </p:nvPicPr>
        <p:blipFill>
          <a:blip r:embed="rId2"/>
          <a:stretch>
            <a:fillRect/>
          </a:stretch>
        </p:blipFill>
        <p:spPr>
          <a:xfrm>
            <a:off x="0" y="0"/>
            <a:ext cx="$cx" cy="$cy"/>
          </a:xfrm>
          <a:prstGeom prst="rect">
            <a:avLst/>
          </a:prstGeom>
        </p:spPr>
      </p:pic>
    </p:spTree>
  </p:cSld>
  <p:clrMapOvr>
    <a:masterClrMapping/>
  </p:clrMapOvr>
</p:sld>''';
  }

  String _buildSlideRelsXml(int slideNumber) {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/image$slideNumber.png"/>
</Relationships>''';
  }

  String _xmlEscape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _ensureExtension(String path, String extension) {
    if (path.toLowerCase().endsWith(extension)) {
      return path;
    }
    return '$path$extension';
  }

  double _pointsFromPixels(double pixels) {
    const double dpi = 96.0;
    return pixels / dpi * pdf.PdfPageFormat.inch;
  }

  static const double _emuPerPixel = 9525.0; // 914400 / 96
}

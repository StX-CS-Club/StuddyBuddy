import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:studdy_buddy_app/frontend/startup/theme.dart';

import '../../backend/files/app_file.dart';

class FileViewPage extends StatelessWidget {
  const FileViewPage({super.key, required this.file});

  final AppFile file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StuddyBuddyTheme.surfaceDim,
      appBar: AppBar(
        backgroundColor: StuddyBuddyTheme.surfaceBase,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: StuddyBuddyTheme.teal,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          file.fileName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: StuddyBuddyTheme.nearBlack,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: file.isImage ? _ImageView(file: file) : _PdfView(file: file),
        ),
      ),
    );
  }
}

class _ImageView extends StatelessWidget {
  const _ImageView({required this.file});

  final AppFile file;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: file.path != null
          ? Image.file(File(file.path!), fit: BoxFit.contain)
          : Image.network(file.url!, fit: BoxFit.contain),
    );
  }
}

class _PdfView extends StatefulWidget {
  const _PdfView({required this.file});

  final AppFile file;

  @override
  State<_PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<_PdfView> {
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PDFView(
              filePath: widget.file.path,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              onRender: (pages) => setState(() => _totalPages = pages ?? 0),
              onPageChanged: (page, _) =>
                  setState(() => _currentPage = (page ?? 0) + 1),
            ),
          ),
        ),
        if (_totalPages > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '$_currentPage / $_totalPages',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import '../models/whiteboard_model.dart';
import '../services/auth_service.dart';
import '../services/whiteboard_factory.dart';
import '../screens/collaborative_drawing_page.dart';
import 'package:provider/provider.dart';

class WhiteboardListScreen extends StatefulWidget {
  const WhiteboardListScreen({Key? key}) : super(key: key);

  @override
  _WhiteboardListScreenState createState() => _WhiteboardListScreenState();
}

class _WhiteboardListScreenState extends State<WhiteboardListScreen> {
  List<WhiteboardModel>? _whiteboards;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWhiteboards();
  }

  Future<void> _loadWhiteboards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = await authService.getCurrentUser();
      
      if (currentUser != null) {
        final whiteboards = await WhiteboardFactory.getUserWhiteboards(currentUser.id);
        
        setState(() {
          _whiteboards = whiteboards;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Not logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading whiteboards: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewWhiteboard() async {
    final TextEditingController nameController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Whiteboard'),
          content: SingleChildScrollView(
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Whiteboard Name',
              ),
              autofocus: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  
                  setState(() {
                    _isLoading = true;
                  });
                  
                  try {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final currentUser = await authService.getCurrentUser();
                    
                    if (currentUser != null) {
                      final whiteboard = await WhiteboardFactory.createWhiteboard(
                        name: nameController.text.trim(),
                        ownerId: currentUser.id,
                        ownerName: currentUser.displayName,
                      );
                      
                      // Refresh the list
                      _loadWhiteboards();
                      
                      // Navigate to the new whiteboard
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CollaborativeDrawingPage(
                          whiteboardId: whiteboard.id,
                          whiteboardName: whiteboard.name,
                        ),
                      ));
                    }
                  } catch (e) {
                    setState(() {
                      _errorMessage = 'Error creating whiteboard: $e';
                      _isLoading = false;
                    });
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Whiteboards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWhiteboards,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _createNewWhiteboard,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Try Again'),
              onPressed: _loadWhiteboards,
            ),
          ],
        ),
      );
    }

    if (_whiteboards == null || _whiteboards!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No whiteboards found',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Create Whiteboard'),
              onPressed: _createNewWhiteboard,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _whiteboards!.length,
      itemBuilder: (context, index) {
        final whiteboard = _whiteboards![index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(whiteboard.name),
            subtitle: Text(
              'Updated: ${_formatDateTime(DateTime.fromMillisecondsSinceEpoch(whiteboard.updatedAt))}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CollaborativeDrawingPage(
                  whiteboardId: whiteboard.id,
                  whiteboardName: whiteboard.name,
                ),
              ));
            },
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
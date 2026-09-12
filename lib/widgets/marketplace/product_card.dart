import 'package:flutter/material.dart';
import 'package:agribased/models/product.dart';
import 'package:agribased/screens/chat/chat_screen.dart';
import 'package:agribased/services/chat_service.dart';
import 'package:agribased/services/auth_service.dart';
import 'package:agribased/widgets/safe_network_image.dart';
import 'package:agribased/app/utils/formatters.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  Future<void> _startChat(BuildContext context) async {
    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to start a chat')),
        );
        return;
      }

      if (currentUserId == product.sellerId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This is your own product')),
        );
        return;
      }

      final chat = await ChatService.instance.createChat(product.sellerId);

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatScreen(chatId: chat.id, otherUserId: product.sellerId),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          InkWell(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: SafeNetworkImage(
                imageUrl: product.imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: Container(height: 150, color: Colors.grey[300]),
              ),
            ),
          ),

          // DETAILS
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat, color: Colors.green),
                      onPressed: () => _startChat(context),
                      tooltip: 'Message Seller',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  Formatter.formatCurrency(product.price.toDouble()),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seller ID: ${product.sellerId}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

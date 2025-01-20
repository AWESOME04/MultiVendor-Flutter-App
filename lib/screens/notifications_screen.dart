import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample notifications data - in real app, this would come from a backend
    final List<Map<String, dynamic>> notifications = [
      {
        'title': '30% Special Discount!',
        'description': 'Special promotion only valid today.',
        'date': 'Today',
        'icon': Icons.local_offer_outlined,
      },
      {
        'title': 'Top Up E-wallet Successfully!',
        'description': 'You have top up your e-wallet.',
        'date': 'Yesterday',
        'icon': Icons.account_balance_wallet_outlined,
      },
      {
        'title': 'New Service Available!',
        'description': 'Now you can track order in real-time.',
        'date': 'Yesterday',
        'icon': Icons.location_on_outlined,
      },
      {
        'title': 'Credit Card Connected!',
        'description': 'Credit card has been linked.',
        'date': 'June 7, 2023',
        'icon': Icons.credit_card_outlined,
      },
      {
        'title': 'Account Setup Successfully!',
        'description': 'Your account has been created.',
        'date': 'June 7, 2023',
        'icon': Icons.person_outline,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(notifications),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'You haven\'t gotten any\nnotifications yet!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll alert you when something\ncool happens.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> notifications) {
    String? currentDate;
    
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final showDate = currentDate != notification['date'];
        if (showDate) {
          currentDate = notification['date'];
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showDate) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  notification['date'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            ListTile(
              leading: Icon(
                notification['icon'] as IconData,
                size: 28,
              ),
              title: Text(
                notification['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                notification['description'],
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}
